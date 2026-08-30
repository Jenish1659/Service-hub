import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:service_hub_customer/features/services/presentation/ac_date_time_selection_screen.dart';
import 'package:service_hub_customer/features/services/services/ac_availability_service.dart';

void main() {
  test('ACAvailabilityService strictly generates next 3 days and excludes Today', () {
    final service = ACAvailabilityService.instance;
    final dates = service.getNext3BookingDates();

    expect(dates.length, equals(3));

    final now = DateTime.now();
    final todayIso = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowIso = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));

    // Ensure Today is NOT in the list
    expect(dates.any((d) => d.formattedIso == todayIso), isFalse);

    // Ensure first available date is Tomorrow (D+1)
    expect(dates[0].formattedIso, equals(tomorrowIso));
    expect(dates[0].isTomorrow, isTrue);
    expect(dates[0].dayName, equals('Tomorrow'));
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
    expect(find.text('Why can’t I book for Today?'), findsOneWidget);
    expect(find.text('How long does an AC service take?'), findsOneWidget);
  });
}
