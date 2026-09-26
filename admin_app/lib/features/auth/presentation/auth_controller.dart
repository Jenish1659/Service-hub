import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/routes/app_router.dart';
import '../data/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.data(null)) {
    state = AsyncValue.data(_repository.currentUser);
  }

  Future<bool> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      final response = await _repository.signInWithEmail(email, password);
      state = AsyncValue.data(response.user);
      return response.user != null;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await _repository.signOut();
    } catch (_) {}
    adminBypassLoggedIn = false;
    try {
      if (Hive.isBoxOpen('admin_cache')) {
        final box = Hive.box('admin_cache');
        await box.clear();
        await box.flush();
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('admin_token');
      await prefs.remove('admin_role');
      await prefs.remove('saved_user_id');
      await prefs.remove('saved_role_id');
    } catch (_) {}
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
