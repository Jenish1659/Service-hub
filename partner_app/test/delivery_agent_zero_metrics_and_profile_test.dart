import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/dashboard/presentation/delivery_dashboard_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/delivery_agent_profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_agent_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_delivery_test');
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
  });

  setUp(() async {
    final box = Hive.box('partner_cache');
    await box.clear();
    LocalRegistrationCache.clearMemorySession();
    LiveBookingSyncService.instance.clearBookingsForTest();
    LiveBookingSyncService.instance.stopPolling();
  });

  tearDown(() async {
    LiveBookingSyncService.instance.stopPolling();
  });

  tearDownAll(() async {
    LiveBookingSyncService.instance.stopPolling();
  });

  group('DeliveryAgentProfileController Zero Dummy Data Verification', () {
    test('1. Controller initializes all metrics strictly to 0 and credentials to empty', () {
      final controller = DeliveryAgentProfileController();

      // Zero metrics guarantee
      expect(controller.completedDeliveries, equals(0));
      expect(controller.onTimeRate, equals(0.0));
      expect(controller.totalEarnings, equals(0.0));
      expect(controller.rating, equals(0.0));
      expect(controller.reviewCount, equals(0));

      // Cleared fake credentials guarantee
      expect(controller.vehicleRegNumber, isEmpty);
      expect(controller.drivingLicenseNumber, isEmpty);
      expect(controller.vehicleType, equals('Motorcycle / Scooter'));
      expect(controller.bankName, isEmpty);
      expect(controller.accountNumber, isEmpty);
      expect(controller.ifscCode, isEmpty);
    });
  });

  group('DeliveryAgentProfileScreen Empty Fallbacks & Zero State Verification', () {
    testWidgets('2. Screen displays fallback placeholders when vehicle, DL, and bank are empty', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = DeliveryAgentProfileController();
      controller.agentName = 'Rider Ram';
      controller.isLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryAgentProfileScreen(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Rider details
      expect(find.text('Rider Profile'), findsOneWidget);
      expect(find.text('Rider Ram'), findsOneWidget);

      // Empty vehicle & DL placeholders
      expect(find.text('Motorcycle / Scooter • Not Linked / Upload Required'), findsOneWidget);
      expect(find.text('DL: Not Linked / Upload Required'), findsOneWidget);

      // Empty bank placeholder
      expect(find.text('No Bank Account Linked'), findsOneWidget);

      // Rating: New Rider and 0.0 (0 reviews)
      expect(find.text('New Rider'), findsNWidgets(2)); // Identity card & metric card
      expect(find.text('0.0 (0 reviews)'), findsOneWidget);

      // Zero metrics: Deliveries = 0, On-Time = 0.0%, Earnings = ₹0
      expect(find.text('0'), findsOneWidget);
      expect(find.text('0.0%'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
    });

    testWidgets('3. Screen renders real credentials and reviews when populated', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = DeliveryAgentProfileController();
      controller.agentName = 'Kiran Express';
      controller.vehicleType = 'Electric Scooter';
      controller.vehicleRegNumber = 'GJ-10-EE-4567';
      controller.drivingLicenseNumber = 'DL-GJ10-20250098';
      controller.bankName = 'State Bank of India';
      controller.accountNumber = '123456789012';
      controller.completedDeliveries = 15;
      controller.onTimeRate = 100.0;
      controller.totalEarnings = 1500.0;
      controller.rating = 4.9;
      controller.reviewCount = 12;
      controller.isLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryAgentProfileScreen(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Electric Scooter • GJ-10-EE-4567'), findsOneWidget);
      expect(find.text('DL: DL-GJ10-20250098'), findsOneWidget);
      expect(find.text('State Bank of India • Acc 123456789012'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      expect(find.text('100.0%'), findsOneWidget);
      expect(find.text('₹1.5k'), findsOneWidget);
      expect(find.text('4.9'), findsOneWidget);
      expect(find.text('Rating (12)'), findsOneWidget);
    });
  });

  group('DeliveryDashboardScreen Zero Starting Metrics Verification', () {
    testWidgets('4. Dashboard strictly starts metrics at 0', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await LocalRegistrationCache.updateActiveDeliveryAgent({
          'user_id': 'deliv_test_01',
          'name': 'Active Rider',
          'verification_status': 'VERIFIED',
        });
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryDashboardScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify 3 metric cards start from 0
      expect(find.text('Active Deliveries'), findsOneWidget);
      expect(find.text("Today's Deliveries"), findsOneWidget);
      expect(find.text("Today's Earnings"), findsOneWidget);
      expect(find.text('0 Orders'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
      expect(find.text('No Active Delivery Requests'), findsOneWidget);
    });
  });
}
