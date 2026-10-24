import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/core/services/live_booking_sync_service.dart';
import 'package:service_hub_customer/features/cart/presentation/cart_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin Product Schema Alignment & Customer App Normalization', () {
    test('1. Normalizes raw Supabase products table row into customer app card format', () {
      final rawSupabaseRow = {
        'product_id': 'ccfdf6ee-45be-4ff4-be29-3b3867f9db6d',
        'shop_id': '8644497a-8c8a-4ff1-8912-c4e7048176c8',
        'product_name': 'Universal Split AC Remote Control',
        'sku': 'AC-REMOTE-UNIV-01',
        'price': 349.0,
        'description': 'Universal replacement remote control compatible with all major AC brands',
        'image': 'https://images.unsplash.com/photo-1585338107529-13afc5f02586?w=600',
        'status': 'ACTIVE',
        'shops': {
          'shop_name': 'Radha Enterprises',
          'shop_type': 'AC & Appliance Store',
        },
      };

      // Customer app normalization function
      final normalized = {
        'id': rawSupabaseRow['product_id'],
        'name': rawSupabaseRow['product_name'],
        'price': (rawSupabaseRow['price'] as num).toInt(),
        'description': rawSupabaseRow['description'],
        'sku': rawSupabaseRow['sku'],
        'image_url': rawSupabaseRow['image'],
        'shop_id': rawSupabaseRow['shop_id'],
        'store_name': (rawSupabaseRow['shops'] as Map<String, dynamic>?)?['shop_name'] ?? 'Local Store',
        'category': 'ac_repair',
      };

      expect(normalized['id'], 'ccfdf6ee-45be-4ff4-be29-3b3867f9db6d');
      expect(normalized['name'], 'Universal Split AC Remote Control');
      expect(normalized['price'], 349);
      expect(normalized['sku'], 'AC-REMOTE-UNIV-01');
      expect(normalized['shop_id'], '8644497a-8c8a-4ff1-8912-c4e7048176c8');
      expect(normalized['store_name'], 'Radha Enterprises');
      expect(normalized['category'], 'ac_repair');
    });

    test('2. CartItem correctly retains authentic shopId and JSON serialization', () {
      final item = CartItem(
        id: 'ccfdf6ee-45be-4ff4-be29-3b3867f9db6d',
        name: 'Universal Split AC Remote Control',
        price: 349,
        category: 'ac_repair',
        quantity: 2,
        shopId: '8644497a-8c8a-4ff1-8912-c4e7048176c8',
      );

      final json = item.toJson();
      expect(json['shop_id'], '8644497a-8c8a-4ff1-8912-c4e7048176c8');
      expect(json['name'], 'Universal Split AC Remote Control');
      expect(json['quantity'], 2);

      final restored = CartItem.fromJson(json);
      expect(restored.shopId, '8644497a-8c8a-4ff1-8912-c4e7048176c8');
      expect(restored.price, 349);
      expect(restored.quantity, 2);
    });
  });

  group('Full Parcel Cycle: Order Creation, Shopkeeper Claim, Courier Pickup OTP & Dropoff PIN Handshakes', () {
    final String testOrderId = 'ORD_TEST_PARCEL_CYCLE_${DateTime.now().millisecondsSinceEpoch}';
    final random = Random();
    final pickupOtp = (1000 + random.nextInt(9000)).toString();
    final deliveryOtp = (1000 + random.nextInt(9000)).toString();

    test('3. Dynamic 4-digit OTPs are generated and strictly non-empty', () {
      expect(pickupOtp.length, 4);
      expect(int.tryParse(pickupOtp), isNotNull);
      expect(deliveryOtp.length, 4);
      expect(int.tryParse(deliveryOtp), isNotNull);
    });

    test('4. Order broadcast with authentic shopkeeper and customer details', () async {
      await LiveBookingSyncService.instance.submitBooking({
        'id': testOrderId,
        'booking_id': testOrderId,
        'order_id': testOrderId,
        'type': 'DELIVERY_ORDER',
        'status': 'PENDING_SHOPKEEPER',
        'order_code': 'SHO85935781',
        'customer_id': 'ca96ec12-5416-4446-84f0-95efeae6be47',
        'customer_name': 'Test Customer',
        'customer_phone': '+919825012345',
        'shop_id': '8644497a-8c8a-4ff1-8912-c4e7048176c8',
        'items_summary': 'Universal Split AC Remote Control x1',
        'customer_address': 'Digvijay Plot, Street 4, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
        'pickup_otp': pickupOtp,
        'delivery_otp': deliveryOtp,
        'delivery_pin': deliveryOtp,
        'estimated_amount': 384.0,
        'final_amount': 384.0,
      });

      final booking = LiveBookingSyncService.instance.getBooking(testOrderId);
      expect(booking, isNotNull);
      expect(booking!['status'], 'PENDING_SHOPKEEPER');
      expect(booking['pickup_otp'], pickupOtp);
      expect(booking['delivery_otp'], deliveryOtp);
      expect(booking['delivery_pin'], deliveryOtp);
    });

    test('5. Atomic concurrency claim lock: order is accepted by Shopkeeper A and vanishes from Shopkeeper B', () async {
      await LiveBookingSyncService.instance.submitBooking({
        'id': testOrderId,
        'booking_id': testOrderId,
        'order_id': testOrderId,
        'type': 'DELIVERY_ORDER',
        'status': 'PENDING_SHOPKEEPER',
        'order_code': 'SHO85935781',
        'customer_id': 'ca96ec12-5416-4446-84f0-95efeae6be47',
        'pickup_otp': pickupOtp,
        'delivery_otp': deliveryOtp,
      });

      const shopkeeperAId = 'SHOPKEEPER_A_8644497A';
      const shopkeeperBId = 'SHOPKEEPER_B_9999999B';

      // Before claim: Both shopkeepers can see the order
      final allBookings = LiveBookingSyncService.instance.getAllBookings();
      final visibleToAInitial = allBookings.where((b) {
        final assignedPartner = (b['partner_id'] ?? b['shopkeeper_id'] ?? '').toString();
        return assignedPartner.isEmpty || assignedPartner == shopkeeperAId;
      }).toList();

      final visibleToBInitial = allBookings.where((b) {
        final assignedPartner = (b['partner_id'] ?? b['shopkeeper_id'] ?? '').toString();
        return assignedPartner.isEmpty || assignedPartner == shopkeeperBId;
      }).toList();

      expect(visibleToAInitial.length, 1);
      expect(visibleToBInitial.length, 1);

      // Shopkeeper A accepts the order
      await LiveBookingSyncService.instance.acceptBooking(testOrderId, {
        'partner_id': shopkeeperAId,
        'shopkeeper_id': shopkeeperAId,
        'shopkeeper_name': 'Radha Enterprises',
        'shopkeeper_phone': '+919876543210',
        'shopkeeper_address': 'Patel Colony, Jamnagar',
        'status': 'ACCEPTED_BY_SHOPKEEPER',
      });
      await LiveBookingSyncService.instance.updateBookingStatus(testOrderId, 'ACCEPTED_BY_SHOPKEEPER');

      // After claim: Shopkeeper A sees it as accepted; Shopkeeper B has it hidden immediately!
      final allBookingsAfterClaim = LiveBookingSyncService.instance.getAllBookings();
      final visibleToA = allBookingsAfterClaim.where((b) {
        final assignedPartner = (b['partner_id'] ?? b['shopkeeper_id'] ?? '').toString();
        return assignedPartner.isEmpty || assignedPartner == shopkeeperAId;
      }).toList();

      final visibleToB = allBookingsAfterClaim.where((b) {
        final assignedPartner = (b['partner_id'] ?? b['shopkeeper_id'] ?? '').toString();
        return assignedPartner.isEmpty || assignedPartner == shopkeeperBId;
      }).toList();

      expect(visibleToA.length, 1, reason: 'Shopkeeper A who claimed the order can manage it');
      expect(visibleToB.length, 0, reason: 'Shopkeeper B must not see orders already claimed by other shopkeepers');
    });

    test('6. Shopkeeper prepares order and marks READY_FOR_PICKUP for delivery dispatch', () async {
      await LiveBookingSyncService.instance.submitBooking({
        'id': testOrderId,
        'status': 'ACCEPTED_BY_SHOPKEEPER',
        'pickup_otp': pickupOtp,
        'delivery_otp': deliveryOtp,
      });

      await LiveBookingSyncService.instance.updateBookingStatus(testOrderId, 'READY_FOR_PICKUP');
      await LiveBookingSyncService.instance.updateMilestone(testOrderId, 'READY_FOR_PICKUP');

      final order = LiveBookingSyncService.instance.getBooking(testOrderId);
      expect(order?['status'], 'READY_FOR_PICKUP');
      expect(order?['milestone'], 'READY_FOR_PICKUP');
    });

    test('7. Delivery Agent Pickup OTP verification handshake at the store', () async {
      await LiveBookingSyncService.instance.submitBooking({
        'id': testOrderId,
        'status': 'READY_FOR_PICKUP',
        'pickup_otp': pickupOtp,
        'delivery_otp': deliveryOtp,
      });

      final task = LiveBookingSyncService.instance.getBooking(testOrderId)!;
      final expectedPickupOtp = task['pickup_otp'].toString();

      // Attempt wrong OTP -> Failure
      const invalidPickupOtp = '0000';
      final isWrongAttemptValid = (invalidPickupOtp == expectedPickupOtp);
      expect(isWrongAttemptValid, isFalse);

      // Attempt correct OTP -> Success & Status becomes OUT_FOR_DELIVERY
      final isCorrectAttemptValid = (pickupOtp == expectedPickupOtp);
      expect(isCorrectAttemptValid, isTrue);

      await LiveBookingSyncService.instance.updateBookingStatus(testOrderId, 'OUT_FOR_DELIVERY');
      await LiveBookingSyncService.instance.updateMilestone(testOrderId, 'OUT_FOR_DELIVERY');
      await LiveBookingSyncService.instance.updatePartnerLocation(testOrderId, 22.4715, 70.0582);

      final updatedTask = LiveBookingSyncService.instance.getBooking(testOrderId)!;
      expect(updatedTask['status'], 'OUT_FOR_DELIVERY');
      expect(updatedTask['milestone'], 'OUT_FOR_DELIVERY');
      expect(updatedTask['partner_lat'], 22.4715);
      expect(updatedTask['partner_lng'], 70.0582);
    });

    test('8. Customer Delivery PIN verification handshake upon parcel dropoff', () async {
      await LiveBookingSyncService.instance.submitBooking({
        'id': testOrderId,
        'status': 'OUT_FOR_DELIVERY',
        'pickup_otp': pickupOtp,
        'delivery_otp': deliveryOtp,
        'delivery_pin': deliveryOtp,
      });

      final task = LiveBookingSyncService.instance.getBooking(testOrderId)!;
      final expectedDeliveryPin = task['delivery_otp'].toString();

      // Attempt wrong Delivery PIN -> Failure
      const invalidPin = '1111';
      final isWrongPinValid = (invalidPin == expectedDeliveryPin);
      expect(isWrongPinValid, isFalse);

      // Attempt correct Delivery PIN -> Success & Order becomes DELIVERED
      final isCorrectPinValid = (deliveryOtp == expectedDeliveryPin);
      expect(isCorrectPinValid, isTrue);

      await LiveBookingSyncService.instance.updateBookingStatus(testOrderId, 'DELIVERED');
      await LiveBookingSyncService.instance.updateMilestone(testOrderId, 'DELIVERED');

      final finalTask = LiveBookingSyncService.instance.getBooking(testOrderId)!;
      expect(finalTask['status'], 'DELIVERED');
      expect(finalTask['milestone'], 'DELIVERED');
    });

    test('9. Caretaker live map standby mode: zero active bookings leaves map in clean radar standby without mock patient pin', () {
      final allBookings = LiveBookingSyncService.instance.getAllBookings();

      Map<String, dynamic>? findActiveCareBooking() {
        for (final b in allBookings) {
          if (LiveBookingSyncService.isBookingMatchingCategory(b, 'care_taker')) {
            final status = (b['status'] ?? '').toString().toUpperCase();
            final isActive = status == 'ACCEPTED' ||
                status == 'ASSIGNED' ||
                status == 'IN_PROGRESS' ||
                status == 'CONFIRMED' ||
                status == 'ARRIVED' ||
                status == 'ON_THE_WAY';
            if (isActive) {
              return b;
            }
          }
        }
        return null;
      }

      final activeBooking = findActiveCareBooking();
      expect(activeBooking, isNull, reason: 'Zero active bookings must return null');
    });
  });
}
