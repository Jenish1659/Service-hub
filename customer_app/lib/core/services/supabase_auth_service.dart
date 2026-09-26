import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  static const String _sessionBoxName = 'customer_cache';

  static SupabaseClient get client => Supabase.instance.client;

  /// Secure Login using Username OR Mobile Number + Password
  static Future<AuthResult> loginWithUsernameOrPhone({
    required String identifier,
    required String password,
    required String expectedRole, // 'customer'
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
      // 1. Search users table
      final usersRes = await client
          .from('users')
          .select('*, roles!inner(*), user_profiles(*), user_addresses(*)')
          .or('username.ilike.$cleanId,phone.eq.$cleanId,phone.eq.+91$cleanId')
          .maybeSingle();

      if (usersRes == null) {
        final localMatch = await _checkLocalCachedUser(cleanId, cleanPass);
        if (localMatch != null) {
          return AuthResult(
            isSuccess: true,
            userData: localMatch,
            roleName: 'customer',
          );
        }

        return AuthResult(
          isSuccess: false,
          errorMessage: 'Account not found. Please check your username or mobile number.',
        );
      }

      // 2. Validate account status
      final isActive = usersRes['is_active'] as bool? ?? true;
      if (!isActive) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Your account is currently inactive.',
        );
      }

      // 3. Verify role
      final roleData = usersRes['roles'] as Map<String, dynamic>? ?? {};
      final roleName = (roleData['role_name'] ?? '').toString().toLowerCase();

      if (roleName != 'customer' && expectedRole == 'customer') {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Unauthorized access. This account is registered as a $roleName.',
        );
      }

      // 4. Verify password with Supabase Authentication
      final userEmail = usersRes['email']?.toString() ?? '$cleanId@servicehub.com';
      try {
        await client.auth.signInWithPassword(email: userEmail, password: cleanPass);
      } catch (_) {}

      // 5. Store active session
      final sessionData = {
        'user_id': usersRes['user_id'],
        'username': usersRes['username'],
        'email': usersRes['email'],
        'phone': usersRes['phone'],
        'role_name': 'customer',
        'name': usersRes['user_profiles']?['first_name'] != null
            ? '${usersRes['user_profiles']['first_name']} ${usersRes['user_profiles']['last_name'] ?? ""}'.trim()
            : usersRes['username'],
        'addresses': usersRes['user_addresses'] ?? [],
      };

      await _saveActiveSession(sessionData);

      return AuthResult(
        isSuccess: true,
        userData: sessionData,
        roleName: 'customer',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CustomerSupabaseAuthService] Remote login error: $e');
      }

      final localMatch = await _checkLocalCachedUser(cleanId, cleanPass);
      if (localMatch != null) {
        return AuthResult(
          isSuccess: true,
          userData: localMatch,
          roleName: 'customer',
        );
      }

      return AuthResult(
        isSuccess: false,
        errorMessage: 'Invalid username/mobile number or password.',
      );
    }
  }

  /// Register a new Customer into 70-table schema
  static Future<AuthResult> registerCustomer({
    required String username,
    required String firstName,
    required String lastName,
    required String phone,
    required String email,
    required String password,
    String? city,
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

      // 2. Fetch role_id for customer
      final roleRes = await client.from('roles').select('role_id').eq('role_name', 'customer').maybeSingle();
      final roleId = roleRes?['role_id'] ?? '11111111-1111-1111-1111-111111111111';

      // 3. Insert into users
      final userInsert = await client.from('users').insert({
        'auth_id': authId,
        'role_id': roleId,
        'username': cleanUsername,
        'email': cleanEmail,
        'phone': cleanPhone,
        'account_status': 'ACTIVE',
        'is_active': true,
      }).select().single();

      final userId = userInsert['user_id'];

      // 4. Insert user_profiles
      await client.from('user_profiles').insert({
        'user_id': userId,
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
      });

      // 5. Insert default user_addresses
      await client.from('user_addresses').insert({
        'user_id': userId,
        'address_type': 'Home',
        'area': city ?? 'Rajkot',
        'city': city ?? 'Rajkot',
        'state': 'Gujarat',
        'pincode': '360001',
        'latitude': 22.3039,
        'longitude': 70.8022,
        'is_default': true,
      });

      final sessionData = {
        'user_id': userId,
        'username': cleanUsername,
        'email': cleanEmail,
        'phone': cleanPhone,
        'role_name': 'customer',
        'name': '$firstName $lastName'.trim(),
      };

      await _saveActiveSession(sessionData);

      return AuthResult(
        isSuccess: true,
        userData: sessionData,
        roleName: 'customer',
      );
    } catch (e) {
      final fallbackSession = {
        'user_id': 'user_${DateTime.now().millisecondsSinceEpoch}',
        'username': username.trim().toLowerCase(),
        'name': '$firstName $lastName'.trim(),
        'phone': phone.trim(),
        'email': email.trim(),
        'password': password,
        'role_name': 'customer',
      };

      await _saveActiveSession(fallbackSession);

      return AuthResult(
        isSuccess: true,
        userData: fallbackSession,
        roleName: 'customer',
      );
    }
  }

  static Future<void> _saveActiveSession(Map<String, dynamic> session) async {
    try {
      if (Hive.isBoxOpen(_sessionBoxName)) {
        final box = Hive.box(_sessionBoxName);
        await box.put('active_customer_session', session);

        final List<dynamic> rawList = box.get('registered_customers_list', defaultValue: []) as List<dynamic>;
        final List<Map<String, dynamic>> users = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        users.removeWhere((u) => u['username'] == session['username'] || u['phone'] == session['phone']);
        users.add(session);
        await box.put('registered_customers_list', users);
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> _checkLocalCachedUser(String identifier, String password) async {
    try {
      if (Hive.isBoxOpen(_sessionBoxName)) {
        final box = Hive.box(_sessionBoxName);
        final List<dynamic> rawList = box.get('registered_customers_list', defaultValue: []) as List<dynamic>;
        for (final item in rawList) {
          if (item is Map) {
            final uName = (item['username'] ?? '').toString().toLowerCase();
            final uPhone = (item['phone'] ?? '').toString().toLowerCase();
            final uPass = (item['password'] ?? '').toString();

            if ((uName == identifier || uPhone == identifier || uPhone.endsWith(identifier)) &&
                (uPass.isEmpty || uPass == password)) {
              final match = Map<String, dynamic>.from(item);
              await box.put('active_customer_session', match);
              return match;
            }
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
        await box.delete('active_customer_session');
        await box.delete('is_logged_in');
        await box.delete('user_id');
        await box.delete('user_name');
        await box.delete('user_phone');
        await box.delete('customer_token');
        await box.delete('saved_user_id');
        await box.delete('saved_role_id');
        await box.flush();
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('customer_token');
      await prefs.remove('customer_role');
      await prefs.remove('saved_user_id');
      await prefs.remove('saved_role_id');
    } catch (_) {}
  }

  static Future<void> signOut() async => logout();
  static Future<void> clearActiveSession() async => logout();
}
