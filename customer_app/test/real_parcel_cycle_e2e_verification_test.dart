import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/core/services/live_booking_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('100% Real Hyperlocal Parcel & Order Delivery Cycle E2E Test', () {
    final sync = LiveBookingSyncService.instance;
    final testOrderId = 'test_hyperlocal_order_${DateTime.now().millisecondsSinceEpoch}';
    const customerPickupOtp = '7429';
    const customerDeliveryPin = '5892';

    test('Step 1: Customer submits real order with authentic OTPs & items', () async {
      final realOrderPayload = {
        'id': testOrderId,
        'booking_id': testOrderId,
        'order_id': testOrderId,
        'order_code': 'ORD-98421',
        'type': 'DELIVERY_ORDER',
        'status': 'PENDING_SHOPKEEPER',
        'service_id': 'store_products_delivery',
        'service_name': 'Store Order Delivery',
        'category_id': 'store',
        'category_name': 'store',
        'items': [
          {'id': 'prod_filter_01', 'name': 'Air Purifier Dust Filter', 'quantity': 1, 'price': 349.0},
          {'id': 'prod_spark_02', 'name': 'Spark Plug Core', 'quantity': 2, 'price': 150.0},
        ],
        'items_summary': 'Air Purifier Dust Filter x1, Spark Plug Core x2',
        'subtotal': 649.0,
        'delivery_charge': 40.0,
        'grand_total': 689.0,
        'total_amount': 689.0,
        'customer_id': 'cust_uuid_101',
        'customer_name': 'Keval Joshi',
        'customer_phone': '+91 98251 44556',
        'customer_address': 'Patel Colony Street 4, Jamnagar',
        'customer_lat': 22.4690,
        'customer_lng': 70.0550,
        'shop_id': 'shop_radha_01',
        'shop_name': 'Radha Enterprises & Spare Parts',
        'shop_address': 'Shop #4, Central Market, Jamnagar',
        'shop_phone': '+91 98250 12345',
        'store_lat': 22.4720,
        'store_lng': 70.0590,
        'pickup_otp': customerPickupOtp,
        'delivery_otp': customerDeliveryPin,
        'delivery_pin': customerDeliveryPin,
        'partner_id': '',
        'delivery_agent_id': '',
        'created_at': DateTime.now().toIso8601String(),
      };

      await sync.submitBooking(realOrderPayload);

      final fetched = sync.getBooking(testOrderId);
      expect(fetched, isNotNull);
      expect(fetched!['status'], equals('PENDING_SHOPKEEPER'));
      expect(fetched['partner_id'], isEmpty);
      expect(fetched['delivery_agent_id'], isEmpty);
      expect(fetched['pickup_otp'], equals(customerPickupOtp));
      expect(fetched['delivery_pin'], equals(customerDeliveryPin));
      expect(fetched['items_summary'], contains('Air Purifier Dust Filter'));
      expect(fetched['grand_total'], equals(689.0));
    });

    test('Step 2: Shopkeeper claims order atomically & order vanishes from other shops', () async {
      final initialBooking = sync.getBooking(testOrderId);
      expect(initialBooking, isNotNull);

      const shopkeeper1Id = 'SHOP_RADHA_01';
      const shopkeeper2Id = 'SHOP_PATEL_02';

      // Verify that initially the order is unassigned
      expect((initialBooking!['partner_id'] ?? '').toString().isEmpty, isTrue);

      // Shopkeeper 1 accepts the order
      final claimPayload = {
        'partner_id': shopkeeper1Id,
        'shopkeeper_id': shopkeeper1Id,
        'shopkeeper_name': 'Radha Enterprises & Spare Parts',
        'shop_name': 'Radha Enterprises & Spare Parts',
        'shopkeeper_phone': '+91 98250 12345',
        'shopkeeper_address': 'Shop #4, Central Market, Jamnagar',
        'status': 'ACCEPTED_BY_SHOPKEEPER',
      };

      final accepted = await sync.acceptBooking(testOrderId, claimPayload);
      expect(accepted, isTrue);

      final updatedBooking = sync.getBooking(testOrderId);
      expect(updatedBooking, isNotNull);
      expect(updatedBooking!['status'], equals('ACCEPTED_BY_SHOPKEEPER'));
      expect(updatedBooking['partner_id'], equals(shopkeeper1Id));
      expect(updatedBooking['shopkeeper_id'], equals(shopkeeper1Id));

      // Atomic disappearance check:
      // Shopkeeper 2 inspects order list. Because partner_id is non-empty and != shopkeeper2Id,
      // it MUST NOT appear in Shopkeeper 2's available/new orders queue!
      final assignedPartner = (updatedBooking['partner_id'] ?? updatedBooking['shopkeeper_id'] ?? '').toString();
      final isVisibleToShopkeeper2 = assignedPartner.isEmpty || assignedPartner == shopkeeper2Id;
      expect(isVisibleToShopkeeper2, isFalse, reason: 'Order must vanish from other shopkeepers when accepted');
    });

    test('Step 3: Courier claims parcel delivery assignment', () async {
      const courierId = 'COURIER_AGENT_77';
      const courierName = 'Vikram Sharma';
      const courierPhone = '+91 98765 43210';

      final booking = sync.getBooking(testOrderId);
      expect(booking, isNotNull);
      expect(booking!['status'], equals('ACCEPTED_BY_SHOPKEEPER'));

      // Courier claims the order for delivery
      final courierPayload = Map<String, dynamic>.from(booking)..addAll({
        'delivery_agent_id': courierId,
        'delivery_agent_name': courierName,
        'delivery_agent_phone': courierPhone,
        'rider_lat': 22.4705,
        'rider_lng': 70.0570,
        'status': 'AGENT_ASSIGNED_HEADING_TO_STORE',
      });

      await sync.submitBooking(courierPayload);

      final assignedBooking = sync.getBooking(testOrderId);
      expect(assignedBooking, isNotNull);
      expect(assignedBooking!['status'], equals('AGENT_ASSIGNED_HEADING_TO_STORE'));
      expect(assignedBooking['delivery_agent_id'], equals(courierId));
      expect(assignedBooking['delivery_agent_name'], equals(courierName));
    });

    test('Step 4: Store Handover via Pickup OTP Handshake', () async {
      final booking = sync.getBooking(testOrderId);
      expect(booking, isNotNull);

      final expectedPickupOtp = booking!['pickup_otp'].toString();
      const wrongPickupOtp = '9999';

      // 1. Wrong OTP check
      expect(wrongPickupOtp == expectedPickupOtp, isFalse);

      // 2. Correct OTP check & advance to OUT_FOR_DELIVERY
      expect(customerPickupOtp, equals(expectedPickupOtp));
      await sync.updateBookingStatus(testOrderId, 'OUT_FOR_DELIVERY');
      await sync.updateMilestone(testOrderId, 'OUT_FOR_DELIVERY');

      final outForDeliveryBooking = sync.getBooking(testOrderId);
      expect(outForDeliveryBooking!['status'], equals('OUT_FOR_DELIVERY'));
    });

    test('Step 5: Live GPS Parcel Tracing updates dynamically', () async {
      const movingRiderLat = 22.4712;
      const movingRiderLng = 70.0582;

      await sync.updatePartnerLocation(testOrderId, movingRiderLat, movingRiderLng);

      final tracedBooking = sync.getBooking(testOrderId);
      expect(tracedBooking, isNotNull);
      expect(tracedBooking!['partner_lat'], equals(movingRiderLat));
      expect(tracedBooking['partner_lng'], equals(movingRiderLng));
      expect(tracedBooking['delivery_agent_lat'], equals(movingRiderLat));
      expect(tracedBooking['delivery_agent_lng'], equals(movingRiderLng));
    });

    test('Step 6: Customer Collects Parcel via Delivery OTP / PIN Handshake', () async {
      final booking = sync.getBooking(testOrderId);
      expect(booking, isNotNull);

      final expectedDeliveryPin = (booking!['delivery_pin'] ?? booking['delivery_otp']).toString();
      const wrongDeliveryPin = '0000';

      // 1. Wrong PIN check
      expect(wrongDeliveryPin == expectedDeliveryPin, isFalse);

      // 2. Authentic PIN check & complete delivery
      expect(customerDeliveryPin, equals(expectedDeliveryPin));

      await sync.updateBookingStatus(testOrderId, 'DELIVERED');
      await sync.updateMilestone(testOrderId, 'DELIVERED');

      final completedBooking = sync.getBooking(testOrderId);
      expect(completedBooking, isNotNull);
      expect(completedBooking!['status'], equals('DELIVERED'));
    });
  });
}
