import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/core/services/h3_geospatial_service.dart';
import 'package:service_hub_customer/core/services/live_booking_sync_service.dart';
import 'package:service_hub_customer/features/orders/presentation/track_order_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('H3 Hierarchical Hexagonal Radius Expansion & Route Navigation Tests', () {
    const testOrderId = 'ORD_H3_TEST_8899';
    const storePickupOtp = '4321';
    const customerDeliveryPin = '7890';

    test('1. H3 Algorithm calculates hexagonal index and expands k-Ring 1 -> 2 -> 3 correctly', () {
      const custLat = 22.4690;
      const custLng = 70.0550;

      // Resolution 8 is city hyperlocal
      final h3Index = H3GeospatialService.instance.latLngToH3Index(custLat, custLng, resolution: 8);
      expect(h3Index, isNotEmpty);

      // k-Ring 1 (~2 km radius)
      final ring1 = H3GeospatialService.instance.getKRingCells(h3Index, ringSize: 1);
      expect(ring1, isNotEmpty);
      expect(ring1.length, greaterThanOrEqualTo(7));

      // k-Ring 2 (~5 km radius)
      final ring2 = H3GeospatialService.instance.getKRingCells(h3Index, ringSize: 2);
      expect(ring2.length, greaterThan(ring1.length));

      // k-Ring 3 (~10 km radius)
      final ring3 = H3GeospatialService.instance.getKRingCells(h3Index, ringSize: 3);
      expect(ring3.length, greaterThan(ring2.length));
    });

    test('2. Dynamic km-based distance and ETA calculation produces accurate ranges', () {
      // Store to Customer: 22.4720, 70.0590 to 22.4690, 70.0550 (~0.5 km)
      final distMeters = H3GeospatialService.instance.computeHaversineDistanceMeters(
        22.4720,
        70.0590,
        22.4690,
        70.0550,
      );
      final distKm = distMeters / 1000.0;
      expect(distKm, greaterThan(0.3));
      expect(distKm, lessThan(1.5));

      // Average urban courier speed (~22 km/h)
      final mins = (distKm / 22.0 * 60).round().clamp(2, 60);
      expect(mins, greaterThanOrEqualTo(2));
      expect(mins, lessThanOrEqualTo(10));
    });

    testWidgets('3. Finding Shopkeeper stage renders radar and H3 cluster info', (tester) async {
      await LiveBookingSyncService.instance.submitBooking({
        'id': testOrderId,
        'order_id': testOrderId,
        'order_code': 'ORD-8899',
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
        'pickup_otp': storePickupOtp,
        'delivery_otp': customerDeliveryPin,
        'delivery_pin': customerDeliveryPin,
        'partner_id': '',
        'shopkeeper_id': '',
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

      // Verify Finding Local Store heading
      expect(find.text('Finding Nearest Shopkeeper'), findsOneWidget);

      // Verify Hyperlocal Search badge & checklist without disclosing H3
      expect(find.textContaining('Hyperlocal Search'), findsOneWidget);
      expect(find.text('Locating Nearby Stores'), findsOneWidget);
      expect(find.textContaining('H3'), findsNothing);
      expect(find.textContaining('Hex'), findsNothing);

      // Verify Delivery ETA range
      expect(find.textContaining('Mins Delivery'), findsOneWidget);

      // Verify real item is rendered
      expect(find.textContaining('Castrol Engine Oil 4T 1L'), findsOneWidget);

      // Verify zero mock values
      expect(find.text('AC Dust Filter (Universal) x1'), findsNothing);
      expect(find.text('2842'), findsNothing);
    });

    testWidgets('4. Finding Courier stage renders after shopkeeper accepts', (tester) async {
      // Advance booking to ACCEPTED_BY_SHOPKEEPER without delivery agent
      await LiveBookingSyncService.instance.submitBooking({
        'id': testOrderId,
        'order_id': testOrderId,
        'order_code': 'ORD-8899',
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
        'pickup_otp': storePickupOtp,
        'delivery_otp': customerDeliveryPin,
        'delivery_pin': customerDeliveryPin,
        'partner_id': 'SHOP_PATEL_01',
        'shopkeeper_id': 'SHOP_PATEL_01',
        'delivery_agent_id': '', // Unassigned courier
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

      // Verify Confirmed Store Banner
      expect(find.textContaining('Patel Auto Stores Accepted Your Order!'), findsOneWidget);

      // Verify Finding Courier Heading
      expect(find.text('Finding Nearest Delivery Courier'), findsOneWidget);

      // Verify Courier Radar text without disclosing H3
      expect(find.textContaining('Courier Radar'), findsOneWidget);
      expect(find.textContaining('H3'), findsNothing);
      expect(find.textContaining('Hex'), findsNothing);
    });

    testWidgets('5. Map renders Leg A: Courier heading to Store for Pickup', (tester) async {
      // Assign courier heading to store
      await LiveBookingSyncService.instance.submitBooking({
        'id': testOrderId,
        'order_id': testOrderId,
        'order_code': 'ORD-8899',
        'type': 'DELIVERY_ORDER',
        'status': 'AGENT_ASSIGNED_HEADING_TO_STORE',
        'items': [
          {'name': 'Castrol Engine Oil 4T 1L', 'quantity': 1, 'price': 399.0},
        ],
        'items_summary': 'Castrol Engine Oil 4T 1L x1',
        'subtotal': 399.0,
        'delivery_charge': 40.0,
        'grand_total': 439.0,
        'total_amount': 439.0,
        'customer_name': 'Keval Joshi',
        'customer_address': 'Patel Colony Street 4, Jamnagar',
        'customer_lat': 22.4690,
        'customer_lng': 70.0550,
        'shopkeeper_name': 'Patel Auto Stores',
        'shopkeeper_address': 'Digvijay Plot, Jamnagar',
        'store_lat': 22.4720,
        'store_lng': 70.0590,
        'pickup_otp': storePickupOtp,
        'delivery_otp': customerDeliveryPin,
        'delivery_pin': customerDeliveryPin,
        'partner_id': 'SHOP_PATEL_01',
        'shopkeeper_id': 'SHOP_PATEL_01',
        'delivery_agent_id': 'COURIER_AMIT_01',
        'delivery_agent_name': 'Amit Dave',
        'delivery_agent_phone': '+91 99099 22334',
        'partner_lat': 22.4715,
        'partner_lng': 70.0585,
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

      // Verify Leg A Banner: Courier heading to store for pickup
      expect(find.text('Courier Heading to Store for Pickup'), findsOneWidget);

      // Verify Courier name is displayed
      expect(find.text('Amit Dave'), findsOneWidget);

      // Verify Store name is displayed
      expect(find.text('Patel Auto Stores'), findsOneWidget);

      // Verify Delivery PIN is displayed
      expect(find.text(customerDeliveryPin), findsOneWidget);
    });

    testWidgets('6. Map renders Leg B: Courier heading to Customer after Pickup OTP verified', (tester) async {
      // Advance to OUT_FOR_DELIVERY (Pickup OTP verified)
      await LiveBookingSyncService.instance.submitBooking({
        'id': testOrderId,
        'order_id': testOrderId,
        'order_code': 'ORD-8899',
        'type': 'DELIVERY_ORDER',
        'status': 'OUT_FOR_DELIVERY',
        'items': [
          {'name': 'Castrol Engine Oil 4T 1L', 'quantity': 1, 'price': 399.0},
        ],
        'items_summary': 'Castrol Engine Oil 4T 1L x1',
        'subtotal': 399.0,
        'delivery_charge': 40.0,
        'grand_total': 439.0,
        'total_amount': 439.0,
        'customer_name': 'Keval Joshi',
        'customer_address': 'Patel Colony Street 4, Jamnagar',
        'customer_lat': 22.4690,
        'customer_lng': 70.0550,
        'shopkeeper_name': 'Patel Auto Stores',
        'shopkeeper_address': 'Digvijay Plot, Jamnagar',
        'store_lat': 22.4720,
        'store_lng': 70.0590,
        'pickup_otp': storePickupOtp,
        'delivery_otp': customerDeliveryPin,
        'delivery_pin': customerDeliveryPin,
        'partner_id': 'SHOP_PATEL_01',
        'shopkeeper_id': 'SHOP_PATEL_01',
        'delivery_agent_id': 'COURIER_AMIT_01',
        'delivery_agent_name': 'Amit Dave',
        'delivery_agent_phone': '+91 99099 22334',
        'partner_lat': 22.4705,
        'partner_lng': 70.0570,
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

      // Verify Leg B Banner: Heading to doorstep
      expect(find.text('Courier Heading to Your Doorstep'), findsOneWidget);

      // Verify Delivery PIN is displayed prominently
      expect(find.text(customerDeliveryPin), findsOneWidget);
    });
  });
}
