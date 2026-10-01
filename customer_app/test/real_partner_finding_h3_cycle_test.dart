import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/core/services/h3_geospatial_service.dart';
import 'package:service_hub_customer/core/services/live_booking_sync_service.dart';
import 'package:service_hub_customer/features/location/widgets/gps_enforcement_dialog.dart';
import 'package:service_hub_customer/features/services/presentation/ac_finding_technician_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Real Partner Finding Process with H3 Geospatial Assignment Engine', () {
    testWidgets('1. Mandatory Location & GPS Enforcement Dialog renders and handles user response', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool onGpsEnabledCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GpsEnforcementDialog(
              onGpsEnabled: () => onGpsEnabledCalled = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify UI elements
      expect(find.text('Device Location is Off'), findsOneWidget);
      expect(find.textContaining('please turn on your device location (GPS)'), findsOneWidget);
      expect(find.text('Turn On Location'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.byIcon(Icons.location_off_rounded), findsOneWidget);

      expect(onGpsEnabledCalled, isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    test('2. H3 Geospatial Index Generation (Resolution 8) & k-Ring Perimeter expansion', () {
      final h3Service = H3GeospatialService.instance;

      // Customer coordinates in Jamnagar, Gujarat
      const double customerLat = 22.4707;
      const double customerLng = 70.0577;

      final hexIndexRes8 = h3Service.latLngToH3Index(customerLat, customerLng, resolution: 8);
      expect(hexIndexRes8, isNotEmpty);
      expect(hexIndexRes8.length, greaterThanOrEqualTo(14));

      // Expand to k-ring disk neighbors (k=1: immediate neighbors; k=2: 5-8km radius)
      final kRing1 = h3Service.getKRingCells(hexIndexRes8, ringSize: 1);
      expect(kRing1.length, greaterThanOrEqualTo(7));
      expect(kRing1.contains(hexIndexRes8), isTrue);

      final kRing2 = h3Service.getKRingCells(hexIndexRes8, ringSize: 2);
      expect(kRing2.length, greaterThanOrEqualTo(19));
      expect(kRing2.contains(hexIndexRes8), isTrue);

      // Verify Haversine distance calculation to nearby partner (1.5 km away)
      const double partnerLat = 22.4800;
      const double partnerLng = 70.0650;
      final distanceMeters = h3Service.computeHaversineDistanceMeters(customerLat, customerLng, partnerLat, partnerLng);
      expect(distanceMeters, greaterThan(800));
      expect(distanceMeters, lessThan(3000));
    });

    testWidgets('3. Multi-Partner Broadcast: Eligible active partners receive incoming offer stream', (tester) async {
      const bookingId = 'multi_partner_bk_777';
      final h3Service = H3GeospatialService.instance;
      final customerH3 = h3Service.latLngToH3Index(22.4707, 70.0577, resolution: 8);

      // Submit booking with GPS + H3 metadata
      await LiveBookingSyncService.instance.submitBooking({
        'id': bookingId,
        'booking_id': bookingId,
        'status': 'SEARCHING_PROVIDER',
        'service_name': 'Split AC Jet Servicing',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
        'customer_h3_res8': customerH3,
        'price': 498.0,
      });

      // Verify booking appears in pending offers stream for all active listening partners
      final pendingOffers = LiveBookingSyncService.instance.getPendingACOffers();
      final hasOurBooking = pendingOffers.any((b) => (b['booking_id'] ?? b['id']) == bookingId);
      expect(hasOurBooking, isTrue);
    });

    testWidgets('4. Atomic First-Accept-Wins: Winner claims job; Request is REVOKED and removed from others', (tester) async {
      const bookingId = 'contest_revocation_bk_888';

      await LiveBookingSyncService.instance.submitBooking({
        'id': bookingId,
        'booking_id': bookingId,
        'status': 'SEARCHING_PROVIDER',
        'service_name': 'AC Regular Servicing',
        'price': 498.0,
      });

      // 1. Prior to acceptance: booking is active in offers list
      var offersBefore = LiveBookingSyncService.instance.getPendingACOffers();
      expect(offersBefore.any((b) => (b['booking_id'] ?? b['id']) == bookingId), isTrue);

      // 2. Partner A (Alpha Tech) accepts first
      final partnerAAccepted = await LiveBookingSyncService.instance.acceptBooking(bookingId, {
        'partner_id': 'partner_alpha',
        'partner_name': 'Jenish Bheda (Certified)',
        'partner_phone': '+91 75730 21659',
      });
      expect(partnerAAccepted, isTrue);

      // 3. Partner B attempts to accept milliseconds later -> Must be REJECTED!
      final partnerBAccepted = await LiveBookingSyncService.instance.acceptBooking(bookingId, {
        'partner_id': 'partner_beta',
        'partner_name': 'Beta Tech',
      });
      expect(partnerBAccepted, isFalse);

      // 4. CRITICAL: The booking MUST now be removed from pending offers stream for all other partners!
      var offersAfter = LiveBookingSyncService.instance.getPendingACOffers();
      final stillInOffers = offersAfter.any((b) => (b['booking_id'] ?? b['id']) == bookingId);
      expect(stillInOffers, isFalse);

      // Stored booking is allocated strictly to Partner A
      final stored = LiveBookingSyncService.instance.getBooking(bookingId);
      expect(stored?['partner_id'], equals('partner_alpha'));
      expect(stored?['partner_name'], equals('Jenish Bheda (Certified)'));
      expect(stored?['status'], equals('CONFIRMED'));
    });

    testWidgets('5. Customer App transitions Screen 1 -> Screen 2 ("Partner Assigned!") on real partner acceptance', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const bookingId = 'customer_screen_transition_bk_999';

      await LiveBookingSyncService.instance.submitBooking({
        'id': bookingId,
        'booking_id': bookingId,
        'status': 'SEARCHING_PROVIDER',
        'service_name': 'Split AC Servicing',
        'price': 498.0,
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ACFindingTechnicianScreen(
            bookingId: bookingId,
            serviceTitle: 'Split AC Servicing',
            address: 'Digvijay Plot, Jamnagar',
            selectedDateFormatted: 'Today',
            selectedTime: '11:00 AM - 01:00 PM',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Screen 1: "Finding the Best Partner"
      expect(find.text('Finding the Best Partner'), findsOneWidget);
      expect(find.text('Searching nearby technicians'), findsOneWidget);

      // Real partner acceptance arrives
      await LiveBookingSyncService.instance.acceptBooking(bookingId, {
        'partner_id': 'partner_alpha_101',
        'partner_name': 'Jenish Bheda',
        'partner_phone': '+91 75730 21659',
      });

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Transitioned to Screen 2: "Partner Assigned!"
      expect(find.text('Partner Assigned!'), findsOneWidget);
      expect(find.text('Jenish Bheda'), findsOneWidget);
      expect(find.text('Call'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('View Profile'), findsOneWidget);
      expect(find.textContaining('Track Partner'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
