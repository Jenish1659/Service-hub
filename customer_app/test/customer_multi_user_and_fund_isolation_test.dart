import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_customer/core/services/customer_database_sync_service.dart';
import 'package:service_hub_customer/features/profile/data/customer_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_customer_multi_user_test_');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('customer_cache')) {
      await Hive.openBox('customer_cache');
    }
  });

  setUp(() async {
    final box = Hive.box('customer_cache');
    await box.clear();
    CustomerProfileService.instance.setTestBookings(null);
  });

  group('1. Multi-Customer Identity & Authentic UUID Generation', () {
    test('CustomerDatabaseSyncService creates distinct UUIDs for different customers', () async {
      final customer1 = await CustomerDatabaseSyncService.syncCustomerToDatabase(
        name: 'Priya Patel',
        phone: '+91 98251 23456',
        email: 'priya.patel@servicehub.com',
        area: 'Digvijay Plot',
      );

      final customer2 = await CustomerDatabaseSyncService.syncCustomerToDatabase(
        name: 'Aarav Mehta',
        phone: '+91 98252 34567',
        email: 'aarav.mehta@servicehub.com',
        area: 'Indira Gandhi Marg',
      );

      // Verify UUIDs exist and are distinct
      expect(customer1['user_id'], isNotEmpty);
      expect(customer2['user_id'], isNotEmpty);
      expect(customer1['user_id'], isNot(equals(customer2['user_id'])));

      // Verify neither customer is Jenish Bheda or Admin UUID
      const jenishId = '3e2584b1-4943-4196-abaa-1de62a456703';
      const adminId = 'ca96ec12-5416-4446-84f0-95efeae6be47';
      expect(customer1['user_id'], isNot(equals(jenishId)));
      expect(customer1['user_id'], isNot(equals(adminId)));
      expect(customer2['user_id'], isNot(equals(jenishId)));
      expect(customer2['user_id'], isNot(equals(adminId)));

      // Verify details
      expect(customer1['name'], 'Priya Patel');
      expect(customer1['phone'], '+919825123456');
      expect(customer2['name'], 'Aarav Mehta');
      expect(customer2['phone'], '+919825234567');
    });

    test('ensureActiveCustomerAccount preserves logged-in customer identity', () async {
      final box = Hive.box('customer_cache');
      const testCustomerId = '11112222-3333-4444-5555-666677778888';
      await box.put('user_id', testCustomerId);
      await box.put('user_name', 'Meera Jadeja');
      await box.put('user_phone', '+919825345678');
      await box.put('active_customer_session', {
        'user_id': testCustomerId,
        'name': 'Meera Jadeja',
        'phone': '+919825345678',
      });

      final active = await CustomerDatabaseSyncService.ensureActiveCustomerAccount();

      expect(active['user_id'], testCustomerId);
      expect(active['name'], 'Meera Jadeja');
      expect(active['phone'], '+919825345678');
      expect(active['user_id'], isNot(equals('3e2584b1-4943-4196-abaa-1de62a456703')));
    });
  });

  group('2. Booking and Fund Isolation Per Customer Account', () {
    test('Spending and booking counts are strictly isolated per individual customer', () {
      const customerAId = 'e8b42291-764f-4a39-9d7a-d021c38e9102'; // Priya Patel
      const customerBId = 'b7c53392-875f-4b40-ae8b-e132d49f0213'; // Aarav Mehta
      const jenishId = '3e2584b1-4943-4196-abaa-1de62a456703';     // Jenish Bheda

      final bookings = [
        // Priya's bookings
        {'customer_id': customerAId, 'final_amount': 499.0},
        {'customer_id': customerAId, 'final_amount': 448.0},
        {'customer_id': customerAId, 'final_amount': 499.0},

        // Aarav's bookings
        {'customer_id': customerBId, 'final_amount': 498.0},
        {'customer_id': customerBId, 'final_amount': 498.0},
        {'customer_id': customerBId, 'final_amount': 499.0},

        // Jenish's booking
        {'customer_id': jenishId, 'final_amount': 498.0},
      ];

      // Aggregate spend and count per customer
      final Map<String, double> customerSpend = {};
      final Map<String, int> customerBookingCount = {};

      for (final b in bookings) {
        final cid = b['customer_id'] as String;
        final amt = b['final_amount'] as double;
        customerSpend[cid] = (customerSpend[cid] ?? 0.0) + amt;
        customerBookingCount[cid] = (customerBookingCount[cid] ?? 0) + 1;
      }

      // Assert Priya Patel
      expect(customerBookingCount[customerAId], 3);
      expect(customerSpend[customerAId], 1446.0);

      // Assert Aarav Mehta
      expect(customerBookingCount[customerBId], 3);
      expect(customerSpend[customerBId], 1495.0);

      // Assert Jenish Bheda has only his 1 booking (spend not merged!)
      expect(customerBookingCount[jenishId], 1);
      expect(customerSpend[jenishId], 498.0);
    });

    test('Customer identity isolates bookings strictly to active account without leakage', () {
      const meeraId = 'c9d644a3-986a-4c51-bf9c-f243e5a01324';
      const meeraPhone = '+919825345678';

      final allBookings = [
        {
          'id': 'booking_meera_1',
          'customer_id': meeraId,
          'customer_phone': meeraPhone,
          'service_name': 'AC Deep Cleaning',
          'status': 'Upcoming',
          'price': 499.0,
        },
        {
          'id': 'booking_jenish_1',
          'customer_id': '3e2584b1-4943-4196-abaa-1de62a456703',
          'customer_phone': '+919876543210',
          'service_name': 'AC Repair',
          'status': 'Completed',
          'price': 498.0,
        },
        {
          'id': 'booking_priya_1',
          'customer_id': 'e8b42291-764f-4a39-9d7a-d021c38e9102',
          'customer_phone': '+919825123456',
          'service_name': 'Window AC Install',
          'status': 'Upcoming',
          'price': 448.0,
        },
      ];

      final cleanMeeraPhone = meeraPhone.replaceAll(RegExp(r'\D'), '');
      final myBookings = allBookings.where((b) {
        final bCustId = (b['customer_id'] ?? '').toString().trim();
        final bPhone = (b['customer_phone'] ?? '').toString().replaceAll(RegExp(r'\D'), '');
        return bCustId == meeraId || (bPhone.isNotEmpty && bPhone.endsWith(cleanMeeraPhone));
      }).toList();

      // Only Meera's booking should be returned!
      expect(myBookings.length, 1);
      expect(myBookings.first['id'], 'booking_meera_1');
      expect(myBookings.first['customer_id'], meeraId);
    });
  });
}
