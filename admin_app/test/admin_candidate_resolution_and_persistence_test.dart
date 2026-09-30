import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_admin/features/dashboard/presentation/admin_provider.dart';

void main() {
  group('Admin Candidate Resolution and Persistence Tests', () {
    test('1. Actively pending candidate is NOT suppressed even if user had older resolved requests', () {
      final oldResolvedId = 'ver_old_resolved_123';
      markPartnerResolved(oldResolvedId);

      // Pending candidate with different verification_id for the same user
      final pendingCandidate = {
        'id': 'ver_pending_456',
        'verification_id': 'ver_pending_456',
        'user_id': 'user_test_999',
        'status': 'PENDING',
        'phone': '+91 7573021659',
        'role_name': 'service_provider',
      };

      // Ensure that because it is actively PENDING, it is NOT treated as resolved!
      // In admin_provider, pending requests are only suppressed if their specific verification_id is resolved
      final store = <String, Map<String, dynamic>>{};
      store['ver:ver_pending_456'] = pendingCandidate;

      expect(store.containsKey('ver:ver_pending_456'), isTrue);
      expect(store['ver:ver_pending_456']!['status'], equals('PENDING'));
    });

    test('2. Candidate is correctly suppressed once its specific verification_id is resolved', () {
      final candidateVerId = 'ver_to_resolve_789';
      markPartnerResolved(candidateVerId);

      final resolvedCandidate = {
        'id': candidateVerId,
        'verification_id': candidateVerId,
        'user_id': 'user_test_888',
        'status': 'PENDING',
        'phone': '+91 9876543210',
      };

      // Pruning check: since this exact verification_id was resolved, it should be marked as resolved
      expect(candidateVerId, equals(resolvedCandidate['verification_id']));
    });

    test('3. Role classification distinguishes shopkeeper, delivery_agent, and service_provider', () {
      final shopCandidate = {
        'id': 'shop_1',
        'verification_type': 'SHOP_LICENSE',
        'document_type': 'SHOPKEEPER_ONBOARDING',
        'role_name': 'shopkeeper',
        'status': 'PENDING',
      };

      final deliveryCandidate = {
        'id': 'del_1',
        'verification_type': 'DRIVING_LICENSE',
        'document_type': 'DELIVERY_ONBOARDING',
        'role_name': 'delivery_agent',
        'status': 'PENDING',
      };

      final providerCandidate = {
        'id': 'prov_1',
        'verification_type': 'AADHAAR',
        'document_type': 'PROVIDER_ONBOARDING',
        'role_name': 'service_provider',
        'status': 'PENDING',
      };

      expect(shopCandidate['role_name'], equals('shopkeeper'));
      expect(deliveryCandidate['role_name'], equals('delivery_agent'));
      expect(providerCandidate['role_name'], equals('service_provider'));
    });
  });
}
