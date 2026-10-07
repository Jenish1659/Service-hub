import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

/// Configuration definition for each enabled service category.
class ServiceCategoryConfig {
  final String categoryId;
  final String categoryName;
  final String requiredRole;
  final String requiredCapability;
  final double defaultVisitingFee;
  final double protectionFee;
  final String description;

  const ServiceCategoryConfig({
    required this.categoryId,
    required this.categoryName,
    required this.requiredRole,
    required this.requiredCapability,
    required this.defaultVisitingFee,
    required this.protectionFee,
    required this.description,
  });
}

/// Central service for multi-category drafts, photo uploads, and category metadata.
class MultiServiceBookingService {
  static final MultiServiceBookingService instance = MultiServiceBookingService._internal();
  MultiServiceBookingService._internal();

  static const Map<String, ServiceCategoryConfig> categories = {
    'ac_service': ServiceCategoryConfig(
      categoryId: 'ac_service',
      categoryName: 'AC Service & Repair',
      requiredRole: 'service_provider',
      requiredCapability: 'ac_service',
      defaultVisitingFee: 449.0,
      protectionFee: 49.0,
      description: 'Professional AC installation, deep jet cleaning, repair, and gas refilling',
    ),
    'laundry': ServiceCategoryConfig(
      categoryId: 'laundry',
      categoryName: 'Laundry Service',
      requiredRole: 'shopkeeper',
      requiredCapability: 'laundry',
      defaultVisitingFee: 99.0,
      protectionFee: 29.0,
      description: 'Washing, dry cleaning, ironing, and garment care services',
    ),
    'car_service': ServiceCategoryConfig(
      categoryId: 'car_service',
      categoryName: 'Car Service & Repair',
      requiredRole: 'service_provider',
      requiredCapability: 'car_service',
      defaultVisitingFee: 499.0,
      protectionFee: 49.0,
      description: 'Car washing, mechanical inspection, oil change, and doorstep detailing',
    ),
    'care_taker': ServiceCategoryConfig(
      categoryId: 'care_taker',
      categoryName: 'Care Taker Service',
      requiredRole: 'service_provider',
      requiredCapability: 'care_taker',
      defaultVisitingFee: 399.0,
      protectionFee: 49.0,
      description: 'Elderly care, patient care, babysitting, and domestic assistance',
    ),
    'cooking': ServiceCategoryConfig(
      categoryId: 'cooking',
      categoryName: 'Cooking Service',
      requiredRole: 'service_provider',
      requiredCapability: 'cooking',
      defaultVisitingFee: 299.0,
      protectionFee: 29.0,
      description: 'Professional domestic cooks, chefs, and catering services',
    ),
    'plumbing': ServiceCategoryConfig(
      categoryId: 'plumbing',
      categoryName: 'Plumbing Service',
      requiredRole: 'service_provider',
      requiredCapability: 'plumbing',
      defaultVisitingFee: 249.0,
      protectionFee: 29.0,
      description: 'Pipe repair, tap installation, leakage fix, and water motor setup',
    ),
  };

  /// Returns configuration for categoryId, defaulting safely if unknown.
  static ServiceCategoryConfig getConfig(String categoryId) {
    final normalized = categoryId.toLowerCase().trim();
    if (categories.containsKey(normalized)) {
      return categories[normalized]!;
    }
    if (normalized.contains('care')) return categories['care_taker']!;
    if (normalized.contains('car')) return categories['car_service']!;
    if (normalized.contains('ac')) return categories['ac_service']!;
    if (normalized.contains('laundry')) return categories['laundry']!;
    if (normalized.contains('cook')) return categories['cooking']!;
    if (normalized.contains('plumb')) return categories['plumbing']!;
    return categories['ac_service']!;
  }

  ServiceCategoryConfig getCategoryConfig(String categoryId) => getConfig(categoryId);

  /// Uploads photos to Supabase Storage bucket ('booking_attachments').
  Future<List<String>> uploadPhotos(List<File> imageFiles, {String prefix = 'service_issue'}) async {
    final List<String> uploadedUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      final fileName = '${prefix}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
      final path = 'customer_uploads/$fileName';

      try {
        if (!kIsWeb && await file.exists()) {
          final client = Supabase.instance.client;
          final bytes = await file.readAsBytes();
          await client.storage
              .from('booking_attachments')
              .uploadBinary(path, bytes, fileOptions: const FileOptions(contentType: 'image/jpeg'));

          final publicUrl = client.storage.from('booking_attachments').getPublicUrl(path);
          uploadedUrls.add(publicUrl);
        } else {
          uploadedUrls.add(file.path);
        }
      } catch (e) {
        debugPrint('Supabase storage upload fallback to local reference: $e');
        uploadedUrls.add(file.path);
      }
    }

    return uploadedUrls;
  }

  /// Saves the current unconfirmed booking draft for a category to local Hive cache.
  Future<void> saveDraft(String categoryId, Map<String, dynamic> draftData) async {
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        await box.put('${categoryId}_booking_draft', draftData);
      }
    } catch (e) {
      debugPrint('Error saving $categoryId booking draft to cache: $e');
    }
  }

  /// Loads cached booking draft for a category.
  Map<String, dynamic>? loadDraft(String categoryId) {
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        final data = box.get('${categoryId}_booking_draft');
        if (data is Map) {
          return Map<String, dynamic>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Error reading $categoryId booking draft from cache: $e');
    }
    return null;
  }

  /// Clears draft from local cache upon successful booking confirmation.
  Future<void> clearDraft(String categoryId) async {
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        await box.delete('${categoryId}_booking_draft');
      }
    } catch (e) {
      debugPrint('Error clearing $categoryId booking draft: $e');
    }
  }
}
