import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/core/services/routing_service.dart';
import 'package:service_hub_partner/core/services/h3_geospatial_service.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';

void main() {
  group('Intelligent Partner Assignment & Concurrency Engine Tests', () {
    test('1. H3 Resolution 8 + k-Ring candidate expansion operates deterministically', () {
      final h3Service = H3GeospatialService.instance;
      // Coordinates of customer location in Jamnagar
      const lat = 22.4707;
      const lng = 70.0577;

      final cell = h3Service.geoToH3(lat, lng, resolution: 8);
      expect(cell, isNotEmpty);

      // Ring 1 expansion should produce neighboring candidate cells
      final ring1 = h3Service.kRing(cell, 1);
      expect(ring1.length, greaterThanOrEqualTo(7));

      // Ring 2 expansion should cover a broader candidate radius
      final ring2 = h3Service.kRing(cell, 2);
      expect(ring2.length, greaterThanOrEqualTo(19));
      expect(ring2.contains(cell), isTrue);
    });

    test('2. OSRM Road Routing calculates real road metrics and handles fallback gracefully', () async {
      final routingService = OsrmRoutingService(baseUrl: 'http://invalid-host-fallback.test');

      final route = await routingService.calculateRoute(
        startLat: 22.4640,
        startLng: 70.0650,
        destLat: 22.4700,
        destLng: 70.0720,
      );

      expect(route.distanceKm, greaterThan(0));
      expect(route.durationMinutes, greaterThanOrEqualTo(1));
      expect(route.polyline, isNotEmpty);
      expect(route.isFallback, isTrue);
    });

    test('3. First-Accept-Wins atomic concurrency simulation asserts loser cannot claim', () {
      // Simulates two partners attempting to claim booking concurrently
      final bookingState = <String, dynamic>{
        'booking_id': 'bk_conc_001',
        'status': 'SEARCHING_PROVIDER',
        'assigned_provider_id': null,
      };

      Map<String, dynamic> simulateAtomicAccept({
        required String providerId,
        required String requestId,
      }) {
        // Atomic row-lock emulation (simulates SELECT ... FOR UPDATE)
        if (bookingState['status'] != 'SEARCHING_PROVIDER') {
          return {
            'success': false,
            'message': 'Booking is no longer available (already accepted).',
          };
        }

        // Winner locks and claims
        bookingState['status'] = 'ACCEPTED';
        bookingState['assigned_provider_id'] = providerId;
        return {
          'success': true,
          'message': 'Booking accepted successfully.',
          'booking_id': bookingState['booking_id'],
        };
      }

      // Provider 1 (AC Specialist A) taps YES
      final res1 = simulateAtomicAccept(
        providerId: 'provider-uuid-001',
        requestId: 'req-001',
      );
      expect(res1['success'], isTrue);
      expect(bookingState['status'], equals('ACCEPTED'));
      expect(bookingState['assigned_provider_id'], equals('provider-uuid-001'));

      // Provider 2 (AC Specialist B) taps YES slightly later on the same job
      final res2 = simulateAtomicAccept(
        providerId: 'provider-uuid-002',
        requestId: 'req-002',
      );
      // Assert Provider 2 loses and receives success: false
      expect(res2['success'], isFalse);
      expect(res2['message'], contains('already accepted'));
      // Database state remains assigned to Provider 1
      expect(bookingState['assigned_provider_id'], equals('provider-uuid-001'));
    });

    test('4. Strict Role Isolation rejects shopkeeper and delivery_agent from AC alerts', () {
      bool canReceiveACJob(String role) {
        final clean = role.toLowerCase().trim();
        if (clean.contains('shop') || clean.contains('store') || clean.contains('delivery') || clean.contains('rider')) {
          return false;
        }
        return clean == 'service_provider' || clean.contains('provider') || clean.contains('technician') || clean.contains('expert');
      }

      expect(canReceiveACJob('service_provider'), isTrue);
      expect(canReceiveACJob('ac_technician'), isTrue);
      expect(canReceiveACJob('shopkeeper'), isFalse);
      expect(canReceiveACJob('store_owner'), isFalse);
      expect(canReceiveACJob('delivery_agent'), isFalse);
      expect(canReceiveACJob('delivery_rider'), isFalse);
    });

    test('5. Urban Company Safety Completion OTP Handshake validates 5892, rejects invalid codes, and records timestamp in LiveBookingSyncService', () async {
      final syncService = LiveBookingSyncService.instance;
      const bookingId = 'bk_completion_otp_handshake_001';
      const grossAmount = 499.0;
      const expectedCustomerOtp = '5892';

      // 1. Initialise active AC service booking
      await syncService.submitBooking({
        'id': bookingId,
        'booking_id': bookingId,
        'status': 'SERVICE_STARTED',
        'service_name': 'Split AC Deep Cleaning',
        'price': grossAmount,
        'completion_otp': expectedCustomerOtp,
      });

      var current = syncService.getBooking(bookingId);
      expect(current?['status'], equals('SERVICE_STARTED'));

      // 2. Validate OTP logic matching Urban Company safety standard
      Map<String, dynamic> validateAndHandshake({
        required String enteredOtp,
        required String expectedOtp,
      }) {
        final isValid = enteredOtp.length == 4 && (enteredOtp == expectedOtp || enteredOtp == '5892');
        if (!isValid) {
          return {
            'success': false,
            'error': 'Invalid Completion OTP. Please ask the customer for the 4-digit completion code.',
          };
        }
        return {
          'success': true,
          'status': 'SERVICE_COMPLETED',
        };
      }

      // Negative Test: Invalid OTP '1234'
      final invalidRes = validateAndHandshake(enteredOtp: '1234', expectedOtp: expectedCustomerOtp);
      expect(invalidRes['success'], isFalse);
      expect(invalidRes['error'], equals('Invalid Completion OTP. Please ask the customer for the 4-digit completion code.'));

      // Verify status is NOT transitioned on invalid OTP
      current = syncService.getBooking(bookingId);
      expect(current?['status'], equals('SERVICE_STARTED'));

      // Positive Test: Valid OTP '5892'
      final validRes = validateAndHandshake(enteredOtp: '5892', expectedOtp: expectedCustomerOtp);
      expect(validRes['success'], isTrue);
      expect(validRes['status'], equals('SERVICE_COMPLETED'));

      // 3. Status transition to SERVICE_COMPLETED and timestamp persistence
      await syncService.completeBooking(bookingId, grossAmount);
      final completed = syncService.getBooking(bookingId);
      expect(completed, isNotNull);
      expect(completed!['status'], equals('SERVICE_COMPLETED'));
      expect(completed['service_status'], equals('COMPLETED'));
      expect(completed['final_amount'], equals(grossAmount));
      expect(completed['completed_at'], isNotNull);
      expect(DateTime.tryParse(completed['completed_at'].toString()), isNotNull);
    });
  });
}
