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
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_partner_profile_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_request_details_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_live_map_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_personal_info_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_business_info_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_service_pricing_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_working_hours_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_documents_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('hive_plumbing_full_test_');
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
      'user_id': 'plumb_qa_01',
      'full_name': 'Rohit Patel',
      'name': 'Rohit Patel',
      'role': 'plumbing',
      'category': 'plumbing',
      'service_category_id': 'plumbing',
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

  group('Plumbing Partner 100% Real Data & 12-Screen Design Verification', () {
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
            home: PlumbingPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Check Plumbing promotional hero banner
      expect(find.textContaining('Fixing Water Problems'), findsOneWidget);
      expect(find.text('Plumbing Service Provider'), findsWidgets);

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
      expect(find.text('No Scheduled Plumbing Jobs'), findsOneWidget);
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
            home: PlumbingPartnerDashboardScreen(),
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
      expect(find.text('No New Plumbing Requests'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('3. Elevated Center Map Tab opens real OpenStreetMap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlumbingPartnerDashboardScreen(),
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
      expect(find.text('Current Location'), findsOneWidget);
      expect(find.text('Customer Location'), findsOneWidget);
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
            home: PlumbingPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Earnings Tab (Index 3)
      await tester.tap(find.text('Earnings'));
      await tester.pumpAndSettle();

      expect(find.text('Earnings'), findsWidgets);
      expect(find.text('₹0'), findsWidgets);
      expect(find.text('Completed Jobs'), findsOneWidget);
      expect(find.text('Tap / Faucet & Leakage'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('5. Request Details Screen renders full real data and action buttons', (tester) async {
      final mockBooking = {
        'id': 'PLMB-10024',
        'customer_name': 'Ramesh Shah',
        'customer_phone': '+91 98765 12345',
        'service_name': 'Pipe & Tap Leakage Repair',
        'address': 'Patel Colony Street 4, Jamnagar',
        'booking_date': '12 Oct 2026',
        'scheduled_time': '11:30 AM',
        'property_type': 'Bungalow / House',
        'notes': 'Main inlet pipe valve leaking heavily in wash area.',
        'total_amount': 399,
        'status': 'PENDING',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: PlumbingRequestDetailsScreen(booking: mockBooking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request Details'), findsOneWidget);
      expect(find.text('#PLMB-10024'), findsOneWidget);
      expect(find.text('Ramesh Shah'), findsOneWidget);
      expect(find.text('Pipe & Tap Leakage Repair'), findsOneWidget);
      expect(find.text('Patel Colony Street 4, Jamnagar'), findsOneWidget);
      expect(find.text('₹399'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Accept Request'), findsOneWidget);
    });

    testWidgets('6. Live Map Screen renders FlutterMap with route navigation info', (tester) async {
      final mockBooking = {
        'id': 'PLMB-10024',
        'customer_name': 'Ramesh Shah',
        'customer_phone': '+91 98765 12345',
        'service_name': 'Pipe & Tap Leakage Repair',
        'address': 'Patel Colony Street 4, Jamnagar',
        'status': 'IN_PROGRESS',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: PlumbingLiveMapScreen(booking: mockBooking),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('Live Map'), findsOneWidget);
      expect(find.text('Ramesh Shah'), findsOneWidget);
      expect(find.text('Start Navigation'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('7. Profile Screen renders full menu to all 6 subpages and starts at zero rating', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlumbingPartnerProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('0.0 (0 reviews)'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Business Information'), findsOneWidget);
      expect(find.text('Service & Pricing'), findsOneWidget);
      expect(find.text('Availability & Working Hours'), findsOneWidget);
      expect(find.text('Verification Documents'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('8. Subpage 1: Personal Info screen renders profile fields and save button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlumbingPersonalInfoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Phone Number *'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('9. Subpage 2: Business Info screen renders business fields and radius slider', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlumbingBusinessInfoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Business Information'), findsOneWidget);
      expect(find.text('Business Name *'), findsOneWidget);
      expect(find.text('Business Address *'), findsOneWidget);
      expect(find.text('Service Area (Radius)'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('10. Subpage 3: Services & Pricing screen renders plumbing catalog and add button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlumbingServicePricingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Service & Pricing'), findsOneWidget);
      expect(find.text('Plumbing Service'), findsOneWidget);
      expect(find.text('Tap / Faucet Leakage'), findsOneWidget);
      expect(find.text('Blocked Drain Cleaning'), findsOneWidget);
      expect(find.text('Add New Service'), findsOneWidget);
    });

    testWidgets('11. Subpage 4: Working Hours screen renders day selector and time fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlumbingWorkingHoursScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Availability & Working Hours'), findsOneWidget);
      expect(find.text('Working Days'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Start Time'), findsOneWidget);
      expect(find.text('End Time'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('12. Subpage 5: Documents screen renders compliance documents list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlumbingDocumentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verification Documents'), findsOneWidget);
      expect(find.text('Aadhar Card'), findsOneWidget);
      expect(find.text('PAN Card'), findsOneWidget);
      expect(find.text('Shop/Business Photo'), findsOneWidget);
    });

    testWidgets('13. Subpage 6: Settings screen renders preferences, notifications and security', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PlumbingSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    test('14. Category Routing: Cooking resolves to cooking dashboard, Plumbing to plumbing dashboard', () async {
      // 1. Plumbing resolution
      final plumbingRoute = ServiceCategoryRouteHelper.getDashboardRoute('plumbing');
      expect(plumbingRoute, '/dashboard/plumbing');
      expect(ServiceCategoryRouteHelper.getCategoryTitle('plumbing'), 'Plumbing & Sanitation Specialist');

      // 2. Cooking resolution (verifying user bug fix: Cooking does NOT open AC dashboard)
      final cookingRoute = ServiceCategoryRouteHelper.getDashboardRoute('cooking');
      expect(cookingRoute, '/dashboard/cooking');
      expect(ServiceCategoryRouteHelper.getCategoryTitle('cooking'), 'Home Cook & Culinary Specialist');

      expect(ServiceCategoryRouteHelper.normalizeCategory('plumbing'), 'plumbing');
      expect(ServiceCategoryRouteHelper.normalizeCategory('plumber'), 'plumbing');
      expect(ServiceCategoryRouteHelper.normalizeCategory('cooking'), 'cooking');
    });
  });
}
