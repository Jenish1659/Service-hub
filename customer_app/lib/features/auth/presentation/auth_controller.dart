import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

// Provide the AuthRepository instance
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

// Provide the AuthState stream (to automatically react to logins/logouts)
final authStateProvider = StreamProvider<AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

// Auth Controller managing login states
class AuthController extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AsyncValue.data(null)) {
    // Set initial user if exists
    state = AsyncValue.data(_repository.currentUser);
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
      state = AsyncValue.data(response.user);
      return response.user != null;
    } catch (e, stack) {
      state = AsyncError(e, stack);
      return false;
    }
  }

  Future<bool> signUpWithEmail(String email, String password, String name, String role) async {
    state = const AsyncLoading();
    try {
      final response = await _repository.signUpWithEmail(email, password, name, role);
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
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
