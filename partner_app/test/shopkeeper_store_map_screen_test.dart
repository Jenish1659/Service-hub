import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/features/dashboard/presentation/shopkeeper_dashboard_screen.dart';
import 'package:service_hub_partner/features/dashboard/presentation/shopkeeper_store_map_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('shopkeeper_map_test_');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('partner_cache')) {
      await Hive.openBox('partner_cache');
    }
  });

  setUp(() {
    LiveBookingSyncService.instance.stopPolling();
    LiveBookingSyncService.instance.clearBookingsForTest();
  });

  tearDown(() async {
    LiveBookingSyncService.instance.stopPolling();
  });

  tearDownAll(() async {
    try {
      LiveBookingSyncService.instance.stopPolling();
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  Widget createTestWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  group('Shopkeeper OpenStreetMap (OSM) Screen Tests', () {
    testWidgets('1. ShopkeeperStoreMapScreen renders FlutterMap, TileLayer, and Store Marker', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(const ShopkeeperStoreMapScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      // 1. FlutterMap rendered
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsOneWidget);
      expect(find.byType(CircleLayer), findsOneWidget);
      expect(find.byType(MarkerLayer), findsOneWidget);

      // 2. Store origin icon and header text
      expect(find.byIcon(Icons.storefront_rounded), findsWidgets);
      expect(find.text('Store Delivery Zone Radar • Live'), findsOneWidget);

      // 3. Floating map controls
      expect(find.byKey(const Key('shopkeeper_map_recenter_button')), findsOneWidget);
      expect(find.byKey(const Key('shopkeeper_map_zoom_in')), findsOneWidget);
      expect(find.byKey(const Key('shopkeeper_map_zoom_out')), findsOneWidget);

      // 4. Radius toggle chips (2km, 5km, 10km)
      expect(find.byKey(const Key('shopkeeper_map_chip_2km')), findsOneWidget);
      expect(find.byKey(const Key('shopkeeper_map_chip_5km')), findsOneWidget);
      expect(find.byKey(const Key('shopkeeper_map_chip_10km')), findsOneWidget);

      // 5. Bottom summary card
      expect(find.text('ACTIVE ORDERS'), findsOneWidget);
      expect(find.text('AVAILABLE RIDERS'), findsOneWidget);
      expect(find.text('OPEN'), findsOneWidget);
    });

    testWidgets('2. Radius toggle chips interactively toggle delivery circles', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(const ShopkeeperStoreMapScreen()));
      await tester.pump(const Duration(milliseconds: 200));

      final chip2km = find.byKey(const Key('shopkeeper_map_chip_2km'));
      expect(chip2km, findsOneWidget);

      // Tap 2km chip to toggle
      await tester.tap(chip2km);
      await tester.pump(const Duration(milliseconds: 200));

      // Tap 5km chip to toggle
      final chip5km = find.byKey(const Key('shopkeeper_map_chip_5km'));
      await tester.tap(chip5km);
      await tester.pump(const Duration(milliseconds: 200));

      // Tap 10km chip to toggle
      final chip10km = find.byKey(const Key('shopkeeper_map_chip_10km'));
      await tester.tap(chip10km, warnIfMissed: false);
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('3. Nearby Delivery Courier markers render scooter icons and open details sheet', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testCouriers = [
        {
          'id': 'courier_1',
          'name': 'Vikram Rathod',
          'rating': 4.9,
          'distance_km': 0.8,
          'status': 'Available for Pickup',
          'vehicle': 'Honda Activa (GJ10-AB-4029)',
          'phone': '+91 98980 44321',
          'location': const LatLng(22.4707 + 0.0035, 70.0577 - 0.0055),
        },
      ];

      await tester.pumpWidget(createTestWidget(ShopkeeperStoreMapScreen(initialCouriers: testCouriers)));
      await tester.pump(const Duration(milliseconds: 200));

      // Courier scooter icons rendered
      expect(find.byIcon(Icons.two_wheeler_rounded), findsWidgets);

      // Find courier name tag (Vikram)
      final vikramTag = find.textContaining('Vikram');
      expect(vikramTag, findsOneWidget);

      // Tap on courier marker to display bottom sheet
      await tester.tap(vikramTag);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify courier sheet displayed
      expect(find.text('Vikram Rathod'), findsOneWidget);
      expect(find.text('Call Rider'), findsOneWidget);
      expect(find.text('Dispatch Order'), findsOneWidget);
    });

    testWidgets('4. Customer active order pin displays order detail sheet', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testOrders = [
        {
          'order_id': '#SH1024',
          'raw_id': 'SH1024',
          'customer_name': 'Amit Shah',
          'customer_phone': '+91 98981 12345',
          'address': 'Patel Colony, Street 5, Jamnagar',
          'title': 'AC Remote & Copper Pipe',
          'amount': 450.0,
          'status': 'PREPARING',
          'location': const LatLng(22.4707 + 0.0055, 70.0577 + 0.0085),
        },
      ];

      await tester.pumpWidget(createTestWidget(ShopkeeperStoreMapScreen(initialOrders: testOrders)));
      await tester.pump(const Duration(milliseconds: 200));

      // Find customer order marker pin
      final orderMarker = find.byIcon(Icons.location_on_rounded).first;
      expect(orderMarker, findsOneWidget);

      // Tap order marker
      await tester.tap(orderMarker);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify order detail sheet
      expect(find.textContaining('Customer Dropoff'), findsOneWidget);
      expect(find.text('Call Customer'), findsOneWidget);
      expect(find.text('Assign Rider'), findsOneWidget);
    });

    testWidgets('5. ShopkeeperStoreMapModal.show opens bottom sheet modal', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (ctx) => ElevatedButton(
              onPressed: () => ShopkeeperStoreMapModal.show(ctx),
              child: const Text('Open Modal Map'),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Open Modal Map'));
      await tester.pump(const Duration(milliseconds: 300));

      // Map is now open in modal
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('6. Dashboard Index 2 (Center Map button) renders elevated button and opens Map', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        final box = Hive.box('partner_cache');
        await box.put('active_shopkeeper', {
          'id': 'test_shopkeeper_id',
          'user_id': 'test_shopkeeper_id',
          'name': 'Rajesh Kumar',
          'role': 'shopkeeper',
          'business_name': 'Rajesh Electronics',
          'business_address': 'Patel Colony, Jamnagar',
          'verification_status': 'VERIFIED',
          'account_status': 'ACTIVE',
        });
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopkeeperDashboardScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Map bottom nav item exists with elevated container
      expect(find.text('Map'), findsOneWidget);
      expect(find.byIcon(Icons.map_rounded), findsOneWidget);

      // Tap elevated center Map button
      await tester.tap(find.byIcon(Icons.map_rounded));
      await tester.pump(const Duration(milliseconds: 300));

      // Map screen is displayed via modal
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('Store Delivery Zone Radar • Live'), findsOneWidget);
    });
  });
}
