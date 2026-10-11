import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/core/utils/service_category_route_helper.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_partner_profile_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_request_details_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_live_map_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_personal_info_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_business_info_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_service_pricing_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_working_hours_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_documents_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_bank_details_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('hive_car_full_test_');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('partner_cache')) {
      await Hive.openBox('partner_cache');
    }
    LiveBookingSyncService.instance.stopPolling();
  });

  setUp(() async {
    LiveBookingSyncService.instance.stopPolling();
    LiveBookingSyncService.instance.clearBookingsForTest();
    await LocalRegistrationCache.clearActiveSession();
    LocalRegistrationCache.clearMemorySession();
    await LocalRegistrationCache.updateActiveServiceProvider({
      'user_id': 'car_qa_01',
      'full_name': 'Karan Mehta',
      'name': 'Karan Mehta',
      'role': 'car_service',
      'category': 'car_service',
      'service_category_id': 'car_service',
      'is_online': true,
      'availability_status': 'ONLINE',
      'rating': 0.0,
      'review_count': 0,
      'city': 'Jamnagar',
    });
  });

  tearDown(() {
    LiveBookingSyncService.instance.stopPolling();
  });

  group('Car Service Partner 100% Real Data & Full Design Verification', () {
    testWidgets('1. Dashboard renders 5-tab navbar with elevated center Map and counters strictly start at zero', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Check Car Service promotional hero banner matching reference design
      expect(find.textContaining('Keep Vehicles'), findsOneWidget);
      expect(find.text('Car Service Provider'), findsWidgets);

      // Verify strict zero-initialization for all metrics
      expect(find.text('₹0'), findsWidgets);
      expect(find.text('0'), findsWidgets);

      // Verify bottom navigation bar items: Home, Jobs, Center Map, Earnings, Profile
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify zero schedule placeholder is displayed
      expect(find.text('No Scheduled Car Services Today'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('2. Service Requests Tab renders New (0), In Progress (0), Completed (0) and zero state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Jobs Tab (Index 1)
      await tester.tap(find.text('Jobs'));
      await tester.pumpAndSettle();

      expect(find.text('Service Requests'), findsOneWidget);
      expect(find.text('New (0)'), findsOneWidget);
      expect(find.text('In Progress (0)'), findsOneWidget);
      expect(find.text('Completed (0)'), findsOneWidget);
      expect(find.text('No New Car Service Requests'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('3. Elevated Center Map Tab opens real OpenStreetMap without fake images', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap elevated center Map button (Index 2)
      await tester.tap(find.text('Map'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify FlutterMap is rendered
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('Current Order'), findsOneWidget);
      expect(find.text('All Customers'), findsOneWidget);
      expect(find.text('Start Navigation'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('4. Earnings Tab renders ₹0 total and zero breakdown', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Earnings Tab (Index 3)
      await tester.tap(find.text('Earnings'));
      await tester.pumpAndSettle();

      expect(find.text('Earnings'), findsWidgets);
      expect(find.text('₹0'), findsWidgets);
      expect(find.text('Completed Orders'), findsOneWidget);
      expect(find.text('Periodic Service'), findsOneWidget);
      expect(find.text('Brake Service'), findsOneWidget);
      expect(find.text('Wheel Alignment'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('5. Order Details Screen renders vehicle info, Jamnagar GJ10 plate, symptoms and action buttons', (tester) async {
      final mockBooking = {
        'id': 'CAR-000125',
        'customer_name': 'Rahul Sharma',
        'customer_phone': '+91 98765 43210',
        'service_name': 'Periodic Standard Service',
        'address': 'Green Park, Jamnagar',
        'booking_date': '11 Oct 2026',
        'scheduled_time': '10:00 AM',
        'vehicle_model': 'Hyundai i20',
        'vehicle_type': 'Hatchback • 2021',
        'number_plate': 'GJ10AB1234',
        'symptoms': ['Unusual engine noise', 'Check engine warning light'],
        'total_amount': 1499,
        'status': 'PENDING',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: CarRequestDetailsScreen(booking: mockBooking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Order Details'), findsOneWidget);
      expect(find.text('#CAR-000125'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('Periodic Standard Service'), findsOneWidget);
      expect(find.text('Hyundai i20'), findsOneWidget);
      expect(find.text('GJ10AB1234'), findsOneWidget);
      expect(find.text('Unusual engine noise'), findsOneWidget);
      expect(find.text('Check engine warning light'), findsOneWidget);
      expect(find.text('₹1499'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Accept Order'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('6. Live Map Screen renders FlutterMap with route navigation info', (tester) async {
      final mockBooking = {
        'id': 'CAR-000125',
        'customer_name': 'Rahul Sharma',
        'customer_phone': '+91 98765 43210',
        'service_name': 'Periodic Standard Service',
        'address': 'Green Park, Jamnagar',
        'status': 'IN_PROGRESS',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: CarLiveMapScreen(booking: mockBooking),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('Live Map'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('Start Navigation'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('7. Profile Screen renders full menu to all subpages and starts at zero rating', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CarPartnerProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('0.0 (0 reviews)'), findsOneWidget);
      expect(find.text('Verified Partner'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Business / Garage Information'), findsOneWidget);
      expect(find.text('Services & Pricing'), findsOneWidget);
      expect(find.text('Availability & Working Hours'), findsOneWidget);
      expect(find.text('Verification Documents'), findsOneWidget);
      expect(find.text('Bank Details'), findsOneWidget);
      expect(find.text('Reviews & Ratings'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('8. Subpage 1: Personal Info screen renders profile fields and save button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CarPersonalInfoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Phone Number *'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Change Photo'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('9. Subpage 2: Business Info screen renders garage fields and radius slider', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CarBusinessInfoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Business Information'), findsOneWidget);
      expect(find.text('Garage / Business Name *'), findsOneWidget);
      expect(find.text('Business Address *'), findsOneWidget);
      expect(find.text('Service Area (Radius)'), findsOneWidget);
      expect(find.text('Business Description'), findsOneWidget);
      expect(find.text('Open Since'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('10. Subpage 3: Services & Pricing screen renders car service catalog and packages', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CarServicePricingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Services & Pricing'), findsOneWidget);
      expect(find.text('Car Service'), findsOneWidget);
      expect(find.text('Periodic Standard Service'), findsOneWidget);
      expect(find.text('Comprehensive Service'), findsOneWidget);
      expect(find.text('AC Service & Gas Refill'), findsOneWidget);
      expect(find.text('Full Foam Wash & Detailing'), findsOneWidget);
      expect(find.text('Wheel Alignment & Balancing'), findsOneWidget);
      expect(find.text('360° Safety Inspection'), findsOneWidget);
      expect(find.text('+ Add New Service'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('11. Subpage 4: Working Hours screen renders day selector and time fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CarWorkingHoursScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Availability & Working Hours'), findsOneWidget);
      expect(find.text('Working Days'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Start Time'), findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);
      expect(find.text('Break Time (Optional)'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('12. Subpage 5: Documents screen renders compliance documents list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CarDocumentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verification Documents'), findsOneWidget);
      expect(find.text('Aadhar Card'), findsOneWidget);
      expect(find.text('PAN Card'), findsOneWidget);
      expect(find.text('Driving License'), findsOneWidget);
      expect(find.text('Garage Photos'), findsOneWidget);
      expect(find.text('GST Certificate'), findsOneWidget);
      expect(find.text('Update Documents'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('13. Subpage 6: Bank Details screen renders bank account fields and save button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CarBankDetailsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bank Details'), findsOneWidget);
      expect(find.text('Account Holder Name *'), findsOneWidget);
      expect(find.text('Bank Name *'), findsOneWidget);
      expect(find.text('Account Number *'), findsOneWidget);
      expect(find.text('IFSC Code *'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('14. Subpage 7: Settings screen renders preferences, notifications and security', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CarSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    test('15. Category Routing: Car Service resolves to car-service dashboard and profile', () async {
      final carRoute = ServiceCategoryRouteHelper.getDashboardRoute('car_service');
      expect(carRoute, '/dashboard/car-service');
      expect(ServiceCategoryRouteHelper.getProfileRoute('car_service'), '/profile/car-service');
      expect(ServiceCategoryRouteHelper.getCategoryTitle('car_service'), 'Car Repair & Maintenance Specialist');

      // Test aliases
      expect(ServiceCategoryRouteHelper.getDashboardRoute('car'), '/dashboard/car-service');
      expect(ServiceCategoryRouteHelper.getDashboardRoute('automobile'), '/dashboard/car-service');
      expect(ServiceCategoryRouteHelper.normalizeCategory('car_service'), 'car_service');
      expect(ServiceCategoryRouteHelper.normalizeCategory('automobile'), 'car_service');
      expect(ServiceCategoryRouteHelper.normalizeCategory('car'), 'car_service');
    });
  });
}
