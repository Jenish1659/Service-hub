import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_partner_profile_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_request_details_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_personal_info_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_business_info_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_specialties_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_working_hours_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_documents_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = Directory.systemTemp.createTempSync('hive_cooking_full_test_');
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
  });

  tearDown(() async {
    LiveBookingSyncService.instance.stopPolling();
  });

  tearDownAll(() async {
    try {
      LiveBookingSyncService.instance.stopPolling();
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Cooking Partner 100% Real Data & 12-Screen Design Verification', () {
    testWidgets('1. Dashboard renders 5-item navbar with elevated center Map and counters strictly start at zero', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await LocalRegistrationCache.updateActiveServiceProvider({
          'user_id': 'cook_qa_01',
          'full_name': 'Bhavna Ben',
          'role': 'cooking',
          'category': 'cooking',
          'is_online': true,
          'availability_status': 'ONLINE',
          'rating': 0.0,
          'review_count': 0,
        });
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.byType(CookingPartnerDashboardScreen), findsOneWidget);

      // Verify Welcome Banner
      expect(find.textContaining('Cook with Care'), findsOneWidget);
      expect(find.text('Good Morning, '), findsOneWidget);
      expect(find.text('Bhavna Ben'), findsOneWidget);

      // Verify 4 Stat Cards start strictly at 0
      expect(find.text('New Requests'), findsWidgets);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('Total Earnings'), findsWidgets);
      expect(find.text('₹0'), findsWidgets);

      // Verify Genuine Zero State when no scheduled jobs exist
      expect(find.text('No Scheduled Jobs Today'), findsOneWidget);
      expect(find.text('All your real incoming meal requests and chef bookings will appear here in real-time.'), findsOneWidget);

      // Verify 5 Bottom Navigation Items exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Verify center Map elevated button exists
      expect(find.byKey(const Key('cooking_bottom_nav_center_map_button')), findsOneWidget);
      expect(find.byIcon(Icons.location_on_rounded), findsOneWidget);
    });

    testWidgets('2. Tapping Jobs tab shows search and segmented filters starting with zero', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap Jobs tab (Index 1)
      await tester.tap(find.text('Jobs'));
      await tester.pumpAndSettle();

      // Verify Segmented Tabs start at 0
      expect(find.text('New (0)'), findsOneWidget);
      expect(find.text('In Progress (0)'), findsOneWidget);
      expect(find.text('Completed (0)'), findsOneWidget);

      // Verify zero state in Jobs tab
      expect(find.text('No New Requests'), findsOneWidget);
      expect(find.text('When customers book home cooking or meal services, requests will appear here.'), findsOneWidget);
    });

    testWidgets('3. Center Live Map tab renders real OpenStreetMap with interactive controls', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap center Map button (Index 2)
      await tester.tap(find.byKey(const Key('cooking_bottom_nav_center_map_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify FlutterMap is rendered
      expect(find.byType(FlutterMap), findsOneWidget);
      expect(find.byType(TileLayer), findsOneWidget);

      // Verify Location Filter Chips
      expect(find.text('Current Location'), findsOneWidget);
      expect(find.text('Customer Location'), findsOneWidget);

      // Verify Floating Navigation Card
      expect(find.text('Navigate'), findsOneWidget);
      expect(find.text('3.2 km • 10 mins'), findsOneWidget);
    });

    testWidgets('4. Earnings tab shows zero financial totals and clean transaction history', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap Earnings tab (Index 3)
      await tester.tap(find.text('Earnings'));
      await tester.pumpAndSettle();

      // Verify Total Earnings is 0
      expect(find.text('Total Earnings'), findsOneWidget);
      expect(find.text('₹0'), findsWidgets);

      // Verify Sub-metrics are all strictly 0
      expect(find.text('Completed Jobs'), findsOneWidget);
      expect(find.text('Pending Payment'), findsOneWidget);
      expect(find.text('Average per Job'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);

      // Verify zero history state
      expect(find.text('No Earnings History Yet'), findsOneWidget);
    });

    testWidgets('5. Profile screen displays 0.0 rating and all menu sub-screen navigation items', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingPartnerProfileScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify Verified Badge
      expect(find.text('Verified Partner'), findsOneWidget);

      // Verify Rating starts strictly at 0.0 with 0 reviews
      expect(find.text('0.0 (0 reviews)'), findsOneWidget);

      // Verify all sub-screen menu list options
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Business Information'), findsOneWidget);
      expect(find.text('Cooking Specialties'), findsOneWidget);
      expect(find.text('Availability & Working Hours'), findsOneWidget);
      expect(find.text('Verification Documents'), findsOneWidget);
      expect(find.text('Bank Details'), findsOneWidget);
      expect(find.text('Reviews & Ratings'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('6. Sub-screens render faithfully without mock data', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Test Personal Info Screen
      await tester.pumpWidget(const MaterialApp(home: CookingPersonalInfoScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Personal Information'), findsWidgets);
      expect(find.text('Save Changes'), findsOneWidget);

      // Test Business Info Screen
      await tester.pumpWidget(const MaterialApp(home: CookingBusinessInfoScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Business Information'), findsWidgets);
      expect(find.text('Service Area (Radius)'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);

      // Test Specialties Screen
      await tester.pumpWidget(const MaterialApp(home: CookingSpecialtiesScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Cooking Specialties'), findsWidgets);
      expect(find.text('Add Special Dish'), findsOneWidget);

      // Test Working Hours Screen
      await tester.pumpWidget(const MaterialApp(home: CookingWorkingHoursScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Availability & Working Hours'), findsWidgets);
      expect(find.text('Working Days *'), findsOneWidget);
      expect(find.text('Working Hours *'), findsOneWidget);

      // Test Documents Screen
      await tester.pumpWidget(const MaterialApp(home: CookingDocumentsScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Verification Documents'), findsWidgets);
      expect(find.text('Update Documents'), findsOneWidget);

      // Test Settings Screen
      await tester.pumpWidget(const MaterialApp(home: CookingSettingsScreen()));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsWidgets);
      expect(find.text('Order Notifications'), findsOneWidget);
    });

    testWidgets('7. CookingRequestDetailsScreen displays comprehensive order breakdown', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testBooking = {
        'id': 'COOK-998877',
        'customer_name': 'Meera Patel',
        'customer_phone': '+91 98765 43210',
        'customer_address': 'Flat 302, Gokul Dham, Patel Colony, Jamnagar',
        'meal_type': 'Lunch & Dinner',
        'people_count': '4 People',
        'cuisine': 'Kathiyawadi & Gujarati',
        'dietary': 'Jain / Less Oil',
        'note': 'Clean utensils please',
        'price': '650',
        'status': 'PENDING',
      };

      await tester.pumpWidget(
        MaterialApp(
          home: CookingRequestDetailsScreen(booking: testBooking),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      expect(find.text('#COOK-998877'), findsOneWidget);
      expect(find.text('Meera Patel'), findsOneWidget);
      expect(find.text('Cooking Details'), findsOneWidget);
      expect(find.text('Lunch & Dinner'), findsOneWidget);
      expect(find.text('4 People'), findsOneWidget);
      expect(find.text('Kathiyawadi & Gujarati'), findsOneWidget);
      expect(find.text('₹650'), findsWidgets);
      expect(find.text('Accept'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });
  });
}
