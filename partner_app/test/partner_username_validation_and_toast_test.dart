import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/core/services/username_availability_service.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/features/registration/domain/entities/partner_basic_info.dart';
import 'package:service_hub_partner/features/registration/domain/repositories/registration_repository.dart';
import 'package:service_hub_partner/features/registration/presentation/controllers/provider_registration_controller.dart';

class FakeRegistrationRepository implements RegistrationRepository {
  @override
  Future<bool> checkMobileExists(String mobileNumber) async => false;

  @override
  Future<bool> checkEmailExists(String email) async => false;

  @override
  Future<String> saveBasicInformation(PartnerBasicInfo basicInfo) async => 'dummy_id';

  @override
  Future<PartnerBasicInfo?> loadDraftRegistration() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Username Availability & Format Rules Tests', () {
    test('1. Validates minimum 6 characters rule', () {
      // Less than 6 characters -> false
      expect(UsernameAvailabilityService.isValidUsernameFormat(''), isFalse);
      expect(UsernameAvailabilityService.isValidUsernameFormat('abc'), isFalse);
      expect(UsernameAvailabilityService.isValidUsernameFormat('user1'), isFalse);
      expect(UsernameAvailabilityService.isValidUsernameFormat('a_b'), isFalse);

      // Exactly 6 characters -> true (if other rules pass)
      expect(UsernameAvailabilityService.isValidUsernameFormat('user01'), isTrue);
      expect(UsernameAvailabilityService.isValidUsernameFormat('jenish'), isTrue);
    });

    test('2. Validates numbers and letters allowed', () {
      expect(UsernameAvailabilityService.isValidUsernameFormat('jenish1659'), isTrue);
      expect(UsernameAvailabilityService.isValidUsernameFormat('service2026'), isTrue);
    });

    test('3. Validates ONLY _ and . special characters allowed', () {
      // Disallowed special chars
      expect(UsernameAvailabilityService.isValidUsernameFormat('user@123'), isFalse);
      expect(UsernameAvailabilityService.isValidUsernameFormat('user-name'), isFalse);
      expect(UsernameAvailabilityService.isValidUsernameFormat('user#name'), isFalse);
      expect(UsernameAvailabilityService.isValidUsernameFormat('user\$name'), isFalse);
      expect(UsernameAvailabilityService.isValidUsernameFormat('user name'), isFalse);

      // Allowed special chars (single)
      expect(UsernameAvailabilityService.isValidUsernameFormat('rohit_01'), isTrue);
      expect(UsernameAvailabilityService.isValidUsernameFormat('amit.pro'), isTrue);
    });

    test('4. Validates at most 1 special character allowed (error if > 1)', () {
      // 1 special character -> true
      expect(UsernameAvailabilityService.isValidUsernameFormat('rohit_01'), isTrue);
      expect(UsernameAvailabilityService.isValidUsernameFormat('service.hub'), isTrue);

      // 2 or more special characters -> false
      expect(UsernameAvailabilityService.isValidUsernameFormat('rohit_pro_01'), isFalse); // 2 underscores
      expect(UsernameAvailabilityService.isValidUsernameFormat('amit..pro'), isFalse); // 2 dots
      expect(UsernameAvailabilityService.isValidUsernameFormat('service_hub.pro'), isFalse); // 1 underscore + 1 dot = 2
      expect(UsernameAvailabilityService.isValidUsernameFormat('_rohit_'), isFalse); // 2 underscores
    });

    test('5. Generates valid suggestions adhering to all conditions', () {
      final suggestions = UsernameAvailabilityService.generateSuggestions('rohit');
      expect(suggestions, isNotEmpty);
      for (final sug in suggestions) {
        expect(UsernameAvailabilityService.isValidUsernameFormat(sug), isTrue,
            reason: 'Generated suggestion $sug must satisfy all username rules');
        expect(sug.length, greaterThanOrEqualTo(6));
      }

      // Even with short or empty base
      final shortBaseSug = UsernameAvailabilityService.generateSuggestions('a');
      expect(shortBaseSug, isNotEmpty);
      for (final sug in shortBaseSug) {
        expect(UsernameAvailabilityService.isValidUsernameFormat(sug), isTrue,
            reason: 'Suggestion $sug from short base must satisfy all username rules');
      }
    });
  });

  group('ProviderRegistrationController Username Behavior Tests', () {
    late ProviderRegistrationController controller;

    setUp(() {
      controller = ProviderRegistrationController(repository: FakeRegistrationRepository());
    });

    tearDown(() {
      controller.dispose();
    });

    test('1. Controller enforces format conditions before check', () async {
      // When username is less than 6 chars
      controller.usernameController.text = 'abc';
      final okShort = await controller.checkUsernameInDatabase('abc');
      expect(okShort, isFalse);
      expect(controller.usernameError, equals('please enter username as per conditions'));

      // When username has > 1 special char
      controller.usernameController.text = 'a_b_c123';
      final okMultiSpecial = await controller.checkUsernameInDatabase('a_b_c123');
      expect(okMultiSpecial, isFalse);
      expect(controller.usernameError, equals('please enter username as per conditions'));
    });

    test('2. Controller generates suggestions dynamically on typing', () {
      controller.onUsernameChanged('test');
      expect(controller.usernameSuggestions, isNotEmpty);
      for (final sug in controller.usernameSuggestions) {
        expect(controller.isValidUsernameFormat(sug), isTrue);
      }

      controller.onUsernameChanged('');
      expect(controller.usernameSuggestions, isEmpty);
    });
  });

  group('TopToast Engine Widget Tests', () {
    testWidgets('1. Displays top-anchored toast with message and correct icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  TopToast.show(
                    ctx,
                    'use different username it is already availble',
                    isError: true,
                  );
                },
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      // Tap button to show TopToast
      await tester.tap(find.text('Show Error'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 300)); // Complete slide-in animation

      // Verify the toast text is on screen
      expect(find.text('use different username it is already availble'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

      // Verify dismiss close button
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump(const Duration(milliseconds: 300));

      // Advance clock past timer to settle
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('2. Displays success toast with correct styling and auto-dismisses', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () {
                  TopToast.show(
                    ctx,
                    '? Username "@rohit_01" is available!',
                    isError: false,
                  );
                },
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('? Username "@rohit_01" is available!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      // Advance timer so auto-dismiss completes cleanly
      await tester.pump(const Duration(seconds: 4));
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
