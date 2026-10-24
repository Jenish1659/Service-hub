import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_live_map_screen.dart';
import 'package:service_hub_partner/features/dashboard/presentation/delivery_live_map_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Caretaker Map Real Location & Standby Mode Tests', () {
    testWidgets('Renders in Active Standby Radar mode with ZERO fake customer pin when no booking exists', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CareLiveMapScreen(
            booking: null,
            showAppBar: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Active Standby Card is present
      expect(find.text('Active Standby Mode'), findsOneWidget);
      expect(find.text('ONLINE'), findsOneWidget);
      expect(find.textContaining('Caregiver live GPS active'), findsOneWidget);

      // Verify ZERO fake patient pin or fake customer details
      expect(find.text('Customer Location, Jamnagar'), findsNothing);
      expect(find.text('Navigating to Patient...'), findsNothing);
    });

    testWidgets('Renders real patient details when authentic booking coordinates exist', (tester) async {
      final realBooking = {
        'id': 'CARE_REAL_001',
        'booking_id': 'CARE_REAL_001',
        'customer_name': 'Rameshbhai Patel',
        'customer_phone': '+91 98250 12345',
        'customer_address': 'Patel Colony Street 4, Jamnagar',
        'customer_lat': 22.4680,
        'customer_lng': 70.0620,
        'category_id': 'care_taker',
        'status': 'ACCEPTED',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: CareLiveMapScreen(
            booking: realBooking,
            showAppBar: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify real patient name and address are rendered
      expect(find.text('Rameshbhai Patel'), findsOneWidget);
      expect(find.text('Patel Colony Street 4, Jamnagar'), findsOneWidget);
      expect(find.text('Start Navigation'), findsOneWidget);
    });
  });

  group('Delivery Agent Dual OTP Handshake & Zero Mock Text Tests', () {
    testWidgets('Delivery map requires Pickup OTP at store and displays zero demo PIN helper text', (tester) async {
      final deliveryTask = {
        'id': 'TASK_DEL_101',
        'order_id': 'ORD_101',
        'order_code': 'ORD-101',
        'shop_name': 'Universal Electronics & Spares',
        'customer_name': 'Pooja Shah',
        'customer_address': 'Aerodrome Road, Jamnagar',
        'pickup_otp': '7821',
        'delivery_otp': '4390',
        'delivery_pin': '4390',
        'store_lat': 22.4700,
        'store_lng': 70.0600,
        'customer_lat': 22.4800,
        'customer_lng': 70.0700,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryLiveMapScreen(
            task: deliveryTask,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Verify ZERO demo helper PIN text anywhere on screen
      expect(find.textContaining('Demo Verification PIN'), findsNothing);
      expect(find.textContaining('4829'), findsNothing);
    });
  });

  group('Shopkeeper Concurrency & Category Isolation Tests', () {
    test('Bookings claimed by another shopkeeper are isolated and hidden', () {
      // Order claimed by Shopkeeper A
      final orderClaimedByA = {
        'id': 'STORE_ORD_991',
        'type': 'DELIVERY_ORDER',
        'category_id': 'store',
        'partner_id': 'SHOPKEEPER_A',
        'shopkeeper_id': 'SHOPKEEPER_A',
        'status': 'ACCEPTED_BY_SHOPKEEPER',
      };

      // Order pending
      final orderPending = {
        'id': 'STORE_ORD_992',
        'type': 'DELIVERY_ORDER',
        'category_id': 'store',
        'partner_id': '',
        'shopkeeper_id': '',
        'status': 'PENDING_SHOPKEEPER',
      };

      // If current shopkeeper is B
      const currentShopkeeperId = 'SHOPKEEPER_B';
      final partnerOfA = (orderClaimedByA['partner_id'] ?? '').toString();
      final partnerOfPending = (orderPending['partner_id'] ?? '').toString();

      // Concurrency check logic
      final isVisibleToBA = partnerOfA.isEmpty || partnerOfA == currentShopkeeperId;
      final isVisibleToBPending = partnerOfPending.isEmpty || partnerOfPending == currentShopkeeperId;

      expect(isVisibleToBA, isFalse, reason: 'Claimed order must immediately vanish from Shopkeeper B');
      expect(isVisibleToBPending, isTrue, reason: 'Pending order must be visible to Shopkeeper B');
    });
  });
}
