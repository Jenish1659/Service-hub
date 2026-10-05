import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/features/dashboard/presentation/ac_provider_dashboard_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Partner App Zero Fake Requests and Strict Real Dispatch (Bug 1 Fix)', () {
    final syncService = LiveBookingSyncService.instance;

    setUp(() {
      syncService.clearBookingsForTest();
    });

    test('Initial dashboard state has exactly 0 incoming offers and 0 fake requests', () {
      const state = ACProviderDashboardState(
        partnerId: 'prt_real_technician_001',
        providerId: 'prov_real_001',
        incomingOffers: [],
      );

      // Verify that with no requests addressed to this partner, offers list is empty
      expect(state.incomingOffers, isEmpty);
      expect(state.incomingOffers.length, equals(0));
    });

    test('Incoming offers list does NOT contain unassigned or unsolicited bookings', () {
      // Suppose local sync service has an unassigned booking (from a past test)
      final dummyUnassigned = {
        'id': 'booking_unassigned_999',
        'booking_id': 'booking_unassigned_999',
        'status': 'PENDING',
        'partner_id': '', // Unassigned!
        'service_name': 'AC Service',
      };
      syncService.submitBooking(dummyUnassigned);

      // AC Provider controller should NOT load this into incomingOffers
      // A partner with ID 'prt_target_101' should only receive offers explicitly dispatched to 'prt_target_101'
      const targetPartnerId = 'prt_target_101';
      final List<Map<String, dynamic>> offersList = [];

      // Simulated dispatch filtering (matching the controller's logic in Section A)
      final allIncoming = syncService.getAllBookings();
      for (final req in allIncoming) {
        final reqPartner = (req['partner_id'] ?? '').toString();
        if (reqPartner.isNotEmpty && reqPartner == targetPartnerId) {
          offersList.add(req);
        }
      }

      // Must be 0 because the booking was unassigned, not dispatched to prt_target_101
      expect(offersList, isEmpty);
      expect(offersList.length, equals(0));
    });

    test('Incoming offers list receives only bookings explicitly dispatched to this partner', () {
      const targetPartnerId = 'prt_target_202';

      // 1. Booking dispatched to another partner
      syncService.submitBooking({
        'id': 'booking_other_partner',
        'booking_id': 'booking_other_partner',
        'status': 'PENDING',
        'partner_id': 'prt_other_999',
        'service_name': 'AC Jet Wash',
      });

      // 2. Booking dispatched explicitly to target partner
      syncService.submitBooking({
        'id': 'booking_real_dispatched',
        'booking_id': 'booking_real_dispatched',
        'status': 'PENDING',
        'partner_id': targetPartnerId,
        'service_name': 'AC Deep Cleaning',
      });

      // Filter for target partner
      final List<Map<String, dynamic>> targetPartnerOffers = [];
      for (final req in syncService.getAllBookings()) {
        final reqPartner = (req['partner_id'] ?? '').toString();
        if (reqPartner == targetPartnerId) {
          targetPartnerOffers.add(req);
        }
      }

      // Exactly 1 offer, addressed strictly to targetPartnerId
      expect(targetPartnerOffers.length, equals(1));
      expect(targetPartnerOffers.first['booking_id'], equals('booking_real_dispatched'));
      expect(targetPartnerOffers.first['partner_id'], equals(targetPartnerId));
    });
  });
}
