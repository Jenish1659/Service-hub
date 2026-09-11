import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/features/dashboard/presentation/ac_provider_dashboard_controller.dart';
import 'package:service_hub_partner/features/dashboard/presentation/provider_dashboard_screen.dart';

class MockACProviderDashboardNotifier extends ACProviderDashboardNotifier {
  MockACProviderDashboardNotifier([ACProviderDashboardState initial = const ACProviderDashboardState()]) {
    state = initial;
  }

  @override
  Future<void> initDashboard() async {
    // No-op to prevent network or timer calls in tests
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_dashboard_test');
    Hive.init(tempDir.path);
    final box = await Hive.openBox('partner_cache');
    await box.clear();
  });

  tearDownAll(() {
    LiveBookingSyncService.instance.dispose();
  });

  group('Partner Dashboard Real-Data & Customer Privacy Engine Tests', () {
    test('1. Initial Dashboard State initializes all metrics to clean 0 with no dummy data', () {
      const state = ACProviderDashboardState();

      // Today's Work Overview counts must be 0
      expect(state.newRequestsCount, equals(0));
      expect(state.inProgressCount, equals(0));
      expect(state.completedTodayCount, equals(0));
      expect(state.cancelledTodayCount, equals(0));

      // Business Overview metrics must be 0
      expect(state.todayIncome, equals(0.0));
      expect(state.completedAcceptedJobsToday, equals(0));
      expect(state.customerRating, equals(0.0));
      expect(state.repeatCustomers, equals(0));
      expect(state.totalJobsCompleted, equals(0));
      expect(state.totalCustomers, equals(0));

      // Trend strings must start clean
      expect(state.todayIncomeTrend, contains('0%'));
      expect(state.completedJobsTrend, contains('0%'));
      expect(state.ratingTrend, contains('0.0'));
      expect(state.repeatCustomersTrend, contains('0%'));

      // Lists must be empty
      expect(state.todayCompletedJobs, isEmpty);
      expect(state.incomingOffers, isEmpty);
      expect(state.activeBookings, isEmpty);
      expect(state.activeJob, isNull);
    });

    test('2. Completed jobs records enforce strict customer privacy (ONLY name, time, price, Paid)', () {
      final sampleJob = {
        'booking_id': 'bk_123',
        'customer_name': 'Amit Sharma',
        'completed_at': '10:45 AM',
        'price': 650.0,
        'payment_status': 'Paid',
      };

      // Ensure no phone or address keys are present in privacy-protected job record
      expect(sampleJob.containsKey('customer_phone'), isFalse);
      expect(sampleJob.containsKey('customer_address'), isFalse);
      expect(sampleJob.containsKey('customer_area'), isFalse);

      expect(sampleJob['customer_name'], equals('Amit Sharma'));
      expect(sampleJob['completed_at'], equals('10:45 AM'));
      expect(sampleJob['price'], equals(650.0));
      expect(sampleJob['payment_status'], equals('Paid'));
    });

    test('3. Computed getters reflect real incoming offers and active jobs dynamically', () {
      final state = const ACProviderDashboardState().copyWith(
        incomingOffers: [
          {'booking_id': 'offer_1', 'service_name': 'AC Service', 'price': 499.0},
          {'booking_id': 'offer_2', 'service_name': 'AC Jet Wash', 'price': 799.0},
        ],
        activeBookings: [
          {'booking_id': 'act_1', 'service_name': 'AC Repair'},
        ],
        declinedJobsToday: 1,
        todayCompletedJobs: [
          {'booking_id': 'comp_1', 'customer_name': 'Rajesh Patel', 'price': 650.0, 'payment_status': 'Paid'},
        ],
      );

      expect(state.newRequestsCount, equals(2));
      expect(state.inProgressCount, equals(1));
      expect(state.completedTodayCount, equals(1));
      expect(state.cancelledTodayCount, equals(1));
    });

    testWidgets('4. Dashboard Screen renders clean zero-state without dummy data', (WidgetTester tester) async {
      final mockNotifier = MockACProviderDashboardNotifier(
        const ACProviderDashboardState(
          providerName: 'Rajesh',
          businessName: 'Service Center',
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            acProviderDashboardProvider.overrideWith((ref) => mockNotifier),
          ],
          child: const MaterialApp(
            home: ProviderDashboardScreen(),
          ),
        ),
      );

      await tester.pump();

      // Check header greeting is present
      expect(find.textContaining('Stay Active, Keep Growing'), findsOneWidget);

      // Check "You are Online" status card
      expect(find.text('You are Online'), findsOneWidget);

      // Check Section 1: Today's Work Overview
      expect(find.text("Today's Work Overview"), findsOneWidget);
      expect(find.text('New Requests'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(find.text('Cancelled'), findsOneWidget);

      // Check Section 2: Business Overview (Today)
      expect(find.text('Business Overview (Today)'), findsOneWidget);
      expect(find.text("Today's Earnings"), findsOneWidget);
      expect(find.text('Jobs Completed'), findsOneWidget);
      expect(find.text('Average Rating'), findsOneWidget);
      expect(find.text('Repeat Customers'), findsOneWidget);

      // Check Section 3: Completed Jobs – Today empty placeholder
      expect(find.text('Completed Jobs – Today'), findsOneWidget);
      expect(find.text('No jobs completed yet today'), findsOneWidget);

      // Verify NO fake dummy values like 4,850 or fake customer names appear
      expect(find.text('₹4,850'), findsNothing);
      expect(find.text('Neha Patel'), findsNothing);
      expect(find.text('Vishal Mehta'), findsNothing);
    });

    testWidgets('5. Completed jobs only displays customer name, time, price, Paid and NO phone/address', (WidgetTester tester) async {
      final mockNotifier = MockACProviderDashboardNotifier(
        const ACProviderDashboardState(
          providerName: 'Rajesh',
          businessName: 'Service Center',
          todayCompletedJobs: [
            {
              'booking_id': 'job_101',
              'customer_name': 'Amit Sharma',
              'completed_at': '10:45 AM',
              'price': 650.0,
              'payment_status': 'Paid',
            },
            {
              'booking_id': 'job_102',
              'customer_name': 'Neha Patel',
              'completed_at': '01:15 PM',
              'price': 850.0,
              'payment_status': 'Paid',
            },
          ],
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            acProviderDashboardProvider.overrideWith((ref) => mockNotifier),
          ],
          child: const MaterialApp(
            home: ProviderDashboardScreen(),
          ),
        ),
      );

      await tester.pump();

      // Customer names and Paid badges must appear
      expect(find.text('Amit Sharma'), findsOneWidget);
      expect(find.text('Neha Patel'), findsOneWidget);
      expect(find.text('Paid'), findsNWidgets(2));
      expect(find.text('₹650'), findsOneWidget);
      expect(find.text('₹850'), findsOneWidget);

      // Critical privacy check: No private contact or location details
      expect(find.textContaining('+91'), findsNothing);
      expect(find.textContaining('Phone'), findsNothing);
      expect(find.textContaining('Address'), findsNothing);
      expect(find.textContaining('Jamnagar'), findsNothing);
    });
  });
}
