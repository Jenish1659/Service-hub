import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/features/dashboard/presentation/widgets/delivery_next_and_shortcuts_widget.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeliveryNextPreviewCard Tests', () {
    testWidgets('1. Hides when only 1 or 0 tasks are queued and showOnlyWhenMultipleQueued is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeliveryNextPreviewCard(
              tasks: [
                {'order_code': 'ORD-101', 'shop_name': 'Shop 1', 'distance': '1.2 km'}
              ],
            ),
          ),
        ),
      );

      expect(find.text('Next Delivery • In Queue'), findsNothing);
      expect(find.byType(DeliveryNextPreviewCard), findsOneWidget);
    });

    testWidgets('2. Displays next task when multiple tasks are queued', (tester) async {
      final tasks = [
        {'order_code': 'ORD-101', 'shop_name': 'First Store', 'distance': '1.0 km', 'earning': 50.0},
        {'order_code': 'ORD-202', 'shop_name': 'Queued Supermarket', 'distance': '2.4 km', 'earning': 65.0},
      ];

      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryNextPreviewCard(
              tasks: tasks,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Verify all required labels and information
      expect(find.text('Next Delivery • In Queue'), findsOneWidget);
      expect(find.text('Order #ORD-202'), findsOneWidget);
      expect(find.text('Queued Supermarket'), findsOneWidget);
      expect(find.text('2.4 km'), findsOneWidget);
      expect(find.text('Starts after current delivery >'), findsOneWidget);
      expect(find.text('₹65'), findsOneWidget);

      // Tap card
      await tester.tap(find.text('Starts after current delivery >'));
      expect(tapped, isTrue);
    });

    testWidgets('3. Displays next task with explicit field parameters', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeliveryNextPreviewCard(
              orderCode: 'SH-9900',
              storeName: 'Sunrise Bakery',
              distance: '3.1 km',
              earning: 45.0,
            ),
          ),
        ),
      );

      expect(find.text('Next Delivery • In Queue'), findsOneWidget);
      expect(find.text('Order #SH-9900'), findsOneWidget);
      expect(find.text('Sunrise Bakery'), findsOneWidget);
      expect(find.text('3.1 km'), findsOneWidget);
      expect(find.text('Starts after current delivery >'), findsOneWidget);
    });
  });

  group('DeliveryQuickShortcutsGrid Tests', () {
    testWidgets('4. Displays title and 4 rounded shortcut tiles with correct labels and colors', (tester) async {
      bool ordersPressed = false;
      bool mapPressed = false;
      bool earningsPressed = false;
      bool supportPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryQuickShortcutsGrid(
              title: 'QUICK ACTIONS',
              onMyOrdersTap: () => ordersPressed = true,
              onLiveMapTap: () => mapPressed = true,
              onEarningsTap: () => earningsPressed = true,
              onSupportTap: () => supportPressed = true,
            ),
          ),
        ),
      );

      // Title
      expect(find.text('QUICK ACTIONS'), findsOneWidget);

      // 4 shortcut tiles
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('Live Map'), findsOneWidget);
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);

      // Tap callbacks
      await tester.tap(find.text('My Orders'));
      expect(ordersPressed, isTrue);

      await tester.tap(find.text('Live Map'));
      expect(mapPressed, isTrue);

      await tester.tap(find.text('Earnings'));
      expect(earningsPressed, isTrue);

      await tester.tap(find.text('Support'));
      expect(supportPressed, isTrue);
    });

    testWidgets('5. Responsive styling with FittedBox / Expanded prevents RenderFlex overflow on small screens', (tester) async {
      tester.view.physicalSize = const Size(320, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: DeliveryQuickShortcutsGrid(),
              ),
            ),
          ),
        ),
      );

      // Zero exceptions and all 4 shortcuts rendered
      expect(tester.takeException(), isNull);
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('Live Map'), findsOneWidget);
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
    });

    testWidgets('6. Supports 2x2 grid layout mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DeliveryQuickShortcutsGrid(
              is2x2Grid: true,
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('Live Map'), findsOneWidget);
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
    });
  });

  group('DeliveryNextAndShortcutsWidget Combined Tests', () {
    testWidgets('7. Combined widget integrates both preview card and quick actions', (tester) async {
      final tasks = [
        {'order_code': 'ORD-A', 'shop_name': 'Store A'},
        {'order_code': 'ORD-B', 'shop_name': 'Store B', 'distance': '1.5 km'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeliveryNextAndShortcutsWidget(
              activeTasks: tasks,
            ),
          ),
        ),
      );

      expect(find.text('Next Delivery • In Queue'), findsOneWidget);
      expect(find.text('Order #ORD-B'), findsOneWidget);
      expect(find.text('Store B'), findsOneWidget);
      expect(find.text('QUICK ACTIONS'), findsOneWidget);
      expect(find.text('My Orders'), findsOneWidget);
      expect(find.text('Live Map'), findsOneWidget);
      expect(find.text('Earnings'), findsOneWidget);
      expect(find.text('Support'), findsOneWidget);
    });
  });
}
