import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/core/services/firebase_otp_service.dart';
import 'package:service_hub_partner/core/services/otp_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Firebase Real OTP & Notification Verification Engine Tests', () {
    setUp(() {
      FirebaseOtpService.instance.resetForTesting();
    });

    test('Rejects phone numbers with fewer than 10 digits', () async {
      final res = await FirebaseOtpService.instance.sendOtp('98765');
      expect(res.success, isFalse);
      expect(res.message, contains('valid 10-digit mobile number'));
    });

    test('Generates real 6-digit cryptographic OTP and dispatches notification', () async {
      final res = await FirebaseOtpService.instance.sendOtp('9876543210');
      expect(res.success, isTrue);
      expect(FirebaseOtpService.instance.hasActiveOtp, isTrue);

      final realOtp = FirebaseOtpService.instance.testActiveOtp;
      expect(realOtp, isNotNull);
      expect(realOtp!.length, 6);
      expect(int.tryParse(realOtp), isNotNull);
    });

    test('Strict Verification: Rejects non-6 digit inputs', () async {
      await FirebaseOtpService.instance.sendOtp('9876543210');
      final res = await FirebaseOtpService.instance.verifyOtp('9876543210', '123');
      expect(res.success, isFalse);
      expect(res.message, contains('Please enter all 6 digits'));
    });

    test('Strict Verification: Rejects incorrect/arbitrary OTP with error', () async {
      await FirebaseOtpService.instance.sendOtp('9876543210');
      final realOtp = FirebaseOtpService.instance.testActiveOtp!;

      // Formulate a wrong code guaranteed not to equal realOtp
      final wrongCode = realOtp == '999999' ? '111111' : '999999';

      final res = await FirebaseOtpService.instance.verifyOtp('9876543210', wrongCode);
      expect(res.success, isFalse);
      expect(res.message, contains('Invalid OTP'));
      expect(res.message, contains('incorrect'));
    });

    test('Strict Verification: Accepts exact real OTP and consumes it (single-use)', () async {
      await FirebaseOtpService.instance.sendOtp('9876543210');
      final realOtp = FirebaseOtpService.instance.testActiveOtp!;

      // 1. Verify with the actual real OTP
      final successRes = await FirebaseOtpService.instance.verifyOtp('9876543210', realOtp);
      expect(successRes.success, isTrue);
      expect(successRes.message, contains('OTP verified successfully'));

      // 2. Re-using the same OTP must now FAIL because it is single-use consumed
      final replayRes = await FirebaseOtpService.instance.verifyOtp('9876543210', realOtp);
      expect(replayRes.success, isFalse);
      expect(replayRes.message, contains('Invalid OTP'));
    });

    test('OtpService delegates properly to FirebaseOtpService', () async {
      final otpService = OtpService();

      final sendRes = await otpService.sendOtp('9123456780');
      expect(sendRes.success, isTrue);

      final realOtp = FirebaseOtpService.instance.testActiveOtp!;

      // Wrong OTP fails
      final wrongRes = await otpService.verifyOtp('9123456780', '000000');
      expect(wrongRes, isFalse);

      // Detailed verify provides strict error message
      final detailedWrong = await otpService.verifyOtpDetailed('9123456780', '000000');
      expect(detailedWrong.success, isFalse);
      expect(detailedWrong.message, contains('Invalid OTP'));

      // Real OTP succeeds
      final correctRes = await otpService.verifyOtp('9123456780', realOtp);
      expect(correctRes, isTrue);
    });

    test('Supports dynamic 4-digit OTP generation and verification', () async {
      final res = await FirebaseOtpService.instance.sendOtp('9876543210', digits: 4);
      expect(res.success, isTrue);

      final realOtp = FirebaseOtpService.instance.testActiveOtp;
      expect(realOtp, isNotNull);
      expect(realOtp!.length, 4);
      expect(int.tryParse(realOtp), isNotNull);

      // Verify wrong 4-digit fails
      final wrongRes = await FirebaseOtpService.instance.verifyOtp('9876543210', '0000');
      expect(wrongRes.success, isFalse);
      expect(wrongRes.message, contains('Invalid OTP'));

      // Verify correct 4-digit succeeds
      final correctRes = await FirebaseOtpService.instance.verifyOtp('9876543210', realOtp);
      expect(correctRes.success, isTrue);
    });

    test('Guarantees non-repetition per user across consecutive generations', () async {
      const userPhone = '9988776655';
      final generatedCodes = <String>{};

      for (int i = 0; i < 40; i++) {
        // Reset attempts count to simulate multiple requests over time
        FirebaseOtpService.instance.resetForTesting();
        await FirebaseOtpService.instance.sendOtp(userPhone, digits: 6);
        final code = FirebaseOtpService.instance.testActiveOtp!;

        expect(generatedCodes.contains(code), isFalse,
            reason: 'Code $code was generated more than once within the history window for $userPhone');
        generatedCodes.add(code);
      }
      expect(generatedCodes.length, 40);
    });
  });
}
