import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/routes/app_router.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/features/dashboard/presentation/delivery_live_map_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_map_test');
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
  });

  tearDown(() async {
    LiveBookingSyncService.instance.stopPolling();
  });

  tearDownAll(() async {
    LiveBookingSyncService.instance.stopPolling();
  });

  group('DeliveryLiveMapScreen OpenStreetMap Navigation Tests', () {
    testWidgets('1. Renders FlutterMap with OSM TileLayer, Markers, Polyline and Info Card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockTask = {
        'order_code': '#ORD-7744',
        'shop_name': 'Reliance Smart Bazaar',
        'shop_phone': '+91 98980 54321',
        'customer_name': 'Aarav Patel',
        'customer_address': 'Plot 45, Saru Section Road, Jamnagar',
        'customer_phone': '+91 97234 11223',
        'earning': 60.0,
        'rider_lat': 22.4700,
        'rider_lng': 70.0550,
        'store_lat': 22.4740,
        'store_lng': 70.0600,
        'customer_lat': 22.4800,
        'customer_lng': 70.0700,
        'status': 'ACCEPTED',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryLiveMapScreen(task: mockTask),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify FlutterMap is rendered
      expect(find.byType(FlutterMap), findsOneWidget);

      // 2. Verify TileLayer is present with OpenStreetMap template and user agent
      final tileLayerFinder = find.byType(TileLayer);
      expect(tileLayerFinder, findsOneWidget);
      final tileLayer = tester.widget<TileLayer>(tileLayerFinder);
      expect(tileLayer.urlTemplate, equals('https://tile.openstreetmap.org/{z}/{x}/{y}.png'));
      expect(tileLayer.tileProvider.headers['User-Agent'], contains('com.servicehub.partner'));

      // 3. Verify PolylineLayer connects rider -> store -> destination
      final polylineLayerFinder = find.byType(PolylineLayer);
      expect(polylineLayerFinder, findsOneWidget);
      final polylineLayer = tester.widget<PolylineLayer>(polylineLayerFinder);
      expect(polylineLayer.polylines.length, greaterThanOrEqualTo(2));
      expect(polylineLayer.polylines.first.points.length, equals(3));

      // 4. Verify Markers: Rider (scooter), Store pickup, Customer drop
      expect(find.byIcon(Icons.two_wheeler_rounded), findsOneWidget);
      expect(find.text('STORE PICKUP'), findsOneWidget);
      expect(find.text('CUSTOMER DROP'), findsOneWidget);
      expect(find.byIcon(Icons.storefront_rounded), findsWidgets);
      expect(find.byIcon(Icons.flag_rounded), findsOneWidget);

      // 5. Verify Top Info Card
      expect(find.text('#ORD-7744'), findsOneWidget);
      expect(find.text('Pickup: Reliance Smart Bazaar'), findsOneWidget);
      expect(find.text('Dropoff: Plot 45, Saru Section Road, Jamnagar'), findsOneWidget);
      expect(find.textContaining('km'), findsWidgets);
      expect(find.textContaining('min ETA'), findsOneWidget);

      // 6. Verify Interactive Controls
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      expect(find.byIcon(Icons.route_rounded), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);

      // 7. Verify Bottom Action Bar
      expect(find.text('Call Support'), findsOneWidget);
      expect(find.text('Complete Delivery'), findsOneWidget);
    });

    testWidgets('2. Zoom controls and Call Support bottom sheet function interactively', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final mockTask = {
        'order_code': '#ORD-1234',
        'shop_name': 'Quick Mart',
        'shop_phone': '+91 99999 11111',
        'customer_name': 'Ramesh Bhai',
        'customer_address': 'Shanti Nagar, Jamnagar',
        'customer_phone': '+91 98888 22222',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryLiveMapScreen(task: mockTask),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Test Zoom In and Out button taps
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump(const Duration(milliseconds: 100));

      // Test GPS Re-center button taps
      await tester.tap(find.byIcon(Icons.my_location_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.byIcon(Icons.route_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      // Test Call Support Bottom Sheet
      await tester.tap(find.text('Call Support'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Quick Contact Support'), findsOneWidget);
      expect(find.text('Quick Mart'), findsOneWidget);
      expect(find.text('Ramesh Bhai'), findsOneWidget);
      expect(find.text('Store Pickup Partner • +91 99999 11111'), findsOneWidget);
      expect(find.text('Customer (Dropoff) • +91 98888 22222'), findsOneWidget);

      // Close bottom sheet
      Navigator.of(tester.element(find.text('Quick Contact Support'))).pop();
      await tester.pump(const Duration(milliseconds: 500));

      // Verify OTP handover dialog opens on Complete Delivery
      await tester.tap(find.text('Complete Delivery'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Confirm Handover'), findsOneWidget);
      expect(find.text('Demo Verification PIN: 4829'), findsOneWidget);
      expect(find.text('Verify & Settle'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Confirm Handover'), findsNothing);
    });

    testWidgets('3. Complete Delivery updates LiveBookingSyncService and shows success snackbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const orderId = 'ORD-9999';
      await LiveBookingSyncService.instance.submitBooking({
        'id': orderId,
        'order_id': orderId,
        'status': 'ACCEPTED',
      });

      final mockTask = {
        'order_code': '#$orderId',
        'order_id': orderId,
        'assignment_id': 'ASG-101',
        'shop_name': 'Express Grocers',
        'shop_phone': '+91 98980 99999',
        'customer_name': 'Neelam Shah',
        'customer_address': 'Silver Heights, Jamnagar',
        'customer_phone': '+91 97234 88888',
        'earning': 75.0,
        'require_otp': false, // Test direct complete path
      };

      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryLiveMapScreen(task: mockTask),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Complete Delivery directly
      await tester.tap(find.text('Complete Delivery'));
      await tester.pump(const Duration(milliseconds: 300));

      // Verify LiveBookingSyncService is updated to DELIVERED
      final b = LiveBookingSyncService.instance.getBooking(orderId);
      expect(b, isNotNull);
      expect(b!['status'], equals('DELIVERED'));
      expect(b['current_milestone'], equals('DELIVERED'));

      // Verify success notification SnackBar is shown
      expect(find.textContaining('Delivery Completed!'), findsOneWidget);
    });

    test('4. AppRouter contains /delivery/map route', () {
      final routes = appRouter.configuration.routes;
      final mapRoute = routes.whereType<GoRoute>().firstWhere(
        (r) => r.path == '/delivery/map',
        orElse: () => throw StateError('Route /delivery/map not found'),
      );
      expect(mapRoute.path, equals('/delivery/map'));
    });

    testWidgets('5. Empty task renders clean Delivery Zone Radar mode with rider position and nearby hubs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryLiveMapScreen(task: {}),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify FlutterMap is rendered with OSM TileLayer
      expect(find.byType(FlutterMap), findsOneWidget);
      final tileLayer = tester.widget<TileLayer>(find.byType(TileLayer));
      expect(tileLayer.urlTemplate, equals('https://tile.openstreetmap.org/{z}/{x}/{y}.png'));

      // 2. Verify Delivery Zone Radar header and sub-titles
      expect(find.text('DELIVERY ZONE RADAR'), findsOneWidget);
      expect(find.text('Live Courier Radar & Fleet View'), findsOneWidget);
      expect(find.text('3 Nearby Hubs'), findsOneWidget);

      // 3. Verify Rider pulse marker and Hub markers
      expect(find.byIcon(Icons.two_wheeler_rounded), findsOneWidget);
      expect(find.byIcon(Icons.hub_rounded), findsWidgets);
      expect(find.textContaining('Central Dispatch Hub'), findsOneWidget);

      // 4. Verify no dummy store/customer markers exist in radar mode
      expect(find.text('STORE PICKUP'), findsNothing);
      expect(find.text('CUSTOMER DROP'), findsNothing);

      // 5. Verify Radar Bottom Bar controls
      expect(find.text('Focus My GPS'), findsOneWidget);
      expect(find.text('Orders Queue'), findsOneWidget);

      // Test tapping Focus My GPS
      await tester.tap(find.text('Focus My GPS'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
