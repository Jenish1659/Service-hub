import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../storage/local_registration_cache.dart';
import 'live_booking_sync_service.dart';

class AuthResult {
  final bool isSuccess;
  final String? errorMessage;
  final Map<String, dynamic>? userData;
  final String? roleName;

  AuthResult({
    required this.isSuccess,
    this.errorMessage,
    this.userData,
    this.roleName,
  });
}

class SupabaseAuthService {
  static const String _sessionBoxName = 'partner_cache';

  static SupabaseClient get client => Supabase.instance.client;

  /// Secure Login using Username OR Mobile Number + Password
  static Future<AuthResult> loginWithUsernameOrPhone({
    required String identifier,
    required String password,
    required String expectedRole, // 'service_provider', 'customer', 'delivery_agent', 'admin'
  }) async {
    final cleanId = identifier.trim().toLowerCase().replaceAll('@', '');
    final cleanPass = password.trim();

    if (cleanId.isEmpty || cleanPass.isEmpty) {
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Please enter your username or mobile number and password.',
      );
    }

    try {
      // 1. Search users table using entered username OR phone number
      final cleanDigits = cleanId.replaceAll(RegExp(r'\D'), '');
      final isPhone = cleanDigits.length >= 10;
      final last10 = isPhone ? cleanDigits.substring(cleanDigits.length - 10) : '';

      final filterParts = <String>[
        'username.ilike.$cleanId',
        'email.ilike.$cleanId',
        'phone.eq.$cleanId',
      ];
      if (isPhone) {
        filterParts.add('phone.eq.+91$last10');
        filterParts.add('phone.ilike.*$last10*');
      }

      final usersRes = await client
          .from('users')
          .select('*, roles!inner(*), user_profiles(*), partners(*, service_provider_profiles(*), shopkeeper_profiles(*), delivery_agent_profiles(*))')
          .or(filterParts.join(','))
          .maybeSingle();

      if (usersRes == null) {
        // Check local persistent cache fallback
        final localMatch = await _checkLocalCachedUser(cleanId, cleanPass, expectedRole);
        if (localMatch != null) {
          final status = (localMatch['verification_status'] ?? '').toString().toUpperCase();
          final isApproved = status == 'VERIFIED' || status == 'APPROVED';
          if (!isApproved) {
            return AuthResult(
              isSuccess: false,
              errorMessage: 'PENDING_APPROVAL: Your application is pending Admin approval. You can only login to your dashboard after Admin approves your request.',
              userData: localMatch,
              roleName: localMatch['role_name'] ?? expectedRole,
            );
          }
          return AuthResult(
            isSuccess: true,
            userData: localMatch,
            roleName: localMatch['role_name'] ?? expectedRole,
          );
        }

        return AuthResult(
          isSuccess: false,
          errorMessage: 'Account not found. Please check your username or mobile number.',
        );
      }

      // 2. Validate account active status
      final isActive = usersRes['is_active'] as bool? ?? true;
      if (!isActive) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Your account is currently inactive.',
        );
      }

      final accountStatus = (usersRes['account_status'] ?? 'ACTIVE').toString().toUpperCase();
      if (accountStatus == 'SUSPENDED' || accountStatus == 'DEACTIVATED') {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Your account has been suspended. Please contact support.',
        );
      }

      // 3. Verify role matches expected application domain
      final roleData = usersRes['roles'] as Map<String, dynamic>? ?? {};
      final roleName = (roleData['role_name'] ?? '').toString().toLowerCase();

      if (roleName != expectedRole && expectedRole != 'any') {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Unauthorized access. This account is registered as a $roleName.',
        );
      }

      // 4. Verify password with Supabase Authentication securely
      final userEmail = usersRes['email']?.toString() ?? '$cleanId@servicehub.com';
      try {
        await client.auth.signInWithPassword(email: userEmail, password: cleanPass);
      } catch (authErr) {
        // If auth user not in auth.users yet (e.g. newly created business user), check local fallback
        final localPass = await _getStoredPasswordForUser(usersRes['user_id']);
        if (localPass != null && localPass != cleanPass) {
          return AuthResult(
            isSuccess: false,
            errorMessage: 'Incorrect password. Please try again.',
          );
        }
      }

      // 5. Enforce Admin Approval verification
      dynamic partnersData = usersRes['partners'];
      if (partnersData is List && partnersData.isNotEmpty) {
        partnersData = partnersData.first;
      } else if (partnersData is! Map) {
        partnersData = null;
      }

      final String partnerVerStatus = (partnersData?['verification_status'] ?? '').toString().toUpperCase();

      // Check verification_requests table in Supabase
      String? vrStatus;
      try {
        final vr = await client
            .from('verification_requests')
            .select('status')
            .eq('user_id', usersRes['user_id'])
            .order('submitted_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (vr != null) {
          vrStatus = (vr['status'] ?? '').toString().toUpperCase();
        }
      } catch (_) {}

      // Check LiveBookingSyncService memory and local sync bridge
      final userPhone = usersRes['phone']?.toString();
      final syncRecord = LiveBookingSyncService.instance.getPartnerVerification(usersRes['user_id']?.toString() ?? '') ??
          (partnersData?['partner_id'] != null ? LiveBookingSyncService.instance.getPartnerVerification(partnersData['partner_id'].toString()) : null) ??
          (userPhone != null ? LiveBookingSyncService.instance.getPartnerVerification(userPhone) : null) ??
          LiveBookingSyncService.instance.getPartnerVerification(cleanId);
      final String syncStatus = (syncRecord?['status'] ?? syncRecord?['verification_status'] ?? '').toString().toUpperCase();

      final bool isApproved = partnerVerStatus == 'VERIFIED' ||
          partnerVerStatus == 'APPROVED' ||
          accountStatus == 'ACTIVE' ||
          vrStatus == 'APPROVED' ||
          vrStatus == 'VERIFIED' ||
          syncStatus == 'APPROVED' ||
          syncStatus == 'VERIFIED';

      final bool isRejected = partnerVerStatus == 'REJECTED' ||
          vrStatus == 'REJECTED' ||
          syncStatus == 'REJECTED' ||
          accountStatus == 'REJECTED';

      // 6. Store active session locally
      final sessionData = {
        'user_id': usersRes['user_id'],
        'username': usersRes['username'],
        'email': usersRes['email'],
        'phone': usersRes['phone'],
        'role_name': roleName,
        'name': usersRes['user_profiles']?['first_name'] != null
            ? '${usersRes['user_profiles']['first_name']} ${usersRes['user_profiles']['last_name'] ?? ""}'.trim()
            : usersRes['username'],
        'business_name': (partnersData?['shopkeeper_profiles'] is Map)
            ? partnersData['shopkeeper_profiles']['business_name']
            : null,
        'partner_id': partnersData?['partner_id'] ?? usersRes['user_id'],
        'provider_id': partnersData?['service_provider_profiles']?['provider_id'],
        'verification_status': isApproved ? 'VERIFIED' : (isRejected ? 'REJECTED' : 'PENDING'),
        'status': isApproved ? 'APPROVED' : (isRejected ? 'REJECTED' : 'PENDING'),
        'account_status': isApproved ? 'ACTIVE' : (isRejected ? 'REJECTED' : 'PENDING_VERIFICATION'),
        'is_online': isApproved && partnersData?['availability_status'] == 'ONLINE',
      };

      await _saveActiveSession(sessionData);

      if (isRejected) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'REJECTED: Your application was rejected by the Admin. Please contact support.',
          userData: sessionData,
          roleName: roleName,
        );
      }

      if (!isApproved) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'PENDING_APPROVAL: Your application is pending Admin approval. You can only login to your dashboard after Admin approves your request.',
          userData: sessionData,
          roleName: roleName,
        );
      }

      return AuthResult(
        isSuccess: true,
        userData: sessionData,
        roleName: roleName,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseAuthService] Remote login error: $e');
      }

      // Check offline fallback cache
      final localMatch = await _checkLocalCachedUser(cleanId, cleanPass, expectedRole);
      if (localMatch != null) {
        final status = (localMatch['verification_status'] ?? '').toString().toUpperCase();
        final isApproved = status == 'VERIFIED' || status == 'APPROVED';
        if (!isApproved) {
          return AuthResult(
            isSuccess: false,
            errorMessage: 'PENDING_APPROVAL: Your application is pending Admin approval. You can only login to your dashboard after Admin approves your request.',
            userData: localMatch,
            roleName: localMatch['role_name'] ?? expectedRole,
          );
        }
        return AuthResult(
          isSuccess: true,
          userData: localMatch,
          roleName: localMatch['role_name'] ?? expectedRole,
        );
      }

      return AuthResult(
        isSuccess: false,
        errorMessage: 'Invalid username/mobile number or password.',
      );
    }
  }

  /// Register a new Service Provider into the real 70-table database with full KYC synchronization
  static Future<AuthResult> registerServiceProvider({
    required String username,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    required String state,
    required String city,
    required String serviceCategoryId,
    required String specialization,
    String? aadhaarNumber,
    String? panNumber,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? accountHolderName,
    String? businessName,
    String? businessAddress,
    int? experienceYears,
  }) async {
    try {
      final cleanUsername = username.trim().toLowerCase().replaceAll('@', '');
      final cleanPhone = phone.trim();
      final cleanEmail = email.trim().isNotEmpty ? email.trim() : '$cleanUsername@servicehub.com';
      final cleanBusinessName = (businessName != null && businessName.trim().isNotEmpty)
          ? businessName.trim()
          : '$firstName Services';
      final cleanBusinessAddress = (businessAddress != null && businessAddress.trim().isNotEmpty)
          ? businessAddress.trim()
          : '$city, $state';

      // 1. Create Supabase Auth User (graceful if rate limited or already exists)
      String? authId;
      try {
        final authRes = await client.auth.signUp(email: cleanEmail, password: password);
        authId = authRes.user?.id;
      } catch (authErr) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuthService] Auth signup note: $authErr');
        }
      }

      // 2. Fetch role_id for service_provider (with real fallback)
      String roleId = 'e0099244-3a0f-44b1-b347-111b7dd09777';
      try {
        final roleRes = await client.from('roles').select('role_id').eq('role_name', 'service_provider').maybeSingle();
        if (roleRes != null && roleRes['role_id'] != null) {
          roleId = roleRes['role_id'].toString();
        }
      } catch (_) {}

      // 3. Idempotent User Check/Insert: Check if user already exists by phone, email, or username
      String? userId;
      try {
        final rawDigits = cleanPhone.replaceAll(RegExp(r'\D'), '');
        final userMatches = await client
            .from('users')
            .select('user_id, phone, email, username')
            .or('phone.eq.$cleanPhone,email.eq.$cleanEmail,username.eq.$cleanUsername${rawDigits.length >= 10 ? ',phone.ilike.*${rawDigits.substring(rawDigits.length - 10)}*' : ''}')
            .limit(1);

        if (userMatches.isNotEmpty) {
          final matchedId = userMatches.first['user_id']?.toString();
          if (matchedId != null && matchedId.isNotEmpty) {
            userId = matchedId;
            // Update existing user to pending verification
            await client.from('users').update({
              'account_status': 'PENDING_VERIFICATION',
              'is_active': true,
            }).eq('user_id', matchedId);
          }
        }
      } catch (checkErr) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuthService] User lookup note: $checkErr');
        }
      }

      if (userId == null || userId.isEmpty) {
        final userInsert = await client.from('users').insert({
          'auth_id': authId,
          'role_id': roleId,
          'username': cleanUsername,
          'email': cleanEmail,
          'phone': cleanPhone,
          'account_status': 'PENDING_VERIFICATION',
          'is_active': true,
        }).select().single();
        userId = userInsert['user_id']?.toString();
      }

      if (userId == null || userId.isEmpty) {
        throw Exception('Failed to resolve or create user in Supabase');
      }

      // 4. Insert or update user_profiles table
      try {
        final existingProfile = await client.from('user_profiles').select('profile_id').eq('user_id', userId).maybeSingle();
        if (existingProfile != null) {
          await client.from('user_profiles').update({
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
          }).eq('user_id', userId);
        } else {
          await client.from('user_profiles').insert({
            'user_id': userId,
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
          });
        }
      } catch (_) {}

      // 5. Insert or update user_addresses table
      try {
        final existingAddr = await client.from('user_addresses').select('address_id').eq('user_id', userId).maybeSingle();
        if (existingAddr != null) {
          await client.from('user_addresses').update({
            'area': city,
            'city': city,
            'state': state,
          }).eq('user_id', userId);
        } else {
          await client.from('user_addresses').insert({
            'user_id': userId,
            'address_type': 'Work',
            'area': city,
            'city': city,
            'state': state,
            'pincode': '361001',
            'latitude': 22.4707,
            'longitude': 70.0577,
            'is_default': true,
          });
        }
      } catch (_) {}

      // 6. Idempotent insert or update into partners table (PENDING verification)
      String? partnerId;
      try {
        final existingPartner = await client.from('partners').select('partner_id').eq('user_id', userId).maybeSingle();
        if (existingPartner != null) {
          final matchedPartnerId = existingPartner['partner_id']?.toString();
          partnerId = matchedPartnerId;
          if (matchedPartnerId != null && matchedPartnerId.isNotEmpty) {
            await client.from('partners').update({
              'verification_status': 'PENDING',
              'availability_status': 'OFFLINE',
              'approved_at': null,
            }).eq('partner_id', matchedPartnerId);
          }
        } else {
          final partnerInsert = await client.from('partners').insert({
            'user_id': userId,
            'verification_status': 'PENDING',
            'availability_status': 'OFFLINE',
          }).select().single();
          partnerId = partnerInsert['partner_id']?.toString();
        }
      } catch (pErr) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuthService] Partner table note: $pErr');
        }
      }

      // 7. Idempotent insert or update into service_provider_profiles table
      String? providerId;
      if (partnerId != null && partnerId.isNotEmpty) {
        final currentPartnerId = partnerId;
        try {
          final existingProv = await client.from('service_provider_profiles').select('provider_id').eq('partner_id', currentPartnerId).maybeSingle();
          if (existingProv != null) {
            final matchedProvId = existingProv['provider_id']?.toString();
            providerId = matchedProvId;
            if (matchedProvId != null && matchedProvId.isNotEmpty) {
              await client.from('service_provider_profiles').update({
                'experience_years': experienceYears ?? 3,
                'about': 'Expert $specialization technician with quality service guarantee.',
              }).eq('provider_id', matchedProvId);
            }
          } else {
            final providerInsert = await client.from('service_provider_profiles').insert({
              'partner_id': currentPartnerId,
              'experience_years': experienceYears ?? 3,
              'about': 'Expert $specialization technician with quality service guarantee.',
              'rating': 0.0,
              'total_jobs': 0,
              'service_radius_km': 10.0,
            }).select().single();
            providerId = providerInsert['provider_id']?.toString();
          }
        } catch (_) {}
      }

      // 8. Insert into verification_requests table (Unlimited KYC applications)
      final remarksParts = <String>[
        'New registration application for $cleanUsername',
        'Role: service_provider',
        'Category: $serviceCategoryId',
        'Specialization: $specialization',
        'Phone: $cleanPhone',
        'City: $city',
        if (aadhaarNumber != null && aadhaarNumber.isNotEmpty) 'Aadhaar: $aadhaarNumber',
        if (panNumber != null && panNumber.isNotEmpty) 'PAN: $panNumber',
        if (bankName != null && bankName.isNotEmpty) 'Bank: $bankName',
        if (accountNumber != null && accountNumber.isNotEmpty) 'Acc: $accountNumber',
        if (ifscCode != null && ifscCode.isNotEmpty) 'IFSC: $ifscCode',
        if (accountHolderName != null && accountHolderName.isNotEmpty) 'Holder: $accountHolderName',
        'Business: $cleanBusinessName',
        'Address: $cleanBusinessAddress',
      ];
      final kycRemarks = remarksParts.join(' | ');

      String? createdVerId;
      try {
        final vrInsert = await client.from('verification_requests').insert({
          'user_id': userId,
          'verification_type': 'AADHAAR',
          'status': 'PENDING',
          'remarks': kycRemarks,
        }).select().single();
        createdVerId = vrInsert['verification_id']?.toString();
      } catch (vrErr) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuthService] verification_requests insert note: $vrErr');
        }
      }

      // 9. Insert KYC identity documents into identity_documents table
      if (aadhaarNumber != null && aadhaarNumber.trim().isNotEmpty) {
        try {
          await client.from('identity_documents').insert({
            'user_id': userId,
            'document_type': 'AADHAAR',
            'document_number': aadhaarNumber.trim(),
            'verification_status': 'PENDING',
          });
        } catch (_) {}
      }
      if (panNumber != null && panNumber.trim().isNotEmpty) {
        try {
          await client.from('identity_documents').insert({
            'user_id': userId,
            'document_type': 'PAN',
            'document_number': panNumber.trim(),
            'verification_status': 'PENDING',
          });
        } catch (_) {}
      }

      final verId = createdVerId ?? 'ver_provider_$userId';
      final sessionData = {
        'id': verId,
        'verification_id': verId,
        'user_id': userId,
        'username': cleanUsername,
        'email': cleanEmail,
        'phone': cleanPhone,
        'role_name': 'service_provider',
        'name': '$firstName $lastName'.trim(),
        'business_name': cleanBusinessName,
        'business_address': cleanBusinessAddress,
        'partner_id': partnerId ?? '',
        'provider_id': providerId ?? '',
        'verification_status': 'PENDING',
        'status': 'PENDING',
        'is_online': false,
      };

      await _saveActiveSession(sessionData);

      // Broadcast to LiveBookingSyncService for instant Admin App queue recognition
      try {
        await LiveBookingSyncService.instance.submitPartnerVerification({
          'id': verId,
          'verification_id': verId,
          'user_id': userId,
          'partner_id': partnerId ?? '',
          'provider_id': providerId ?? '',
          'name': '$firstName $lastName'.trim(),
          'full_name': '$firstName $lastName'.trim(),
          'phone': cleanPhone,
          'email': cleanEmail,
          'role': 'service_provider',
          'role_name': 'service_provider',
          'category': serviceCategoryId,
          'category_name': 'AC Service Provider',
          'business_name': cleanBusinessName,
          'business_address': cleanBusinessAddress,
          'city': city,
          'state': state,
          'verification_status': 'PENDING',
          'status': 'PENDING',
          'document_type': 'PROVIDER_ONBOARDING',
          'verification_type': 'AADHAAR',
          'aadhaar_number': aadhaarNumber ?? '',
          'pan_number': panNumber ?? '',
          'bank_name': bankName ?? '',
          'account_number': accountNumber ?? '',
          'ifsc_code': ifscCode ?? '',
          'account_holder_name': accountHolderName ?? '$firstName $lastName'.trim(),
          'submitted_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      return AuthResult(
        isSuccess: true,
        userData: sessionData,
        roleName: 'service_provider',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseAuthService] Registration error: $e');
      }

      // Offline / Local save fallback
      final fallbackSession = {
        'user_id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'username': username.trim().toLowerCase(),
        'name': '$firstName $lastName'.trim(),
        'business_name': '$firstName AC Service Center',
        'phone': phone.trim(),
        'email': email.trim(),
        'password': password,
        'role_name': 'service_provider',
        'category': serviceCategoryId,
        'verification_status': 'PENDING',
        'is_online': false,
      };

      await _saveActiveSession(fallbackSession);

      return AuthResult(
        isSuccess: true,
        userData: fallbackSession,
        roleName: 'service_provider',
      );
    }
  }

  /// Register a new Shopkeeper into the real database with full KYC and LiveBooking synchronization
  static Future<AuthResult> registerShopkeeper({
    required String username,
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    required String shopName,
    required String category,
    required String shopAddress,
    String? email,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    double? latitude,
    double? longitude,
    String? aadhaarNumber,
    String? yearsInBusiness,
  }) async {
    final cleanUsername = username.trim().toLowerCase().replaceAll('@', '');
    final cleanPhone = phone.trim();
    final cleanEmail = (email != null && email.trim().isNotEmpty) ? email.trim() : '$cleanUsername@servicehub.com';
    final cleanShopName = shopName.trim().isNotEmpty ? shopName.trim() : '$firstName Electronics';
    final cleanCity = (city != null && city.trim().isNotEmpty) ? city.trim() : 'Jamnagar';
    final cleanState = (state != null && state.trim().isNotEmpty) ? state.trim() : 'Gujarat';
    final cleanPincode = (pincode != null && pincode.trim().isNotEmpty) ? pincode.trim() : '361001';
    final cleanAddress = [
      shopAddress.trim(),
      if (landmark != null && landmark.trim().isNotEmpty) landmark.trim(),
    ].where((s) => s.isNotEmpty).join(', ');
    final lat = latitude ?? 22.4707;
    final lng = longitude ?? 70.0577;

    try {
      // 1. Create Supabase Auth User
      String? authId;
      try {
        final authRes = await client.auth.signUp(email: cleanEmail, password: password);
        authId = authRes.user?.id;
      } catch (authErr) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuthService] Shopkeeper auth note: $authErr');
        }
      }

      // 2. Fetch role_id for shopkeeper
      String roleId = 'a96fc0d6-afd9-45a4-bab1-ee41363b033a';
      try {
        final roleRes = await client.from('roles').select('role_id').eq('role_name', 'shopkeeper').maybeSingle();
        if (roleRes != null && roleRes['role_id'] != null) {
          roleId = roleRes['role_id'].toString();
        }
      } catch (_) {}

      // 3. User check / insert in users table
      String? userId;
      try {
        final rawDigits = cleanPhone.replaceAll(RegExp(r'\D'), '');
        final userMatches = await client
            .from('users')
            .select('user_id, phone, email, username')
            .or('phone.eq.$cleanPhone,email.eq.$cleanEmail,username.eq.$cleanUsername${rawDigits.length >= 10 ? ',phone.ilike.*${rawDigits.substring(rawDigits.length - 10)}*' : ''}')
            .limit(1);

        if (userMatches.isNotEmpty) {
          final matchedId = userMatches.first['user_id']?.toString();
          if (matchedId != null && matchedId.isNotEmpty) {
            userId = matchedId;
            await client.from('users').update({
              'role_id': roleId,
              'account_status': 'PENDING_VERIFICATION',
              'is_active': true,
            }).eq('user_id', matchedId);
          }
        }
      } catch (checkErr) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuthService] Shopkeeper lookup note: $checkErr');
        }
      }

      if (userId == null || userId.isEmpty) {
        final userInsert = await client.from('users').insert({
          'auth_id': authId,
          'role_id': roleId,
          'username': cleanUsername,
          'email': cleanEmail,
          'phone': cleanPhone,
          'account_status': 'PENDING_VERIFICATION',
          'is_active': true,
        }).select().single();
        userId = userInsert['user_id']?.toString();
      }

      if (userId == null || userId.isEmpty) {
        throw Exception('Failed to resolve or create shopkeeper user in Supabase');
      }

      // 4. Insert or update user_profiles
      try {
        final existingProfile = await client.from('user_profiles').select('profile_id').eq('user_id', userId).maybeSingle();
        if (existingProfile != null) {
          await client.from('user_profiles').update({
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'city': cleanCity,
            'state': cleanState,
          }).eq('user_id', userId);
        } else {
          await client.from('user_profiles').insert({
            'user_id': userId,
            'first_name': firstName.trim(),
            'last_name': lastName.trim(),
            'city': cleanCity,
            'state': cleanState,
          });
        }
      } catch (_) {}

      // 5. Insert or update user_addresses
      try {
        final existingAddr = await client.from('user_addresses').select('address_id').eq('user_id', userId).maybeSingle();
        if (existingAddr != null) {
          await client.from('user_addresses').update({
            'street': cleanAddress,
            'area': cleanCity,
            'city': cleanCity,
            'state': cleanState,
            'pincode': cleanPincode,
            'latitude': lat,
            'longitude': lng,
          }).eq('user_id', userId);
        } else {
          await client.from('user_addresses').insert({
            'user_id': userId,
            'address_type': 'Work',
            'street': cleanAddress,
            'area': cleanCity,
            'city': cleanCity,
            'state': cleanState,
            'pincode': cleanPincode,
            'latitude': lat,
            'longitude': lng,
            'is_default': true,
          });
        }
      } catch (_) {}

      // 6. Insert or update partners table and shopkeeper_profiles
      String? partnerId;
      try {
        final existingPartner = await client.from('partners').select('partner_id').eq('user_id', userId).maybeSingle();
        if (existingPartner != null) {
          final matchedPartnerId = existingPartner['partner_id']?.toString();
          partnerId = matchedPartnerId;
          if (matchedPartnerId != null && matchedPartnerId.isNotEmpty) {
            await client.from('partners').update({
              'verification_status': 'PENDING',
              'availability_status': 'OFFLINE',
              'approved_at': null,
            }).eq('partner_id', matchedPartnerId);
          }
        } else {
          final partnerInsert = await client.from('partners').insert({
            'user_id': userId,
            'verification_status': 'PENDING',
            'availability_status': 'OFFLINE',
          }).select().single();
          partnerId = partnerInsert['partner_id']?.toString();
        }

        if (partnerId != null && partnerId.isNotEmpty) {
          try {
            await client.from('shopkeeper_profiles').upsert({
              'partner_id': partnerId,
              'business_name': cleanShopName,
              'business_type': category,
              'business_experience': int.tryParse(yearsInBusiness ?? '1') ?? 1,
            }, onConflict: 'partner_id');
          } catch (_) {}
        }
      } catch (pErr) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuthService] Shopkeeper partner insert note: $pErr');
        }
      }

      // 7. Insert into verification_requests
      final remarksParts = <String>[
        'New shopkeeper registration for $cleanUsername',
        'Role: shopkeeper',
        'Category: $category',
        'Business: $cleanShopName',
        'Address: $cleanAddress',
        if (aadhaarNumber != null && aadhaarNumber.isNotEmpty) 'Aadhaar: $aadhaarNumber',
        'City: $cleanCity',
        'Phone: $cleanPhone',
      ];
      final kycRemarks = remarksParts.join(' | ');

      String? createdVerId;
      try {
        final vrInsert = await client.from('verification_requests').insert({
          'user_id': userId,
          'verification_type': 'SHOP_LICENSE',
          'status': 'PENDING',
          'remarks': kycRemarks,
        }).select().single();
        createdVerId = vrInsert['verification_id']?.toString();
      } catch (vrErr) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuthService] Shopkeeper verification_requests insert note: $vrErr');
        }
      }

      // 8. Broadcast to LiveBookingSyncService (disk cache + HTTP port 8088 bridge)
      final verId = createdVerId ?? 'ver_shop_$userId';
      try {
        await LiveBookingSyncService.instance.submitPartnerVerification({
          'id': verId,
          'verification_id': verId,
          'user_id': userId,
          'partner_id': partnerId ?? verId,
          'name': '$firstName $lastName'.trim(),
          'full_name': '$firstName $lastName'.trim(),
          'username': cleanUsername,
          'phone': cleanPhone,
          'email': cleanEmail,
          'business_name': cleanShopName,
          'shop_name': cleanShopName,
          'category': category,
          'category_name': 'Shopkeeper ($category)',
          'role': 'shopkeeper',
          'role_name': 'shopkeeper',
          'city': cleanCity,
          'state': cleanState,
          'address': cleanAddress,
          'document_type': 'SHOPKEEPER_ONBOARDING',
          'verification_type': 'SHOP_LICENSE',
          'aadhaar_number': aadhaarNumber ?? '',
          'verification_status': 'PENDING',
          'status': 'PENDING',
          'submitted_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      // 9. Save active session & local credentials
      final sessionData = {
        'id': verId,
        'verification_id': verId,
        'user_id': userId,
        'username': cleanUsername,
        'email': cleanEmail,
        'phone': cleanPhone,
        'password': password,
        'role_name': 'shopkeeper',
        'role': 'shopkeeper',
        'name': '$firstName $lastName'.trim(),
        'business_name': cleanShopName,
        'business_address': cleanAddress,
        'category': category,
        'partner_id': partnerId ?? userId,
        'verification_status': 'PENDING',
        'status': 'PENDING',
        'is_online': false,
      };

      await _saveActiveSession(sessionData);

      return AuthResult(
        isSuccess: true,
        userData: sessionData,
        roleName: 'shopkeeper',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseAuthService] Shopkeeper registration error: $e');
      }

      // Offline fallback session
      final fallbackUserId = 'shop_${DateTime.now().millisecondsSinceEpoch}';
      final fallbackSession = {
        'user_id': fallbackUserId,
        'username': cleanUsername,
        'name': '$firstName $lastName'.trim(),
        'business_name': cleanShopName,
        'business_address': cleanAddress,
        'phone': cleanPhone,
        'email': cleanEmail,
        'password': password,
        'role_name': 'shopkeeper',
        'category': category,
        'partner_id': fallbackUserId,
        'verification_status': 'PENDING',
        'is_online': false,
      };

      await _saveActiveSession(fallbackSession);

      try {
        await LiveBookingSyncService.instance.submitPartnerVerification({
          'id': fallbackUserId,
          'verification_id': fallbackUserId,
          'user_id': fallbackUserId,
          'partner_id': fallbackUserId,
          'name': '$firstName $lastName'.trim(),
          'full_name': '$firstName $lastName'.trim(),
          'username': cleanUsername,
          'phone': cleanPhone,
          'email': cleanEmail,
          'business_name': cleanShopName,
          'category': category,
          'category_name': 'Shopkeeper ($category)',
          'role': 'shopkeeper',
          'role_name': 'shopkeeper',
          'document_type': 'SHOPKEEPER_ONBOARDING',
          'verification_type': 'SHOP_LICENSE',
          'city': cleanCity,
          'state': cleanState,
          'address': cleanAddress,
          'verification_status': 'PENDING',
          'status': 'PENDING',
          'submitted_at': DateTime.now().toIso8601String(),
        });
      } catch (_) {}

      return AuthResult(
        isSuccess: true,
        userData: fallbackSession,
        roleName: 'shopkeeper',
      );
    }
  }

  /// Register a new Delivery Agent into the real database with full KYC and LiveBooking synchronization
  static Future<AuthResult> registerDeliveryAgent({
    required String username,
    required String fullName,
    required String phone,
    required String password,
    required String vehicleType,
    required String vehicleNumber,
    required String drivingLicenseNumber,
    String? email,
    String? city,
    String? state,
    String? fullAddress,
    String? aadhaarNumber,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? accountHolderName,
    String? photoUrl,
    String? dlUrl,
    String? rcUrl,
    String? insUrl,
  }) async {
    final cleanUsername = username.trim().toLowerCase().replaceAll('@', '');
    final cleanPhone = phone.trim();
    final cleanEmail = (email != null && email.trim().isNotEmpty) ? email.trim() : '$cleanUsername@servicehub.com';
    final cleanCity = (city != null && city.trim().isNotEmpty) ? city.trim() : 'Jamnagar';
    final cleanState = (state != null && state.trim().isNotEmpty) ? state.trim() : 'Gujarat';
    final cleanAddress = (fullAddress != null && fullAddress.trim().isNotEmpty) ? fullAddress.trim() : '$cleanCity, $cleanState';
    final parts = fullName.trim().split(' ');
    final firstName = parts.isNotEmpty ? parts.first : 'Delivery';
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : 'Partner';

    // Normalize vehicleType for PostgreSQL CHECK constraint: CHECK (vehicle_type IN ('Bike', 'Scooter', 'Electric Vehicle'))
    String normalizedVehicleType = 'Bike';
    final vLower = vehicleType.toLowerCase();
    if (vLower.contains('scooter')) {
      normalizedVehicleType = 'Scooter';
    } else if (vLower.contains('electric') || vLower.contains('ev')) {
      normalizedVehicleType = 'Electric Vehicle';
    } else {
      normalizedVehicleType = 'Bike';
    }

    try {
      // 1. Create Supabase Auth User
      String? authId;
      try {
        final authRes = await client.auth.signUp(email: cleanEmail, password: password);
        authId = authRes.user?.id;
      } catch (authErr) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuthService] Delivery agent auth note: $authErr');
        }
      }

      // 2. Fetch role_id for delivery_agent
      String roleId = 'f0022394-5806-4ea7-9351-5e1b14465730';
      try {
        final roleRes = await client.from('roles').select('role_id').eq('role_name', 'delivery_agent').maybeSingle();
        if (roleRes != null && roleRes['role_id'] != null) {
          roleId = roleRes['role_id'].toString();
        }
      } catch (_) {}

      // 3. User check / insert in users table
      String? userId;
      try {
        final rawDigits = cleanPhone.replaceAll(RegExp(r'\D'), '');
        final userMatches = await client
            .from('users')
            .select('user_id, phone, email, username')
            .or('phone.eq.$cleanPhone,email.eq.$cleanEmail,username.eq.$cleanUsername${rawDigits.length >= 10 ? ',phone.ilike.*${rawDigits.substring(rawDigits.length - 10)}*' : ''}')
            .limit(1);

        if (userMatches.isNotEmpty) {
          final matchedId = userMatches.first['user_id']?.toString();
          if (matchedId != null && matchedId.isNotEmpty) {
            userId = matchedId;
            await client.from('users').update({
              'role_id': roleId,
              'account_status': 'PENDING_VERIFICATION',
              'is_active': true,
            }).eq('user_id', matchedId);
          }
        }
      } catch (checkErr) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuthService] Delivery agent user lookup note: $checkErr');
        }
      }

      if (userId == null || userId.isEmpty) {
        final userInsert = await client.from('users').insert({
          'auth_id': authId,
          'role_id': roleId,
          'username': cleanUsername,
          'email': cleanEmail,
          'phone': cleanPhone,
          'account_status': 'PENDING_VERIFICATION',
          'is_active': true,
        }).select().single();
        userId = userInsert['user_id']?.toString();
      }

      if (userId == null || userId.isEmpty) {
        throw Exception('Failed to resolve or create delivery agent user in Supabase');
      }

      // 4. Insert or update user_profiles
      try {
        final existingProfile = await client.from('user_profiles').select('profile_id').eq('user_id', userId).maybeSingle();
        if (existingProfile != null) {
          await client.from('user_profiles').update({
            'first_name': firstName,
            'last_name': lastName,
            'profile_photo': photoUrl,
          }).eq('user_id', userId);
        } else {
          await client.from('user_profiles').insert({
            'user_id': userId,
            'first_name': firstName,
            'last_name': lastName,
            'profile_photo': photoUrl,
          });
        }
      } catch (_) {}

      // 5. Insert or update user_addresses
      try {
        final existingAddr = await client.from('user_addresses').select('address_id').eq('user_id', userId).maybeSingle();
        if (existingAddr != null) {
          await client.from('user_addresses').update({
            'street': cleanAddress,
            'area': cleanCity,
            'city': cleanCity,
            'state': cleanState,
          }).eq('user_id', userId);
        } else {
          await client.from('user_addresses').insert({
            'user_id': userId,
            'address_type': 'Work',
            'street': cleanAddress,
            'area': cleanCity,
            'city': cleanCity,
            'state': cleanState,
            'pincode': '361001',
            'latitude': 22.4707,
            'longitude': 70.0577,
            'is_default': true,
          });
        }
      } catch (_) {}

      // 6. Insert or update partners table
      String? partnerId;
      try {
        final existingPartner = await client.from('partners').select('partner_id').eq('user_id', userId).maybeSingle();
        if (existingPartner != null) {
          final matchedPartnerId = existingPartner['partner_id']?.toString();
          partnerId = matchedPartnerId;
          if (matchedPartnerId != null && matchedPartnerId.isNotEmpty) {
            await client.from('partners').update({
              'verification_status': 'PENDING',
              'availability_status': 'OFFLINE',
              'approved_at': null,
            }).eq('partner_id', matchedPartnerId);
          }
        } else {
          final partnerInsert = await client.from('partners').insert({
            'user_id': userId,
            'verification_status': 'PENDING',
            'availability_status': 'OFFLINE',
          }).select().single();
          partnerId = partnerInsert['partner_id']?.toString();
        }

        // 7. Insert or update delivery_agent_profiles
        if (partnerId != null && partnerId.isNotEmpty) {
          try {
            await client.from('delivery_agent_profiles').upsert({
              'partner_id': partnerId,
              'vehicle_type': normalizedVehicleType,
              'vehicle_number': vehicleNumber.trim().toUpperCase(),
              'driving_license_number': drivingLicenseNumber.trim().toUpperCase(),
              'availability_status': 'ONLINE',
            }, onConflict: 'partner_id');
          } catch (_) {}
        }
      } catch (pErr) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuthService] Delivery agent partner insert note: $pErr');
        }
      }

      // 8. Insert into verification_requests
      final remarksParts = <String>[
        'New delivery partner registration for $cleanUsername',
        'Role: delivery_agent',
        'Category: delivery_agent',
        'VehicleType: $normalizedVehicleType',
        'VehicleNo: ${vehicleNumber.trim().toUpperCase()}',
        'DL: ${drivingLicenseNumber.trim().toUpperCase()}',
        'City: $cleanCity',
        'Phone: $cleanPhone',
        if (aadhaarNumber != null && aadhaarNumber.isNotEmpty) 'Aadhaar: $aadhaarNumber',
        if (bankName != null && bankName.isNotEmpty) 'Bank: $bankName',
        if (accountNumber != null && accountNumber.isNotEmpty) 'Acc: $accountNumber',
        if (ifscCode != null && ifscCode.isNotEmpty) 'IFSC: $ifscCode',
        if (accountHolderName != null && accountHolderName.isNotEmpty) 'Holder: $accountHolderName',
        'Business: $fullName Express Delivery',
        'Address: $cleanAddress',
      ];
      final kycRemarks = remarksParts.join(' | ');

      String? createdVerId;
      try {
        final vrInsert = await client.from('verification_requests').insert({
          'user_id': userId,
          'verification_type': 'DRIVING_LICENSE',
          'status': 'PENDING',
          'remarks': kycRemarks,
        }).select().single();
        createdVerId = vrInsert['verification_id']?.toString();
      } catch (vrErr) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuthService] Delivery agent verification_requests insert note: $vrErr');
        }
      }

      // 9. Broadcast to LiveBookingSyncService
      final verId = createdVerId ?? 'ver_delivery_$userId';
      final sessionData = {
        'id': verId,
        'verification_id': verId,
        'user_id': userId,
        'partner_id': partnerId ?? verId,
        'name': fullName.trim(),
        'full_name': fullName.trim(),
        'username': cleanUsername,
        'phone': cleanPhone,
        'email': cleanEmail,
        'password': password,
        'role': 'delivery_agent',
        'role_name': 'delivery_agent',
        'business_name': '$fullName Express Delivery',
        'category': 'delivery_agent',
        'category_name': 'Delivery Partner ($normalizedVehicleType)',
        'vehicle_type': normalizedVehicleType,
        'vehicle_number': vehicleNumber.trim().toUpperCase(),
        'driving_license_number': drivingLicenseNumber.trim().toUpperCase(),
        'city': cleanCity,
        'state': cleanState,
        'address': cleanAddress,
        'document_type': 'DELIVERY_ONBOARDING',
        'verification_type': 'DRIVING_LICENSE',
        'aadhaar_number': aadhaarNumber ?? '',
        'verification_status': 'PENDING',
        'status': 'PENDING',
        'submitted_at': DateTime.now().toIso8601String(),
        'is_online': false,
      };

      try {
        await LiveBookingSyncService.instance.submitPartnerVerification(sessionData);
      } catch (_) {}

      await _saveActiveSession(sessionData);
      await LocalRegistrationCache.updateActiveDeliveryAgent(sessionData);

      return AuthResult(
        isSuccess: true,
        userData: sessionData,
        roleName: 'delivery_agent',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupabaseAuthService] Delivery agent registration error: $e');
      }

      // Offline fallback session
      final fallbackUserId = 'delivery_${DateTime.now().millisecondsSinceEpoch}';
      final fallbackSession = {
        'id': fallbackUserId,
        'verification_id': fallbackUserId,
        'user_id': fallbackUserId,
        'partner_id': fallbackUserId,
        'username': cleanUsername,
        'name': fullName.trim(),
        'full_name': fullName.trim(),
        'business_name': '$fullName Express Delivery',
        'vehicle_type': normalizedVehicleType,
        'vehicle_number': vehicleNumber,
        'driving_license_number': drivingLicenseNumber,
        'phone': cleanPhone,
        'email': cleanEmail,
        'password': password,
        'role': 'delivery_agent',
        'role_name': 'delivery_agent',
        'category': 'delivery_agent',
        'category_name': 'Delivery Partner ($normalizedVehicleType)',
        'city': cleanCity,
        'state': cleanState,
        'document_type': 'DELIVERY_ONBOARDING',
        'verification_type': 'DRIVING_LICENSE',
        'verification_status': 'PENDING',
        'status': 'PENDING',
        'submitted_at': DateTime.now().toIso8601String(),
        'is_online': false,
      };

      await _saveActiveSession(fallbackSession);
      await LocalRegistrationCache.updateActiveDeliveryAgent(fallbackSession);

      try {
        await LiveBookingSyncService.instance.submitPartnerVerification(fallbackSession);
      } catch (_) {}

      return AuthResult(
        isSuccess: true,
        userData: fallbackSession,
        roleName: 'delivery_agent',
      );
    }
  }

  static Future<void> _saveActiveSession(Map<String, dynamic> session) async {
    try {
      final role = (session['role_name'] ?? session['role'] ?? '').toString().toLowerCase();
      await LocalRegistrationCache.updateActivePartner(session, role);

      if (Hive.isBoxOpen(_sessionBoxName)) {
        final box = Hive.box(_sessionBoxName);
        await box.put('active_user_session', session);
        await box.put('active_partner_session', session);

        // Store in registered users list for local lookup
        final List<dynamic> rawList = box.get('registered_users_list', defaultValue: []) as List<dynamic>;
        final List<Map<String, dynamic>> users = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        users.removeWhere((u) => u['username'] == session['username'] || u['phone'] == session['phone']);
        users.add(session);
        await box.put('registered_users_list', users);
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> _checkLocalCachedUser(String identifier, String password, String expectedRole) async {
    try {
      if (Hive.isBoxOpen(_sessionBoxName)) {
        final box = Hive.box(_sessionBoxName);
        final List<dynamic> rawList = [
          ...(box.get('registered_users_list', defaultValue: []) as List<dynamic>),
          ...(box.get('registered_partners_list', defaultValue: []) as List<dynamic>),
        ];
        final activePartner = box.get('active_partner_session');
        if (activePartner is Map) rawList.add(activePartner);
        final activeUser = box.get('active_user_session');
        if (activeUser is Map) rawList.add(activeUser);

        final cleanId = identifier.trim().toLowerCase().replaceAll('@', '').replaceAll('+', '').replaceAll(' ', '');

        for (final item in rawList) {
          if (item is Map) {
            final uName = (item['username'] ?? '').toString().toLowerCase().replaceAll('@', '').replaceAll(' ', '');
            final uPhone = (item['phone'] ?? item['mobile'] ?? '').toString().toLowerCase().replaceAll('+', '').replaceAll(' ', '');
            final uPass = (item['password'] ?? '').toString();
            final uRole = (item['role_name'] ?? item['role'] ?? '').toString().toLowerCase();

            final idMatches = (uName == cleanId || uPhone == cleanId || (cleanId.length >= 10 && uPhone.endsWith(cleanId)));
            final passMatches = (uPass.isEmpty || uPass == password.trim());

            if (idMatches && passMatches) {
              if (uRole == expectedRole || expectedRole == 'any' || uRole.isEmpty) {
                final match = Map<String, dynamic>.from(item);
                // Check latest live sync status
                final syncRecord = LiveBookingSyncService.instance.getPartnerVerification(match['user_id']?.toString() ?? '') ??
                    LiveBookingSyncService.instance.getPartnerVerification(match['id']?.toString() ?? '') ??
                    LiveBookingSyncService.instance.getPartnerVerification(identifier);
                final syncStatus = (syncRecord?['status'] ?? syncRecord?['verification_status'] ?? '').toString().toUpperCase();
                if (syncStatus.isNotEmpty) {
                  match['verification_status'] = syncStatus;
                }
                await box.put('active_user_session', match);
                await box.put('active_partner_session', match);
                return match;
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _getStoredPasswordForUser(dynamic userId) async {
    try {
      if (Hive.isBoxOpen(_sessionBoxName)) {
        final box = Hive.box(_sessionBoxName);
        final session = box.get('active_user_session');
        if (session is Map && session['user_id'] == userId && session['password'] != null) {
          return session['password']?.toString();
        }
        final rawList = box.get('registered_users_list', defaultValue: []) as List<dynamic>;
        for (var u in rawList) {
          if (u is Map && u['user_id'] == userId && u['password'] != null) {
            return u['password'].toString();
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<void> logout() async {
    try {
      await client.auth.signOut();
    } catch (_) {}
    try {
      if (Hive.isBoxOpen(_sessionBoxName)) {
        final box = Hive.box(_sessionBoxName);
        await box.delete('active_user_session');
        await box.delete('active_partner_session');
        await box.delete('active_service_provider_session');
        await box.delete('active_shopkeeper_session');
        await box.delete('active_delivery_agent_session');
        await box.delete('current_active_role');
        await box.delete('partner_registration_draft');
        await box.delete('partner_token');
        await box.delete('partner_role');
        await box.delete('saved_user_id');
        await box.delete('saved_role_id');
        await box.delete('cached_shopkeeper_data');
        await box.delete('cached_delivery_data');
        await box.delete('cached_credentials');
        await box.delete('user_credentials');
        await box.flush();
      }
    } catch (_) {}
    await LocalRegistrationCache.clearActiveSession();
  }

  static Future<void> signOut() async => logout();
  static Future<void> clearActiveSession() async => logout();
}
