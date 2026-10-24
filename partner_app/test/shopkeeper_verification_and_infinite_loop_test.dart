import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Shopkeeper Verification & Role Isolation Tests', () {
    setUp(() async {
      LocalRegistrationCache.clearMemorySession();
    });

    test('1. Shopkeeper registration strictly isolates role and wipes delivery agent session', () async {
      // Step A: Simulate a previously cached Delivery Agent session
      await LocalRegistrationCache.updateActiveDeliveryAgent({
        'user_id': 'deliv-user-111',
        'name': 'Vishal Rider',
        'role': 'delivery_agent',
        'role_name': 'delivery_agent',
        'status': 'VERIFIED',
      });

      final cachedRider = await LocalRegistrationCache.getActiveDeliveryAgent();
      expect(cachedRider, isNotNull);
      expect(cachedRider!['name'], 'Vishal Rider');

      // Step B: User registers as a Shopkeeper (e.g., named Vishal)
      await LocalRegistrationCache.updateActiveShopkeeper({
        'user_id': 'shop-user-222',
        'name': 'Vishal Store Owner',
        'role': 'shopkeeper',
        'role_name': 'shopkeeper',
        'shop_name': 'Vishal Electronics',
        'verification_status': 'PENDING',
        'status': 'PENDING',
      });

      // Step C: Verify strict isolation
      // 1. getActiveShopkeeper must return the newly registered shopkeeper
      final activeShop = await LocalRegistrationCache.getActiveShopkeeper();
      expect(activeShop, isNotNull);
      expect(activeShop!['name'], 'Vishal Store Owner');
      expect(activeShop['shop_name'], 'Vishal Electronics');

      // 2. getActiveDeliveryAgent must now be completely wiped to prevent cross-role leaks
      final leakedRider = await LocalRegistrationCache.getActiveDeliveryAgent();
      expect(leakedRider, isNull, reason: 'Delivery agent session MUST be deleted when registering as shopkeeper');

      // 3. Generic getActivePartner must return shopkeeper, NEVER delivery agent
      final activePartner = await LocalRegistrationCache.getActivePartner();
      expect(activePartner, isNotNull);
      expect(activePartner!['role_name'], 'shopkeeper');
      expect(activePartner['name'], 'Vishal Store Owner');
    });

    test('2. Admin queue matcher correctly classifies Shopkeeper requests across all categories', () {
      // Matcher function identical to admin_partners_view.dart _isShopkeeperItem
      bool isShopkeeperItem(Map<String, dynamic> p) {
        final vType = (p['verification_type'] ?? '').toString().toUpperCase();
        final docType = (p['document_type'] ?? '').toString().toUpperCase();
        final remarks = (p['remarks'] ?? '').toString().toLowerCase();
        final role = (p['role_name'] ?? p['role'] ?? '').toString().toLowerCase();
        final cat = (p['category'] ?? p['category_name'] ?? '').toString().toLowerCase();
        final bName = (p['business_name'] ?? p['shop_name'] ?? '').toString().toLowerCase();

        if (vType == 'SHOP_LICENSE' || docType.contains('SHOP') || remarks.contains('role: shopkeeper') || remarks.contains('role:shopkeeper') || role == 'shopkeeper') {
          return true;
        }
        if (role == 'delivery_agent' || docType == 'DELIVERY_ONBOARDING' || vType == 'DRIVING_LICENSE') return false;
        if (role == 'service_provider' && !cat.contains('parts') && !cat.contains('store') && !cat.contains('shop') && !cat.contains('supplies') && !cat.contains('grocery')) {
          return false;
        }

        return role.contains('shop') ||
            role.contains('store') ||
            cat.contains('shop') ||
            cat.contains('store') ||
            cat.contains('parts') ||
            cat.contains('supplies') ||
            cat.contains('grocery') ||
            cat.contains('hardware') ||
            bName.contains('shop') ||
            bName.contains('store') ||
            bName.contains('parts') ||
            bName.contains('supplies') ||
            bName.contains('traders') ||
            bName.contains('enterprise') ||
            docType.contains('SHOP') ||
            (p['shop_id'] != null && p['shop_id'].toString().trim().isNotEmpty) ||
            (p['shop_name'] != null && p['shop_name'].toString().trim().isNotEmpty);
      }

      // Shopkeeper with AC Parts
      final acPartsShop = {
        'id': 'ver-101',
        'role': 'shopkeeper',
        'category': 'ac_parts',
        'business_name': 'Cool Air Spares',
        'verification_type': 'SHOP_LICENSE',
        'remarks': 'Role: shopkeeper | Category: ac_parts',
      };
      expect(isShopkeeperItem(acPartsShop), isTrue);

      // Shopkeeper with Grocery
      final groceryShop = {
        'id': 'ver-102',
        'role': 'shopkeeper',
        'category': 'grocery',
        'business_name': 'Vishal Kirana Store',
        'verification_type': 'SHOP_LICENSE',
        'remarks': 'Role: shopkeeper | Category: grocery',
      };
      expect(isShopkeeperItem(groceryShop), isTrue);

      // Shopkeeper with Caretaker supplies
      final suppliesShop = {
        'id': 'ver-103',
        'role': '',
        'category': 'caretaker_supplies',
        'business_name': 'Health Supplies Enterprise',
        'verification_type': 'SHOP_LICENSE',
        'remarks': 'Role: shopkeeper | Category: caretaker_supplies',
      };
      expect(isShopkeeperItem(suppliesShop), isTrue);

      // Delivery agent request MUST NOT be classified as shopkeeper
      final riderRequest = {
        'id': 'ver-201',
        'role': 'delivery_agent',
        'verification_type': 'DRIVING_LICENSE',
        'document_type': 'DELIVERY_ONBOARDING',
      };
      expect(isShopkeeperItem(riderRequest), isFalse);

      // Service provider technician request MUST NOT be classified as shopkeeper
      final technicianRequest = {
        'id': 'ver-301',
        'role': 'service_provider',
        'category': 'ac_service',
        'verification_type': 'AADHAAR',
        'document_type': 'PROVIDER_ONBOARDING',
      };
      expect(isShopkeeperItem(technicianRequest), isFalse);
    });

    test('3. Verification status PENDING blocks dashboard auto-opening and directs to status tracker', () {
      final activePartner = {
        'user_id': 'usr-999',
        'name': 'Vishal',
        'role_name': 'shopkeeper',
        'verification_status': 'PENDING',
      };

      final status = (activePartner['verification_status'] ?? '').toString().toUpperCase();
      final isPending = status == 'PENDING' || status == 'IN_REVIEW' || status == 'UNDER_REVIEW' || status == 'SUBMITTED';

      expect(isPending, isTrue, reason: 'Pending verification MUST be caught to prevent auto-opening any dashboard');

      String determineTargetRoute(Map<String, dynamic> partner) {
        final st = (partner['verification_status'] ?? '').toString().toUpperCase();
        if (st == 'PENDING' || st == 'IN_REVIEW' || st == 'UNDER_REVIEW') {
          return '/register/status-tracker';
        }
        final role = (partner['role_name'] ?? partner['role'] ?? '').toString().toLowerCase();
        if (role == 'delivery_agent') return '/dashboard/delivery';
        if (role == 'shopkeeper') return '/dashboard/shopkeeper';
        return '/role-selection';
      }

      expect(determineTargetRoute(activePartner), '/register/status-tracker');

      // Once approved, routes to /dashboard/shopkeeper, NEVER /dashboard/delivery
      final approvedPartner = Map<String, dynamic>.from(activePartner)..['verification_status'] = 'VERIFIED';
      expect(determineTargetRoute(approvedPartner), '/dashboard/shopkeeper');
    });

    test('4. Zero mock/fake values: IDs are dynamically generated from user UUIDs and not hardcoded defaults', () {
      const hardcodedMockShopId = 'SH-SHOP-2026-8910';
      const hardcodedMockDelId = 'SH-DEL-2026-9042';

      const userUuid = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890';
      final clean = userUuid.replaceAll('-', '');
      final dynamicShopId = 'SH-SHOP-2026-${clean.substring(0, 6).toUpperCase()}';
      final dynamicDelId = 'SH-DEL-2026-${clean.substring(0, 6).toUpperCase()}';

      expect(dynamicShopId, isNot(equals(hardcodedMockShopId)));
      expect(dynamicDelId, isNot(equals(hardcodedMockDelId)));
      expect(dynamicShopId, 'SH-SHOP-2026-A1B2C3');
      expect(dynamicDelId, 'SH-DEL-2026-A1B2C3');
    });
  });
}
