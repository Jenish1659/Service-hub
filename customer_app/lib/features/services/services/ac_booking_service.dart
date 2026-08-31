import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

class ACIssueBookingService {
  static final ACIssueBookingService instance = ACIssueBookingService._internal();
  ACIssueBookingService._internal();

  /// Uploads photos to Supabase Storage bucket ('ac_issue_photos' or 'booking_attachments').
  /// Returns a list of public URLs or stored paths.
  Future<List<String>> uploadPhotos(List<File> imageFiles) async {
    final List<String> uploadedUrls = [];

    for (int i = 0; i < imageFiles.length; i++) {
      final file = imageFiles[i];
      final fileName = 'ac_issue_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
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
        // Fallback: save local path reference if bucket is not created or network is offline
        debugPrint('Supabase storage upload fallback to local reference: $e');
        uploadedUrls.add(file.path);
      }
    }

    return uploadedUrls;
  }

  /// Saves the current unconfirmed AC booking draft to local Hive cache.
  /// (Does NOT commit to database until final confirmation).
  Future<void> saveDraft(Map<String, dynamic> draftData) async {
    try {
      final box = Hive.box('customer_cache');
      await box.put('ac_booking_draft', draftData);
    } catch (e) {
      debugPrint('Error saving AC booking draft to cache: $e');
    }
  }

  /// Loads the cached AC booking draft if present.
  Map<String, dynamic>? loadDraft() {
    try {
      final box = Hive.box('customer_cache');
      final data = box.get('ac_booking_draft');
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (e) {
      debugPrint('Error reading AC booking draft from cache: $e');
    }
    return null;
  }

  /// Clears the draft from local cache upon successful booking confirmation.
  Future<void> clearDraft() async {
    try {
      final box = Hive.box('customer_cache');
      await box.delete('ac_booking_draft');
    } catch (e) {
      debugPrint('Error clearing AC booking draft: $e');
    }
  }

  /// Saves AC issue details into draft format.
  Future<Map<String, dynamic>> saveACIssueDetails({
    required String acType,
    required String acBrand,
    required String problemDescription,
    required String acAge,
    required List<String> photoUrls,
    String? serviceName,
    double? servicePrice,
  }) async {
    String customerId = 'cust_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      if (currentUser != null) {
        customerId = currentUser.id;
      }
    } catch (_) {}

    final issueDraft = {
      'customer_id': customerId,
      'service_id': 'srv_ac_service',
      'service_name': serviceName ?? 'AC Service & Repair',
      'service_price': servicePrice ?? 499.0,
      'ac_type': acType,
      'ac_brand': acBrand,
      'problem_description': problemDescription,
      'ac_age': acAge,
      'photo_urls': photoUrls,
      'status': 'DRAFT_ISSUE_DETAILS',
      'created_at': DateTime.now().toIso8601String(),
    };

    // Save only to local draft cache
    await saveDraft(issueDraft);

    return issueDraft;
  }
}

class WalletRewardService {
  static final WalletRewardService instance = WalletRewardService._internal();
  WalletRewardService._internal();

  static const String cacheBoxName = 'customer_cache';
  static const String walletCoinsKey = 'wallet_coins';
  static const String walletBalanceKey = 'wallet_balance_inr';
  static const String completedServicesKey = 'completed_services_count';
  static const String isInitializedKey = 'wallet_initialized_v2';

  /// Ensures that on first-time account opening, the customer receives exactly 300 coins.
  void ensureInitialWalletCreated() {
    try {
      if (!Hive.isBoxOpen(cacheBoxName)) return;
      final box = Hive.box(cacheBoxName);
      final isInitialized = box.get(isInitializedKey, defaultValue: false) as bool;

      if (!isInitialized) {
        final existingCoins = box.get(walletCoinsKey);
        if (existingCoins == null) {
          box.put(walletCoinsKey, 300);
          box.put(walletBalanceKey, 30.0);
        }
        box.put(isInitializedKey, true);
      }
    } catch (e) {
      debugPrint('Wallet init error: $e');
    }
  }

  /// Calculates and awards coins upon service completion:
  /// - 1st Service: 200 coins
  /// - 2nd Service: 100 coins
  /// - 3rd Service onwards: Random coins <= 80 (range 30..80)
  int rewardCompletedService() {
    try {
      if (!Hive.isBoxOpen(cacheBoxName)) return 0;
      final box = Hive.box(cacheBoxName);

      final currentServices = (box.get(completedServicesKey, defaultValue: 0) as num).toInt();
      final newServicesCount = currentServices + 1;
      box.put(completedServicesKey, newServicesCount);

      int coinsAwarded = 0;
      if (newServicesCount == 1) {
        coinsAwarded = 200;
      } else if (newServicesCount == 2) {
        coinsAwarded = 100;
      } else {
        // Random coins under 80 (range 30..80 coins)
        final random = DateTime.now().microsecondsSinceEpoch;
        coinsAwarded = 30 + (random % 51); // 30..80
      }

      final currentCoins = (box.get(walletCoinsKey, defaultValue: 300) as num).toInt();
      box.put(walletCoinsKey, currentCoins + coinsAwarded);

      return coinsAwarded;
    } catch (e) {
      debugPrint('Reward error: $e');
      return 0;
    }
  }

  int getWalletCoins() {
    try {
      if (!Hive.isBoxOpen(cacheBoxName)) return 300;
      final box = Hive.box(cacheBoxName);
      return (box.get(walletCoinsKey, defaultValue: 300) as num).toInt();
    } catch (_) {
      return 300;
    }
  }

  double getWalletBalanceInr() {
    try {
      if (!Hive.isBoxOpen(cacheBoxName)) return 30.0;
      final box = Hive.box(cacheBoxName);
      return (box.get(walletBalanceKey, defaultValue: 30.0) as num).toDouble();
    } catch (_) {
      return 30.0;
    }
  }
}
