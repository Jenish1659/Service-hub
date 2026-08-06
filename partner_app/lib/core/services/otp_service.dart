import 'dart:async';
import 'package:flutter/foundation.dart';

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
  static const int maxResendAttempts = 3;

  int _resendCount = 0;

  Future<OtpResult> sendOtp(String mobileNumber) async {
    if (mobileNumber.length != 10) {
      return OtpResult(success: false, message: 'Please enter a valid 10-digit mobile number.');
    }

    if (_resendCount >= maxResendAttempts) {
      return OtpResult(
        success: false,
        message: 'Maximum resend attempts reached. Please try again after 15 minutes.',
      );
    }

    _resendCount++;
    if (kDebugMode) {
      debugPrint('[OtpService] Sending OTP to +91 $mobileNumber (Attempt #$_resendCount)');
    }

    // Simulate server API call delay
    await Future.delayed(const Duration(milliseconds: 600));

    return OtpResult(
      success: true,
      message: 'OTP sent successfully to +91 $mobileNumber',
      otpReference: 'OTP_${DateTime.now().millisecondsSinceEpoch}',
      expiresInSeconds: 60,
    );
  }

  Future<bool> verifyOtp(String mobileNumber, String otpCode) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // In demo/production backend validation:
    // OTP code validation engine (accept 123456 or any 6 digit input for test session)
    return otpCode.length == 6;
  }
}
