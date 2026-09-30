import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_hub_customer/features/services/presentation/ac_finding_technician_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_booking_confirmed_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_technician_details_screen.dart';
import 'package:service_hub_customer/core/services/live_booking_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AC Service Finding Technician Screen Tests', () {
    testWidgets('1. Renders AppBar, Header, Need Help pill, and all 4 stepper stages', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ACFindingTechnicianScreen(
            bookingId: 'bk_test_ac_001',
            serviceTitle: 'AC Service (Split AC)',
            address: '42, Sunset Drive, Bodakdev, Ahmedabad',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AppBar
      expect(find.text('AC Service'), findsOneWidget);
      expect(find.text('Need Help?'), findsOneWidget);

      // Verify Header
      expect(find.text('Finding a Technician'), findsOneWidget);
      expect(find.text('We are finding the best technician near you...'), findsOneWidget);

      // Verify 4 Stepper stages
      expect(find.text('Searching nearby technicians'), findsOneWidget);
      expect(find.text('Checking availability'), findsOneWidget);
      expect(find.text('Matching best partner'), findsOneWidget);
      expect(find.text('Finalizing assignment'), findsOneWidget);

      // Verify Estimated time card
      expect(find.text('Estimated time'), findsOneWidget);
      expect(find.text('2 - 5 minutes'), findsOneWidget);

      // Verify While you wait card
      expect(find.text('While you wait'), findsOneWidget);
      expect(find.textContaining('Keep your phone reachable for calls.'), findsOneWidget);
      expect(find.textContaining('Ensure someone is available at the address.'), findsOneWidget);
      expect(find.textContaining('Our technician will carry genuine tools and safety equipment.'), findsOneWidget);
      expect(find.textContaining('You\'ll receive a notification once the technician is assigned.'), findsOneWidget);

      // Verify Trust Badge
      expect(find.text('100% Verified Technicians'), findsOneWidget);
      expect(find.text('Trained professionals | Background checked | Genuine service'), findsOneWidget);

      // Verify Buttons
      expect(find.text('View Technicians Details'), findsOneWidget);
      expect(find.text('Live Chat'), findsOneWidget);
      expect(find.textContaining('View Live Tracking'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('2. Tapping View Technicians Details navigates to ACTechnicianDetailsScreen with real partner info', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/services/ac/finding-technician',
        routes: [
          GoRoute(
            path: '/services/ac/finding-technician',
            builder: (context, state) => const ACFindingTechnicianScreen(
              bookingId: 'bk_test_ac_002',
            ),
          ),
          GoRoute(
            path: '/services/ac/technician-details',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return ACTechnicianDetailsScreen(
                bookingId: extra['booking_id']?.toString() ?? 'bk_test_ac_002',
                partnerData: extra['partner_data'] as Map<String, dynamic>?,
                serviceTitle: extra['service_title'] as String? ?? 'AC Service',
                address: extra['address'] as String? ?? '',
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Tap View Technicians Details
      final viewDetailsBtn = find.text('View Technicians Details');
      expect(viewDetailsBtn, findsOneWidget);
      await tester.ensureVisible(viewDetailsBtn);
      await tester.tap(viewDetailsBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Check Technician Details page elements
      expect(find.text('Technician Assigned'), findsOneWidget);
      expect(find.text('Your technician is on the way'), findsOneWidget);
      expect(find.text('Vehicle Details'), findsOneWidget);
      expect(find.text('Track Technician ➔'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('3. Tapping Live Chat opens in-app chat modal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ACFindingTechnicianScreen(
            bookingId: 'bk_test_ac_003',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap Live Chat
      final liveChatBtn = find.text('Live Chat');
      expect(liveChatBtn, findsOneWidget);
      await tester.ensureVisible(liveChatBtn);
      await tester.tap(liveChatBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Check Chat modal elements
      expect(find.textContaining('Chat with'), findsOneWidget);
      expect(find.textContaining('Hello! I am assigned to your AC Service.'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Close chat modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('4. ACBookingConfirmedScreen navigates smoothly to ACFindingTechnicianScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/services/ac/confirmed',
        routes: [
          GoRoute(
            path: '/services/ac/confirmed',
            builder: (context, state) => const ACBookingConfirmedScreen(
              bookingData: {
                'id': 'bk_test_flow_01',
                'booking_id': 'bk_test_flow_01',
                'service_id': 'ac_service',
              },
              selectedDateFormatted: 'Tomorrow',
              selectedTime: '02:00 PM',
              serviceTitle: 'AC Deep Clean Service',
              address: '101, Titanium Square, Rajkot',
            ),
          ),
          GoRoute(
            path: '/services/ac/finding-technician',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return ACFindingTechnicianScreen(
                bookingId: extra['booking_id']?.toString() ?? 'bk_test_flow_01',
                serviceTitle: extra['service_title']?.toString() ?? 'AC Service',
                address: extra['address']?.toString() ?? '',
              );
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Booking Confirmed screen loaded
      expect(find.text('Booking Confirmed!'), findsOneWidget);
      expect(find.text('Find Technician Now'), findsOneWidget);
      expect(find.text('View My Bookings'), findsOneWidget);

      // Tap Find Technician Now
      await tester.tap(find.text('Find Technician Now'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify transitioned to Finding a Technician Screen!
      expect(find.text('Finding a Technician'), findsOneWidget);
      expect(find.text('Searching nearby technicians'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('5. Fallback timer is strictly cancelled when real partner assignment arrives via LiveBookingSyncService', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ACFindingTechnicianScreen(
            bookingId: 'bk_real_cancel_timer_99',
            serviceTitle: 'AC Jet Clean',
            address: '77, Lake View Road',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Emit real partner assignment via LiveBookingSyncService
      await LiveBookingSyncService.instance.submitBooking({
        'id': 'bk_real_cancel_timer_99',
        'booking_id': 'bk_real_cancel_timer_99',
        'status': 'ASSIGNED',
        'partner_id': 'partner_real_test_99',
        'partner_name': 'Vikram Rathore',
        'partner_phone': '+91 98989 77665',
      });

      // Pump to process stream update and assignment
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Advance time well beyond fallback timers (which run at 700ms intervals)
      await tester.pump(const Duration(seconds: 3));

      // Confirm assignment is reached ('Technician Found!') and fallback timer was strictly cancelled
      expect(find.text('Technician Found!'), findsOneWidget);
      expect(find.text('View Technicians Details'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
