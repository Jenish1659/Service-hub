import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/features/services/presentation/ac_date_time_selection_screen.dart';
import 'package:service_hub_customer/features/services/services/ac_availability_service.dart';

void main() {
  test('ACAvailabilityService allows Today (D) and all future dates, excludes past dates', () {
    final service = ACAvailabilityService.instance;
    final now = DateTime.now();

    // Today is bookable
    expect(service.isDateBookable(now), isTrue);

    // Tomorrow is bookable
    expect(service.isDateBookable(now.add(const Duration(days: 1))), isTrue);

    // 10 days in future is bookable
    expect(service.isDateBookable(now.add(const Duration(days: 10))), isTrue);

    // Yesterday is NOT bookable
    expect(service.isDateBookable(now.subtract(const Duration(days: 1))), isFalse);
  });

  testWidgets('ACDateTimeSelectionScreen renders real user data and slot intervals', (WidgetTester tester) async {
    final realIssueData = {
      'service_name': 'Split AC Jet Wash Clean',
      'ac_type': 'Split AC',
      'ac_brand': 'Panasonic',
      'problem_description': 'Water leaking from indoor drain pipe',
      'photo_urls': ['https://storage.servicehub.com/leak.jpg'],
    };

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ACDateTimeSelectionScreen(issueDetails: realIssueData),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & "Need Help?"
    expect(find.text('AC Service'), findsOneWidget);
    expect(find.text('Need Help?'), findsOneWidget);

    // Verify Hero title & subtitle
    expect(find.text('Choose Date & Time'), findsOneWidget);
    expect(find.text('Select a convenient date and time for our expert visit.'), findsOneWidget);

    // Verify Summary Card contains REAL user data from previous step
    expect(find.text('Split AC Jet Wash Clean'), findsOneWidget);
    expect(find.text('Type: Split AC'), findsOneWidget);
    expect(find.text('Brand: Panasonic'), findsOneWidget);
    expect(find.text('Issue: Water leaking from indoor drain pipe'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);

    // Verify 4-Item Status Strip
    expect(find.text('Estimated Duration'), findsOneWidget);
    expect(find.text('60 – 90 min'), findsOneWidget);
    expect(find.text('Available Partners'), findsOneWidget);
    expect(find.text('Service Mode'), findsOneWidget);
    expect(find.text('Time Zone'), findsOneWidget);

    // Verify 1. Select Date section with Tomorrow as first option
    expect(find.text('1. Select Date'), findsOneWidget);
    expect(find.text('Tomorrow'), findsOneWidget);

    // Verify 2. Select Time section with Morning, Afternoon, Evening periods
    expect(find.text('2. Select Time'), findsOneWidget);
    expect(find.text('Morning'), findsOneWidget);
    expect(find.text('Afternoon'), findsOneWidget);
    expect(find.text('Evening'), findsOneWidget);

    // Verify Availability Banner and Continue Button
    expect(find.text("We've checked availability"), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Need Help? opens ServiceHub Scheduling AI sheet', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ACDateTimeSelectionScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap "Need Help?" button
    await tester.tap(find.text('Need Help?'));
    await tester.pumpAndSettle();

    // Verify Scheduling AI Chatbot modal appears
    expect(find.text('ServiceHub Scheduling AI'), findsOneWidget);
    expect(find.text('Online • Live Availability Assistant'), findsOneWidget);
    expect(find.text('Can I book for Today?'), findsOneWidget);
    expect(find.text('How long does an AC service take?'), findsOneWidget);
  });
}
