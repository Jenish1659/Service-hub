import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/services/firebase_otp_service.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/services/secure_otp_engine.dart';
import 'package:service_hub_partner/core/services/supabase_auth_service.dart';
import 'package:service_hub_partner/features/auth/presentation/forgot_password_screen.dart';
import 'package:service_hub_partner/features/registration/presentation/screens/track_application_verification_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testPhone = '9825144556';
  const testUsername = 'keval_plumber';
  const testInitialPass = 'OldPassword@123';
  const testNewPass = 'NewSecretPass@2026';

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('partner_auth_test_');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('partner_cache')) {
      await Hive.openBox('partner_cache');
    }
  });

  setUp(() async {
    // ignore: invalid_use_of_visible_for_testing_member
    SecureOtpEngine.instance.resetForTesting();

    final box = Hive.box('partner_cache');
    await box.clear();
    // Pre-populate an authentic test partner user in registered_users_list
    final registeredUsers = [
      {
        'user_id': 'usr_keval_001',
        'username': testUsername,
        'phone': '+91$testPhone',
        'email': 'keval@servicehub.com',
        'password': testInitialPass,
        'password_hash': testInitialPass,
        'role_name': 'service_provider',
        'account_status': 'ACTIVE',
        'is_active': true,
      }
    ];
    await box.put('registered_users_list', registeredUsers);

    // Pre-populate an authentic submitted partner application in LiveBookingSyncService
    await LiveBookingSyncService.instance.submitPartnerVerification({
      'verification_id': 'APP-PLUMB-98251',
      'id': 'APP-PLUMB-98251',
      'partner_id': 'PRT_KEVAL_98251',
      'phone': testPhone,
      'mobile': testPhone,
      'name': 'Keval Joshi',
      'business_name': 'Joshi Plumbing & Leak Repair',
      'role_name': 'Plumber Technician',
      'category': 'Plumber',
      'status': 'UNDER_REVIEW',
      'city': 'Jamnagar',
      'created_at': '2026-10-25T01:00:00Z',
    });
  });

  group('Track Application with 6-Digit Mobile OTP & Real Data Tests', () {
    testWidgets('1. TrackApplicationVerificationScreen requires 10-digit mobile number and sends 6-digit OTP', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TrackApplicationVerificationScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify header and mobile number entry
      expect(find.text('Track Application'), findsOneWidget);
      expect(find.text('Partner Identity Verification'), findsOneWidget);
      expect(find.text('Registered Mobile Number'), findsOneWidget);
      expect(find.text('Send 6-Digit OTP'), findsOneWidget);

      // Attempting to send without 10 digits shows validation error
      await tester.tap(find.text('Send 6-Digit OTP'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a valid 10-digit mobile number.'), findsOneWidget);

      // Enter valid 10-digit mobile number
      await tester.enterText(find.byType(TextField).first, testPhone);
      await tester.tap(find.text('Send 6-Digit OTP'));
      await tester.pumpAndSettle();

      // Verify 6-digit OTP card is presented
      expect(find.textContaining('Enter 6-Digit OTP sent to +91 $testPhone'), findsOneWidget);
      expect(find.text('Verify & Search Applications'), findsOneWidget);
    });

    testWidgets('2. Verifying 6-digit OTP queries database and renders authentic application cards', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TrackApplicationVerificationScreen(initialPhone: testPhone),
        ),
      );
      await tester.pumpAndSettle();

      // Trigger OTP
      await tester.tap(find.text('Send 6-Digit OTP'));
      await tester.pumpAndSettle();

      // Retrieve the generated 6-digit OTP from FirebaseOtpService
      final validOtp = FirebaseOtpService.instance.testActiveOtp;
      expect(validOtp, isNotNull);
      expect(validOtp!.length, 6);

      // Enter valid 6-digit OTP
      final otpField = find.byType(TextField).last;
      await tester.enterText(otpField, validOtp);
      await tester.ensureVisible(find.text('Verify & Search Applications'));
      await tester.tap(find.text('Verify & Search Applications'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify phone verification success header
      expect(find.textContaining('Verified: +91 $testPhone'), findsOneWidget);

      // Verify authentic application details are rendered with 0 mock data
      expect(find.text('Select Application to Track'), findsOneWidget);
      expect(find.textContaining('Plumber Technician'), findsOneWidget);
      expect(find.textContaining('APP-PLUMB-98251'), findsOneWidget);
      expect(find.text('Joshi Plumbing & Leak Repair'), findsOneWidget);
      expect(find.text('Under Review'), findsOneWidget);
      expect(find.text('View Real-Time Status'), findsOneWidget);

      // Strictly zero mock values
      expect(find.text('Fake Technician'), findsNothing);
      expect(find.text('Mock Store'), findsNothing);
    });

    testWidgets('3. Unregistered phone number shows authentic empty state with Register button', (tester) async {
      const unknownPhone = '9999900000';
      await tester.pumpWidget(
        const MaterialApp(
          home: TrackApplicationVerificationScreen(initialPhone: unknownPhone),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Send 6-Digit OTP'));
      await tester.pumpAndSettle();

      final validOtp = FirebaseOtpService.instance.testActiveOtp;
      expect(validOtp, isNotNull);

      await tester.enterText(find.byType(TextField).last, validOtp!);
      await tester.ensureVisible(find.text('Verify & Search Applications'));
      await tester.tap(find.text('Verify & Search Applications'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify authentic empty state
      expect(find.text('No Applications Found'), findsOneWidget);
      expect(find.textContaining('We could not find any submitted partner applications registered under +91 $unknownPhone.'), findsOneWidget);
      expect(find.text('Register as Partner'), findsOneWidget);
    });
  });

  group('Forgot Password with Multi-Identifier & Database Sync Tests', () {
    test('0. Unit Test: resetPasswordForIdentifier directly updates Hive credentials and logs in with new password', () async {
      const unitUser = 'unit_keval_plumber';
      const unitPhone = '9825199999';
      final box = Hive.box('partner_cache');
      final users = [
        {
          'user_id': 'usr_unit_001',
          'username': unitUser,
          'phone': '+91$unitPhone',
          'email': 'unit@servicehub.com',
          'password': testInitialPass,
          'password_hash': testInitialPass,
          'role_name': 'service_provider',
          'account_status': 'ACTIVE',
          'is_active': true,
        }
      ];
      await box.put('registered_users_list', users);

      final res = await SupabaseAuthService.resetPasswordForIdentifier(
        identifier: unitUser,
        newPassword: testNewPass,
      );
      expect(res, isTrue);

      final user = await SupabaseAuthService.findUserByIdentifier(unitUser);
      expect(user, isNotNull);
      expect(user!['password'], equals(testNewPass));
      expect(user['password_hash'], equals(testNewPass));

      // Assert that old password fails
      final oldLogin = await SupabaseAuthService.loginWithUsernameOrPhone(
        identifier: unitUser,
        password: testInitialPass,
        expectedRole: 'service_provider',
      );
      expect(oldLogin.isSuccess, isFalse);

      // Assert that new password succeeds
      final newLogin = await SupabaseAuthService.loginWithUsernameOrPhone(
        identifier: unitUser,
        password: testNewPass,
        expectedRole: 'service_provider',
      );
      expect(newLogin.isSuccess, isTrue);
      expect(newLogin.roleName, equals('service_provider'));
    });

    testWidgets('1. ForgotPasswordScreen rejects non-existent account identifier', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Find Your Account'), findsOneWidget);

      // Enter unknown account
      await tester.enterText(find.byType(TextField).first, 'unknown_user_9999');
      await tester.tap(find.text('Verify & Send 6-Digit OTP'));
      await tester.pumpAndSettle();

      expect(find.text('Account not found with this username, mobile number, or email. Please check your credentials.'), findsOneWidget);
    });

    testWidgets('2. Full Forgot Password Cycle: Username Lookup -> 6-Digit OTP -> Database New Password Sync -> Success View', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ForgotPasswordScreen(initialIdentifier: testUsername),
        ),
      );
      await tester.pumpAndSettle();

      // Step 1: Verify Account & Send 6-Digit OTP
      await tester.tap(find.text('Verify & Send 6-Digit OTP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 2: Verify 6-digit OTP was dispatched to registered phone
      expect(find.textContaining('Enter 6-Digit OTP sent to +91 ******4556'), findsOneWidget);
      final validOtp = FirebaseOtpService.instance.testActiveOtp;
      expect(validOtp, isNotNull);
      expect(validOtp!.length, 6);

      // Enter 6-digit OTP
      await tester.enterText(find.byType(TextField).first, validOtp);
      await tester.ensureVisible(find.text('Verify 6-Digit OTP'));
      await tester.tap(find.text('Verify 6-Digit OTP'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Step 3: Enter New Password & Confirm Password
      expect(find.text('Create New Password'), findsOneWidget);
      final passFields = find.byType(TextField);
      expect(passFields, findsNWidgets(2));

      await tester.enterText(passFields.at(0), testNewPass);
      await tester.enterText(passFields.at(1), testNewPass);

      // Tap Update & Save Password
      await tester.ensureVisible(find.text('Update & Save Password'));
      await tester.tap(find.text('Update & Save Password'));
      await tester.pump();

      await tester.runAsync(() async {
        await Future.delayed(const Duration(milliseconds: 800));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Step 4: Verify Success screen rendered with latest password confirmation
      expect(find.text('Password Updated Successfully!'), findsOneWidget);
      expect(find.textContaining('Your new password has been synchronized with the database and is now active as your latest password.'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);

      // Step 5: Assert that the latest password in database / Hive is now testNewPass
      final updatedUser = await SupabaseAuthService.findUserByIdentifier(testUsername);
      expect(updatedUser, isNotNull);
      expect(updatedUser!['password'], equals(testNewPass));
      expect(updatedUser['password_hash'], equals(testNewPass));
    });
  });
}
