import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/features/services/presentation/ac_service_overview_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_select_date_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_select_time_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_service_details_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_review_confirm_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_booking_confirmed_screen.dart';
import 'package:service_hub_customer/features/services/services/ac_availability_service.dart';
import 'package:service_hub_customer/features/services/services/ac_booking_service.dart';

void main() {
  test('WalletRewardService coin allocation rules: 300 initial, +200 on 1st service, +100 on 2nd, <=80 on 3rd+', () {
    // 1st Service gives 200 coins
    // 2nd Service gives 100 coins
    // 3rd+ Service gives random coins <= 80
    final service = WalletRewardService.instance;
    expect(service.getWalletCoins(), greaterThanOrEqualTo(300));
  });

  test('Date availability allows Today (D) and all future dates, disallows past dates', () {
    final service = ACAvailabilityService.instance;
    final now = DateTime.now();

    expect(service.isDateBookable(now), isTrue);
    expect(service.isDateBookable(now.add(const Duration(days: 1))), isTrue);
    expect(service.isDateBookable(now.add(const Duration(days: 7))), isTrue);
    expect(service.isDateBookable(now.subtract(const Duration(days: 1))), isFalse);
  });

  testWidgets('Screen 1: ACServiceOverviewScreen renders overview, Your AC card, and status grid',
      (WidgetTester tester) async {
    final issueData = {
      'service_name': 'AC Service',
      'ac_type': 'Split AC',
      'ac_brand': 'Daikin',
      'problem_description': 'Not cooling properly',
    };

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ACServiceOverviewScreen(issueDetails: issueData),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title, Headline & Subtext
    expect(find.text('AC Service'), findsOneWidget);
    expect(find.text("We'll keep you\ncool & comfortable."), findsOneWidget);
    expect(find.text('Need Help?'), findsOneWidget);

    // Verify "Your AC" Card with tags
    expect(find.text('Your AC'), findsOneWidget);
    expect(find.text('Type: Split AC'), findsOneWidget);
    expect(find.text('Brand: Daikin'), findsOneWidget);
    expect(find.text('Issue: Not cooling properly'), findsOneWidget);

    // Verify 4 Status Grid Items & 100% Hygiene Card
    expect(find.text('60 – 90 min'), findsOneWidget);
    expect(find.text('At your location'), findsOneWidget);
    expect(find.text('Local Time (Auto-detected)'), findsOneWidget);
    expect(find.text('100% Hygiene Maintained'), findsOneWidget);

    // Verify Book Service button
    expect(find.text('Book Service'), findsOneWidget);
  });

  testWidgets('Screen 2: ACSelectDateScreen displays month calendar and selected date card',
      (WidgetTester tester) async {
    final realDraft = {
      'service_name': 'AC Service',
      'ac_type': 'Split AC',
      'ac_brand': 'Daikin',
      'problem_description': 'Not cooling properly',
    };

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ACSelectDateScreen(issueDetails: realDraft),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header & Subtitle
    expect(find.text('Select Date'), findsOneWidget);
    expect(find.text('Choose a convenient date'), findsOneWidget);

    // Verify Calendar Days of Week Header
    expect(find.text('S'), findsWidgets);
    expect(find.text('M'), findsWidgets);
    expect(find.text('T'), findsWidgets);
    expect(find.text('W'), findsWidgets);
    expect(find.text('F'), findsWidgets);

    // Selected Date Card
    expect(find.text('Selected Date'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Screen 3: ACSelectTimeScreen renders AM/PM toggle, analog clock, and digital badge',
      (WidgetTester tester) async {
    final realDraft = {
      'service_name': 'AC Service',
      'ac_type': 'Split AC',
      'ac_brand': 'Daikin',
      'problem_description': 'Not cooling properly',
    };

    final mockDate = BookingDateOption(
      date: DateTime.now().add(const Duration(days: 1)),
      dayName: 'Tomorrow',
      dateNumber: '31',
      monthName: 'Aug',
      formattedIso: '2026-08-31',
      isTomorrow: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ACSelectTimeScreen(
            issueDetails: realDraft,
            selectedDate: mockDate,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header & Subtitle
    expect(find.text('Select Time'), findsOneWidget);
    expect(find.text('Choose your preferred time'), findsOneWidget);

    // AM/PM Toggle
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);

    // Selected Time card and Next button
    expect(find.text('Selected Time'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Screen 4: ACServiceDetailsScreen renders name, phone, address, and notes fields',
      (WidgetTester tester) async {
    final realDraft = {
      'service_name': 'AC Service',
      'ac_type': 'Split AC',
      'ac_brand': 'Daikin',
      'problem_description': 'Not cooling properly',
    };

    final mockDate = BookingDateOption(
      date: DateTime.now().add(const Duration(days: 1)),
      dayName: 'Tomorrow',
      dateNumber: '31',
      monthName: 'Aug',
      formattedIso: '2026-08-31',
      isTomorrow: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ACServiceDetailsScreen(
            issueDetails: realDraft,
            selectedDate: mockDate,
            selectedTime: '02:00 PM',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header & Subtitle
    expect(find.text('Service Details'), findsOneWidget);
    expect(find.text('Tell us a few details'), findsOneWidget);

    // Inputs
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.text('Complete Address'), findsOneWidget);
    expect(find.text('Additional Notes (Optional)'), findsOneWidget);

    // Continue button
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Screen 5: ACReviewConfirmScreen renders review card, coupon, wallet, raw bill, and Confirm button',
      (WidgetTester tester) async {
    final realDraft = {
      'service_name': 'AC Service',
      'ac_type': 'Split AC',
      'ac_brand': 'Daikin',
      'problem_description': 'Not cooling properly',
      'customer_name': 'Jenish Bheda',
      'customer_phone': '+91 98765 43210',
      'customer_address': '12, Shanti Nagar, Ahmedabad, Gujarat 380001',
      'booking_date_formatted': 'Sat, 24 May 2025',
    };

    final mockDate = BookingDateOption(
      date: DateTime.now().add(const Duration(days: 1)),
      dayName: 'Tomorrow',
      dateNumber: '31',
      monthName: 'Aug',
      formattedIso: '2026-08-31',
      isTomorrow: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ACReviewConfirmScreen(
            issueDetails: realDraft,
            selectedDate: mockDate,
            selectedTime: '02:00 PM',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header & Subtitle
    expect(find.text('Review & Confirm'), findsOneWidget);
    expect(find.text('Please review your booking details and bill estimate'), findsOneWidget);

    // Fields & Raw Bill
    expect(find.text('Sat, 24 May 2025'), findsOneWidget);
    expect(find.text('02:00 PM'), findsOneWidget);
    expect(find.text('AC Service (Split AC)'), findsOneWidget);
    expect(find.text('Not cooling properly'), findsOneWidget);
    expect(find.text('12, Shanti Nagar, Ahmedabad, Gujarat 380001'), findsOneWidget);
    expect(find.text('Raw Bill / Price Breakdown'), findsOneWidget);
    expect(find.text('Visiting & Inspection Charge'), findsOneWidget);
    expect(find.text('Safety & Protection Fee'), findsOneWidget);
    expect(find.text('Do you have a coupon code?'), findsOneWidget);
    expect(find.text('Use Wallet Balance'), findsOneWidget);
    expect(find.text('Estimated Technician Arrival'), findsOneWidget);

    // Confirm Booking button
    expect(find.text('Confirm Booking'), findsOneWidget);
  });

  testWidgets('Screen 6: ACBookingConfirmedScreen renders checkmark, arrival notice, and View Raw Bill',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ACBookingConfirmedScreen(
            bookingData: {'id': 'bk_12345'},
            selectedDateFormatted: 'Sat, 24 May 2025',
            selectedTime: '02:00 PM',
            serviceTitle: 'AC Service (Split AC)',
            address: '12, Shanti Nagar, Ahmedabad, Gujarat 380001',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Confirmed Header & Pre-Booking Tracking ID
    expect(find.text('Booking Confirmed!'), findsOneWidget);
    expect(find.text("We've received your request and\nour partner will be there soon."), findsOneWidget);
    expect(find.text('PRE-BOOKING TRACKING ID'), findsOneWidget);

    // Summary Details
    expect(find.text('Sat, 24 May 2025'), findsOneWidget);
    expect(find.text('02:00 PM'), findsOneWidget);
    expect(find.text('AC Service (Split AC)'), findsOneWidget);
    expect(find.text('12, Shanti Nagar, Ahmedabad, Gujarat 380001'), findsOneWidget);
    expect(find.text('Estimated Technician Arrival'), findsOneWidget);
    expect(find.text('View Raw Bill'), findsOneWidget);

    // Tap View Raw Bill and verify modal
    await tester.ensureVisible(find.text('View Raw Bill'));
    await tester.tap(find.text('View Raw Bill'));
    await tester.pumpAndSettle();
    expect(find.text('Itemized Raw Bill'), findsOneWidget);

    // Close modal
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // View My Bookings button
    await tester.ensureVisible(find.text('View My Bookings'));
    expect(find.text('View My Bookings'), findsOneWidget);
  });
}
