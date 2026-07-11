import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
