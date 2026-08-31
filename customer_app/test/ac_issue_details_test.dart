import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/features/services/presentation/ac_issue_details_screen.dart';
import 'package:service_hub_customer/features/services/services/ac_booking_service.dart';

void main() {
  testWidgets('ACIssueDetailsScreen renders all compulsory fields and no step counters', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ACIssueDetailsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and "Need Help?" button
    expect(find.text('AC Service'), findsOneWidget);
    expect(find.text('Need Help?'), findsOneWidget);

    // Verify No Step 1 of 3 or step progress bars exist
    expect(find.textContaining('Step 1'), findsNothing);
    expect(find.textContaining('Step 2'), findsNothing);
    expect(find.textContaining('Step 3'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    // Verify Hero title & subtitle
    expect(find.text("Let's fix your AC"), findsOneWidget);
    expect(find.text('Please provide accurate details so we can assign the right expert for you.'), findsOneWidget);

    // Verify 5 Fields
    expect(find.text('1. Type of AC *'), findsOneWidget);
    expect(find.text('Select AC Type'), findsOneWidget);

    expect(find.text('2. Company / Brand *'), findsOneWidget);
    expect(find.text('Select Company / Brand'), findsOneWidget);

    expect(find.text('3. Describe the problem *'), findsOneWidget);
    expect(find.text('0/500'), findsOneWidget);

    expect(find.text('4. Upload photos of the problem *'), findsOneWidget);
    expect(find.text('Add clear photos'), findsOneWidget);
    expect(find.text('Take Photo'), findsOneWidget);
    expect(find.text('Choose from Gallery'), findsOneWidget);
    expect(find.text('You can upload up to 5 photos'), findsOneWidget);

    expect(find.text('5. How old is your AC? *'), findsOneWidget);
    expect(find.text('Select Age'), findsOneWidget);

    // Verify Next button
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Need Help? opens ServiceHub AI Chatbot sheet', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ACIssueDetailsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Tap "Need Help?" button
    await tester.tap(find.text('Need Help?'));
    await tester.pumpAndSettle();

    // Verify AI Chatbot modal appears
    expect(find.text('ServiceHub AC Assistant'), findsOneWidget);
    expect(find.text('Online • AI AC Booking Specialist'), findsOneWidget);
    expect(find.text('How do I identify my AC type?'), findsOneWidget);
    expect(find.text('My AC is not cooling, what to write?'), findsOneWidget);
  });

  test('ACIssueBookingService persists issue metadata into draft format', () async {
    final service = ACIssueBookingService.instance;
    final result = await service.saveACIssueDetails(
      acType: 'Split AC',
      acBrand: 'Daikin',
      problemDescription: 'AC is not cooling properly and blowing only normal ambient air since yesterday',
      acAge: '1–2 years',
      photoUrls: ['https://storage.servicehub.com/sample_ac.jpg'],
      serviceName: 'AC Deep Clean & Diagnostic',
      servicePrice: 499.0,
    );

    expect(result['ac_type'], equals('Split AC'));
    expect(result['ac_brand'], equals('Daikin'));
    expect(result['ac_age'], equals('1–2 years'));
    expect(result['photo_urls'], isNotEmpty);
  });
}
