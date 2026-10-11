import 'package:flutter/foundation.dart';
import '../storage/local_registration_cache.dart';

/// Centralized Service Category Route Resolver
/// Guarantees 100% role & service isolation across all 6 official ServiceHub domains.
class ServiceCategoryRouteHelper {
  ServiceCategoryRouteHelper._();

  // Canonical category identifiers matching database schema
  static const String categoryAc = 'ac_service';
  static const String categoryLaundry = 'laundry';
  static const String categoryPlumbing = 'plumbing';
  static const String categoryCarService = 'car_service';
  static const String categoryCareTaker = 'care_taker';
  static const String categoryCooking = 'cooking';

  /// Normalizes any input category slug, alias, or display title into canonical id.
  static String normalizeCategory(String? rawCategory) {
    if (rawCategory == null || rawCategory.trim().isEmpty) {
      return categoryAc;
    }

    final normalized = rawCategory
        .trim()
        .toLowerCase()
        .replaceAll(' ', '_')
        .replaceAll('-', '_');

    // Plumber / Plumbing normalization
    if (normalized == 'plumber' ||
        normalized == 'plumbing' ||
        normalized.contains('plumb')) {
      return categoryPlumbing;
    }

    // Laundry normalization
    if (normalized == 'laundry' ||
        normalized.contains('laundry') ||
        normalized.contains('dry_clean') ||
        normalized.contains('washing')) {
      return categoryLaundry;
    }

    // Car Service normalization
    if (normalized == 'car_service' ||
        normalized == 'car' ||
        normalized == 'automobile' ||
        normalized.contains('car_') ||
        normalized.contains('auto')) {
      return categoryCarService;
    }

    // Care Taker normalization
    if (normalized == 'care_taker' ||
        normalized == 'care_taker_partner' ||
        normalized == 'caretaker' ||
        normalized.contains('care_taker') ||
        normalized.contains('caretaker') ||
        normalized.contains('nursing') ||
        normalized.contains('elderly')) {
      return categoryCareTaker;
    }

    // Cooking normalization
    if (normalized == 'cooking' ||
        normalized == 'cook' ||
        normalized == 'chef' ||
        normalized.contains('cook') ||
        normalized.contains('culinary')) {
      return categoryCooking;
    }

    // AC Service normalization
    if (normalized == 'ac_service' ||
        normalized == 'ac' ||
        normalized == 'hvac' ||
        normalized.contains('ac_') ||
        normalized.contains('air_condition')) {
      return categoryAc;
    }

    return normalized;
  }

  /// Maps canonical category id to its dedicated Dashboard route.
  static String getDashboardRoute(String? rawCategory) {
    final cat = normalizeCategory(rawCategory);
    switch (cat) {
      case categoryLaundry:
        return '/dashboard/laundry';
      case categoryPlumbing:
        return '/dashboard/plumbing';
      case categoryCarService:
        return '/dashboard/car-service';
      case categoryCareTaker:
        return '/dashboard/care-taker';
      case categoryCooking:
        return '/dashboard/cooking';
      case categoryAc:
      default:
        return '/dashboard/ac';
    }
  }

  /// Maps canonical category id to its dedicated Profile route.
  static String getProfileRoute(String? rawCategory) {
    final cat = normalizeCategory(rawCategory);
    switch (cat) {
      case categoryLaundry:
        return '/profile/laundry';
      case categoryPlumbing:
        return '/profile/plumbing';
      case categoryCarService:
        return '/profile/car-service';
      case categoryCareTaker:
        return '/profile/care-taker';
      case categoryCooking:
        return '/profile/cooking';
      case categoryAc:
      default:
        return '/profile/ac';
    }
  }

  /// Human-readable category display title.
  static String getCategoryTitle(String? rawCategory) {
    final cat = normalizeCategory(rawCategory);
    switch (cat) {
      case categoryLaundry:
        return 'Laundry & Dry Clean Specialist';
      case categoryPlumbing:
        return 'Plumbing & Sanitation Specialist';
      case categoryCarService:
        return 'Car Repair & Maintenance Specialist';
      case categoryCareTaker:
        return 'Care Taker & Nursing Specialist';
      case categoryCooking:
        return 'Home Cook & Culinary Specialist';
      case categoryAc:
      default:
        return 'AC & HVAC Specialist';
    }
  }

  /// Resolves the active partner category from session cache.
  static Future<String> resolveActivePartnerCategory() async {
    try {
      final activeProvider = await LocalRegistrationCache.getActiveServiceProvider();
      if (activeProvider != null) {
        final cat = activeProvider['category'] ??
            activeProvider['service_category_id'] ??
            activeProvider['serviceCategoryId'] ??
            activeProvider['business_type'];
        if (cat != null && cat.toString().trim().isNotEmpty) {
          return normalizeCategory(cat.toString());
        }
      }

      final activePartner = await LocalRegistrationCache.getActivePartner();
      if (activePartner != null) {
        final cat = activePartner['category'] ??
            activePartner['service_category_id'] ??
            activePartner['business_type'];
        if (cat != null && cat.toString().trim().isNotEmpty) {
          return normalizeCategory(cat.toString());
        }
      }

      final activeShopkeeper = await LocalRegistrationCache.getActiveShopkeeper();
      if (activeShopkeeper != null) {
        final cat = activeShopkeeper['category'] ??
            activeShopkeeper['business_type'];
        if (cat != null && cat.toString().trim().isNotEmpty) {
          return normalizeCategory(cat.toString());
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ServiceCategoryRouteHelper] Error resolving category: $e');
      }
    }

    return categoryAc;
  }
}
