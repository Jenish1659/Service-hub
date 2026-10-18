import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';

void main() {
  setUp(() {
    LiveBookingSyncService.instance.clearBookingsForTest();
  });

  tearDown(() {
    LiveBookingSyncService.instance.clearBookingsForTest();
  });

  group('All Services Live Dispatch & Arrival Tests (Zero Cross-Talk & Zero Fake Data)', () {
    test('1. AC Service Request arrives for AC Provider and NOT on other 5 services', () async {
      await LiveBookingSyncService.instance.submitBooking({
        'id': 'REAL_AC_01',
        'booking_id': 'REAL_AC_01',
        'customer_id': 'CUST_AC_01',
        'customer_name': 'Ramesh Bhai',
        'customer_phone': '+91 98765 11111',
        'category_id': 'ac_service',
        'service_name': 'Split AC Jet Wash Cleaning',
        'price': 499.0,
        'status': 'PENDING',
        'address': 'Patel Colony, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
      });

      final acOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service');
      expect(acOffers.length, 1);
      expect(acOffers.first['booking_id'], 'REAL_AC_01');

      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('car_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('care_taker').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('cooking').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('laundry').isEmpty, true);
    });

    test('2. Car Service Request arrives for Car Partner and NOT on other 5 services', () async {
      await LiveBookingSyncService.instance.submitBooking({
        'id': 'REAL_CAR_01',
        'booking_id': 'REAL_CAR_01',
        'customer_id': 'CUST_CAR_01',
        'customer_name': 'Hiren Shah',
        'customer_phone': '+91 98765 22222',
        'category_id': 'car_service',
        'service_name': 'Periodic Standard Service & Inspection',
        'price': 1499.0,
        'status': 'PENDING',
        'address': 'Khodiyar Colony, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
      });

      final carOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('car_service');
      expect(carOffers.length, 1);
      expect(carOffers.first['booking_id'], 'REAL_CAR_01');

      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('care_taker').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('cooking').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('laundry').isEmpty, true);
    });

    test('3. Care Taker Request arrives for Care Partner and NOT on other 5 services', () async {
      await LiveBookingSyncService.instance.submitBooking({
        'id': 'REAL_CARE_01',
        'booking_id': 'REAL_CARE_01',
        'customer_id': 'CUST_CARE_01',
        'customer_name': 'Meena Trivedi',
        'customer_phone': '+91 98765 33333',
        'category_id': 'care_taker',
        'service_name': 'Elderly Care Assistant (Day Shift)',
        'price': 499.0,
        'status': 'PENDING',
        'address': 'Valkeshwari Nagari, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
      });

      final careOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('care_taker');
      expect(careOffers.length, 1);
      expect(careOffers.first['booking_id'], 'REAL_CARE_01');

      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('car_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('cooking').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('laundry').isEmpty, true);
    });

    test('4. Cooking Request arrives for Cooking Partner and NOT on other 5 services', () async {
      await LiveBookingSyncService.instance.submitBooking({
        'id': 'REAL_COOK_01',
        'booking_id': 'REAL_COOK_01',
        'customer_id': 'CUST_COOK_01',
        'customer_name': 'Rajeshwari Ben',
        'customer_phone': '+91 98765 44444',
        'category_id': 'cooking',
        'service_name': 'Daily Domestic Home Cook (2 Meals)',
        'price': 399.0,
        'status': 'PENDING',
        'address': 'Digjam Circle, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
      });

      final cookOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('cooking');
      expect(cookOffers.length, 1);
      expect(cookOffers.first['booking_id'], 'REAL_COOK_01');

      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('car_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('care_taker').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('laundry').isEmpty, true);
    });

    test('5. Plumbing Request arrives for Plumbing Partner and NOT on other 5 services', () async {
      await LiveBookingSyncService.instance.submitBooking({
        'id': 'REAL_PLUMB_01',
        'booking_id': 'REAL_PLUMB_01',
        'customer_id': 'CUST_PLUMB_01',
        'customer_name': 'Suresh Vora',
        'customer_phone': '+91 98765 55555',
        'category_id': 'plumbing',
        'service_name': 'Tap & Pipe Leakage Repair',
        'price': 249.0,
        'status': 'PENDING',
        'address': 'Digvijay Plot, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
      });

      final plumbOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing');
      expect(plumbOffers.length, 1);
      expect(plumbOffers.first['booking_id'], 'REAL_PLUMB_01');

      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('car_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('care_taker').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('cooking').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('laundry').isEmpty, true);
    });

    test('6. Laundry Request arrives for Laundry Partner and NOT on other 5 services', () async {
      await LiveBookingSyncService.instance.submitBooking({
        'id': 'REAL_LAUNDRY_01',
        'booking_id': 'REAL_LAUNDRY_01',
        'customer_id': 'CUST_LAUNDRY_01',
        'customer_name': 'Pooja Dave',
        'customer_phone': '+91 98765 66666',
        'category_id': 'laundry',
        'service_name': 'Wash & Steam Ironing',
        'price': 199.0,
        'status': 'PENDING',
        'address': 'Oshwal Colony, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
      });

      final laundryOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('laundry');
      expect(laundryOffers.length, 1);
      expect(laundryOffers.first['booking_id'], 'REAL_LAUNDRY_01');

      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('car_service').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('care_taker').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('cooking').isEmpty, true);
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing').isEmpty, true);
    });

    test('7. Universal Accept & Lifecycle Handshake across all services', () async {
      const bId = 'CYCLE_PLUMB_777';
      await LiveBookingSyncService.instance.submitBooking({
        'id': bId,
        'booking_id': bId,
        'category_id': 'plumbing',
        'service_name': 'Tap & Pipe Leakage Repair',
        'price': 249.0,
        'status': 'PENDING',
      });

      // 1. Initial pending
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing').length, 1);

      // 2. Partner accepts
      final ok = await LiveBookingSyncService.instance.acceptBooking(bId, {
        'partner_id': 'PARTNER_PLUMB_01',
        'partner_name': 'Kanti Bhai Plumber',
        'partner_phone': '+91 98765 88888',
      });
      expect(ok, true);

      // 3. Immediately leaves pending queue
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('plumbing').isEmpty, true);

      // 4. Booking has partner assignment
      final b = LiveBookingSyncService.instance.getBooking(bId);
      expect(b?['status'], anyOf('ACCEPTED', 'CONFIRMED'));
      expect(b?['partner_id'], 'PARTNER_PLUMB_01');

      // 5. Completion
      await LiveBookingSyncService.instance.updateBookingStatus(bId, 'COMPLETED');
      expect(LiveBookingSyncService.instance.getBooking(bId)?['status'], 'COMPLETED');
    });

    test('8. Future SCHEDULED Booking arrives in Partner Queue and can be Accepted', () async {
      const bId = 'SCHED_COOK_888';
      await LiveBookingSyncService.instance.submitBooking({
        'id': bId,
        'booking_id': bId,
        'customer_id': 'CUST_SCHED_01',
        'customer_name': 'Kinjal Patel',
        'customer_phone': '+91 98765 77777',
        'category_id': 'cooking',
        'service_name': 'Daily Domestic Home Cook (2 Meals)',
        'price': 499.0,
        'status': 'SCHEDULED',
        'scheduled_date': 'Tomorrow, 10:00 AM',
        'address': 'Patel Colony Street 4, Jamnagar',
      });

      // 1. Verify arrives in cooking pending offers despite status being SCHEDULED
      final offers = LiveBookingSyncService.instance.getPendingOffersForCategory('cooking');
      expect(offers.length, 1);
      expect(offers.first['booking_id'], bId);
      expect(offers.first['status'], 'SCHEDULED');

      // 2. Cooking Partner accepts scheduled request
      final ok = await LiveBookingSyncService.instance.acceptBooking(bId, {
        'partner_id': '0f5f402b-8887-4afd-8948-f9489297c9c9',
        'partner_name': 'Chef Rajesh',
      });
      expect(ok, true);

      // 3. Leaves pending queue
      expect(LiveBookingSyncService.instance.getPendingOffersForCategory('cooking').isEmpty, true);

      // 4. Partner assigned
      final b2 = LiveBookingSyncService.instance.getBooking(bId);
      expect(b2?['status'], anyOf('ACCEPTED', 'CONFIRMED'));
      expect(b2?['partner_id'], '0f5f402b-8887-4afd-8948-f9489297c9c9');
    });
  });
}

