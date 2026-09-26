import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/dashboard/presentation/delivery_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_delivery_incoming_test');
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
    LiveBookingSyncService.instance.stopPolling();
  });

  tearDownAll(() async {
    for (final path in [
      r'C:\Users\Public\ServiceHub\service_hub_live_bookings.json',
      '${Directory.systemTemp.path}/service_hub_live_bookings.json',
    ]) {
      final f = File(path);
      if (f.existsSync()) {
        try {
          final content = f.readAsStringSync();
          final map = jsonDecode(content) as Map<String, dynamic>;
          map.remove('test_order_live_999');
          map.remove('ORD-9999');
          f.writeAsStringSync(jsonEncode(map));
        } catch (_) {}
      }
    }
  });

  setUp(() async {
    final box = Hive.box('partner_cache');
    await box.clear();
    LocalRegistrationCache.clearMemorySession();
  });

  testWidgets('Live customer delivery order appears on DeliveryDashboardScreen in real time', (tester) async {
    await tester.runAsync(() async {
      await LocalRegistrationCache.updateActiveDeliveryAgent({
        'user_id': 'deliv_rider_100',
        'delivery_agent_id': 'agent_100',
        'name': 'Sanjay Varma',
        'city': 'Jamnagar',
        'state': 'Gujarat',
        'verification_status': 'VERIFIED',
      });

      // Submit an incoming customer delivery order to LiveBookingSyncService
      await LiveBookingSyncService.instance.submitBooking({
        'id': 'test_order_live_999',
        'booking_id': 'test_order_live_999',
        'order_id': 'test_order_live_999',
        'order_code': 'ORD-999-XYZ',
        'type': 'DELIVERY_ORDER',
        'status': 'ASSIGNED',
        'service_id': 'food_grocery_delivery',
        'service_name': 'Express Grocery Delivery',
        'shop_name': 'SuperMart Jamnagar',
        'shop_address': 'Main Market Road',
        'customer_name': 'Priya Patel',
        'address': 'Patel Colony, Jamnagar',
        'customer_address': 'Patel Colony, Jamnagar',
        'delivery_charge': 65.0,
      });
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: DeliveryDashboardScreen(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify task is loaded and displayed on the active hero card
    expect(find.text('Active Delivery • On the Way'), findsOneWidget);
    expect(find.text('SuperMart Jamnagar'), findsOneWidget);
    expect(find.text('Patel Colony, Jamnagar'), findsOneWidget);
    expect(find.textContaining('999-XYZ'), findsOneWidget);

    // Verify complete delivery action by scrolling until visible and tapping
    await tester.scrollUntilVisible(find.text('Continue Delivery'), 100, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Continue Delivery'));
    await tester.pump(const Duration(milliseconds: 200));

    // Verify snackbar feedback
    expect(find.textContaining('Delivery Completed'), findsOneWidget);
  });
}
