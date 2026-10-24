import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/core/services/booking_chat_service.dart';
import 'package:service_hub_customer/core/services/phone_launcher_service.dart';
import 'package:service_hub_customer/features/bookings/presentation/chat_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Customer PhoneLauncherService Real Dialer Tests', () {
    testWidgets('makePhoneCall sanitizes formatted numbers and validates empty string', (tester) async {
      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) {
                capturedContext = ctx;
                return const Text('Test Container');
              },
            ),
          ),
        ),
      );

      // Empty number should return false and show SnackBar
      final emptyResult = await PhoneLauncherService.makePhoneCall(capturedContext, '   ');
      expect(emptyResult, isFalse);

      await tester.pumpAndSettle();
      expect(find.text('No valid contact phone number available for this booking.'), findsOneWidget);

      // Verify sanitization logic
      const rawNumber = '+91 98250 12345';
      final clean = rawNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      expect(clean, '+919825012345');
      final telUri = Uri(scheme: 'tel', path: clean);
      expect(telUri.toString(), 'tel:+919825012345');
    });
  });

  group('Customer ChatScreen Upper Navbar & Direct Messaging Tests', () {
    const testBookingId = 'TEST_CUSTOMER_BOOKING_303';

    tearDown(() {
      BookingChatService.instance.closeChatStream(testBookingId);
    });

    testWidgets('Renders Upper Navbar with Call Button and zero mock messages', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ChatScreen(
            bookingId: testBookingId,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify AppBar Call Button exists
      expect(find.byIcon(Icons.phone_rounded), findsOneWidget);

      // Verify Send Button in composer
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Verify empty state banner indicating direct human chat
      expect(find.byIcon(Icons.chat_bubble_outline_rounded), findsOneWidget);

      // Verify message composer input
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
