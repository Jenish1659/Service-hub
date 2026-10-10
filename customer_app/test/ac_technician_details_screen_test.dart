import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:service_hub_customer/features/services/presentation/ac_technician_details_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ACTechnicianDetailsScreen Tests', () {
    testWidgets('1. Renders all header, partner profile card, appointment card, and vehicle card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ACTechnicianDetailsScreen(
            bookingId: 'bk_ac_real_001',
            partnerData: {
              'name': 'Ramesh Kumar',
              'phone': '+91 98250 11223',
              'rating': 4.8,
              'total_jobs': 320,
              'experience_years': 4,
              'specialty': 'AC Specialist',
              'vehicle_number': 'GJ01AB1234',
              'vehicle_model': 'Honda Activa 6G',
            },
            selectedDateFormatted: 'Sun, 27 Sep 2026',
            selectedTime: '01:20 PM',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Header & App Bar
      expect(find.text('AC Service'), findsOneWidget);
      expect(find.text('Need Help?'), findsOneWidget);
      expect(find.text('Technician Assigned'), findsOneWidget);
      expect(find.text('Your technician is on the way'), findsOneWidget);

      // Card 1: Technician Profile
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('(320 reviews)'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      expect(find.text('AC Specialist'), findsOneWidget);

      // Card 2: Appointment Details
      expect(find.text('Date'), findsOneWidget);
      expect(find.text('Sun, 27 Sep 2026'), findsOneWidget);
      expect(find.text('Time'), findsOneWidget);
      expect(find.text('01:20 PM'), findsOneWidget);
      expect(find.text('Estimated Arrival'), findsOneWidget);
      expect(find.text('20 – 25 minutes'), findsOneWidget);

      // Quick Actions
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('View Profile'), findsOneWidget);

      // Card 3: Vehicle Details
      expect(find.text('Vehicle Details'), findsOneWidget);
      expect(find.text('Vehicle Number'), findsOneWidget);
      expect(find.text('GJ01AB1234'), findsOneWidget);
      expect(find.text('Vehicle Model'), findsOneWidget);
      expect(find.text('Honda Activa 6G'), findsOneWidget);

      // Bottom Button
      expect(find.text('Track Technician ➔'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('2. Tapping Call shows confirmation snackbar and copies phone number', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ACTechnicianDetailsScreen(
            bookingId: 'bk_ac_real_002',
            partnerData: {
              'name': 'Jenish Bheda',
              'phone': '+91 6359726320',
              'vehicle_number': 'GJ 10 BD 0933',
              'vehicle_model': 'Honda Activa 6G',
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final callBtn = find.text('Call');
      expect(callBtn, findsOneWidget);
      await tester.ensureVisible(callBtn);
      await tester.tap(callBtn);
      await tester.pump();

      expect(find.textContaining('Calling Jenish Bheda (+91 6359726320)...'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('3. Tapping View Profile opens detailed verified partner bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ACTechnicianDetailsScreen(
            bookingId: 'bk_ac_real_003',
            partnerData: {
              'name': 'Jenish Bheda',
              'phone': '+91 6359726320',
              'experience_years': 3,
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final profileBtn = find.text('View Profile');
      expect(profileBtn, findsOneWidget);
      await tester.ensureVisible(profileBtn);
      await tester.tap(profileBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('Jenish Bheda Profile'), findsOneWidget);
      expect(find.text('Verified ServiceHub Partner'), findsOneWidget);
      expect(find.textContaining('3+ Years Exp'), findsOneWidget);
      expect(find.textContaining('Police Verified'), findsOneWidget);

      // Close bottom sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('4. Tapping Track Technician ➔ routes to live tracking screen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/services/ac/technician-details',
        routes: [
          GoRoute(
            path: '/services/ac/technician-details',
            builder: (context, state) => const ACTechnicianDetailsScreen(
              bookingId: 'bk_track_test_99',
            ),
          ),
          GoRoute(
            path: '/track-booking/:id',
            builder: (context, state) => Scaffold(
              body: Text('Live Tracking Screen ${state.pathParameters['id']}'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final trackBtn = find.text('Track Technician ➔');
      expect(trackBtn, findsOneWidget);
      await tester.ensureVisible(trackBtn);
      await tester.tap(trackBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Live Tracking Screen bk_track_test_99'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('5. Renders Urban Company-style Entrance PIN & Safety Card with default codes and copy actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ACTechnicianDetailsScreen(
            bookingId: 'bk_safety_test_01',
            bookingData: {
              'entrance_pin': '7429',
              'completion_otp': '5892',
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Header & Security Badges
      expect(find.text('Safety Handshake'), findsOneWidget);
      expect(find.text('2-Step Security'), findsOneWidget);

      // Entrance PIN Card
      expect(find.text('🔑 Entrance PIN: 7429'), findsOneWidget);
      expect(find.text('Share this PIN with your technician before allowing entry.'), findsOneWidget);

      // Completion OTP Card
      expect(find.text('🔒 Completion OTP: 5892'), findsOneWidget);
      expect(find.text('Share this OTP only after the service is fully completed.'), findsOneWidget);

      // Copy Entrance PIN
      final copyButtons = find.text('Copy');
      expect(copyButtons, findsNWidgets(2));

      await tester.ensureVisible(copyButtons.first);
      await tester.tap(copyButtons.first);
      await tester.pump();
      expect(find.text('Entrance PIN (7429) copied to clipboard!'), findsOneWidget);

      // Copy Completion OTP
      await tester.ensureVisible(copyButtons.last);
      await tester.tap(copyButtons.last);
      await tester.pump();
      expect(find.text('Completion OTP (5892) copied to clipboard!'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });

    testWidgets('6. Supports custom Entrance PIN and Completion OTP from bookingData', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ACTechnicianDetailsScreen(
            bookingId: 'bk_custom_pin_02',
            bookingData: {
              'entrance_pin': '9182',
              'completion_otp': '4321',
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('🔑 Entrance PIN: 9182'), findsOneWidget);
      expect(find.text('Share this PIN with your technician before allowing entry.'), findsOneWidget);
      expect(find.text('🔒 Completion OTP: 4321'), findsOneWidget);
      expect(find.text('Share this OTP only after the service is fully completed.'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 200));
    });
  });
}
