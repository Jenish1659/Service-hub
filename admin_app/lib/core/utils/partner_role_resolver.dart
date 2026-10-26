/// Centralized Authoritative Partner Role Resolver for Multi-Queue Isolation
/// Guarantees 100% strict mutual exclusivity across Partner, Shopkeeper, and Delivery Agent queues.
class PartnerRoleResolver {
  PartnerRoleResolver._();

  static const String roleServiceProvider = 'service_provider';
  static const String roleShopkeeper = 'shopkeeper';
  static const String roleDeliveryAgent = 'delivery_agent';

  /// Authoritatively resolves a partner map into exactly ONE canonical role:
  /// - 'service_provider'
  /// - 'shopkeeper'
  /// - 'delivery_agent'
  static String resolveRole(Map<String, dynamic> p) {
    final explicitRole = (p['role_name'] ?? p['role'] ?? '').toString().toLowerCase().trim();
    if (explicitRole == 'shopkeeper') return roleShopkeeper;
    if (explicitRole == 'delivery_agent' || explicitRole == 'delivery_partner' || explicitRole == 'delivery') {
      return roleDeliveryAgent;
    }
    if (explicitRole == 'service_provider' || explicitRole == 'provider') {
      return roleServiceProvider;
    }

    // Direct Database Profile Identifiers
    final shopId = (p['shop_id'] ?? '').toString().trim();
    final delivId = (p['delivery_agent_id'] ?? '').toString().trim();
    final provId = (p['provider_id'] ?? '').toString().trim();

    if (shopId.isNotEmpty && delivId.isEmpty && provId.isEmpty) return roleShopkeeper;
    if (delivId.isNotEmpty && shopId.isEmpty && provId.isEmpty) return roleDeliveryAgent;
    if (provId.isNotEmpty && shopId.isEmpty && delivId.isEmpty) return roleServiceProvider;

    // Document & Verification Types
    final docType = (p['document_type'] ?? '').toString().toUpperCase().trim();
    final verType = (p['verification_type'] ?? '').toString().toUpperCase().trim();

    if (docType == 'SHOPKEEPER_ONBOARDING' || verType == 'SHOP_LICENSE' || docType.contains('SHOP')) {
      return roleShopkeeper;
    }
    if (docType == 'DELIVERY_ONBOARDING' || verType == 'DRIVING_LICENSE' || docType.contains('DELIVERY')) {
      return roleDeliveryAgent;
    }
    if (docType == 'PROVIDER_ONBOARDING' || docType == 'SERVICE_ONBOARDING') {
      return roleServiceProvider;
    }

    // Explicit remarks tags (e.g. 'Role: service_provider', 'Role: shopkeeper')
    final remarks = (p['remarks'] ?? '').toString().toLowerCase();
    if (remarks.contains('role: shopkeeper') || remarks.contains('role:shopkeeper')) {
      return roleShopkeeper;
    }
    if (remarks.contains('role: delivery') || remarks.contains('role:delivery')) {
      return roleDeliveryAgent;
    }
    if (remarks.contains('role: service_provider') || remarks.contains('role:service_provider') || remarks.contains('role: provider')) {
      return roleServiceProvider;
    }

    // Explicit Vehicle / License Information (exclusive to Delivery Agents)
    final vType = (p['vehicle_type'] ?? '').toString().trim();
    final vNum = (p['vehicle_number'] ?? p['vehicle_reg_number'] ?? '').toString().trim();
    final dl = (p['driving_license_number'] ?? '').toString().trim();
    if (vNum.isNotEmpty || dl.isNotEmpty || (vType.isNotEmpty && vType.toLowerCase() != 'none')) {
      return roleDeliveryAgent;
    }

    // Default Fallback: Service Provider
    return roleServiceProvider;
  }

  static bool isShopkeeper(Map<String, dynamic> p) => resolveRole(p) == roleShopkeeper;
  static bool isDeliveryAgent(Map<String, dynamic> p) => resolveRole(p) == roleDeliveryAgent;
  static bool isServiceProvider(Map<String, dynamic> p) => resolveRole(p) == roleServiceProvider;

  /// Check whether candidate belongs to the requested queue filter
  static bool matchesQueue(Map<String, dynamic> p, String? filterRole) {
    if (filterRole == null || filterRole.isEmpty || filterRole == 'all') return true;
    final target = filterRole.toLowerCase().trim();
    if (target == 'shopkeeper') return isShopkeeper(p);
    if (target == 'delivery_agent' || target == 'delivery_partner' || target == 'delivery') {
      return isDeliveryAgent(p);
    }
    if (target == 'service_provider' || target == 'provider') {
      return isServiceProvider(p);
    }
    return resolveRole(p) == target;
  }
}
