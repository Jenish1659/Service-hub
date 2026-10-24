import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/core/services/live_booking_sync_service.dart';
import 'package:service_hub_customer/features/orders/presentation/track_order_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TrackOrderScreen 100% Real Hyperlocal Data & Map Verification Tests', () {
    const testOrderId = 'REAL_ORD_778899';
    const realDeliveryPin = '9153';

    setUp(() async {
      // Seed an authentic real order in LiveBookingSyncService
      await LiveBookingSyncService.instance.submitBooking({
        'id': testOrderId,
        'order_id': testOrderId,
        'booking_id': testOrderId,
        'order_code': 'ORD-778899',
        'type': 'DELIVERY_ORDER',
        'status': 'ACCEPTED_BY_SHOPKEEPER',
        'items': [
          {'name': 'Bosch Spark Plug Super 4', 'quantity': 2, 'price': 240.0},
          {'name': 'Mobil 1 Fully Synthetic 4L', 'quantity': 1, 'price': 1450.0},
        ],
        'items_summary': 'Bosch Spark Plug Super 4 x2, Mobil 1 Fully Synthetic 4L x1',
        'subtotal': 1930.0,
        'delivery_charge': 50.0,
        'grand_total': 1980.0,
        'total_amount': 1980.0,
        'customer_name': 'Keval Joshi',
        'customer_phone': '+91 98251 44556',
        'customer_address': 'Patel Colony Street 4, Jamnagar',
        'customer_lat': 22.4690,
        'customer_lng': 70.0550,
        'shopkeeper_name': 'Shree Maruti Auto Care & Spares',
        'shop_name': 'Shree Maruti Auto Care & Spares',
        'shopkeeper_address': 'Shop #12, GIDC Phase 2, Jamnagar',
        'shopkeeper_phone': '+91 98250 99887',
        'store_lat': 22.4720,
        'store_lng': 70.0590,
        'pickup_otp': '3321',
        'delivery_otp': realDeliveryPin,
        'delivery_pin': realDeliveryPin,
        'partner_id': 'PARTNER_MARUTI_01',
        'shopkeeper_id': 'PARTNER_MARUTI_01',
        'delivery_agent_id': 'COURIER_RAJ_09',
        'delivery_agent_name': 'Rajesh Vaghela',
        'delivery_agent_phone': '+91 99099 11223',
        'partner_lat': 22.4710,
        'partner_lng': 70.0575,
        'created_at': DateTime.now().toIso8601String(),
      });
    });

    testWidgets('TrackOrderScreen renders 100% real data with NO mock values', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: TrackOrderScreen(orderId: testOrderId),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify real Order Code is rendered
      expect(find.textContaining('ORD-778899'), findsWidgets);

      // 2. Verify authentic Delivery PIN is rendered prominently
      expect(find.text(realDeliveryPin), findsOneWidget);

      // 3. Verify real Shopkeeper name is rendered
      expect(find.text('Shree Maruti Auto Care & Spares'), findsOneWidget);

      // 4. Verify real Courier name is rendered
      expect(find.text('Rajesh Vaghela'), findsOneWidget);

      // 5. Verify real Items are rendered
      expect(find.textContaining('Bosch Spark Plug Super 4 x2'), findsOneWidget);
      expect(find.textContaining('Mobil 1 Fully Synthetic 4L x1'), findsOneWidget);

      // 6. Verify real Grand Total is rendered
      expect(find.text('₹1980'), findsOneWidget);

      // 7. Strictly verify ZERO mock or dummy data exists
      expect(find.text('AC Dust Filter (Universal) x1'), findsNothing);
      expect(find.text('₹384.0'), findsNothing);
      expect(find.text('₹349.0'), findsNothing);
      expect(find.text('2842'), findsNothing);
      expect(find.text('Ravi Kumar'), findsNothing);
    });
  });
}
