import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/core/services/live_booking_sync_service.dart';
import 'package:service_hub_customer/features/bookings/presentation/track_booking_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_booking_confirmed_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_finding_technician_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Service-Booking Assignment Cycle — Strict Two-Path Validation', () {
    testWidgets('Path A: Same-Day Booking -> Finding Screen -> Real Partner Acceptance -> Screen 2 Assigned', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const bookingId = 'same_day_test_bk_101';

      // 1. Customer creates Same-Day booking (status: SEARCHING_PROVIDER)
      await LiveBookingSyncService.instance.submitBooking({
        'id': bookingId,
        'booking_id': bookingId,
        'status': 'SEARCHING_PROVIDER',
        'service_name': 'AC Regular Servicing',
        'scheduled_date': 'Today',
        'scheduled_time': '10:00 AM - 12:00 PM',
        'price': 498.0,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ACFindingTechnicianScreen(
            bookingId: bookingId,
            serviceTitle: 'AC Regular Servicing',
            address: 'Sector 5, Jamnagar, Gujarat',
            selectedDateFormatted: 'Today',
            selectedTime: '10:00 AM - 12:00 PM',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Image 1 Screen 1: "Finding the Best Partner"
      expect(find.text('Finding the Best Partner'), findsOneWidget);
      expect(find.text('Searching nearby technicians'), findsOneWidget);
      expect(find.text('Checking availability'), findsOneWidget);
      expect(find.text('Matching best partner'), findsOneWidget);
      expect(find.text('Finalizing assignment'), findsOneWidget);
      expect(find.textContaining('Technicians usually accept within 2-3 minutes'), findsOneWidget);
      expect(find.text('Cancel Search'), findsOneWidget);

      // 2. Real Partner Acceptance arrives
      await LiveBookingSyncService.instance.acceptBooking(bookingId, {
        'partner_id': 'partner_jenish_001',
        'partner_name': 'Jenish Bheda',
        'partner_phone': '+91 75730 21659',
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Transitioned to Image 1 Screen 2: "Partner Assigned!"
      expect(find.text('Partner Assigned!'), findsOneWidget);
      expect(find.text('Jenish Bheda'), findsOneWidget);
      expect(find.textContaining('Track Partner'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('Path B: Future-Date Pre-Booking -> Scheduled Screen with notice and Itemized Raw Bill modal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const bookingId = 'future_date_test_bk_202';

      await tester.pumpWidget(
        const MaterialApp(
          home: ACBookingConfirmedScreen(
            bookingData: {
              'id': bookingId,
              'booking_id': bookingId,
              'status': 'SCHEDULED',
              'partner_id': null,
            },
            selectedDateFormatted: 'Tomorrow, Oct 2',
            selectedTime: '10:00 AM - 12:00 PM',
            serviceTitle: 'AC Regular Servicing',
            address: 'Palace Road, Jamnagar',
            visitingCharge: 449.0,
            protectionFee: 49.0,
            finalPayable: 498.0,
            isFutureDate: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Image 2 Screen 1: "Booking Scheduled!"
      expect(find.text('Booking Scheduled!'), findsOneWidget);
      expect(find.text('Matching starts on service date morning'), findsOneWidget);
      expect(find.textContaining('A certified technician will be assigned 2 hours before your scheduled slot'), findsOneWidget);
      expect(find.text('Add to Calendar'), findsOneWidget);

      // Verify Itemized Raw Bill Modal inspection
      final viewBillBtn = find.text('View Raw Bill');
      expect(viewBillBtn, findsOneWidget);
      await tester.ensureVisible(viewBillBtn);
      await tester.tap(viewBillBtn);
      await tester.pumpAndSettle();

      expect(find.text('Itemized Raw Bill'), findsOneWidget);
      expect(find.text('Visiting & Inspection Charge'), findsOneWidget);
      expect(find.text('Safety & Protection Fee'), findsOneWidget);
      expect(find.text('₹498.00'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('Concurrency Protection: First-Accept-Wins (Partner A wins, Partner B rejected)', (tester) async {
      const contestedBookingId = 'contest_bk_999';

      await LiveBookingSyncService.instance.submitBooking({
        'id': contestedBookingId,
        'booking_id': contestedBookingId,
        'status': 'SEARCHING_PROVIDER',
        'service_name': 'AC Regular Servicing',
        'price': 498.0,
      });

      // Partner A accepts first -> Must succeed
      final partnerAAccepted = await LiveBookingSyncService.instance.acceptBooking(contestedBookingId, {
        'partner_id': 'partner_alpha',
        'partner_name': 'Alpha Tech',
      });
      expect(partnerAAccepted, isTrue);

      // Partner B attempts to accept milliseconds later -> Must be rejected!
      final partnerBAccepted = await LiveBookingSyncService.instance.acceptBooking(contestedBookingId, {
        'partner_id': 'partner_beta',
        'partner_name': 'Beta Tech',
      });
      expect(partnerBAccepted, isFalse);

      // Verified: Contested booking stays allocated strictly to Partner A
      final stored = LiveBookingSyncService.instance.getBooking(contestedBookingId);
      expect(stored?['partner_id'], equals('partner_alpha'));
      expect(stored?['partner_name'], equals('Alpha Tech'));
    });

    testWidgets('Track Booking Screen: Screen 3 Partner on the Way -> Entrance PIN & OpenStreetMap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const trackId = 'track_test_bk_303';
      await LiveBookingSyncService.instance.submitBooking({
        'id': trackId,
        'booking_id': trackId,
        'status': 'ON_THE_WAY',
        'service_name': 'AC Regular Servicing',
        'partner_name': 'Jenish Bheda',
        'partner_phone': '+91 75730 21659',
        'entrance_pin': '4821',
        'completion_otp': '8294',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: TrackBookingScreen(bookingId: trackId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Screen 3: "Partner on the Way"
      expect(find.text('Partner on the Way'), findsOneWidget);
      expect(find.text('One-Time Entrance PIN'), findsOneWidget);
      expect(find.text('4821'), findsOneWidget);
      expect(find.text('Jenish Bheda'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('Track Booking Screen: Screen 4 Service in Progress -> Milestones & Completion OTP', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const inProgressId = 'inprogress_bk_404';
      await LiveBookingSyncService.instance.submitBooking({
        'id': inProgressId,
        'booking_id': inProgressId,
        'status': 'IN_PROGRESS',
        'service_name': 'AC Regular Servicing',
        'partner_name': 'Jenish Bheda',
        'completion_otp': '8294',
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: TrackBookingScreen(bookingId: inProgressId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Screen 4: "Service in Progress"
      expect(find.text('Service in Progress'), findsAtLeastNWidgets(1));
      expect(find.text('8294'), findsOneWidget);
      expect(find.text('Service Checklist & Milestones'), findsOneWidget);
      expect(find.text('Partner arrived at doorstep'), findsOneWidget);
      expect(find.text('Initial AC inspection & diagnosis'), findsOneWidget);
      expect(find.text('Filter & indoor cooling coil jet wash'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('Track Booking Screen: Screen 5 Service Completed -> Raw Bill & Screen 6 Rate and Review', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const completedId = 'completed_bk_505';
      await LiveBookingSyncService.instance.submitBooking({
        'id': completedId,
        'booking_id': completedId,
        'status': 'COMPLETED',
        'service_name': 'AC Regular Servicing',
        'partner_name': 'Jenish Bheda',
        'final_amount': 498.0,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: TrackBookingScreen(bookingId: completedId),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Screen 5: "Service Completed!"
      expect(find.text('Service Completed!'), findsOneWidget);
      expect(find.text('₹498.00'), findsOneWidget);
      expect(find.text('Paid via Cash / UPI on Delivery'), findsOneWidget);
      expect(find.text('View Raw Bill Breakdown'), findsOneWidget);

      // Screen 6: "Rate & Review Partner"
      expect(find.text('Rate & Review Partner'), findsOneWidget);
      expect(find.text('Punctuality'), findsOneWidget);
      expect(find.text('Quality of Service'), findsOneWidget);
      expect(find.text('Cleanliness & Safety'), findsOneWidget);
      expect(find.text('Professionalism'), findsOneWidget);
      expect(find.text('Submit Review'), findsOneWidget);

      // Submit Review and verify success state
      await tester.ensureVisible(find.text('Submit Review'));
      await tester.tap(find.text('Submit Review'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Thank You for Your Review!'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
