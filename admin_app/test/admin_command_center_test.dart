import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_admin/features/dashboard/presentation/widgets/admin_kpi_cards.dart';
import 'package:service_hub_admin/features/dashboard/presentation/widgets/admin_sidebar.dart';
import 'package:service_hub_admin/features/dashboard/presentation/widgets/recent_bookings_card.dart';
import 'package:service_hub_admin/features/dashboard/presentation/widgets/booking_status_donut_chart.dart';

void main() {
  group('Admin Command Center Widget Tests', () {
    testWidgets('AdminKPICards renders all 6 key performance indicator cards dynamically', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminKPICards(
              totalBookings: 1248,
              completedServices: 987,
              ongoingServices: 142,
              totalCustomers: 2356,
              totalPartners: 320,
              totalRevenue: 1875430.0,
            ),
          ),
        ),
      );

      expect(find.text('Total Bookings'), findsOneWidget);
      expect(find.text('1248'), findsOneWidget);
      expect(find.text('Completed Services'), findsOneWidget);
      expect(find.text('987'), findsOneWidget);
      expect(find.text('Ongoing Services'), findsOneWidget);
      expect(find.text('142'), findsOneWidget);
      expect(find.text('Total Customers'), findsOneWidget);
      expect(find.text('2356'), findsOneWidget);
      expect(find.text('Total Partners'), findsOneWidget);
      expect(find.text('320'), findsOneWidget);
      expect(find.text('Total Revenue'), findsOneWidget);
    });

    testWidgets('AdminSidebar renders all major groups and triggers tab callback', (WidgetTester tester) async {
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
              isCollapsed: false,
              onToggleCollapse: () {},
            ),
          ),
        ),
      );

      expect(find.text('ServiceHub'), findsOneWidget);
      expect(find.text('Admin Panel'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('BOOKINGS'), findsOneWidget);
      expect(find.text('AC Service Bookings'), findsOneWidget);

      await tester.tap(find.text('AC Service Bookings'));
      expect(selectedTab, 'AC Service Bookings');
    });

    testWidgets('RecentBookingsCard renders recent booking rows and triggers View All', (WidgetTester tester) async {
      bool viewAllTapped = false;

      final testBookings = [
        {
          'id': 'BK1250',
          'customer_name': 'Rahul Sharma',
          'service_name': 'AC Service (Split AC)',
          'status': 'CONFIRMED',
          'time_ago': '10 mins ago',
        },
        {
          'id': 'BK1249',
          'customer_name': 'Priya Patel',
          'service_name': 'AC Service (Window AC)',
          'status': 'ONGOING',
          'time_ago': '25 mins ago',
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecentBookingsCard(
              bookings: testBookings,
              onViewAll: () => viewAllTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Recent Bookings'), findsOneWidget);
      expect(find.text('Rahul Sharma'), findsOneWidget);
      expect(find.text('AC Service (Split AC)'), findsOneWidget);
      expect(find.text('Priya Patel'), findsOneWidget);
      expect(find.text('AC Service (Window AC)'), findsOneWidget);

      await tester.tap(find.text('View All'));
      expect(viewAllTapped, isTrue);
    });

    testWidgets('BookingStatusDonutChart renders total status count and legend correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BookingStatusDonutChart(
              totalCount: 1248,
              completedCount: 987,
              ongoingCount: 142,
              confirmedCount: 54,
              cancelledCount: 65,
            ),
          ),
        ),
      );

      expect(find.text('Booking Status'), findsOneWidget);
      expect(find.text('1248'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);
    });
  });
}
