import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/features/dashboard/presentation/widgets/delivery_overview_and_goal_widget.dart';

void main() {
  group('DeliveryOverviewMetricsGrid Tests', () {
    testWidgets('1. Baseline verification: STRICT ZERO DUMMY DATA defaults', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: DeliveryOverviewMetricsGrid(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title in bold grey caps
      expect(find.text("TODAY'S OVERVIEW"), findsOneWidget);

      // Verify all 4 KPI card labels
      expect(find.text('Deliveries Completed'), findsOneWidget);
      expect(find.text('Pending Deliveries'), findsOneWidget);
      expect(find.text("Today's Earnings"), findsOneWidget);
      expect(find.text('On-Time Rate'), findsOneWidget);

      // Verify strict 0 baseline counts
      // 0 for Deliveries Completed, 0 for Pending Deliveries
      expect(find.text('0'), findsNWidgets(2));
      // ₹0 for Today's Earnings
      expect(find.text('₹0'), findsOneWidget);
      // 100% for baseline On-Time Rate
      expect(find.text('100%'), findsOneWidget);

      // Verify icons
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.schedule_rounded), findsOneWidget);
      expect(find.byIcon(Icons.account_balance_wallet_rounded), findsOneWidget);
      expect(find.byIcon(Icons.speed_rounded), findsOneWidget);
    });

    testWidgets('2. Populated metrics update dynamically matching mockup values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: DeliveryOverviewMetricsGrid(
                completedCount: 5,
                pendingCount: 2,
                earnings: 650.0,
                onTimeRate: 96.0,
                dateText: 'Tue, 23 Sep',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text("TODAY'S OVERVIEW"), findsOneWidget);
      expect(find.text('Tue, 23 Sep'), findsOneWidget);

      // Values from mockup
      expect(find.text('5'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('₹650'), findsOneWidget);
      expect(find.text('96%'), findsOneWidget);
    });
  });

  group('DeliveryDailyGoalCard Tests', () {
    testWidgets('3. Default baseline verification (0 / 8) & Action text', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: DeliveryDailyGoalCard(
                onActionTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Title & Goal description
      expect(find.text("TODAY'S GOAL"), findsOneWidget);
      expect(
        find.text('Complete 8 deliveries today to earn ₹200 bonus'),
        findsOneWidget,
      );

      // Counter starts at 0 / 8
      expect(find.text('0 / 8'), findsOneWidget);

      // Action arrow
      expect(find.text('Keep Going! 💪'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);

      // Progress indicator with 0.0 value
      final progressFinder = find.byType(LinearProgressIndicator);
      expect(progressFinder, findsOneWidget);
      final LinearProgressIndicator progressWidget =
          tester.widget<LinearProgressIndicator>(progressFinder);
      expect(progressWidget.value, equals(0.0));

      // Tap action arrow
      await tester.tap(find.text('Keep Going! 💪'));
      expect(tapped, isTrue);
    });

    testWidgets('4. Dynamic progress calculation (5 / 8)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: EdgeInsets.all(16.0),
              child: DeliveryDailyGoalCard(
                completedCount: 5,
                targetCount: 8,
                bonusAmount: 200,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5 / 8'), findsOneWidget);
      final progressFinder = find.byType(LinearProgressIndicator);
      final LinearProgressIndicator progressWidget =
          tester.widget<LinearProgressIndicator>(progressFinder);
      expect(progressWidget.value, closeTo(5 / 8, 0.001));
    });
  });

  group('Zero Pixel Buffer Overflow Tests (320px, 360px, 390px)', () {
    final screenSizes = [
      const Size(320, 568), // Ultra compact phone (iPhone SE 1st gen)
      const Size(360, 640), // Standard compact Android
      const Size(390, 844), // iPhone 14/15/16 Pro
      const Size(768, 1024), // Tablet
    ];

    for (final size in screenSizes) {
      testWidgets('5. Zero overflow at ${size.width.toInt()}x${size.height.toInt()} screen',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: DeliveryOverviewAndGoalWidget(
                  completedCount: 5,
                  pendingCount: 2,
                  earnings: 650.0,
                  onTimeRate: 96.0,
                  targetDeliveries: 8,
                  bonusAmount: 200,
                  dateText: 'Tue, 23 Sep',
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Verify zero exceptions
        final exception = tester.takeException();
        expect(exception, isNull,
            reason: 'Overflow or layout error detected at width ${size.width}');

        // Verify no RenderFlex is overflowing
        for (final rf in tester.allRenderObjects.whereType<RenderFlex>()) {
          expect(rf.toString().contains('OVERFLOWING'), isFalse,
              reason: 'Found overflowing RenderFlex at width ${size.width}');
        }
      });
    }
  });
}
