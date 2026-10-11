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
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_partner_profile_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_request_details_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_live_map_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_personal_info_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_business_info_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_service_pricing_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_working_hours_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_documents_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_bank_details_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('hive_care_full_test_');
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
      'user_id': 'care_qa_01',
      'full_name': 'Neha Patel',
      'name': 'Neha Patel',
      'role': 'care_taker',
      'category': 'care_taker',
      'service_category_id': 'care_taker',
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

  group('Care Taker Partner 100% Real Data & Full Design Verification', () {
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
            home: CarePartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Check Care Taker promotional hero banner matching reference design
      expect(find.textContaining('Care'), findsWidgets);
      expect(find.textContaining('Beyond Service'), findsOneWidget);
      expect(find.text('Care Taker & Nursing Provider'), findsWidgets);

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
      expect(find.text('No Scheduled Care Services Today'), findsOneWidget);
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
            home: CarePartnerDashboardScreen(),
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
      expect(find.text('No New Care Requests'), findsOneWidget);
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
            home: CarePartnerDashboardScreen(),
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
      expect(find.text('Start Navigation'), findsOneWidget);
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
            home: CarePartnerDashboardScreen(),
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
      expect(find.text('Elderly Care'), findsOneWidget);
      expect(find.text('Nursing Care'), findsOneWidget);
      expect(find.text('Post-Surgery Care'), findsOneWidget);
      expect(find.text('Babysitting Care'), findsOneWidget);
      expect(find.text('Special Needs Care'), findsOneWidget);
    });

    testWidgets('5. Request Details Screen renders genuine patient info, requirements and action buttons', (tester) async {
      final mockBooking = {
        'id': 'CARE-000125',
        'customer_name': 'Rajesh Kumar',
        'customer_phone': '+91 98765 43210',
        'service_name': 'Elderly Companion & Assistance',
        'address': 'Shivam Apartment, Jamnagar',
        'booking_date': '12 Oct 2026',
        'scheduled_time': '09:00 AM',
        'patient_age': '72 Years',
        'shift_duration': '8 Hours (Full Day)',
        'special_requirements': 'Assistance with daily activities, medication reminder, and companionship.',
        'notes': 'My father needs support for daily routine activities. Please be kind and patient.',
        'total_amount': 699,
        'status': 'PENDING',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: CareRequestDetailsScreen(booking: mockBooking),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Request Details'), findsOneWidget);
      expect(find.text('#CARE-000125'), findsOneWidget);
      expect(find.text('Rajesh Kumar'), findsOneWidget);
      expect(find.text('Elderly Companion & Assistance'), findsOneWidget);
      expect(find.text('72 Years'), findsOneWidget);
      expect(find.text('8 Hours (Full Day)'), findsOneWidget);
      expect(find.text('Assistance with daily activities, medication reminder, and companionship.'), findsOneWidget);
      expect(find.text('Shivam Apartment, Jamnagar'), findsOneWidget);
      expect(find.text('₹699'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
      expect(find.text('Accept Request'), findsOneWidget);
    });

    testWidgets('6. Live Map Screen renders FlutterMap with route navigation info', (tester) async {
      final mockBooking = {
        'id': 'CARE-000125',
        'customer_name': 'Rajesh Kumar',
        'customer_phone': '+91 98765 43210',
        'service_name': 'Elderly Companion & Assistance',
        'address': 'Shivam Apartment, Jamnagar',
        'status': 'IN_PROGRESS',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: CareLiveMapScreen(booking: mockBooking),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.text('Live Map'), findsOneWidget);
      expect(find.text('Rajesh Kumar'), findsOneWidget);
      expect(find.text('Start Navigation'), findsOneWidget);
    });

    testWidgets('7. Profile Screen renders full menu to all subpages and starts at zero rating', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CarePartnerProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('0.0 (0 reviews)'), findsOneWidget);
      expect(find.text('Verified Partner'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Business Information'), findsOneWidget);
      expect(find.text('Service & Pricing'), findsOneWidget);
      expect(find.text('Availability & Working Hours'), findsOneWidget);
      expect(find.text('Verification Documents'), findsOneWidget);
      expect(find.text('Bank Details'), findsOneWidget);
      expect(find.text('Reviews & Ratings'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('8. Subpage 1: Personal Info screen renders profile fields and save button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CarePersonalInfoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Phone Number *'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Change Photo'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('9. Subpage 2: Business Info screen renders care service fields and radius slider', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CareBusinessInfoScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Business Information'), findsOneWidget);
      expect(find.text('Care Service Name *'), findsOneWidget);
      expect(find.text('Business Address *'), findsOneWidget);
      expect(find.text('Service Area (Radius)'), findsOneWidget);
      expect(find.text('Business Description'), findsOneWidget);
      expect(find.text('Open Since'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('10. Subpage 3: Services & Pricing screen renders care packages catalog and add button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CareServicePricingScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Care Services & Pricing'), findsOneWidget);
      expect(find.text('Care Taker & Nursing Service'), findsOneWidget);
      expect(find.text('Elderly Companion'), findsOneWidget);
      expect(find.text('Post-Surgery Care'), findsOneWidget);
      expect(find.text('Bedridden Patient Care'), findsOneWidget);
      expect(find.text('Infant & Babysitting Care'), findsOneWidget);
      expect(find.text('Special Needs Care'), findsOneWidget);
      expect(find.text('Medical Assistance'), findsOneWidget);
      expect(find.text('+ Add New Care Type'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('11. Subpage 4: Working Hours screen renders day selector and time fields', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CareWorkingHoursScreen(),
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
    });

    testWidgets('12. Subpage 5: Documents screen renders compliance documents list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CareDocumentsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verification Documents'), findsOneWidget);
      expect(find.text('Aadhar Card'), findsOneWidget);
      expect(find.text('PAN Card'), findsOneWidget);
      expect(find.text('Caregiver Certificate'), findsOneWidget);
      expect(find.text('Medical Training Cert.'), findsOneWidget);
      expect(find.text('Background Verification'), findsOneWidget);
      expect(find.text('Profile Photo'), findsOneWidget);
      expect(find.text('Update Documents'), findsOneWidget);
    });

    testWidgets('13. Subpage 6: Bank Details screen renders bank account fields and save button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CareBankDetailsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Bank Details'), findsOneWidget);
      expect(find.text('Account Holder Name *'), findsOneWidget);
      expect(find.text('Bank Name *'), findsOneWidget);
      expect(find.text('Account Number *'), findsOneWidget);
      expect(find.text('IFSC Code *'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('14. Subpage 7: Settings screen renders preferences, notifications and security', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: CareSettingsScreen(),
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
    });

    test('15. Category Routing: Care Taker resolves to care-taker dashboard and profile', () async {
      final careRoute = ServiceCategoryRouteHelper.getDashboardRoute('care_taker');
      expect(careRoute, '/dashboard/care-taker');
      expect(ServiceCategoryRouteHelper.getProfileRoute('care_taker'), '/profile/care-taker');
      expect(ServiceCategoryRouteHelper.getCategoryTitle('care_taker'), 'Care Taker & Nursing Specialist');

      // Test aliases
      expect(ServiceCategoryRouteHelper.getDashboardRoute('caretaker'), '/dashboard/care-taker');
      expect(ServiceCategoryRouteHelper.getDashboardRoute('nursing'), '/dashboard/care-taker');
      expect(ServiceCategoryRouteHelper.normalizeCategory('care_taker'), 'care_taker');
      expect(ServiceCategoryRouteHelper.normalizeCategory('caretaker'), 'care_taker');
      expect(ServiceCategoryRouteHelper.normalizeCategory('nursing'), 'care_taker');
    });
  });
}
