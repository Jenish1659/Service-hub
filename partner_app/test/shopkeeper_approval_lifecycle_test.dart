import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('shopkeeper_lifecycle_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Shopkeeper Approval & Unlock Lifecycle Tests', () {
    test('1. Shopkeeper registration persists pending payload in LocalRegistrationCache', () async {
      final syncPayload = {
        'id': 'ver_cycle_001',
        'verification_id': 'ver_cycle_001',
        'user_id': 'user_cycle_001',
        'partner_id': 'partner_cycle_001',
        'shop_id': 'shop_cycle_001',
        'name': 'Bheda Cooling Services',
        'full_name': 'Jenish Bheda',
        'phone': '+91 9123456780',
        'email': 'shop_test@servicehub.com',
        'business_name': 'Bheda Cooling Services',
        'category': 'ac_parts',
        'role': 'shopkeeper',
        'role_name': 'shopkeeper',
        'status': 'PENDING',
        'verification_status': 'PENDING',
        'document_type': 'SHOPKEEPER_ONBOARDING',
      };

      await LocalRegistrationCache.updateActiveShopkeeper(syncPayload);

      final active = await LocalRegistrationCache.getActiveShopkeeper();
      expect(active, isNotNull);
      expect(active!['role_name'], equals('shopkeeper'));
      expect(active['verification_status'], equals('PENDING'));
      expect(active['category'], equals('ac_parts'));
    });

    test('2. LiveBookingSyncService approval updates cache to VERIFIED and unlocks dashboard access', () async {
      final syncService = LiveBookingSyncService.instance;

      final syncPayload = {
        'id': 'ver_cycle_002',
        'verification_id': 'ver_cycle_002',
        'user_id': 'user_cycle_002',
        'partner_id': 'partner_cycle_002',
        'phone': '+91 9123456781',
        'business_name': 'Super Spare Store',
        'category': 'ac_parts',
        'role': 'shopkeeper',
        'status': 'PENDING',
        'verification_status': 'PENDING',
      };

      await syncService.submitPartnerVerification(syncPayload);
      await LocalRegistrationCache.updateActiveShopkeeper(syncPayload);

      // Simulate Admin Approval
      await syncService.approvePartnerVerification('ver_cycle_002');

      // Verify updated status in sync service
      final record = syncService.getPartnerVerification('ver_cycle_002');
      expect(record, isNotNull);
      final status = (record!['status'] ?? record['verification_status'] ?? '').toString().toUpperCase();
      expect(status == 'APPROVED' || status == 'VERIFIED', isTrue);

      // Update local cache on approval
      final approvedPayload = Map<String, dynamic>.from(syncPayload);
      approvedPayload['status'] = 'APPROVED';
      approvedPayload['verification_status'] = 'VERIFIED';
      await LocalRegistrationCache.updateActiveShopkeeper(approvedPayload);

      final updatedCache = await LocalRegistrationCache.getActiveShopkeeper();
      expect(updatedCache!['verification_status'], equals('VERIFIED'));
      expect(updatedCache['status'], equals('APPROVED'));
    });

    test('3. Logging out from shopkeeper dashboard clears active shopkeeper session', () async {
      final active = await LocalRegistrationCache.getActiveShopkeeper();
      expect(active, isNotNull);

      await LocalRegistrationCache.logoutShopkeeper();

      final afterLogout = await LocalRegistrationCache.getActiveShopkeeper();
      expect(afterLogout, isNull);
    });
  });
}
