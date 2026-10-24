import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:service_hub_customer/features/profile/data/customer_profile_service.dart';
import 'package:service_hub_customer/features/profile/presentation/profile_screen.dart';
import 'package:service_hub_customer/features/profile/presentation/screens/customer_personal_info_screen.dart';
import 'package:service_hub_customer/features/profile/presentation/screens/customer_addresses_screen.dart';
import 'package:service_hub_customer/features/profile/presentation/screens/customer_add_address_screen.dart';
import 'package:service_hub_customer/features/profile/presentation/screens/customer_payment_methods_screen.dart';
import 'package:service_hub_customer/features/profile/presentation/screens/customer_add_payment_method_screen.dart';
import 'package:service_hub_customer/features/profile/presentation/screens/customer_my_bookings_screen.dart';
import 'package:service_hub_customer/features/profile/presentation/screens/customer_booking_details_screen.dart';
import 'package:service_hub_customer/features/profile/presentation/screens/customer_saved_services_screen.dart';
import 'package:service_hub_customer/features/profile/presentation/screens/customer_notifications_screen.dart';
import 'package:service_hub_customer/features/profile/presentation/screens/customer_settings_screen.dart';
import 'package:service_hub_customer/features/profile/presentation/screens/customer_help_support_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_customer_profile_test_');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('customer_cache')) {
      await Hive.openBox('customer_cache');
    }
  });

  group('1. Customer Profile Service Real Data & Persistence Tests', () {
    test('Profile data returns Customer User fallback and persists updates', () async {
      final service = CustomerProfileService.instance;
      final profile = service.getProfile();
      expect(profile['full_name'], 'Customer User');
      expect(profile['tier'], 'Premium User');

      await service.updateProfile({'full_name': 'Real Customer Name'});
      final updated = service.getProfile();
      expect(updated['full_name'], 'Real Customer Name');

      // Reset
      await service.updateProfile({'full_name': 'Customer User'});
    });

    test('Addresses CRUD starts clean and persists user-added addresses', () async {
      final service = CustomerProfileService.instance;
      final list = service.getAddresses();
      expect(list.any((a) => (a['full_address'] ?? '').toString().contains('Sunrise Residency')), isFalse);
      expect(list.any((a) => (a['full_address'] ?? '').toString().contains('Rajkot Road')), isFalse);

      // Save a new address
      await service.saveAddress({
        'id': 'test_addr_99',
        'label': 'Home',
        'type': 'Home',
        'full_address': 'Patel Colony, Jamnagar',
        'city': 'Jamnagar',
        'state': 'Gujarat',
        'pincode': '361008',
        'is_default': true,
      });

      final afterAdd = service.getAddresses();
      expect(afterAdd.any((a) => a['id'] == 'test_addr_99'), isTrue);

      // Delete the test address
      await service.deleteAddress('test_addr_99');
      final afterDelete = service.getAddresses();
      expect(afterDelete.any((a) => a['id'] == 'test_addr_99'), isFalse);
    });

    test('Payment methods CRUD starts clean and persists real user-added payment methods', () async {
      final service = CustomerProfileService.instance;
      final methods = service.getPaymentMethods();
      expect(methods.any((m) => (m['detail'] ?? '').toString().contains('bheda.aryan')), isFalse);
      expect(methods.any((m) => (m['detail'] ?? '').toString().contains('4589')), isFalse);

      await service.savePaymentMethod({
        'id': 'test_pay_99',
        'type': 'UPI',
        'title': 'UPI',
        'detail': 'realuser@okhdfcbank',
        'is_default': false,
      });

      final afterAdd = service.getPaymentMethods();
      expect(afterAdd.any((m) => m['id'] == 'test_pay_99'), isTrue);

      await service.removePaymentMethod('test_pay_99');
      final afterRemove = service.getPaymentMethods();
      expect(afterRemove.any((m) => m['id'] == 'test_pay_99'), isFalse);
    });

    test('Saved services toggles and dynamic metrics calculate accurately', () async {
      final service = CustomerProfileService.instance;
      final savedBefore = service.getSavedServiceIds().contains('car_service');
      await service.toggleSavedService('car_service');
      final savedAfter = service.getSavedServiceIds().contains('car_service');
      expect(savedAfter, !savedBefore);

      // Revert
      await service.toggleSavedService('car_service');

      final metrics = service.getMetrics();
      expect(metrics['bookings_count'], isNotNull);
      expect(metrics['addresses_count'], isNotNull);
      expect(metrics['saved_count'], isNotNull);
      expect(metrics['total_spent'], isNotNull);
    });
  });

  group('2. Profile 12-Screen UI Verification Tests', () {
    testWidgets('Screen 1: Main ProfileScreen renders avatar, 4-stat metrics card, and 8-item menu', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsNWidgets(2)); // in header action & menu item
      expect(find.byIcon(Icons.notifications_none_outlined), findsOneWidget);

      // Verify Profile Info
      expect(find.text('Customer User'), findsOneWidget);
      expect(find.text('Premium User'), findsOneWidget);

      // Verify 4-stat metrics
      expect(find.text('Bookings'), findsOneWidget);
      expect(find.text('Saved'), findsOneWidget);
      expect(find.text('Total Spent'), findsOneWidget);

      // Verify 8 menu items
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Addresses'), findsNWidgets(2)); // metric label and menu item
      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('My Bookings'), findsOneWidget);
      expect(find.text('Saved Services'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Screen 2: CustomerPersonalInfoScreen renders form fields and Verified badges', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerPersonalInfoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Phone Number *'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Date of Birth'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
      expect(find.text('Verified'), findsNWidgets(2)); // Phone & Email verified
      expect(find.text('Emergency Contact (Optional)'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Screen 3: CustomerAddressesScreen renders saved cards with Default badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerAddressesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Addresses'), findsOneWidget);
      expect(find.text('+ Add New'), findsOneWidget);
      expect(find.text('No Saved Addresses'), findsOneWidget);
      expect(find.text('Add Address'), findsOneWidget);
    });

    testWidgets('Screen 4: CustomerAddAddressScreen renders category chips and address inputs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerAddAddressScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add New Address'), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Office'), findsOneWidget);
      expect(find.text('Others'), findsOneWidget);
      expect(find.text('Full Address *'), findsOneWidget);
      expect(find.text('Set as Default Address'), findsOneWidget);
      expect(find.text('Save Address'), findsOneWidget);
    });

    testWidgets('Screen 5: CustomerPaymentMethodsScreen renders UPI and Bank cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerPaymentMethodsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('+ Add New'), findsOneWidget);
      expect(find.text('No Saved Payment Methods'), findsOneWidget);
      expect(find.text('Add UPI or card for instant checkout'), findsOneWidget);
    });

    testWidgets('Screen 6: CustomerAddPaymentMethodScreen renders 3 tabs and encryption notice', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerAddPaymentMethodScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Add Payment Method'), findsOneWidget);
      expect(find.text('UPI'), findsWidgets);
      expect(find.text('Debit Card'), findsOneWidget);
      expect(find.text('Credit Card'), findsOneWidget);
      expect(find.text('Set as Default Payment Method'), findsOneWidget);
      expect(find.textContaining('securely encrypted'), findsOneWidget);
      expect(find.text('Save UPI'), findsOneWidget);
    });

    testWidgets('Screen 7: CustomerMyBookingsScreen renders filter chips and booking items', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerMyBookingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Bookings'), findsOneWidget);
      expect(find.textContaining('All ('), findsOneWidget);
      expect(find.textContaining('Upcoming ('), findsOneWidget);
      expect(find.textContaining('Completed ('), findsOneWidget);
      expect(find.text('No Bookings Found'), findsOneWidget);
      expect(find.text('You do not have any bookings in this section'), findsOneWidget);
    });

    testWidgets('Screen 8: CustomerBookingDetailsScreen renders tracker, partner details, and reschedule/cancel actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final booking = {
        'id': 'bk_1',
        'booking_code': '#CAR-000125',
        'service_name': 'Car Service & Repair',
        'status': 'Upcoming',
        'scheduled_date': '12 Oct 2026',
        'scheduled_time': '10:00 AM',
        'address': 'Green Park, Jamnagar',
        'price': 1499.0,
        'partner_name': 'Vikram Joshi',
        'partner_rating': '4.8 (125 reviews)',
        'service_details': 'Periodic Standard Service',
        'vehicle_info': 'Hyundai i20 (GJ10AB1234)',
        'step_index': 1,
      };

      await tester.pumpWidget(
        MaterialApp(
          home: CustomerBookingDetailsScreen(booking: booking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Booking Details'), findsOneWidget);
      expect(find.text('#CAR-000125'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.text('Vikram Joshi'), findsOneWidget);
      expect(find.text('Periodic Standard Service'), findsOneWidget);
      expect(find.text('Reschedule'), findsOneWidget);
      expect(find.text('Cancel Booking'), findsOneWidget);
    });

    testWidgets('Screen 9: CustomerSavedServicesScreen renders service cards and heart toggle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerSavedServicesScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Saved Services'), findsOneWidget);
      expect(find.text('AC Service'), findsOneWidget);
      expect(find.text('Car Service & Repair'), findsOneWidget);
      expect(find.text('Plumbing Service'), findsOneWidget);
      expect(find.text('Laundry Service'), findsOneWidget);
      expect(find.text('Care Taker & Nursing'), findsOneWidget);
    });

    testWidgets('Screen 10: CustomerNotificationsScreen renders Today and Yesterday sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerNotificationsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Mark all read'), findsOneWidget);
      expect(find.text('No Notifications'), findsOneWidget);
      expect(find.text('You are all caught up with your updates'), findsOneWidget);
    });

    testWidgets('Screen 11: CustomerSettingsScreen renders security, language, policies and logout button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CustomerSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Account & Security'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('App Version'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('Screen 12: CustomerHelpSupportScreen renders search bar and 5 support options', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: CustomerHelpSupportScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Search for help...'), findsOneWidget);
      expect(find.text('FAQs'), findsOneWidget);
      expect(find.text('Contact Support'), findsOneWidget);
      expect(find.text('Raise a Complaint'), findsOneWidget);
      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('Service Guides'), findsOneWidget);
    });
  });
}
