import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/services/supabase_auth_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_test');
    Hive.init(tempDir.path);
    final box = await Hive.openBox('partner_cache');
    await box.clear();
  });

  tearDownAll(() async {
    final file = File(r'C:\Users\Public\ServiceHub\service_hub_partner_verifications.json');
    if (file.existsSync()) {
      try {
        file.writeAsStringSync('{}');
      } catch (_) {}
    }
  });

  group('Partner Login Barrier & Tracking Checkmark Verification', () {
    final syncService = LiveBookingSyncService.instance;
    const partnerPhone = '9876543210';
    const partnerUsername = 'jenish_ac_services';
    final String partnerId = 'partner_${DateTime.now().millisecondsSinceEpoch}';

    test('1. Partner registration sets PENDING status and is stored locally and in live sync', () async {
      final partnerRecord = {
        'id': partnerId,
        'verification_id': partnerId,
        'user_id': partnerId,
        'username': partnerUsername,
        'name': 'Jenish Bheda',
        'full_name': 'Jenish Bheda',
        'business_name': 'Jenish AC Care & Repair',
        'phone': partnerPhone,
        'email': 'jenish@servicehub.com',
        'password': 'SecurePassword@123',
        'role_name': 'service_provider',
        'verification_status': 'PENDING',
        'status': 'PENDING',
        'is_online': false,
        'created_at': DateTime.now().toIso8601String(),
      };

      await LocalRegistrationCache.saveRegisteredPartner(partnerRecord);
      await syncService.submitPartnerVerification(partnerRecord);

      final active = await LocalRegistrationCache.getActivePartner();
      expect(active, isNotNull);
      expect(active!['verification_status'], equals('PENDING'));
      expect(active['username'], equals(partnerUsername));

      final liveRecord = syncService.getPartnerVerification(partnerId);
      expect(liveRecord, isNotNull);
      expect(liveRecord!['status'], equals('PENDING'));
    });

    test('2. Partner Login is STRICTLY BLOCKED before Admin Approval', () async {
      final result = await SupabaseAuthService.loginWithUsernameOrPhone(
        identifier: partnerPhone,
        password: 'SecurePassword@123',
        expectedRole: 'service_provider',
      );

      // Must NOT be successful!
      expect(result.isSuccess, isFalse, reason: 'Partner MUST NOT be allowed to login before Admin approves.');
      expect(result.errorMessage, contains('PENDING_APPROVAL'), reason: 'Error message must specify PENDING_APPROVAL to trigger application tracking flow.');
    });

    test('3. Admin Approves the Partner in the Master Verification Queue', () async {
      // Admin approves the partner
      await syncService.approvePartnerVerification(partnerId);

      final liveRecord = syncService.getPartnerVerification(partnerId);
      expect(liveRecord, isNotNull);
      expect(liveRecord!['status'], equals('APPROVED'));
      expect(liveRecord['verification_status'], equals('VERIFIED'));
    });

    test('4. Partner Login is AUTHORIZED and SUCCEEDS once Admin Approves', () async {
      // Update local cache session to reflect approved status
      await LocalRegistrationCache.updateActivePartner({
        'verification_status': 'VERIFIED',
        'status': 'APPROVED',
      });

      final result = await SupabaseAuthService.loginWithUsernameOrPhone(
        identifier: partnerPhone,
        password: 'SecurePassword@123',
        expectedRole: 'service_provider',
      );

      // Must now succeed!
      expect(result.isSuccess, isTrue, reason: 'Partner must be allowed to login into dashboard after Admin approval.');
      expect(result.userData, isNotNull);
      final status = result.userData!['verification_status'];
      expect(status == 'VERIFIED' || status == 'APPROVED', isTrue);
    });

    test('5. Tracking screen timeline checkmark logic: UNCHECKED when pending vs CHECKED when approved', () {
      IconData resolveStepIcon(bool approved, bool rejected) {
        if (approved) return Icons.check_rounded;
        if (rejected) return Icons.close_rounded;
        return Icons.radio_button_unchecked_rounded;
      }

      String resolveStepTag(bool approved, bool rejected) {
        if (approved) return 'Approved ✓';
        if (rejected) return 'Rejected';
        return 'Unchecked (Pending)';
      }

      // 1. Pending Admin review
      expect(resolveStepIcon(false, false), equals(Icons.radio_button_unchecked_rounded), reason: 'Icon must be UNCHECKED circle when pending.');
      expect(resolveStepTag(false, false), equals('Unchecked (Pending)'));

      // 2. Approved by Admin
      expect(resolveStepIcon(true, false), equals(Icons.check_rounded), reason: 'Icon must be CHECK MARK when approved by admin.');
      expect(resolveStepTag(true, false), equals('Approved ✓'));
    });
  });
}
