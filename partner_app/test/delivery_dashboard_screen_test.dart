import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/dashboard/presentation/delivery_dashboard_screen.dart';
import 'package:service_hub_partner/features/dashboard/presentation/widgets/delivery_recent_and_nav_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_delivery_dash_test');
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
    LiveBookingSyncService.instance.stopPolling();
  });

  setUp(() async {
    final box = Hive.box('partner_cache');
    await box.clear();
    LocalRegistrationCache.clearMemorySession();
  });

  group('DeliveryDashboardScreen Layout & Zero Dummy Data Tests', () {
    testWidgets('1. Dashboard renders with zero RenderFlex overflow on compact screen (320x640)', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await LocalRegistrationCache.updateActiveDeliveryAgent({
          'user_id': 'deliv_rider_01',
          'name': 'Raju Patel',
          'city': 'Rajkot',
          'state': 'Gujarat',
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

      // No overflow exceptions on 320px
      expect(tester.takeException(), isNull);

      // Verify Header & Greeting
      expect(find.textContaining('Raju'), findsOneWidget);
      expect(find.text('VERIFIED PARTNER'), findsOneWidget);

      // Verify Shift status card
      expect(find.text('ONLINE'), findsOneWidget);

      // Verify strictly 0 metrics baseline
      expect(find.text('Deliveries Completed'), findsOneWidget);
      expect(find.text('Pending Deliveries'), findsOneWidget);
      expect(find.text("Today's Earnings"), findsOneWidget);
      expect(find.text('On-Time Rate'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);

      // Verify Daily Goal Card
      expect(find.text("TODAY'S GOAL"), findsOneWidget);
      expect(find.text('0 / 8'), findsOneWidget);

      // Verify Quick Shortcuts & Nav Bar
      expect(find.text('QUICK ACTIONS'), findsOneWidget);
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('Live Map'), findsOneWidget);
      expect(find.text('Earnings'), findsNWidgets(2)); // in Quick Shortcuts and in Bottom Nav
      expect(find.text('Support'), findsOneWidget);

      // Verify Curved Bottom Nav Bar
      expect(find.byType(DeliveryBottomCurvedNavBar), findsOneWidget);
    });

    testWidgets('2. Dashboard renders with zero RenderFlex overflow on standard screen (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await LocalRegistrationCache.updateActiveDeliveryAgent({
          'user_id': 'deliv_rider_02',
          'name': 'Mahesh Chavda',
          'city': 'Jamnagar',
          'state': 'Gujarat',
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

      expect(tester.takeException(), isNull);
      expect(find.textContaining('Mahesh'), findsOneWidget);
      expect(find.text('No Active Delivery Requests'), findsOneWidget);
    });

    testWidgets('3. Curved Bottom Nav Bar has elevated circular center map button and 5 items', (tester) async {
      await tester.runAsync(() async {
        await LocalRegistrationCache.updateActiveDeliveryAgent({
          'user_id': 'deliv_rider_03',
          'name': 'Rider Partner',
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

      // 5 Nav items in bottom curved navbar
      expect(find.descendant(of: find.byType(DeliveryBottomCurvedNavBar), matching: find.text('Home')), findsOneWidget);
      expect(find.descendant(of: find.byType(DeliveryBottomCurvedNavBar), matching: find.text('Orders')), findsOneWidget);
      expect(find.descendant(of: find.byType(DeliveryBottomCurvedNavBar), matching: find.text('Map')), findsOneWidget);
      expect(find.descendant(of: find.byType(DeliveryBottomCurvedNavBar), matching: find.text('Earnings')), findsOneWidget);
      expect(find.descendant(of: find.byType(DeliveryBottomCurvedNavBar), matching: find.text('Profile')), findsOneWidget);

      // Elevated map button is present
      expect(find.byKey(const Key('elevated_map_circle_button')), findsOneWidget);
    });
  });
}
