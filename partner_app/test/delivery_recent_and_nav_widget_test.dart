import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/features/dashboard/presentation/widgets/delivery_recent_and_nav_widget.dart';

void main() {
  group('DeliveryRecentDeliveriesSection Tests', () {
    testWidgets('1. Header and clean zero-state when empty', (tester) async {
      bool viewAllTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeliveryRecentDeliveriesSection(
                recentDeliveries: const [],
                onViewAll: () => viewAllTapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header verification
      expect(find.text('Recent Deliveries'), findsOneWidget);
      expect(find.text('View All >'), findsOneWidget);
      expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);

      // Clean zero-state message verification
      expect(
        find.text('No deliveries completed yet today. Your completed trips will appear here.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);

      // Tap View All
      await tester.tap(find.text('View All >'));
      await tester.pump();
      expect(viewAllTapped, isTrue);
    });

    testWidgets('2. Completed delivery items rendered with order code, store name, timestamp, earnings pill, and status badge', (tester) async {
      Map<String, dynamic>? tappedTrip;

      final testDeliveries = [
        {
          'order_code': '#SH10247',
          'store_name': 'CityMart',
          'timestamp': '8:24 PM',
          'status': 'Delivered',
          'earning': 40.0,
        },
        {
          'order_code': '#SH10246',
          'store_name': 'Home Essentials',
          'timestamp': '6:10 PM',
          'status': 'Delivered',
          'earning': 80.0,
        },
        {
          'order_code': '#SH10245',
          'store_name': 'TechCare Store',
          'timestamp': '4:32 PM',
          'status': 'Picked Up',
          'earning': 100.0,
        },
        {
          'order_code': '#SH10244',
          'store_name': 'Rajesh Stores',
          'timestamp': '2:15 PM',
          'status': 'Cancelled',
          'earning': 0.0,
        },
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeliveryRecentDeliveriesSection(
                recentDeliveries: testDeliveries,
                onDeliveryTap: (trip) => tappedTrip = trip,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify order codes
      expect(find.text('#SH10247'), findsOneWidget);
      expect(find.text('#SH10246'), findsOneWidget);
      expect(find.text('#SH10245'), findsOneWidget);
      expect(find.text('#SH10244'), findsOneWidget);

      // Verify store names
      expect(find.text('CityMart'), findsOneWidget);
      expect(find.text('Home Essentials'), findsOneWidget);
      expect(find.text('TechCare Store'), findsOneWidget);
      expect(find.text('Rajesh Stores'), findsOneWidget);

      // Verify timestamps
      expect(find.text('8:24 PM'), findsOneWidget);
      expect(find.text('6:10 PM'), findsOneWidget);
      expect(find.text('4:32 PM'), findsOneWidget);
      expect(find.text('2:15 PM'), findsOneWidget);

      // Verify status badges
      expect(find.text('Delivered'), findsNWidgets(2));
      expect(find.text('Picked Up'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);

      // Verify earnings pills ("+₹40.00" specifically required by prompt)
      expect(find.text('+₹40.00'), findsOneWidget);
      expect(find.text('+ ₹80'), findsOneWidget);
      expect(find.text('+ ₹100'), findsOneWidget);
      expect(find.text('+ ₹0'), findsOneWidget);

      // Tap an item and verify callback
      await tester.tap(find.text('#SH10247'));
      await tester.pump();
      expect(tappedTrip, isNotNull);
      expect(tappedTrip?['order_code'], equals('#SH10247'));
    });

    testWidgets('3. Zero overflow on narrow screen (320px)', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: DeliveryRecentDeliveriesSection(
                recentDeliveries: DeliveryRecentDeliveriesSection.sampleMockupDeliveries,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });

  group('DeliveryBottomCurvedNavBar Tests', () {
    testWidgets('1. Verification of all 5 navigation items and active Home color (#EA580C)', (tester) async {
      int selectedTab = -1;
      bool mapTriggered = false;
      bool profileTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: DeliveryBottomCurvedNavBar(
              currentIndex: 0,
              onTabSelected: (idx) => selectedTab = idx,
              onOpenMap: () => mapTriggered = true,
              onProfileTap: () => profileTriggered = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 5 items labels
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Icons
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.description_outlined), findsOneWidget);
      expect(find.byIcon(Icons.map_rounded), findsOneWidget);
      expect(find.byIcon(Icons.currency_rupee_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);

      // Active Home text color #EA580C
      final homeText = tester.widget<Text>(find.text('Home'));
      expect(homeText.style?.color, equals(const Color(0xFFEA580C)));

      // Tap Orders tab
      await tester.tap(find.text('Orders'));
      await tester.pump();
      expect(selectedTab, equals(1));

      // Tap Elevated Map Button
      await tester.tap(find.byIcon(Icons.map_rounded));
      await tester.pump();
      expect(mapTriggered, isTrue);

      // Tap Profile
      await tester.tap(find.text('Profile'));
      await tester.pump();
      expect(profileTriggered, isTrue);
    });

    testWidgets('2. Center Elevated Map button triggers OpenStreetMap with custom scooter icon and blue color', (tester) async {
      bool mapTriggered = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: DeliveryBottomCurvedNavBar(
              currentIndex: 2,
              centerButtonColor: const Color(0xFF2563EB),
              centerIcon: Icons.two_wheeler_rounded,
              onOpenMap: () => mapTriggered = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.two_wheeler_rounded), findsOneWidget);

      // Tap elevated center button
      await tester.tap(find.byIcon(Icons.two_wheeler_rounded));
      await tester.pump();
      expect(mapTriggered, isTrue);
    });

    testWidgets('3. Safe area handling and zero overflow on narrow device (320px)', (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: DeliveryBottomCurvedNavBar(
              currentIndex: 0,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
