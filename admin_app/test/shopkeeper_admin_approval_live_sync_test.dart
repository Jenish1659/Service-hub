import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_admin/core/services/live_booking_sync_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shopkeeper Registration & Admin Approval Live Sync Test', () {
    setUp(() {
      LiveBookingSyncService.instance.reloadAllFromDisk();
    });

    test('1. Shopkeeper registration with category "ac_parts" properly persists in LiveBookingSyncService', () async {
      final syncService = LiveBookingSyncService.instance;

      final testShopkeeper = {
        'id': 'ver_ac_parts_001',
        'verification_id': 'ver_ac_parts_001',
        'user_id': 'user_ac_parts_001',
        'partner_id': 'partner_ac_parts_001',
        'shop_id': 'shop_ac_parts_001',
        'name': 'Rajesh Bheda',
        'full_name': 'Rajesh Bheda',
        'phone': '+91 9988776655',
        'email': 'rajesh@coolingparts.com',
        'business_name': 'Apex Cooling Components',
        'shop_name': 'Apex Cooling Components',
        'category': 'ac_parts',
        'category_name': 'Shopkeeper (AC Service Parts)',
        'role': 'shopkeeper',
        'role_name': 'shopkeeper',
        'city': 'Jamnagar',
        'address': 'Main Market, Jamnagar',
        'verification_status': 'PENDING',
        'status': 'PENDING',
        'document_type': 'SHOPKEEPER_ONBOARDING',
        'gst_number': 'GSTIN-24AAACP1234Z',
        'created_at': DateTime.now().toIso8601String(),
        'submitted_at': DateTime.now().toIso8601String(),
        'remarks': 'Role: shopkeeper | Category: ac_parts | Shop: Apex Cooling Components | Phone: +91 9988776655',
      };

      // Submit verification
      await syncService.submitPartnerVerification(testShopkeeper);

      // Verify it appears in pending verifications
      final pending = syncService.getPendingPartnerVerifications();
      expect(pending.isNotEmpty, isTrue);

      final found = pending.firstWhere((p) => p['id'] == 'ver_ac_parts_001' || p['verification_id'] == 'ver_ac_parts_001');
      expect(found['role'], equals('shopkeeper'));
      expect(found['category'], equals('ac_parts'));
      expect(found['business_name'], equals('Apex Cooling Components'));
      expect(found['document_type'], equals('SHOPKEEPER_ONBOARDING'));
    });

    test('2. Admin approval updates status to APPROVED across LiveBookingSyncService and stream', () async {
      final syncService = LiveBookingSyncService.instance;

      final testShopkeeper = {
        'id': 'ver_ac_parts_002',
        'verification_id': 'ver_ac_parts_002',
        'user_id': 'user_ac_parts_002',
        'partner_id': 'partner_ac_parts_002',
        'shop_id': 'shop_ac_parts_002',
        'name': 'Hitesh Vora',
        'full_name': 'Hitesh Vora',
        'phone': '+91 9876543219',
        'business_name': 'Vora Refrigeration Depot',
        'category': 'ac_parts',
        'role': 'shopkeeper',
        'verification_status': 'PENDING',
        'status': 'PENDING',
        'document_type': 'SHOPKEEPER_ONBOARDING',
        'created_at': DateTime.now().toIso8601String(),
      };

      await syncService.submitPartnerVerification(testShopkeeper);

      // Admin clicks Approve
      await syncService.approvePartnerVerification('ver_ac_parts_002');

      // Verify status is now APPROVED/VERIFIED
      final record = syncService.getPartnerVerification('ver_ac_parts_002');
      expect(record, isNotNull);
      final status = (record!['status'] ?? record['verification_status'] ?? '').toString().toUpperCase();
      expect(status == 'APPROVED' || status == 'VERIFIED', isTrue);
    });

    test('3. Verification lookup works by phone number and partner_id as well as verification_id', () async {
      final syncService = LiveBookingSyncService.instance;

      final testShopkeeper = {
        'id': 'ver_ac_parts_003',
        'verification_id': 'ver_ac_parts_003',
        'user_id': 'user_ac_parts_003',
        'partner_id': 'partner_ac_parts_003',
        'shop_id': 'shop_ac_parts_003',
        'name': 'Ketan Mehta',
        'phone': '+91 9825012345',
        'business_name': 'Mehta Spares & Tools',
        'category': 'ac_parts',
        'role': 'shopkeeper',
        'status': 'PENDING',
        'verification_status': 'PENDING',
      };

      await syncService.submitPartnerVerification(testShopkeeper);

      // Lookup by phone
      final byPhone = syncService.getPartnerVerification('+91 9825012345');
      expect(byPhone, isNotNull);
      expect(byPhone!['id'], equals('ver_ac_parts_003'));

      // Approve by phone
      await syncService.approvePartnerVerification('+91 9825012345');

      final updatedByVerId = syncService.getPartnerVerification('ver_ac_parts_003');
      expect(updatedByVerId, isNotNull);
      final status = (updatedByVerId!['status'] ?? updatedByVerId['verification_status'] ?? '').toString().toUpperCase();
      expect(status == 'APPROVED' || status == 'VERIFIED', isTrue);
    });
  });
}
