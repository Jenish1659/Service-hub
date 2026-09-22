import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/widgets/profile_avatar_widget.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/my_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/my_services_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/availability_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/service_area_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/earnings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_profile_test');
    Hive.init(tempDir.path);
    final box = await Hive.openBox('partner_cache');
    await box.clear();

    // Set real partner profile data in cache
    await LocalRegistrationCache.saveRegisteredPartner({
      'id': 'partner_test_101',
      'name': 'Rajesh Kumar',
      'phone': '9876543210',
      'email': 'rajesh.kumar@example.com',
      'dob': '12 Mar 1995',
      'businessName': 'Rajesh AC Service',
      'categoryTitle': 'AC Service Expert',
      'experienceYears': '3+ Years',
      'shortBio': 'Professional AC Service Expert delivering reliable and quality service.',
      'selectedCity': 'Rajkot',
      'selectedState': 'Gujarat',
      'verification_status': 'VERIFIED',
    });
  });

  group('Zero Fake Data & Profile Controller Tests', () {
    test('1. Profile metrics strictly start with 0 with no dummy fake data', () {
      final controller = ProfileController();

      // Metrics must strictly start at 0
      expect(controller.jobsCompletedThisMonth, equals(0));
      expect(controller.averageRating, equals(0.0));
      expect(controller.repeatCustomersThisMonth, equals(0));

      // Earnings metrics must strictly start at 0
      expect(controller.totalEarnings, equals(0.0));
      expect(controller.earningsGrowthPercent, equals(0.0));
      expect(controller.completedOrders, equals(0));
      expect(controller.pendingPaymentsAmount, equals(0.0));
      expect(controller.pendingOrdersCount, equals(0));
      expect(controller.thisMonthEarnings, equals(0.0));
      expect(controller.allTimeEarnings, equals(0.0));
      expect(controller.recentTransactions, isEmpty);
    });

    test('2. Availability settings initialize with realistic work defaults', () {
      final controller = ProfileController();

      expect(controller.isAvailable, isTrue);
      expect(controller.workingStartTime, equals('09:00 AM'));
      expect(controller.workingEndTime, equals('08:00 PM'));
      expect(controller.selectedWorkingDays, contains('Mon'));
      expect(controller.selectedWorkingDays, contains('Fri'));
      expect(controller.serviceRadiusKm, equals(10.0));
      expect(controller.breakTimes, isNotEmpty);
    });

    test('3. Services list initializes default offerings and supports add/toggle/remove', () async {
      final controller = ProfileController();
      expect(controller.services, isEmpty);

      // Load profile creates default services
      await controller.loadProfileData();
      expect(controller.services, isNotEmpty);
      expect(controller.services.any((s) => s.name == 'AC Installation'), isTrue);

      // Test toggle
      final srv = controller.services.first;
      final initialStatus = srv.isActive;
      controller.toggleServiceStatus(srv.id);
      expect(srv.isActive, equals(!initialStatus));

      // Test custom add
      final custom = PartnerServiceItem(
        id: 'srv_custom_1',
        name: 'AC Coil Replacement',
        description: 'Coil repair service',
        startingPrice: 1500,
        duration: '2 hours',
      );
      controller.addNewService(custom);
      expect(controller.services.any((s) => s.id == 'srv_custom_1'), isTrue);

      // Test remove
      controller.removeService('srv_custom_1');
      expect(controller.services.any((s) => s.id == 'srv_custom_1'), isFalse);
    });
  });

  group('ProfileAvatarWidget Tests', () {
    testWidgets('1. Displays computed initials when no registration photo path exists', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ProfileAvatarWidget(
                name: 'Rajesh Kumar',
                size: 80,
                showCameraBadge: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('RK'), findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);
    });
  });

  group('Main Profile Screen (Image 1) Tests', () {
    testWidgets('1. Renders verified partner identity, zero-state metrics, and menu items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Top title and subtitle
      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('Manage your account and preferences'), findsOneWidget);

      // Verified Partner Badge
      expect(find.text('Verified Partner'), findsOneWidget);

      // Motto banner
      expect(find.text('“Good Service Builds Better Tomorrows”'), findsOneWidget);

      // Metric Cards starting at clean 0
      expect(find.text('Jobs Completed'), findsOneWidget);
      expect(find.text('Earnings'), findsWidgets);
      expect(find.text('Ratings'), findsOneWidget);

      // Menu Tiles
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('My Services'), findsOneWidget);
      expect(find.text('Availability'), findsOneWidget);
      expect(find.text('Service Area'), findsOneWidget);
      expect(find.text('Documents & Verification'), findsOneWidget);
      expect(find.text('Earnings'), findsWidgets);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });

  group('Sub-Page 1: Edit Profile Screen (Image 2) Tests', () {
    testWidgets('1. Renders personal & business inputs and photo change controls', (tester) async {
      final controller = ProfileController();
      await controller.loadProfileData();

      await tester.pumpWidget(
        MaterialApp(
          home: EditProfileScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Keep your information up to date'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Business Information'), findsOneWidget);
      expect(find.text('Profile Picture'), findsOneWidget);
      expect(find.text('Change Photo'), findsOneWidget);
      expect(find.text('Remove Photo'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });
  });

  group('Sub-Page 2: My Services Screen (Image 3) Tests', () {
    testWidgets('1. Renders services offerings list and Add New Service button', (tester) async {
      final controller = ProfileController();
      await controller.loadProfileData();

      await tester.pumpWidget(
        MaterialApp(
          home: MyServicesScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Services'), findsOneWidget);
      expect(find.text('Manage the services you offer to customers'), findsOneWidget);
      expect(find.text('Offer the best service,'), findsOneWidget);
      expect(find.text('Build a better tomorrow'), findsOneWidget);
      expect(find.text('Your Services'), findsOneWidget);
      expect(find.text('Add New Service'), findsOneWidget);
      expect(find.text('AC Installation'), findsOneWidget);
    });
  });

  group('Sub-Page 3: Availability Screen (Image 4) Tests', () {
    testWidgets('1. Renders status toggle, working hours, working days, and radius slider', (tester) async {
      final controller = ProfileController();
      await controller.loadProfileData();

      await tester.pumpWidget(
        MaterialApp(
          home: AvailabilityScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Availability'), findsOneWidget);
      expect(find.text('Set your working hours and days'), findsOneWidget);
      expect(find.text('Be Available,\nGet More Bookings'), findsOneWidget);
      expect(find.text('Availability Status'), findsOneWidget);
      expect(find.text('Working Hours'), findsOneWidget);
      expect(find.text('Working Days'), findsOneWidget);
      expect(find.text('Break Time (Optional)'), findsOneWidget);
      expect(find.text('Instant & Emergency Bookings'), findsOneWidget);
      expect(find.text('Save Availability'), findsOneWidget);
    });

    testWidgets('2. ServiceAreaScreen renders base city, service radius slider, and preferred areas', (tester) async {
      final controller = ProfileController();
      await controller.loadProfileData();

      await tester.pumpWidget(
        MaterialApp(
          home: ServiceAreaScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Service Area'), findsOneWidget);
      expect(find.text('Manage your working area and service radius'), findsOneWidget);
      expect(find.text('Primary Operating City'), findsOneWidget);
      expect(find.text('Service Radius'), findsOneWidget);
      expect(find.text('Preferred Localities'), findsOneWidget);
      expect(find.text('Save Service Area'), findsOneWidget);
    });
  });

  group('Sub-Page 4: Earnings Screen (Image 5) Tests', () {
    testWidgets('1. Renders clean zero-state total earnings, 4 metrics grid, and chart', (tester) async {
      final controller = ProfileController();
      await controller.loadProfileData();

      await tester.pumpWidget(
        MaterialApp(
          home: EarningsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Track your income and withdrawals'), findsOneWidget);
      expect(find.text('Total Earnings'), findsOneWidget);
      expect(find.text('₹0'), findsWidgets);
      expect(find.text('Completed Orders'), findsOneWidget);
      expect(find.text('Pending Payments'), findsOneWidget);
      expect(find.text('This Month'), findsWidgets);
      expect(find.text('All Time Earnings'), findsOneWidget);
      expect(find.text('Withdraw Money'), findsOneWidget);
      expect(find.text('Earning History'), findsOneWidget);
      expect(find.text('Payment Settings'), findsOneWidget);
      expect(find.text('Earnings Overview'), findsOneWidget);
      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('No transactions yet'), findsOneWidget);
    });
  });
}
