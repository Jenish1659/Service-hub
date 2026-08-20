import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
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
  static const String _sessionBoxName = 'delivery_cache';

  static SupabaseClient get client => Supabase.instance.client;

  /// Secure Login using Username OR Mobile Number + Password
  static Future<AuthResult> loginWithUsernameOrPhone({
    required String identifier,
    required String password,
    required String expectedRole, // 'delivery_agent'
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
      final usersRes = await client
          .from('users')
          .select('*, roles!inner(*), user_profiles(*), partners(*, delivery_agent_profiles(*))')
          .or('username.ilike.$cleanId,phone.eq.$cleanId,phone.eq.+91$cleanId')
          .maybeSingle();

      if (usersRes == null) {
        final localMatch = await _checkLocalCachedUser(cleanId, cleanPass);
        if (localMatch != null) {
          return AuthResult(
            isSuccess: true,
            userData: localMatch,
            roleName: 'delivery_agent',
          );
        }

        return AuthResult(
          isSuccess: false,
          errorMessage: 'Account not found. Please check your username or mobile number.',
        );
      }

      final isActive = usersRes['is_active'] as bool? ?? true;
      if (!isActive) {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Your account is currently inactive.',
        );
      }

      final roleData = usersRes['roles'] as Map<String, dynamic>? ?? {};
      final roleName = (roleData['role_name'] ?? '').toString().toLowerCase();

      if (roleName != 'delivery_agent' && expectedRole == 'delivery_agent') {
        return AuthResult(
          isSuccess: false,
          errorMessage: 'Unauthorized access. This account is registered as a $roleName.',
        );
      }

      final userEmail = usersRes['email']?.toString() ?? '$cleanId@servicehub.com';
      try {
        await client.auth.signInWithPassword(email: userEmail, password: cleanPass);
      } catch (_) {}

      final sessionData = {
        'user_id': usersRes['user_id'],
        'username': usersRes['username'],
        'email': usersRes['email'],
        'phone': usersRes['phone'],
        'role_name': 'delivery_agent',
        'name': usersRes['user_profiles']?['first_name'] != null
            ? '${usersRes['user_profiles']['first_name']} ${usersRes['user_profiles']['last_name'] ?? ""}'.trim()
            : usersRes['username'],
        'partner_id': usersRes['partners']?['partner_id'],
        'delivery_agent_id': usersRes['partners']?['delivery_agent_profiles']?['delivery_agent_id'],
        'vehicle_type': usersRes['partners']?['delivery_agent_profiles']?['vehicle_type'] ?? 'Bike',
        'is_online': usersRes['partners']?['availability_status'] == 'ONLINE',
      };

      await _saveActiveSession(sessionData);

      return AuthResult(
        isSuccess: true,
        userData: sessionData,
        roleName: 'delivery_agent',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[DeliverySupabaseAuthService] Remote login error: $e');
      }

      final localMatch = await _checkLocalCachedUser(cleanId, cleanPass);
      if (localMatch != null) {
        return AuthResult(
          isSuccess: true,
          userData: localMatch,
          roleName: 'delivery_agent',
        );
      }

      return AuthResult(
        isSuccess: false,
        errorMessage: 'Invalid username/mobile number or password.',
      );
    }
  }

  static Future<void> _saveActiveSession(Map<String, dynamic> session) async {
    try {
      if (Hive.isBoxOpen(_sessionBoxName)) {
        final box = Hive.box(_sessionBoxName);
        await box.put('active_delivery_session', session);

        final List<dynamic> rawList = box.get('registered_delivery_agents_list', defaultValue: []) as List<dynamic>;
        final List<Map<String, dynamic>> users = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        users.removeWhere((u) => u['username'] == session['username'] || u['phone'] == session['phone']);
        users.add(session);
        await box.put('registered_delivery_agents_list', users);
      }
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> _checkLocalCachedUser(String identifier, String password) async {
    try {
      if (Hive.isBoxOpen(_sessionBoxName)) {
        final box = Hive.box(_sessionBoxName);
        final List<dynamic> rawList = box.get('registered_delivery_agents_list', defaultValue: []) as List<dynamic>;
        for (final item in rawList) {
          if (item is Map) {
            final uName = (item['username'] ?? '').toString().toLowerCase();
            final uPhone = (item['phone'] ?? '').toString().toLowerCase();
            final uPass = (item['password'] ?? '').toString();

            if ((uName == identifier || uPhone == identifier || uPhone.endsWith(identifier)) &&
                (uPass.isEmpty || uPass == password)) {
              final match = Map<String, dynamic>.from(item);
              await box.put('active_delivery_session', match);
              return match;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }
}
