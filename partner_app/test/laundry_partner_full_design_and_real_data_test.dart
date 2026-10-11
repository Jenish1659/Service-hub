import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_partner_profile_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_order_details_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_personal_info_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_business_info_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_service_pricing_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_working_hours_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_documents_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_settings_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_help_support_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync('hive_laundry_full_test');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('partner_cache')) {
      await Hive.openBox('partner_cache');
    }
  });

  setUp(() {
    LiveBookingSyncService.instance.clearBookingsForTest();
  });

  group('Laundry Partner 100% Real Data & 14-Screen Design Verification', () {
    testWidgets('1. Dashboard renders 4 tabs and all counters start strictly with zero', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LaundryPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LaundryPartnerDashboardScreen), findsOneWidget);

      // Verify "Today's Overview" stats start strictly at 0
      expect(find.text("Today's Overview"), findsOneWidget);
      expect(find.text('New Orders'), findsWidgets);
      expect(find.text('In Progress'), findsWidgets);
      expect(find.text('Completed'), findsWidgets);
      expect(find.text('₹0'), findsWidgets);

      // Verify Genuine Zero State when no orders exist
      expect(find.text('No Orders Yet'), findsOneWidget);
      expect(find.text('All your real incoming laundry requests and bookings will appear here in real-time.'), findsOneWidget);

      // Verify 4 Bottom Nav tabs exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_outlined), findsWidgets);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });

    testWidgets('2. Tapping Orders tab shows search and segmented filters starting with zero', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LaundryPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Orders tab (Index 1)
      await tester.tap(find.text('Orders'));
      await tester.pumpAndSettle();

      // Verify Segmented Tabs start at 0
      expect(find.text('New (0)'), findsOneWidget);
      expect(find.text('In Progress (0)'), findsOneWidget);
      expect(find.text('Completed (0)'), findsOneWidget);

      // Verify zero state in Orders tab
      expect(find.text('No New Orders'), findsOneWidget);
    });

    testWidgets('3. Tapping Earnings tab displays Total Earnings starting at ₹0 and genuine zero state', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LaundryPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Earnings tab via bottom nav icon (.last)
      await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined).last);
      await tester.pumpAndSettle();

      expect(find.text('Total Earnings'), findsOneWidget);
      expect(find.text('Completed Orders'), findsOneWidget);
      expect(find.text('Avg. per Order'), findsOneWidget);
      expect(find.text('Earnings Breakdown'), findsOneWidget);
      expect(find.text('No Payouts Yet'), findsOneWidget);
    });

    testWidgets('4. Profile Screen renders rating starting at 0.0 with 0 reviews and all menu items', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LaundryPartnerProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LaundryPartnerProfileScreen), findsOneWidget);

      // Verify rating starts with 0.0 (0)
      expect(find.text('0.0 (0)'), findsOneWidget);
      expect(find.text('Verified Partner'), findsOneWidget);

      // Verify all menu items (using skipOffstage: false to catch any scrolled below fold)
      expect(find.text('Personal Information', skipOffstage: false), findsOneWidget);
      expect(find.text('Business Information', skipOffstage: false), findsOneWidget);
      expect(find.text('Service & Pricing', skipOffstage: false), findsOneWidget);
      expect(find.text('Availability & Working Hours', skipOffstage: false), findsOneWidget);
      expect(find.text('Verification Documents', skipOffstage: false), findsOneWidget);
      expect(find.text('Bank Details', skipOffstage: false), findsOneWidget);
      expect(find.text('Reviews & Ratings', skipOffstage: false), findsOneWidget);
      expect(find.text('Settings', skipOffstage: false), findsOneWidget);
      expect(find.text('Help & Support', skipOffstage: false), findsOneWidget);
      expect(find.text('Log Out', skipOffstage: false), findsOneWidget);
    });

    testWidgets('5. LaundryOrderDetailsScreen renders with real order payload and step tracker', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final sampleOrder = {
        'id': 'LDY-998811',
        'status': 'PENDING',
        'customer_name': 'Aarav Patel',
        'customer_phone': '+91 98765 11223',
        'address': 'Plot 42, Sunrise Apartments, Jamnagar',
        'total_amount': '350',
        'created_at': DateTime.now().toIso8601String(),
        'items': [
          {'name': 'Shirts (Wash & Iron)', 'quantity': 3, 'price': 150},
          {'name': 'Trousers (Wash & Iron)', 'quantity': 2, 'price': 160},
        ],
      };

      await tester.pumpWidget(
        MaterialApp(
          home: LaundryOrderDetailsScreen(booking: sampleOrder),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LaundryOrderDetailsScreen), findsOneWidget);
      expect(find.text('Aarav Patel'), findsOneWidget);
      expect(find.text('Plot 42, Sunrise Apartments, Jamnagar'), findsOneWidget);
      expect(find.text('Accept Order'), findsOneWidget);
      expect(find.text('Reject'), findsOneWidget);
    });

    testWidgets('6. All Laundry Sub-Screens render valid widget trees without errors', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Personal Info
      await tester.pumpWidget(const MaterialApp(home: LaundryPersonalInfoScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(LaundryPersonalInfoScreen), findsOneWidget);

      // Business Info
      await tester.pumpWidget(const MaterialApp(home: LaundryBusinessInfoScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(LaundryBusinessInfoScreen), findsOneWidget);

      // Service & Pricing
      await tester.pumpWidget(const MaterialApp(home: LaundryServicePricingScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(LaundryServicePricingScreen), findsOneWidget);

      // Working Hours
      await tester.pumpWidget(const MaterialApp(home: LaundryWorkingHoursScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(LaundryWorkingHoursScreen), findsOneWidget);

      // Documents
      await tester.pumpWidget(const MaterialApp(home: LaundryDocumentsScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(LaundryDocumentsScreen), findsOneWidget);

      // Settings
      await tester.pumpWidget(const MaterialApp(home: LaundrySettingsScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(LaundrySettingsScreen), findsOneWidget);

      // Help & Support
      await tester.pumpWidget(const MaterialApp(home: LaundryHelpSupportScreen()));
      await tester.pumpAndSettle();
      expect(find.byType(LaundryHelpSupportScreen), findsOneWidget);
    });
  });
}
