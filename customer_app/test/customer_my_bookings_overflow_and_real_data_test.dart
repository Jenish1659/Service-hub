import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:service_hub_customer/features/profile/data/customer_profile_service.dart';
import 'package:service_hub_customer/features/profile/presentation/screens/customer_my_bookings_screen.dart';
import 'package:service_hub_customer/features/profile/presentation/screens/customer_booking_details_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_bookings_test_');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('customer_cache')) {
      await Hive.openBox('customer_cache');
    }
  });

  tearDown(() {
    CustomerProfileService.instance.setTestBookings(null);
  });

  group('1. Booking Code Formatting & Dynamic Real Data Mapping', () {
    test('formatBookingCode cleanly formats raw UUIDs, SHB codes, and short prefixes', () {
      // 1. Raw 36-char UUIDs from database
      expect(formatBookingCode('bd7f4035-a0a0-424d-8d42-55b4e5457826', 'ac_service'), '#AC-BD7F40');
      expect(formatBookingCode('bd7f4035-a0a0-424d-8d42-55b4e5457826', 'car_service'), '#CAR-BD7F40');
      expect(formatBookingCode('8f0e4703-344e-4a2d-b475-257cea0b12a8', 'plumbing'), '#PLMB-8F0E47');
      expect(formatBookingCode('ea3e71d0-4f0f-4d23-bf55-75915d3cc1c9', 'laundry'), '#LNDR-EA3E71');
      expect(formatBookingCode('55d8435b-d159-4bcf-8019-c5e0cefbb541', 'care_taker'), '#CARE-55D843');
      expect(formatBookingCode('889388bc-ad04-4c04-bc17-7626d60d2aeb', 'cooking'), '#COOK-889388');

      // 2. Real Supabase DB booking codes
      expect(formatBookingCode('SHB13955444'), '#SHB-13955444');
      expect(formatBookingCode('SHB77628101'), '#SHB-77628101');
      expect(formatBookingCode('#SHB29783675'), '#SHB-29783675');

      // 3. Short codes
      expect(formatBookingCode('#CAR-000125'), '#CAR-000125');
      expect(formatBookingCode('#AC-000124'), '#AC-000124');
    });

    test('CustomerProfileService loads diverse real data and isolates customer bookings', () {
      final service = CustomerProfileService.instance;
      final bookings = service.getBookings();

      expect(bookings, isNotEmpty);
      for (final b in bookings) {
        final code = (b['booking_code'] ?? '').toString();
        expect(code, isNotEmpty);
        expect(code.startsWith('#'), isTrue);
        expect(code.length, lessThanOrEqualTo(20));

        expect(b['service_name'], isNotEmpty);
        expect((b['price'] as num).toDouble(), greaterThan(0.0));
      }
    });
  });

  group('2. Overflow Bug Elimination Tests (Small Viewport & Extreme Data)', () {
    testWidgets('CustomerMyBookingsScreen renders with ZERO overflow on narrow 320px screen with long data', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      CustomerProfileService.instance.setTestBookings([
        {
          'id': 'bd7f4035-a0a0-424d-8d42-55b4e5457826',
          'booking_code': '#SHB-13955444',
          'service_name': 'Full Body Foam Wash & Interior Detailing (Super Deep Cleansing)',
          'category': 'car_service',
          'status': 'Upcoming',
          'scheduled_date': '20 Oct 2026',
          'scheduled_time': '10:00 AM - 12:00 PM',
          'address': 'Flat 402, Royal Residency, Opp Reliance Greens, Jamnagar',
          'price': 2923.0,
          'partner_name': 'Vikram Joshi',
          'partner_phone': '+91 98250 12345',
          'partner_rating': '4.9 (142 reviews)',
          'service_details': 'Full Body Foam Wash & Interior Detailing',
          'vehicle_info': 'Hyundai i20 (GJ10AB1234)',
          'step_index': 0,
        },
        {
          'id': '8f0e4703-344e-4a2d-b475-257cea0b12a8',
          'booking_code': '#AC-8F0E47',
          'service_name': 'Window AC (Panasonic) - Jet Cleaning & Gas Refill',
          'category': 'ac_service',
          'status': 'Upcoming',
          'scheduled_date': '21 Oct 2026',
          'scheduled_time': '02:30 PM - 03:30 PM',
          'address': 'Plot 18, Patel Colony Street 4, Jamnagar',
          'price': 2548.0,
          'partner_name': 'Ramesh Patel',
          'partner_phone': '+91 98251 23456',
          'partner_rating': '4.8 (89 reviews)',
          'service_details': 'Window AC (Panasonic)',
          'vehicle_info': '',
          'step_index': 3,
        },
        {
          'id': '55d8435b-d159-4bcf-8019-c5e0cefbb541',
          'booking_code': '#PLMB-55D843',
          'service_name': 'Bathroom Pipeline Leakage Fix & Tap Fitting',
          'category': 'plumbing',
          'status': 'Completed',
          'scheduled_date': '15 Oct 2026',
          'scheduled_time': '11:00 AM',
          'address': 'Sunrise Residency, Jamnagar',
          'price': 448.0,
          'partner_name': 'Kishore Dave',
          'partner_phone': '+91 98252 34567',
          'partner_rating': '4.7 (54 reviews)',
          'service_details': 'Pipe Leakage Fix',
          'vehicle_info': '',
          'step_index': 4,
        },
      ]);

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerMyBookingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify no overflow occurred
      expect(tester.takeException(), isNull);

      // Verify clean codes and titles rendered
      expect(find.text('#SHB-13955444'), findsOneWidget);
      expect(find.text('#AC-8F0E47'), findsOneWidget);
      expect(find.text('#PLMB-55D843'), findsOneWidget);

      // Verify diverse service names
      expect(find.textContaining('Full Body Foam Wash'), findsOneWidget);
      expect(find.textContaining('Window AC (Panasonic)'), findsOneWidget);
      expect(find.textContaining('Bathroom Pipeline Leakage'), findsOneWidget);

      // Verify prices
      expect(find.text('₹2923'), findsOneWidget);
      expect(find.text('₹2548'), findsOneWidget);
      expect(find.text('₹448'), findsOneWidget);

      // Filter chips test - safely scroll to the 3rd chip on narrow screens
      await tester.ensureVisible(find.textContaining('Completed ('));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Completed ('));
      await tester.pumpAndSettle();
      expect(find.text('#PLMB-55D843'), findsOneWidget);
      expect(find.text('#SHB-13955444'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CustomerBookingDetailsScreen renders with ZERO overflow on narrow 320px screen', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final booking = {
        'id': 'bd7f4035-a0a0-424d-8d42-55b4e5457826',
        'booking_code': 'SHB13955444',
        'service_name': 'Full Body Foam Wash & Interior Detailing With Premium Waxing',
        'category': 'car_service',
        'status': 'Upcoming',
        'scheduled_date': '20 Oct 2026',
        'scheduled_time': '10:00 AM',
        'address': 'Very Long Customer Address At Opp Reliance Greens Main Gate, Jamnagar',
        'price': 2923.0,
        'partner_name': 'Vikram Joshi Senior Car Specialist',
        'partner_phone': '+91 98250 12345',
        'partner_rating': '4.9 (142 reviews)',
        'service_details': 'Full Body Foam Wash & Interior Detailing',
        'vehicle_info': 'Hyundai i20 Asta (GJ10AB1234)',
        'step_index': 1,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerBookingDetailsScreen(booking: booking),
        ),
      );
      await tester.pumpAndSettle();

      // Zero exceptions / zero overflow
      expect(tester.takeException(), isNull);
      expect(find.text('#SHB-13955444'), findsOneWidget);
      expect(find.text('Booking Details'), findsOneWidget);
      expect(find.text('Reschedule'), findsOneWidget);
      expect(find.text('Cancel Booking'), findsOneWidget);
    });
  });
}
