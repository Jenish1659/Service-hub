import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/core/services/live_booking_sync_service.dart';
import 'package:service_hub_customer/features/orders/presentation/track_order_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testOrderId = 'ORD-RESP-1001';

  group('TrackOrderScreen Responsive Zero-Overflow & No H3 Disclosure Tests', () {
    setUp(() async {
      await LiveBookingSyncService.instance.submitBooking({
        'id': testOrderId,
        'order_id': testOrderId,
        'order_code': 'ORD-1001',
        'type': 'DELIVERY_ORDER',
        'status': 'PENDING_SHOPKEEPER',
        'items': [
          {'name': 'Castrol Engine Oil 4T 1L', 'quantity': 1, 'price': 399.0},
        ],
        'items_summary': 'Castrol Engine Oil 4T 1L x1',
        'subtotal': 399.0,
        'delivery_charge': 40.0,
        'grand_total': 439.0,
        'total_amount': 439.0,
        'customer_name': 'Keval Joshi',
        'customer_phone': '+91 98251 44556',
        'customer_address': 'Patel Colony Street 4, Jamnagar',
        'customer_lat': 22.4690,
        'customer_lng': 70.0550,
        'pickup_otp': '4821',
        'delivery_otp': '7392',
        'delivery_pin': '7392',
        'partner_id': '',
        'shopkeeper_id': '',
        'delivery_agent_id': '',
        'created_at': DateTime.now().toIso8601String(),
      });
    });

    testWidgets('1. Compact phone width (320px) has ZERO overflow and ZERO H3 text disclosure', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 700 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrackOrderScreen(orderId: testOrderId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify no Flutter error or overflow exception was thrown
      expect(tester.takeException(), isNull);

      // Verify UI text matches clean customer wording
      expect(find.text('Finding Nearest Shopkeeper'), findsOneWidget);
      expect(find.textContaining('Hyperlocal Search'), findsOneWidget);
      expect(find.text('Locating Nearby Stores'), findsOneWidget);

      // Verify strictly NO H3 or Hexagonal text disclosed
      expect(find.textContaining('H3'), findsNothing);
      expect(find.textContaining('Hexagon'), findsNothing);
      expect(find.textContaining('Hex Cells'), findsNothing);
    });

    testWidgets('2. Stage 2 (Finding Courier) on 320px width has ZERO overflow and ZERO H3 text disclosure', (tester) async {
      tester.view.physicalSize = const Size(320 * 2.0, 700 * 2.0);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await LiveBookingSyncService.instance.submitBooking({
        'id': testOrderId,
        'order_id': testOrderId,
        'order_code': 'ORD-1001',
        'type': 'DELIVERY_ORDER',
        'status': 'ACCEPTED_BY_SHOPKEEPER',
        'items': [
          {'name': 'Castrol Engine Oil 4T 1L', 'quantity': 1, 'price': 399.0},
        ],
        'items_summary': 'Castrol Engine Oil 4T 1L x1',
        'subtotal': 399.0,
        'delivery_charge': 40.0,
        'grand_total': 439.0,
        'total_amount': 439.0,
        'customer_name': 'Keval Joshi',
        'customer_phone': '+91 98251 44556',
        'customer_address': 'Patel Colony Street 4, Jamnagar',
        'customer_lat': 22.4690,
        'customer_lng': 70.0550,
        'shopkeeper_name': 'Patel Auto Stores',
        'shop_name': 'Patel Auto Stores',
        'shopkeeper_address': 'Digvijay Plot, Jamnagar',
        'shopkeeper_phone': '+91 98250 88776',
        'store_lat': 22.4720,
        'store_lng': 70.0590,
        'pickup_otp': '4821',
        'delivery_otp': '7392',
        'delivery_pin': '7392',
        'partner_id': 'SHOP_01',
        'shopkeeper_id': 'SHOP_01',
        'delivery_agent_id': '',
        'created_at': DateTime.now().toIso8601String(),
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrackOrderScreen(orderId: testOrderId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify no Flutter error or overflow exception was thrown
      expect(tester.takeException(), isNull);

      // Verify Courier UI text matches clean customer wording
      expect(find.text('Finding Nearest Delivery Courier'), findsOneWidget);
      expect(find.textContaining('Courier Radar'), findsOneWidget);

      // Verify strictly NO H3 or Hexagonal text disclosed
      expect(find.textContaining('H3'), findsNothing);
      expect(find.textContaining('Hexagon'), findsNothing);
      expect(find.textContaining('Hex Cells'), findsNothing);
    });
  });
}
