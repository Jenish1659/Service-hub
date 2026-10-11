import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_hub_customer/features/services/presentation/car_service_requirement_screen.dart';
import 'package:service_hub_customer/features/services/presentation/plumbing_requirement_screen.dart';
import 'package:service_hub_customer/features/services/presentation/service_select_date_screen.dart';
import 'package:service_hub_customer/features/home/presentation/home_screen.dart';
import 'package:service_hub_customer/features/products/presentation/products_provider.dart';

void main() {
  group('Service Routing & Car / Plumbing Requirement Tests (Zero Electrical)', () {
    testWidgets('1. CarServiceRequirementScreen opens Select Date without requiring mandatory photos', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarServiceRequirementScreen(),
          ),
        ),
      );

      // Verify Screen loaded
      expect(find.text('Car Service & Repair'), findsOneWidget);
      expect(find.text('Select Service Date'), findsOneWidget);

      // Select mandatory vehicle type, car brand, and package
      await tester.tap(find.text('Hatchback'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Select Car Brand *'), warnIfMissed: false);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Maruti Suzuki').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Periodic Standard Service'));
      await tester.pumpAndSettle();

      // Tap Select Service Date without uploading photos
      await tester.tap(find.text('Select Service Date'));
      await tester.pumpAndSettle();

      // ServiceSelectDateScreen must be opened!
      expect(find.byType(ServiceSelectDateScreen), findsOneWidget);
      expect(find.textContaining('Select Date for'), findsOneWidget);
    });

    testWidgets('2. PlumbingRequirementScreen renders multi-issue checkboxes and navigates to Select Date', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlumbingRequirementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify plumbing screen loaded
      expect(find.text('Plumbing Services & Repair'), findsOneWidget);
      expect(find.text('Select Plumbing Issue(s) *'), findsOneWidget);
      expect(find.text('Tap & Pipe Leakage Repair'), findsOneWidget);

      // Select an issue to satisfy mandatory validation
      await tester.tap(find.text('Tap & Pipe Leakage Repair'));
      await tester.pumpAndSettle();

      // Tap Select Service Date
      await tester.tap(find.text('Select Service Date'));
      await tester.pumpAndSettle();

      // Must open ServiceSelectDateScreen
      expect(find.byType(ServiceSelectDateScreen), findsOneWidget);
    });

    testWidgets('3. HomeScreen renders all 6 active services and Electrical is eradicated', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            productsProvider.overrideWith((ref) async => <Map<String, dynamic>>[]),
          ],
          child: const MaterialApp(
            home: Scaffold(body: HomeScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AC Repair'), findsOneWidget);
      expect(find.text('Car Service'), findsOneWidget);
      expect(find.text('Cooking'), findsOneWidget);
      expect(find.text('Care Taker'), findsOneWidget);
      expect(find.text('Plumbing'), findsOneWidget);
      expect(find.text('Laundry'), findsOneWidget);
      // Electrical must NOT exist
      expect(find.text('Electrical'), findsNothing);
    });
  });
}
