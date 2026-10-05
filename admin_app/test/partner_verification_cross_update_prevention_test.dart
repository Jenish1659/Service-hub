import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_admin/core/services/live_booking_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Partner Verification Cross-Update Prevention Tests (Bug 2 Fix)', () {
    final syncService = LiveBookingSyncService.instance;

    setUp(() {
      syncService.clearVerificationsForTest();
    });

    test('Approving one role does not approve other roles for same user/phone', () async {
      const sharedPhone = '+919876543210';
      const sharedUserId = 'usr_shared_001';

      // 1. Submit Shopkeeper verification request
      final shopkeeperRequest = {
        'id': 'ver_shop_001',
        'verification_id': 'ver_shop_001',
        'partner_id': 'prt_shop_001',
        'user_id': sharedUserId,
        'name': 'Ramesh Shopkeeper',
        'phone': sharedPhone,
        'role': 'shopkeeper',
        'role_name': 'shopkeeper',
        'category': 'ac_parts',
        'status': 'PENDING',
        'verification_status': 'PENDING',
        'business_name': 'Ramesh AC Spares',
      };
      await syncService.submitPartnerVerification(shopkeeperRequest);

      // 2. Submit Delivery Agent verification request for SAME user & phone
      final deliveryRequest = {
        'id': 'ver_deliv_002',
        'verification_id': 'ver_deliv_002',
        'partner_id': 'prt_deliv_002',
        'user_id': sharedUserId,
        'name': 'Ramesh Courier',
        'phone': sharedPhone,
        'role': 'delivery_agent',
        'role_name': 'delivery_agent',
        'category': 'delivery',
        'status': 'PENDING',
        'verification_status': 'PENDING',
        'vehicle_type': 'Bike',
        'vehicle_number': 'GJ-10-XX-1234',
      };
      await syncService.submitPartnerVerification(deliveryRequest);

      // Both must exist in pending queue
      final pendingBefore = syncService.getPendingPartnerVerifications();
      expect(pendingBefore.length, equals(2));
      expect(pendingBefore.any((p) => p['verification_id'] == 'ver_shop_001'), isTrue);
      expect(pendingBefore.any((p) => p['verification_id'] == 'ver_deliv_002'), isTrue);

      // 3. Admin approves ONLY the Shopkeeper verification request
      await syncService.approvePartnerVerification('ver_shop_001');

      // 4. Verify Shopkeeper is APPROVED
      final shopRecord = syncService.getPartnerVerification('ver_shop_001');
      expect(shopRecord, isNotNull);
      expect(shopRecord!['status'], equals('APPROVED'));
      expect(shopRecord['verification_status'], equals('VERIFIED'));

      // 5. CRITICAL: Delivery Agent MUST REMAIN PENDING!
      final delivRecord = syncService.getPartnerVerification('ver_deliv_002');
      expect(delivRecord, isNotNull);
      expect(delivRecord!['status'], equals('PENDING'));
      expect(delivRecord['verification_status'], equals('PENDING'));

      // 6. Check pending verifications: Delivery Agent is still pending, Shopkeeper is not
      final pendingAfter = syncService.getPendingPartnerVerifications();
      expect(pendingAfter.length, equals(1));
      expect(pendingAfter.first['verification_id'], equals('ver_deliv_002'));
    });

    test('Rejecting one role does not reject or affect other roles for same user/phone', () async {
      const sharedPhone = '+919998887776';
      const sharedUserId = 'usr_shared_002';

      // 1. Submit Shopkeeper request (Approved)
      await syncService.submitPartnerVerification({
        'id': 'ver_shop_010',
        'verification_id': 'ver_shop_010',
        'partner_id': 'prt_shop_010',
        'user_id': sharedUserId,
        'name': 'Kishan Electronics',
        'phone': sharedPhone,
        'role': 'shopkeeper',
        'category': 'ac_parts',
        'status': 'PENDING',
      });
      await syncService.approvePartnerVerification('ver_shop_010');

      // 2. Submit Delivery Agent request
      await syncService.submitPartnerVerification({
        'id': 'ver_deliv_020',
        'verification_id': 'ver_deliv_020',
        'partner_id': 'prt_deliv_020',
        'user_id': sharedUserId,
        'name': 'Kishan Courier',
        'phone': sharedPhone,
        'role': 'delivery_agent',
        'category': 'delivery',
        'status': 'PENDING',
      });

      // 3. Reject Delivery Agent request
      await syncService.rejectPartnerVerification('ver_deliv_020', 'Invalid Driving License');

      // 4. Verify Delivery Agent is REJECTED
      final delivRecord = syncService.getPartnerVerification('ver_deliv_020');
      expect(delivRecord!['status'], equals('REJECTED'));
      expect(delivRecord['remarks'], equals('Invalid Driving License'));

      // 5. Verify Shopkeeper REMAINS APPROVED
      final shopRecord = syncService.getPartnerVerification('ver_shop_010');
      expect(shopRecord!['status'], equals('APPROVED'));
      expect(shopRecord['verification_status'], equals('VERIFIED'));
    });
  });
}
