import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_admin/features/dashboard/presentation/widgets/admin_sidebar.dart';
import 'package:service_hub_admin/features/bookings/presentation/admin_bookings_view.dart';

void main() {
  group('Admin All Services & Dedicated Booking Views Isolation Tests', () {
    testWidgets('1. AdminSidebar renders ALL SERVICES and all 6 dedicated service booking items', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String selectedTab = 'Dashboard';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSidebar(
              activeTab: selectedTab,
              onTabSelected: (tab) => selectedTab = tab,
              onToggleCollapse: () {},
            ),
          ),
        ),
      );

      // Verify Headers
      expect(find.text('ALL SERVICES'), findsOneWidget);
      expect(find.text('SERVICES / BOOKINGS'), findsOneWidget);

      // Verify All Services nav item
      expect(find.text('All Services'), findsOneWidget);

      // Verify all 6 dedicated service items + All Bookings
      expect(find.text('AC Service Bookings'), findsOneWidget);
      expect(find.text('Care Taker Bookings'), findsOneWidget);
      expect(find.text('Laundry Bookings'), findsOneWidget);
      expect(find.text('Car Service Bookings'), findsOneWidget);
      expect(find.text('Plumbing Bookings'), findsOneWidget);
      expect(find.text('Cooking Bookings'), findsOneWidget);
      expect(find.text('All Bookings'), findsOneWidget);

      // Tap on Car Service Bookings
      await tester.tap(find.text('Car Service Bookings'));
      expect(selectedTab, 'Car Service Bookings');
    });

    testWidgets('2. AdminBookingsView strictly isolates Car Service bookings and excludes others', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mixedBookings = [
        {
          'id': 'BK-CAR-01',
          'booking_id': 'BK-CAR-01',
          'category_id': 'car_service',
          'service_name': 'Periodic Standard Service',
          'customer_name': 'Ramesh Kumar',
          'status': 'CONFIRMED',
          'final_amount': 1499.0,
        },
        {
          'id': 'BK-AC-01',
          'booking_id': 'BK-AC-01',
          'category_id': 'ac_service',
          'service_name': 'Split AC Jet Wash',
          'customer_name': 'Suresh Patel',
          'status': 'PENDING',
          'final_amount': 499.0,
        },
        {
          'id': 'BK-PLUMB-01',
          'booking_id': 'BK-PLUMB-01',
          'category_id': 'plumbing',
          'service_name': 'Tap Leakage Repair',
          'customer_name': 'Jignesh Shah',
          'status': 'COMPLETED',
          'final_amount': 249.0,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminBookingsView(
              allBookings: mixedBookings,
              serviceCategory: 'car_service',
              title: 'Car Service Bookings',
            ),
          ),
        ),
      );

      // Car service booking must be visible
      expect(find.text('#BK-CAR-0'), findsOneWidget);
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Periodic Standard Service'), findsOneWidget);

      // Other services must NOT be rendered
      expect(find.text('#BK-AC-01'), findsNothing);
      expect(find.text('Suresh Patel'), findsNothing);
      expect(find.text('Split AC Jet Wash'), findsNothing);
      expect(find.text('#BK-PLUMB-'), findsNothing);
      expect(find.text('Jignesh Shah'), findsNothing);
    });

    testWidgets('3. AdminBookingsView shows proper empty state when database returns zero records for service', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminBookingsView(
              allBookings: [],
              serviceCategory: 'cooking',
              title: 'Cooking Bookings',
            ),
          ),
        ),
      );

      expect(find.text('No bookings found for "Cooking Bookings"'), findsOneWidget);
    });
  });
}
