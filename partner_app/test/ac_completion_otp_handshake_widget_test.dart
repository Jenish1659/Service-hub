import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/features/dashboard/presentation/ac_job_navigation_screen.dart';

void main() {
  group('Urban Company Safety Completion OTP Handshake Widget Tests', () {
    test('1. ACJobNavigationScreen type alias is identical to ACActiveJobNavigationScreen', () {
      expect(ACJobNavigationScreen, equals(ACActiveJobNavigationScreen));
    });

    testWidgets('2. Screen shows Complete Service button when status is SERVICE_STARTED', (tester) async {
      final jobData = <String, dynamic>{
        'booking_id': 'bk_test_101',
        'id': 'bk_test_101',
        'service_name': 'Split AC Jet Wash',
        'customer_name': 'Kavita Patel',
        'customer_phone': '9876543210',
        'customer_address': 'Patel Colony, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
        'price': 599.0,
        'status': 'SERVICE_STARTED',
        'completion_otp': '5892',
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ACJobNavigationScreen(job: jobData),
          ),
        ),
      );
      await tester.pump();

      // Action button should state "Complete Service"
      expect(find.text('Complete Service'), findsOneWidget);

      // Clean up timer by replacing widget
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('3. Tapping Complete Service opens Urban Company Safety Completion OTP dialog', (tester) async {
      final jobData = <String, dynamic>{
        'booking_id': 'bk_test_102',
        'id': 'bk_test_102',
        'service_name': 'Split AC Jet Wash',
        'customer_name': 'Kavita Patel',
        'customer_phone': '9876543210',
        'customer_address': 'Patel Colony, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
        'price': 499.0,
        'status': 'SERVICE_STARTED',
        'completion_otp': '5892',
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ACActiveJobNavigationScreen(job: jobData),
          ),
        ),
      );
      await tester.pump();

      // Tap "Complete Service" button
      await tester.tap(find.text('Complete Service'));
      await tester.pump();

      // Verify Safety Completion modal opens
      expect(find.text('Customer Safety Code'), findsOneWidget);
      expect(find.text('Urban Company Safety Verification'), findsOneWidget);
      expect(find.byKey(const Key('completion_otp_field')), findsOneWidget);
      expect(find.text('Default customer code: 5892'), findsOneWidget);

      // Clean up timer
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('4. Invalid OTP rejects with error "Invalid Completion OTP. Please ask the customer for the 4-digit completion code."', (tester) async {
      final jobData = <String, dynamic>{
        'booking_id': 'bk_test_103',
        'id': 'bk_test_103',
        'service_name': 'Split AC Jet Wash',
        'customer_name': 'Kavita Patel',
        'customer_phone': '9876543210',
        'customer_address': 'Patel Colony, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
        'price': 499.0,
        'status': 'SERVICE_STARTED',
        'completion_otp': '5892',
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: ACActiveJobNavigationScreen(job: jobData),
          ),
        ),
      );
      await tester.pump();

      // Tap "Complete Service"
      await tester.tap(find.text('Complete Service'));
      await tester.pump();

      // Enter invalid OTP '9999'
      await tester.enterText(find.byKey(const Key('completion_otp_field')), '9999');
      await tester.pump();

      // Tap submit button in dialog
      await tester.tap(find.byKey(const Key('submit_completion_otp_button')));
      await tester.pump();

      // Assert expected Urban Company error message is shown
      const expectedError = 'Invalid Completion OTP. Please ask the customer for the 4-digit completion code.';
      expect(find.text(expectedError), findsWidgets);

      // Verify dialog remains open
      expect(find.text('Customer Safety Code'), findsOneWidget);

      // Clean up timer
      await tester.pumpWidget(const SizedBox());
    });
  });
}
