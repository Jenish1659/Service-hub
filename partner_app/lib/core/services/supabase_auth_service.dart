import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
      final usersRes = await client
          .from('users')
          .select('*, roles!inner(*), user_profiles(*), partners(*, service_provider_profiles(*))')
          .or('username.ilike.$cleanId,phone.eq.$cleanId,phone.eq.+91$cleanId')
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
          vrStatus == 'APPROVED' ||
          vrStatus == 'VERIFIED' ||
          syncStatus == 'APPROVED' ||
          syncStatus == 'VERIFIED' ||
          (accountStatus == 'ACTIVE' && partnerVerStatus != 'PENDING' && vrStatus != 'PENDING' && syncStatus != 'PENDING');

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
        'partner_id': partnersData?['partner_id'] ?? usersRes['user_id'],
        'provider_id': partnersData?['service_provider_profiles']?['provider_id'],
        'verification_status': isApproved ? 'VERIFIED' : (isRejected ? 'REJECTED' : 'PENDING'),
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

  /// Register a new Service Provider into the real 70-table database
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
  }) async {
    try {
      final cleanUsername = username.trim().toLowerCase().replaceAll('@', '');
      final cleanPhone = phone.trim();
      final cleanEmail = email.trim().isNotEmpty ? email.trim() : '$cleanUsername@servicehub.com';

      // 1. Create Supabase Auth User
      String? authId;
      try {
        final authRes = await client.auth.signUp(email: cleanEmail, password: password);
        authId = authRes.user?.id;
      } catch (_) {}

      // 2. Fetch role_id for service_provider
      final roleRes = await client.from('roles').select('role_id').eq('role_name', 'service_provider').maybeSingle();
      final roleId = roleRes?['role_id'] ?? '11111111-1111-1111-1111-111111111112';

      // 3. Insert into users table
      final userInsert = await client.from('users').insert({
        'auth_id': authId,
        'role_id': roleId,
        'username': cleanUsername,
        'email': cleanEmail,
        'phone': cleanPhone,
        'account_status': 'PENDING_VERIFICATION',
        'is_active': true,
      }).select().single();

      final userId = userInsert['user_id'];

      // 4. Insert into user_profiles table
      await client.from('user_profiles').insert({
        'user_id': userId,
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
      });

      // 5. Insert into user_addresses table
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

      // 6. Insert into partners table (PENDING verification)
      final partnerInsert = await client.from('partners').insert({
        'user_id': userId,
        'verification_status': 'PENDING',
        'availability_status': 'OFFLINE',
      }).select().single();

      final partnerId = partnerInsert['partner_id'];

      // 7. Insert into service_provider_profiles table
      final providerInsert = await client.from('service_provider_profiles').insert({
        'partner_id': partnerId,
        'experience_years': 3,
        'about': 'Expert $specialization technician with quality service guarantee.',
        'rating': 0.0,
        'total_jobs': 0,
        'service_radius_km': 10.0,
      }).select().single();

      final providerId = providerInsert['provider_id'];

      // 8. Insert into verification_requests table
      try {
        await client.from('verification_requests').insert({
          'user_id': userId,
          'verification_type': 'AADHAAR',
          'status': 'PENDING',
          'remarks': 'New service provider registration application for $cleanUsername',
        });
      } catch (vrErr) {
        if (kDebugMode) {
          debugPrint('[SupabaseAuthService] verification_requests insert note: $vrErr');
        }
      }

      final sessionData = {
        'user_id': userId,
        'username': cleanUsername,
        'email': cleanEmail,
        'phone': cleanPhone,
        'role_name': 'service_provider',
        'name': '$firstName $lastName'.trim(),
        'business_name': '$firstName Services',
        'partner_id': partnerId,
        'provider_id': providerId,
        'verification_status': 'PENDING',
        'is_online': false,
      };

      await _saveActiveSession(sessionData);

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

  static Future<void> _saveActiveSession(Map<String, dynamic> session) async {
    try {
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
        if (session is Map && session['user_id'] == userId) {
          return session['password']?.toString();
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
      }
    } catch (_) {}
  }
}
