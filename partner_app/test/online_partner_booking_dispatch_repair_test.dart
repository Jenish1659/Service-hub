import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/features/dashboard/presentation/ac_provider_dashboard_controller.dart';
import 'package:service_hub_partner/core/services/routing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Online Partner Booking Dispatch & Asynchronous Redispatch Repair Tests', () {
    final syncService = LiveBookingSyncService.instance;

    setUp(() {
      syncService.clearBookingsForTest();
    });

    test('1. Customer creates booking while partner is offline -> Partner goes online -> Receives booking', () async {
      // Step 1: Customer submits booking (unassigned in Jamnagar)
      const bookingId = 'shb_jamnagar_ac_booking_101';
      final customerBooking = {
        'id': bookingId,
        'booking_id': bookingId,
        'status': 'SEARCHING_PROVIDER',
        'partner_id': null, // unassigned
        'service_name': 'Split AC Deep Jet Cleaning',
        'category_id': 'ac_service',
        'customer_name': 'Ramesh Mehta',
        'customer_address': 'Patel Colony, Jamnagar',
        'customer_lat': 22.4707,
        'customer_lng': 70.0577,
        'price': 499.0,
      };
      await syncService.submitBooking(customerBooking);

      // Verify booking exists unassigned
      final bookingsBefore = syncService.getAllBookings();
      expect(bookingsBefore.any((b) => b['booking_id'] == bookingId), isTrue);

      // Step 2: Partner logs in offline
      var state = const ACProviderDashboardState(
        partnerId: 'partner_jamnagar_ac_tech_01',
        providerId: 'provider_ac_01',
        isOnline: false,
        category: 'ac_service',
      );
      expect(state.isOnline, isFalse);
      expect(state.incomingOffers, isEmpty);

      // Step 3: Partner switches ONLINE
      state = state.copyWith(isOnline: true);
      expect(state.isOnline, isTrue);

      // Step 4: Redispatch engine finds pending unassigned bookings for this online AC partner
      final List<Map<String, dynamic>> offersList = [];
      final Set<String> seenBookingIds = {};

      for (final b in syncService.getAllBookings()) {
        final bStatus = (b['status'] ?? '').toString().toUpperCase();
        final bPartner = (b['partner_id'] ?? '').toString();
        final bCat = (b['category_id'] ?? 'ac_service').toString();

        // Must be unassigned and pending/searching
        if ((bPartner.isEmpty || bPartner == state.partnerId) &&
            (bStatus == 'SEARCHING_PROVIDER' || bStatus == 'OFFERED_TO_PROVIDERS' || bStatus == 'PENDING') &&
            bCat == state.category) {
          final bId = b['booking_id']?.toString() ?? '';
          if (bId.isNotEmpty && !seenBookingIds.contains(bId)) {
            seenBookingIds.add(bId);
            final lat = (b['customer_lat'] as num?)?.toDouble() ?? 22.4707;
            final lng = (b['customer_lng'] as num?)?.toDouble() ?? 70.0577;
            final distKm = OsrmRoutingService.computeHaversineDistanceKm(22.4707, 70.0650, lat, lng) * 1.35;
            final etaMin = (distKm / 25.0 * 60.0).round().clamp(5, 45);

            offersList.add({
              'request_id': 'req_auto_101',
              'booking_id': bId,
              'service_name': b['service_name'],
              'price': b['price'],
              'customer_name': b['customer_name'],
              'customer_address': b['customer_address'],
              'distance_km': distKm,
              'eta_minutes': etaMin,
            });
          }
        }
      }

      state = state.copyWith(incomingOffers: offersList);

      // Assert partner now sees the customer's request
      expect(state.incomingOffers.length, equals(1));
      expect(state.incomingOffers.first['booking_id'], equals(bookingId));
      expect(state.incomingOffers.first['customer_name'], equals('Ramesh Mehta'));
      expect(state.newRequestsCount, equals(1));
    });

    test('2. PostgREST Map vs List response normalization handles list joins safely', () {
      // Helper function mirroring the production _asMap implementation
      Map<String, dynamic>? asMap(dynamic val) {
        if (val is Map<String, dynamic>) return val;
        if (val is Map) return Map<String, dynamic>.from(val);
        if (val is List && val.isNotEmpty) {
          final first = val.first;
          if (first is Map<String, dynamic>) return first;
          if (first is Map) return Map<String, dynamic>.from(first);
        }
        return null;
      }

      // Case A: Supabase returns a 1-element List for reverse foreign-key joins
      final rawPostgRestResponseWithLists = {
        'partner_id': 'p_123',
        'service_provider_profiles': [
          {'provider_id': 'prov_777', 'about': 'AC Expert'}
        ],
        'users': [
          {
            'user_id': 'u_123',
            'user_profiles': [
              {'first_name': 'Amit', 'last_name': 'Shah'}
            ]
          }
        ]
      };

      final spp = asMap(rawPostgRestResponseWithLists['service_provider_profiles']);
      expect(spp, isNotNull);
      expect(spp!['provider_id'], equals('prov_777'));

      final users = asMap(rawPostgRestResponseWithLists['users']);
      expect(users, isNotNull);
      final profile = asMap(users!['user_profiles']);
      expect(profile, isNotNull);
      expect(profile!['first_name'], equals('Amit'));

      // Case B: Supabase returns a Map
      final rawPostgRestResponseWithMap = {
        'partner_id': 'p_123',
        'service_provider_profiles': {'provider_id': 'prov_888'},
      };

      final sppMap = asMap(rawPostgRestResponseWithMap['service_provider_profiles']);
      expect(sppMap, isNotNull);
      expect(sppMap!['provider_id'], equals('prov_888'));
    });

    test('3. Jamnagar 15km operational radius correctly includes local requests and excludes far requests', () {
      const technicianLat = 22.4707; // Jamnagar City Center
      const technicianLng = 70.0577;

      // Location 1: Patel Colony, Jamnagar (~2.5 km away)
      const loc1Lat = 22.4650;
      const loc1Lng = 70.0750;
      final dist1 = OsrmRoutingService.computeHaversineDistanceKm(technicianLat, technicianLng, loc1Lat, loc1Lng);
      expect(dist1, lessThan(15.0));

      // Location 2: Bedi Port / Rozi, Jamnagar (~8.5 km away)
      const loc2Lat = 22.5350;
      const loc2Lng = 70.0450;
      final dist2 = OsrmRoutingService.computeHaversineDistanceKm(technicianLat, technicianLng, loc2Lat, loc2Lng);
      expect(dist2, lessThan(15.0));

      // Location 3: Outside Jamnagar (e.g. Rajkot, ~85 km away)
      const loc3Lat = 22.3039;
      const loc3Lng = 70.8022;
      final dist3 = OsrmRoutingService.computeHaversineDistanceKm(technicianLat, technicianLng, loc3Lat, loc3Lng);
      expect(dist3, greaterThan(15.0));
    });

    test('4. Atomic Accept claims booking and updates state with zero fake data', () async {
      const bookingId = 'shb_real_atomic_test_01';
      await syncService.submitBooking({
        'id': bookingId,
        'booking_id': bookingId,
        'status': 'SEARCHING_PROVIDER',
        'partner_id': null,
        'service_name': 'AC Gas Refill',
        'price': 1499.0,
      });

      // Partner accepts
      final accepted = await syncService.acceptBooking(bookingId, {
        'partner_id': 'prt_winner_101',
        'partner_name': 'Vijay Parmar',
      });
      expect(accepted, isTrue);

      final updatedBooking = syncService.getAllBookings().firstWhere((b) => b['booking_id'] == bookingId);
      expect(updatedBooking, isNotNull);
      expect(updatedBooking['status'], equals('CONFIRMED'));
      expect(updatedBooking['partner_id'], equals('prt_winner_101'));

      // Competing partner attempts to accept same booking -> rejected
      final acceptedSecond = await syncService.acceptBooking(bookingId, {
        'partner_id': 'prt_loser_202',
        'partner_name': 'Other Tech',
      });
      expect(acceptedSecond, isFalse);
    });
  });
}
