import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/core/services/booking_chat_service.dart';
import 'package:service_hub_partner/core/services/phone_launcher_service.dart';
import 'package:service_hub_partner/features/chat/presentation/partner_chat_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhoneLauncherService Real Dialer Tests', () {
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
      const rawNumber = '+91 98250-99887 (Ext: 12)';
      final clean = rawNumber.replaceAll(RegExp(r'[^0-9+]'), '');
      expect(clean, '+91982509988712');
      final telUri = Uri(scheme: 'tel', path: clean);
      expect(telUri.toString(), 'tel:+91982509988712');
    });
  });

  group('BookingChatService 2-Human Dynamic Messaging Tests', () {
    const testBookingId = 'TEST_BOOKING_CHAT_101';

    tearDown(() {
      BookingChatService.instance.closeChatStream(testBookingId);
    });

    test('Zero predefined messages on fresh booking and dynamic message sending', () async {
      // 1. Initial cached messages for a brand-new booking should be empty
      final initial = BookingChatService.instance.getCachedMessages(testBookingId);
      expect(initial, isEmpty);

      // 2. Customer sends a real message
      await BookingChatService.instance.sendMessage(
        bookingId: testBookingId,
        text: 'Hello, what time will you arrive?',
        senderRole: 'customer',
        senderName: 'Jenish Bheda',
        senderPhone: '+919825011223',
      );

      final afterCustomer = BookingChatService.instance.getCachedMessages(testBookingId);
      expect(afterCustomer.length, 1);
      expect(afterCustomer[0]['text'], 'Hello, what time will you arrive?');
      expect(afterCustomer[0]['sender_role'], 'customer');
      expect(afterCustomer[0]['sender_name'], 'Jenish Bheda');

      // 3. Partner replies with a real human message
      await BookingChatService.instance.sendMessage(
        bookingId: testBookingId,
        text: 'I am on my way, reaching in 10 minutes.',
        senderRole: 'partner',
        senderName: 'Aryan Bheda',
        senderPhone: '+919825099887',
      );

      final afterPartner = BookingChatService.instance.getCachedMessages(testBookingId);
      expect(afterPartner.length, 2);
      expect(afterPartner[1]['text'], 'I am on my way, reaching in 10 minutes.');
      expect(afterPartner[1]['sender_role'], 'partner');
      expect(afterPartner[1]['sender_name'], 'Aryan Bheda');
    });
  });

  group('PartnerChatScreen Navbar & Real UI Tests', () {
    const testBookingId = 'TEST_UI_BOOKING_202';

    testWidgets('Renders Customer Name in Upper Navbar with Call Button in Actions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PartnerChatScreen(
            bookingId: testBookingId,
            initialCustomerName: 'Jenish Bheda',
            initialCustomerPhone: '+919825011223',
            initialServiceName: 'AC Service & Repair',
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Upper Navbar displays authentic Customer Name
      expect(find.text('Jenish Bheda'), findsAtLeast(1));

      // Verify Subtitle displays Service & Customer role
      expect(find.text('AC Service & Repair • Customer'), findsOneWidget);

      // Verify Call Button exists in the AppBar
      expect(find.byIcon(Icons.phone_rounded), findsOneWidget);

      // Verify Send Button exists in the Composer
      expect(find.byIcon(Icons.send_rounded), findsOneWidget);

      // Verify text composer hint
      expect(find.text('Type message for Jenish Bheda...'), findsOneWidget);
    });
  });
}
