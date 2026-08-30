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

  /// Saves the AC issue details to the database and local session cache.
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

    final issueRecord = {
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

    // 1. Save to local cache
    try {
      final box = Hive.box('customer_cache');
      await box.put('current_ac_issue_booking', issueRecord);
    } catch (_) {}

    // 2. Try inserting into Supabase
    try {
      final client = Supabase.instance.client;
      await client.from('booking_issue_details').insert(issueRecord);
    } catch (e) {
      debugPrint('Database insert note (offline or custom schema fallback): $e');
    }

    return issueRecord;
  }
}
