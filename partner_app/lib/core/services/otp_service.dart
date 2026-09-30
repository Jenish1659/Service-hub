import 'dart:async';
import 'package:flutter/foundation.dart';
import 'firebase_otp_service.dart';

class OtpResult {
  final bool success;
  final String message;
  final String? otpReference;
  final int expiresInSeconds;

  OtpResult({
    required this.success,
    required this.message,
    this.otpReference,
    this.expiresInSeconds = 60,
  });
}

class OtpService {
  static const int maxVerificationAttempts = 5;
  static const int maxResendAttempts = 4;

  final FirebaseOtpService _firebaseOtpService = FirebaseOtpService.instance;

  Future<OtpResult> sendOtp(String mobileNumber, {int digits = 6}) async {
    final response = await _firebaseOtpService.sendOtp(mobileNumber, digits: digits);
    if (kDebugMode) {
      debugPrint('[OtpService] sendOtp result: ${response.success} - ${response.message}');
    }
    return OtpResult(
      success: response.success,
      message: response.message,
      otpReference: response.verificationId,
      expiresInSeconds: 60,
    );
  }

  Future<bool> verifyOtp(String mobileNumber, String otpCode) async {
    final response = await _firebaseOtpService.verifyOtp(mobileNumber, otpCode);
    return response.success;
  }

  Future<OtpVerificationResponse> verifyOtpDetailed(String mobileNumber, String otpCode) async {
    return await _firebaseOtpService.verifyOtp(mobileNumber, otpCode);
  }
}
