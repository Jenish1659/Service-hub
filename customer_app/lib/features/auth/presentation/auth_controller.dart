import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../../core/services/customer_database_sync_service.dart';
import '../../../core/services/supabase_auth_service.dart';
import '../data/auth_repository.dart';

class UninitializedAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Session? get currentSession => null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signInWithPhone(String phoneNumber) async => throw UnimplementedError();

  @override
  Future<AuthResponse> verifyOtp(String phoneNumber, String token) async => throw UnimplementedError();

  @override
  Future<AuthResponse> signInWithEmail(String email, String password) async => throw UnimplementedError();

  @override
  Future<AuthResponse> signUpWithEmail(String email, String password, String name, String role) async => throw UnimplementedError();
}

// Provide the AuthRepository instance
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  try {
    return AuthRepository(Supabase.instance.client);
  } catch (_) {
    return UninitializedAuthRepository();
  }
});

// Provide the AuthState stream (to automatically react to logins/logouts)
final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

// Auth Controller managing login states
class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;
  StreamSubscription<AuthState>? _authSubscription;

  AuthController(this._repository) : super(const AsyncValue.data(null)) {
    _initUser();
    // Listen to changes to persist session on startup/reload
    _authSubscription = _repository.authStateChanges.listen((event) {
      if (event.session != null) {
        state = AsyncValue.data(event.session!.user);
      } else {
        _checkHiveUser();
      }
    });
  }

  void _initUser() {
    final currentUser = _repository.currentUser;
    if (currentUser != null) {
      state = AsyncValue.data(currentUser);
    } else {
      _checkHiveUser();
    }
  }

  void _checkHiveUser() {
    try {
      final box = Hive.box('customer_cache');
      final isLoggedIn = box.get('is_logged_in', defaultValue: false) as bool;
      if (isLoggedIn) {
        final name = box.get('user_name', defaultValue: 'Customer') as String;
        final phone = box.get('user_phone', defaultValue: '') as String;
        final rawId = box.get('user_id')?.toString();
        final userId = (rawId != null && rawId.isNotEmpty) ? rawId : const Uuid().v4();
        
        // Construct a User object matching the Supabase User structure
        final cachedUser = User(
          id: userId,
          appMetadata: {},
          userMetadata: {'name': name},
          aud: 'authenticated',
          email: 'phone_$phone@servicehub.com',
          phone: phone,
          createdAt: DateTime.now().toIso8601String(),
        );
        state = AsyncValue.data(cachedUser);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (_) {
      state = const AsyncValue.data(null);
    }
  }

  Future<bool> sendOtp(String phoneNumber) async {
    state = const AsyncLoading();
    try {
      await _repository.signInWithPhone(phoneNumber);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> verifyOtp(String phoneNumber, String token) async {
    state = const AsyncLoading();
    try {
      final response = await _repository.verifyOtp(phoneNumber, token);
      state = AsyncValue.data(response.user);
      return response.user != null;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> loginWithEmail(String email, String password) async {
    state = const AsyncLoading();
    try {
      final response = await _repository.signInWithEmail(email, password);
      if (response.user != null) {
        final name = response.user!.userMetadata?['name'] ?? email.split('@').first;
        final phone = response.user!.phone ?? '';
        final synced = await CustomerDatabaseSyncService.syncCustomerToDatabase(
          name: name,
          phone: phone,
          email: email,
          existingUserId: response.user!.id,
        );
        final realId = (synced['user_id'] ?? response.user!.id).toString();

        final box = Hive.box('customer_cache');
        box.put('is_logged_in', true);
        box.put('user_id', realId);
        box.put('user_name', name);
        box.put('user_phone', phone);
        state = AsyncValue.data(response.user);
        return true;
      }
      return false;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String name, String role) async {
    state = const AsyncLoading();
    try {
      final response = await _repository.signUpWithEmail(email, password, name, role);
      if (response.user != null) {
        final synced = await CustomerDatabaseSyncService.syncCustomerToDatabase(
          name: name,
          phone: response.user!.phone ?? '',
          email: email,
          existingUserId: response.user!.id,
        );
        final realId = (synced['user_id'] ?? response.user!.id).toString();

        final box = Hive.box('customer_cache');
        box.put('is_logged_in', true);
        box.put('user_id', realId);
        box.put('user_name', name);
        box.put('user_phone', response.user!.phone ?? '');
        state = AsyncValue.data(response.user);
        return true;
      }
      return false;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  // Unified phone OTP login to prevent multiple loading/redirect glitches
  Future<bool> verifyPhoneOtpAndLogin(String name, String phone) async {
    state = const AsyncLoading();
    final authEmail = 'phone_$phone@servicehub.com';
    final authPassword = 'ServiceHub_${phone.substring(phone.length > 4 ? phone.length - 4 : 0)}!';

    // 1. Try to login
    try {
      final response = await _repository.signInWithEmail(authEmail, authPassword);
      if (response.user != null) {
        final finalName = response.user!.userMetadata?['name'] ?? name;
        final synced = await CustomerDatabaseSyncService.syncCustomerToDatabase(
          name: finalName,
          phone: phone,
          email: authEmail,
          existingUserId: response.user!.id,
        );
        final realId = (synced['user_id'] ?? response.user!.id).toString();

        final box = Hive.box('customer_cache');
        box.put('is_logged_in', true);
        box.put('user_id', realId);
        box.put('user_name', finalName);
        box.put('user_phone', response.user!.phone ?? phone);
        state = AsyncValue.data(response.user);
        return true;
      }
    } catch (_) {
      // Ignore login failure, proceed to sign up
    }

    // 2. Try to sign up if login failed
    try {
      final response = await _repository.signUpWithEmail(authEmail, authPassword, name, 'customer');
      if (response.user != null) {
        final synced = await CustomerDatabaseSyncService.syncCustomerToDatabase(
          name: name,
          phone: phone,
          email: authEmail,
          existingUserId: response.user!.id,
        );
        final realId = (synced['user_id'] ?? response.user!.id).toString();

        final box = Hive.box('customer_cache');
        box.put('is_logged_in', true);
        box.put('user_id', realId);
        box.put('user_name', name);
        box.put('user_phone', phone);
        state = AsyncValue.data(response.user);
        return true;
      }
    } catch (_) {
      // Ignore signup failure, fallback to database sync
    }

    // 3. Fallback: direct database sync with real UUID
    final synced = await CustomerDatabaseSyncService.syncCustomerToDatabase(
      name: name,
      phone: phone,
      email: authEmail,
    );
    final realUserId = synced['user_id'] as String;

    final box = Hive.box('customer_cache');
    box.put('is_logged_in', true);
    box.put('user_id', realUserId);
    box.put('user_name', name);
    box.put('user_phone', phone);

    // Construct local user with authentic real UUID
    final localUser = User(
      id: realUserId,
      appMetadata: {},
      userMetadata: {'name': name},
      aud: 'authenticated',
      email: authEmail,
      phone: phone,
      createdAt: DateTime.now().toIso8601String(),
    );
    state = AsyncValue.data(localUser);
    return true;
  }

  // Local session fallback login
  Future<void> loginLocalSession(String name, String phone) async {
    final synced = await CustomerDatabaseSyncService.syncCustomerToDatabase(
      name: name,
      phone: phone,
    );
    final realUserId = synced['user_id'] as String;

    final box = Hive.box('customer_cache');
    box.put('is_logged_in', true);
    box.put('user_id', realUserId);
    box.put('user_name', name);
    box.put('user_phone', phone);

    _checkHiveUser();
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _repository.signOut();
    } catch (_) {}
    try {
      await SupabaseAuthService.logout();
    } catch (_) {}
    
    try {
      final box = Hive.box('customer_cache');
      box.put('is_logged_in', false);
      box.delete('user_id');
      box.delete('user_name');
      box.delete('user_phone');
      box.delete('active_customer_session');
    } catch (_) {}
    
    state = const AsyncValue.data(null);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
