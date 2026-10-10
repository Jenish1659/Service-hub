import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:service_hub_customer/features/services/services/multi_service_booking_service.dart';
import 'package:service_hub_customer/features/services/services/ac_availability_service.dart';
import 'package:service_hub_customer/features/location/services/service_area_service.dart';
import 'package:service_hub_customer/features/services/presentation/laundry_requirement_screen.dart';
import 'package:service_hub_customer/features/services/presentation/car_service_requirement_screen.dart';
import 'package:service_hub_customer/features/services/presentation/care_taker_requirement_screen.dart';
import 'package:service_hub_customer/features/services/presentation/cooking_requirement_screen.dart';
import 'package:service_hub_customer/features/services/presentation/plumbing_requirement_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_multi_service_test_');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('customer_cache')) {
      await Hive.openBox('customer_cache');
    }
  });

  group('MultiServiceBookingService - Role Routing & Capability Mapping', () {
    test('Strict Role Mapping: Laundry routes exclusively to SHOPKEEPER role', () {
      final config = MultiServiceBookingService.getConfig('laundry');
      expect(config.requiredRole, 'shopkeeper');
      expect(config.requiredCapability, 'laundry');
      expect(config.categoryName, 'Laundry Service');
    });

    test('Strict Role Mapping: AC Service routes exclusively to SERVICE_PROVIDER role', () {
      final config = MultiServiceBookingService.getConfig('ac_service');
      expect(config.requiredRole, 'service_provider');
      expect(config.requiredCapability, 'ac_service');
    });

    test('Strict Role Mapping: Car Service routes exclusively to SERVICE_PROVIDER role', () {
      final config = MultiServiceBookingService.getConfig('car_service');
      expect(config.requiredRole, 'service_provider');
      expect(config.requiredCapability, 'car_service');
    });

    test('Strict Role Mapping: Care Taker routes exclusively to SERVICE_PROVIDER role', () {
      final config = MultiServiceBookingService.getConfig('care_taker');
      expect(config.requiredRole, 'service_provider');
      expect(config.requiredCapability, 'care_taker');
    });

    test('Strict Role Mapping: Cooking routes exclusively to SERVICE_PROVIDER role', () {
      final config = MultiServiceBookingService.getConfig('cooking');
      expect(config.requiredRole, 'service_provider');
      expect(config.requiredCapability, 'cooking');
    });

    test('Strict Role Mapping: Plumbing routes exclusively to SERVICE_PROVIDER role', () {
      final config = MultiServiceBookingService.getConfig('plumbing');
      expect(config.requiredRole, 'service_provider');
      expect(config.requiredCapability, 'plumbing');
    });

    test('Draft Saving and Loading across service categories', () async {
      final laundryDraft = {
        'service_mode': 'Wash & Fold Service',
        'total_items': 5,
        'estimated_amount': 225.0,
      };
      await MultiServiceBookingService.instance.saveDraft('laundry', laundryDraft);
      final loadedLaundry = MultiServiceBookingService.instance.loadDraft('laundry');
      expect(loadedLaundry, isNotNull);
      expect(loadedLaundry!['service_mode'], 'Wash & Fold Service');
      expect(loadedLaundry['total_items'], 5);

      final carDraft = {
        'vehicle_type': 'Compact SUV',
        'package_name': 'Periodic Standard Service',
        'estimated_amount': 1874.0,
      };
      await MultiServiceBookingService.instance.saveDraft('car_service', carDraft);
      final loadedCar = MultiServiceBookingService.instance.loadDraft('car_service');
      expect(loadedCar, isNotNull);
      expect(loadedCar!['vehicle_type'], 'Compact SUV');

      // Clear draft
      await MultiServiceBookingService.instance.clearDraft('laundry');
      expect(MultiServiceBookingService.instance.loadDraft('laundry'), isNull);
    });
  });

 group('Strict Jamnagar Geofence Isolation across Services', () {
    final serviceArea = ServiceAreaService();

    test('Jamnagar coordinates are authorized (Inside Geofence)', () {
      final result = serviceArea.checkServiceArea('Jamnagar', 22.4707, 70.0577);
      expect(result.isAvailable, isTrue);
    });

    test('Coordinates outside Jamnagar (e.g. Rajkot, Ahmedabad, Mumbai) are rejected', () {
      final rajkot = serviceArea.checkServiceArea('Rajkot', 22.3039, 70.8022);
      expect(rajkot.isAvailable, isFalse);

      final ahmedabad = serviceArea.checkServiceArea('Ahmedabad', 23.0225, 72.5714);
      expect(ahmedabad.isAvailable, isFalse);

      final mumbai = serviceArea.checkServiceArea('Mumbai', 19.0760, 72.8777);
      expect(mumbai.isAvailable, isFalse);
    });
  });

  group('ACAvailabilityService & BookingDateOption Enhancements', () {
    test('userFriendlyDisplay formats correctly without throwing', () {
      final option = BookingDateOption(
        date: DateTime(2026, 8, 15),
        dayName: 'Sat',
        dateNumber: '15',
        monthName: 'Aug',
        formattedIso: '2026-08-15',
        isTomorrow: false,
      );
      expect(option.userFriendlyDisplay, 'Sat, 15 Aug');
    });

    test('calculateHaversineDistanceKm calculates real distance accurately', () {
      // Jamnagar center to Bedi Port (~6km)
      final dist = ACAvailabilityService.instance.calculateHaversineDistanceKm(
        22.4707, 70.0577,
        22.5186, 70.0528,
      );
      expect(dist, greaterThan(4.0));
      expect(dist, lessThan(8.0));
    });
  });

  group('Service Requirement Screens - 10-Character Minimum Constraint', () {
    testWidgets('LaundryRequirementScreen renders and validates min 10 chars', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LaundryRequirementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Laundry Service'), findsWidgets);
      expect(find.text('Select Laundry Service Type *'), findsWidgets);

      // Enter 5 chars in special instructions
      final textField = find.byType(TextField);
      expect(textField, findsOneWidget);
      await tester.enterText(textField, 'Short');
      await tester.pump();

      expect(find.text('5 / 10 min chars'), findsOneWidget);

      // Tap continue -> should block with warning
      final continueBtn = find.text('Select Pickup Date');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);
      await tester.pump();

      expect(find.text('Special instructions must be at least 10 characters.'), findsOneWidget);

      // Fix text to >= 10 chars
      await tester.enterText(textField, 'Please do gentle wash for silk shirt');
      await tester.pump();
      expect(find.text('36 / 10 min chars'), findsOneWidget);
    });

    testWidgets('CarServiceRequirementScreen renders and validates min 10 chars', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarServiceRequirementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Car Service & Repair'), findsOneWidget);
      expect(find.text('Select Vehicle Type *'), findsOneWidget);

      // Enter short instruction in problem description
      final problemField = find.widgetWithText(TextField, '');
      if (problemField.evaluate().isNotEmpty) {
        await tester.enterText(problemField.last, 'Noise');
        await tester.pump();

        expect(find.text('5 / 10 min chars'), findsOneWidget);

        final continueBtn = find.text('Select Service Date');
        await tester.tap(continueBtn);
        await tester.pump();

        expect(find.text('Problem description must be at least 10 characters.'), findsOneWidget);
      }
    });

    testWidgets('CareTakerRequirementScreen renders and validates min 10 chars', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CareTakerRequirementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Care Taker & Nursing'), findsOneWidget);
      expect(find.text('Type of Care Needed *'), findsOneWidget);

      // Short notes test
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(2)); // Age and Notes
      await tester.enterText(textFields.last, 'Diabetic');
      await tester.pump();

      expect(find.text('8 / 10 min chars'), findsOneWidget);

      final continueBtn = find.text('Select Care Schedule');
      await tester.tap(continueBtn);
      await tester.pump();

      expect(find.text('Medical notes / instructions must be at least 10 characters.'), findsOneWidget);
    });

    testWidgets('CookingRequirementScreen renders and validates min 10 chars', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingRequirementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home Cook & Chef'), findsOneWidget);
      expect(find.text('Select Cooking Service *'), findsOneWidget);

      final instructionsField = find.byType(TextField);
      expect(instructionsField, findsOneWidget);
      await tester.enterText(instructionsField, 'Low salt');
      await tester.pump();

      expect(find.text('8 / 10 min chars'), findsOneWidget);

      final continueBtn = find.text('Select Cooking Schedule');
      await tester.tap(continueBtn);
      await tester.pump();

      expect(find.text('Menu instructions / preferences must be at least 10 characters.'), findsOneWidget);
    });

    testWidgets('PlumbingRequirementScreen renders and validates min 10 chars', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlumbingRequirementScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Plumbing Services & Repair'), findsOneWidget);
      expect(find.text('Select Plumbing Issue(s) *'), findsOneWidget);

      final problemField = find.byType(TextField);
      expect(problemField, findsOneWidget);
      await tester.enterText(problemField, 'Leak tap');
      await tester.pump();

      expect(find.text('8 / 10 min chars'), findsOneWidget);

      final continueBtn = find.text('Select Service Date');
      await tester.tap(continueBtn);
      await tester.pump();

      expect(find.text('Problem description must be at least 10 characters.'), findsOneWidget);
    });
  });
}
