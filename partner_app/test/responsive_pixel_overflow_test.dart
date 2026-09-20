import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/auth/presentation/service_provider_login_screen.dart';
import 'package:service_hub_partner/features/dashboard/presentation/ac_provider_dashboard_controller.dart';
import 'package:service_hub_partner/features/dashboard/presentation/provider_dashboard_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/availability_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/earnings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/my_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/my_services_screen.dart';
import 'package:service_hub_partner/features/registration/presentation/screens/provider_application_status_screen.dart';
import 'package:service_hub_partner/features/registration/presentation/screens/provider_basic_info_registration_screen.dart';
import 'package:service_hub_partner/features/registration/presentation/screens/provider_experience_registration_screen.dart';

class MockDashboardNotifier extends ACProviderDashboardNotifier {
  MockDashboardNotifier([ACProviderDashboardState initial = const ACProviderDashboardState()]) {
    state = initial;
  }

  @override
  Future<void> initDashboard() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_responsive_test');
    Hive.init(tempDir.path);
    final box = await Hive.openBox('partner_cache');
    await box.clear();

    await LocalRegistrationCache.saveRegisteredPartner({
      'id': 'partner_responsive_1',
      'name': 'Rajesh Kumar',
      'phone': '9876543210',
      'email': 'rajesh.kumar@example.com',
      'dob': '12 Mar 1995',
      'businessName': 'Rajesh AC Service & Repairs Multi-line Long Text Test',
      'categoryTitle': 'AC Service Expert',
      'experienceYears': '3+ Years',
      'shortBio': 'Professional AC Service Expert delivering reliable and quality service to homes.',
      'selectedCity': 'Ahmedabad',
      'selectedState': 'Gujarat',
      'verification_status': 'VERIFIED',
    });
  });

  tearDown(() async {
    LiveBookingSyncService.instance.dispose();
  });

  tearDownAll(() {
    LiveBookingSyncService.instance.dispose();
  });

  Future<void> testScreenAtSizes({
    required WidgetTester tester,
    required Widget widget,
    required String screenName,
  }) async {
    final sizes = [
      const Size(320, 568), // Ultra compact phone (iPhone SE 1st gen)
      const Size(360, 640), // Standard compact Android
      const Size(390, 844), // Modern iPhone
    ];

    for (final size in sizes) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;


      // 1. Test standard text scaling
      await tester.pumpWidget(
        MaterialApp(
          home: widget,
        ),
      );
      await tester.pump();
      final excStandard = tester.takeException();
      if (excStandard != null) {
        // ignore: avoid_print
        print('STANDARD ERROR: $excStandard');
        for (final rf in tester.allRenderObjects.whereType<RenderFlex>()) {
          if (rf.toString().contains('OVERFLOWING')) {
            // ignore: avoid_print
            print('FOUND OVERFLOWING RENDERFLEX (STANDARD):\n${rf.toStringDeep()}');
          }
        }
      }
      expect(excStandard, isNull,
          reason: '$screenName has layout exception at size ${size.width}x${size.height}: $excStandard');

      // 2. Test 1.25x elevated font scaling
      await tester.pumpWidget(
        MaterialApp(
          home: widget,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(1.25),
            ),
            child: child!,
          ),
        ),
      );
      await tester.pump();
      final excScaled = tester.takeException();
      if (excScaled != null) {
        // ignore: avoid_print
        print('SCALED ERROR: $excScaled');
        for (final rf in tester.allRenderObjects.whereType<RenderFlex>()) {
          if (rf.toString().contains('OVERFLOWING')) {
            // ignore: avoid_print
            print('FOUND OVERFLOWING RENDERFLEX:\n${rf.toStringDeep()}');
          }
        }
      }
      expect(excScaled, isNull,
          reason: '$screenName has layout exception at size ${size.width}x${size.height} with 1.25x font scale: $excScaled');
    }

    await tester.pumpWidget(const SizedBox());
    LiveBookingSyncService.instance.dispose();
    await tester.pump(const Duration(milliseconds: 300));
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  group('Mobile Responsive Zero-Pixel-Overflow Validation Suite', () {
    testWidgets('1. MyProfileScreen has zero pixel overflow on compact mobile sizes', (tester) async {
      await testScreenAtSizes(
        tester: tester,
        widget: const MyProfileScreen(),
        screenName: 'MyProfileScreen',
      );
    });

    testWidgets('2. EditProfileScreen has zero pixel overflow on compact mobile sizes', (tester) async {
      final controller = ProfileController();
      await controller.loadProfileData();

      await testScreenAtSizes(
        tester: tester,
        widget: EditProfileScreen(controller: controller),
        screenName: 'EditProfileScreen',
      );
    });

    testWidgets('3. MyServicesScreen has zero pixel overflow on compact mobile sizes', (tester) async {
      final controller = ProfileController();
      await controller.loadProfileData();

      await testScreenAtSizes(
        tester: tester,
        widget: MyServicesScreen(controller: controller),
        screenName: 'MyServicesScreen',
      );
    });

    testWidgets('4. AvailabilityScreen has zero pixel overflow on compact mobile sizes', (tester) async {
      final controller = ProfileController();
      await controller.loadProfileData();

      await testScreenAtSizes(
        tester: tester,
        widget: AvailabilityScreen(controller: controller),
        screenName: 'AvailabilityScreen',
      );
    });

    testWidgets('5. EarningsScreen has zero pixel overflow on compact mobile sizes', (tester) async {
      final controller = ProfileController();
      await controller.loadProfileData();

      await testScreenAtSizes(
        tester: tester,
        widget: EarningsScreen(controller: controller),
        screenName: 'EarningsScreen',
      );
    });

    testWidgets('6. ServiceProviderLoginScreen has zero pixel overflow on compact mobile sizes', (tester) async {
      await testScreenAtSizes(
        tester: tester,
        widget: const ServiceProviderLoginScreen(),
        screenName: 'ServiceProviderLoginScreen',
      );
    });

    testWidgets('7. ProviderBasicInfoRegistrationScreen has zero pixel overflow on compact mobile sizes', (tester) async {
      await testScreenAtSizes(
        tester: tester,
        widget: const ProviderBasicInfoRegistrationScreen(),
        screenName: 'ProviderBasicInfoRegistrationScreen',
      );
    });

    testWidgets('8. ProviderExperienceRegistrationScreen has zero pixel overflow on compact mobile sizes', (tester) async {
      await testScreenAtSizes(
        tester: tester,
        widget: const ProviderExperienceRegistrationScreen(
          categoryId: 'ac_service',
        ),
        screenName: 'ProviderExperienceRegistrationScreen',
      );
    });

    testWidgets('9. ProviderDashboardScreen has zero pixel overflow on compact mobile sizes', (tester) async {
      await testScreenAtSizes(
        tester: tester,
        widget: ProviderScope(
          overrides: [
            acProviderDashboardProvider.overrideWith(
              (ref) => MockDashboardNotifier(),
            ),
          ],
          child: const ProviderDashboardScreen(),
        ),
        screenName: 'ProviderDashboardScreen',
      );
    });

    testWidgets('10. ProviderApplicationStatusScreen has zero pixel overflow on compact mobile sizes', (tester) async {
      await testScreenAtSizes(
        tester: tester,
        widget: const ProviderApplicationStatusScreen(initialIdentifier: '9876543210'),
        screenName: 'ProviderApplicationStatusScreen',
      );
    });
  });
}
