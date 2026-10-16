import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';

void main() {
  setUp(() {
    LiveBookingSyncService.instance.clearBookingsForTest();
  });

  tearDown(() {
    LiveBookingSyncService.instance.clearBookingsForTest();
  });

  group('Multi-Service Real Cycle & Strict Category Isolation Tests', () {
    test('1. AC Service Booking routes ONLY to AC Provider (Zero leaks to other 7 categories)', () async {
      final acBooking = {
        'id': 'BK_REAL_AC_001',
        'booking_id': 'BK_REAL_AC_001',
        'customer_id': 'CUST_REAL_123',
        'customer_name': 'Jenish Customer',
        'customer_phone': '+919876543210',
        'category_id': 'ac_service',
        'category': 'ac_service',
        'category_name': 'AC Service Specialist',
        'service_id': 'ac_jet_clean_01',
        'service_name': 'Split AC Deep Cleaning (Jet Wash)',
        'price': 499.0,
        'status': 'PENDING',
        'address': 'Patel Colony, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
      };

      await LiveBookingSyncService.instance.submitBooking(acBooking);

      // Verify AC Provider receives it
      final acOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service');
      expect(acOffers.length, 1);
      expect(acOffers.first['booking_id'], 'BK_REAL_AC_001');

      // Verify all other 7 categories receive exactly 0
      final plumbingOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing');
      expect(plumbingOffers.isEmpty, true, reason: 'Plumbing provider must not receive AC booking');

      final cookingOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('cooking');
      expect(cookingOffers.isEmpty, true, reason: 'Cooking provider must not receive AC booking');

      final carOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('car_service');
      expect(carOffers.isEmpty, true, reason: 'Car provider must not receive AC booking');

      final careOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('care_taker');
      expect(careOffers.isEmpty, true, reason: 'Care taker provider must not receive AC booking');

      final laundryOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('laundry');
      expect(laundryOffers.isEmpty, true, reason: 'Laundry provider must not receive AC booking');

      final shopOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('shopkeeper');
      expect(shopOffers.isEmpty, true, reason: 'Shopkeeper must not receive AC booking');

      final deliveryOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('delivery');
      expect(deliveryOffers.isEmpty, true, reason: 'Delivery agent must not receive AC booking');
    });

    test('2. Plumbing Booking routes ONLY to Plumbing Partner (Zero leaks)', () async {
      final plumbBooking = {
        'id': 'BK_REAL_PLUMB_002',
        'booking_id': 'BK_REAL_PLUMB_002',
        'customer_id': 'CUST_REAL_123',
        'customer_name': 'Jenish Customer',
        'customer_phone': '+919876543210',
        'category_id': 'plumbing',
        'category': 'plumbing',
        'category_name': 'Plumbing Specialist',
        'service_id': 'plumb_pipe_repair',
        'service_name': 'Leakage Fix & Tap Replacement',
        'price': 299.0,
        'status': 'PENDING',
        'address': 'Digvijay Plot, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
      };

      await LiveBookingSyncService.instance.submitBooking(plumbBooking);

      // Verify Plumbing Partner receives it
      final plumbingOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing');
      expect(plumbingOffers.length, 1);
      expect(plumbingOffers.first['booking_id'], 'BK_REAL_PLUMB_002');

      // Verify other categories receive 0
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('cooking').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('car_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('care_taker').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('laundry').isEmpty, true);
    });

    test('3. Cooking Booking routes ONLY to Cooking Partner (Zero leaks)', () async {
      final cookBooking = {
        'id': 'BK_REAL_COOK_003',
        'booking_id': 'BK_REAL_COOK_003',
        'customer_id': 'CUST_REAL_123',
        'customer_name': 'Jenish Customer',
        'customer_phone': '+919876543210',
        'category_id': 'cooking',
        'category': 'cooking',
        'category_name': 'Cooking Specialist',
        'service_id': 'cook_daily_meal',
        'service_name': 'Daily Domestic Home Cook (2 Meals)',
        'price': 399.0,
        'status': 'PENDING',
        'address': 'Indira Marg, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
      };

      await LiveBookingSyncService.instance.submitBooking(cookBooking);

      final cookOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('cooking');
      expect(cookOffers.length, 1);
      expect(cookOffers.first['booking_id'], 'BK_REAL_COOK_003');

      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('car_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('care_taker').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('laundry').isEmpty, true);
    });

    test('4. Car Service Booking routes ONLY to Car Service Partner (Zero leaks)', () async {
      final carBooking = {
        'id': 'BK_REAL_CAR_004',
        'booking_id': 'BK_REAL_CAR_004',
        'customer_id': 'CUST_REAL_123',
        'customer_name': 'Jenish Customer',
        'customer_phone': '+919876543210',
        'category_id': 'car_service',
        'category': 'car_service',
        'category_name': 'Car Service Specialist',
        'service_id': 'car_foam_wash',
        'service_name': 'Full Body Foam Wash & Interior Detailing',
        'price': 499.0,
        'status': 'PENDING',
        'address': 'Khodiyar Colony, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
      };

      await LiveBookingSyncService.instance.submitBooking(carBooking);

      final carOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('car_service');
      expect(carOffers.length, 1);
      expect(carOffers.first['booking_id'], 'BK_REAL_CAR_004');

      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('cooking').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('care_taker').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('laundry').isEmpty, true);
    });

    test('5. Care Taker Booking routes ONLY to Care Taker Partner (Zero leaks)', () async {
      final careBooking = {
        'id': 'BK_REAL_CARE_005',
        'booking_id': 'BK_REAL_CARE_005',
        'customer_id': 'CUST_REAL_123',
        'customer_name': 'Jenish Customer',
        'customer_phone': '+919876543210',
        'category_id': 'care_taker',
        'category': 'care_taker',
        'category_name': 'Care Taker Specialist',
        'service_id': 'care_elderly_day',
        'service_name': 'Elderly Care Assistant (Day Shift)',
        'price': 599.0,
        'status': 'PENDING',
        'address': 'Valkeshwari Nagari, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
      };

      await LiveBookingSyncService.instance.submitBooking(careBooking);

      final careOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('care_taker');
      expect(careOffers.length, 1);
      expect(careOffers.first['booking_id'], 'BK_REAL_CARE_005');

      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('cooking').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('car_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('laundry').isEmpty, true);
    });

    test('6. Laundry Booking routes ONLY to Laundry Partner (Never to Shopkeeper store orders)', () async {
      final laundryBooking = {
        'id': 'BK_REAL_LAUNDRY_006',
        'booking_id': 'BK_REAL_LAUNDRY_006',
        'customer_id': 'CUST_REAL_123',
        'customer_name': 'Jenish Customer',
        'customer_phone': '+919876543210',
        'category_id': 'laundry',
        'category': 'laundry',
        'category_name': 'Laundry Specialist',
        'service_id': 'laundry_wash_iron',
        'service_name': 'Wash & Steam Iron',
        'price': 299.0,
        'status': 'PENDING',
        'address': 'Oshwal Colony, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
      };

      await LiveBookingSyncService.instance.submitBooking(laundryBooking);

      final laundryOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('laundry');
      expect(laundryOffers.length, 1);
      expect(laundryOffers.first['booking_id'], 'BK_REAL_LAUNDRY_006');

      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('shopkeeper').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing').isEmpty, true);
    });

    test('7. End-to-End Real-Time Acceptance Cycle: Accept -> Disappear from pending -> Status Confirmed', () async {
      const bookingId = 'BK_CYCLE_E2E_999';
      await LiveBookingSyncService.instance.submitBooking({
        'id': bookingId,
        'booking_id': bookingId,
        'customer_id': 'CUST_REAL_123',
        'customer_name': 'Jenish Customer',
        'customer_phone': '+919876543210',
        'category_id': 'ac_service',
        'service_name': 'Split AC Deep Cleaning',
        'price': 499.0,
        'status': 'PENDING',
      });

      // 1. Initially visible in pending offers
      var offers = LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service');
      expect(offers.length, 1);
      expect(offers.first['booking_id'], bookingId);

      // 2. Online partner accepts the job
      final accepted = await LiveBookingSyncService.instance.acceptBooking(
        bookingId,
        {
          'partner_id': 'PRT_SHYAM_01',
          'partner_name': 'Shyam Patel',
          'partner_phone': '+919876543211',
        },
      );
      expect(accepted, true);

      // 3. Immediately disappears from pending queue (claimed!)
      offers = LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service');
      expect(offers.isEmpty, true, reason: 'Claimed booking must no longer appear as unassigned pending offer');

      // 4. Booking record in sync service reflects assignment
      final updatedBooking = LiveBookingSyncService.instance.getBooking(bookingId);
      expect(updatedBooking?['status'], 'CONFIRMED');
      expect(updatedBooking?['partner_id'], 'PRT_SHYAM_01');
      expect(updatedBooking?['partner_name'], 'Shyam Patel');

      // 5. Job completion via OTP
      await LiveBookingSyncService.instance.updateBookingStatus(bookingId, 'COMPLETED');
      final completedBooking = LiveBookingSyncService.instance.getBooking(bookingId);
      expect(completedBooking?['status'], 'COMPLETED');
    });
  });
}
