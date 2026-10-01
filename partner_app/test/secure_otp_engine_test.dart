import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/core/services/secure_otp_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureOtpEngine Dynamic & Non-Repeating Verification Suite', () {
    setUp(() {
      SecureOtpEngine.instance.resetForTesting();
    });

    test('1. Generates valid 4-digit numeric OTPs within 1000 - 9999', () {
      for (int i = 0; i < 25; i++) {
        final otp = SecureOtpEngine.instance.generateOtp(
          userIdOrPhone: 'user_4digit_$i',
          digits: 4,
        );
        expect(otp.length, 4);
        final val = int.parse(otp);
        expect(val >= 1000 && val <= 9999, isTrue);
      }
    });

    test('2. Generates valid 6-digit numeric OTPs within 100000 - 999999', () {
      for (int i = 0; i < 25; i++) {
        final otp = SecureOtpEngine.instance.generateOtp(
          userIdOrPhone: 'user_6digit_$i',
          digits: 6,
        );
        expect(otp.length, 6);
        final val = int.parse(otp);
        expect(val >= 100000 && val <= 999999, isTrue);
      }
    });

    test('3. Requesting consecutive OTPs for the same user yields distinct unique codes with zero repetition', () {
      const userPhone = '+91 98765 43210';
      final issued = <String>{};

      for (int i = 0; i < 50; i++) {
        final otp = SecureOtpEngine.instance.generateOtp(
          userIdOrPhone: userPhone,
          digits: 6,
        );
        expect(issued.contains(otp), isFalse,
            reason: 'Code $otp was repeated for user $userPhone within the rolling window!');
        issued.add(otp);
      }

      expect(issued.length, 50);
      expect(SecureOtpEngine.instance.getRecentOtpsForUser(userPhone).length, 50);
    });

    test('4. Two different users maintain independent rolling history pools', () {
      const userA = 'user_alpha';
      const userB = 'user_beta';

      final otpA = SecureOtpEngine.instance.generateOtp(userIdOrPhone: userA, digits: 6);
      final otpB = SecureOtpEngine.instance.generateOtp(userIdOrPhone: userB, digits: 6);

      expect(SecureOtpEngine.instance.getRecentOtpsForUser(userA), contains(otpA));
      expect(SecureOtpEngine.instance.getRecentOtpsForUser(userB), contains(otpB));
      expect(SecureOtpEngine.instance.getRecentOtpsForUser(userA), isNot(contains(otpB)));
    });

    test('5. Re-running after history capacity rotates correctly without crash', () {
      const userPhone = '919898011223';
      // Generate beyond the 4-digit history limit (100)
      for (int i = 0; i < 110; i++) {
        final otp = SecureOtpEngine.instance.generateOtp(userIdOrPhone: userPhone, digits: 4);
        expect(otp.length, 4);
      }

      // History should be capped at maxHistoryPerUser4Digit (100)
      final history = SecureOtpEngine.instance.getRecentOtpsForUser(userPhone);
      expect(history.length, SecureOtpEngine.maxHistoryPerUser4Digit);
    });

    test('6. Clears history per user cleanly', () {
      const userPhone = '9100000001';
      SecureOtpEngine.instance.generateOtp(userIdOrPhone: userPhone, digits: 6);
      expect(SecureOtpEngine.instance.getRecentOtpsForUser(userPhone), isNotEmpty);

      SecureOtpEngine.instance.clearHistoryForUser(userPhone);
      expect(SecureOtpEngine.instance.getRecentOtpsForUser(userPhone), isEmpty);
    });
  });
}
