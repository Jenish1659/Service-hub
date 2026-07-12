import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  // Send OTP code to phone number
  Future<void> signInWithPhone(String phoneNumber) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: phoneNumber,
      );
    } catch (e) {
      throw Exception('Failed to send verification OTP: ${e.toString()}');
    }
  }

  // Verify OTP token and log user in
  Future<AuthResponse> verifyOtp(String phoneNumber, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phoneNumber,
        token: token,
        type: OtpType.sms,
      );
      return response;
    } catch (e) {
      throw Exception('Verification failed: ${e.toString()}');
    }
  }

  // Sign in using email & password
  Future<AuthResponse> signInWithEmail(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw Exception('Email login failed: ${e.toString()}');
    }
  }

  // Sign up using email & password
  Future<AuthResponse> signUpWithEmail(String email, String password, String name, String role) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'name': name,
          'role': role,
        },
      );
      return response;
    } catch (e) {
      throw Exception('Email signup failed: ${e.toString()}');
    }
  }

  // Sign out user session
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Get current user session details
  Session? get currentSession => _supabase.auth.currentSession;

  // Get current user profile details
  User? get currentUser => _supabase.auth.currentUser;

  // Stream auth state changes
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
}
