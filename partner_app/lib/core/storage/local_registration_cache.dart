import 'dart:convert';
import 'package:flutter/foundation.dart';

class LocalRegistrationCache {
  static final Map<String, String> _memoryStorage = {};

  static Future<void> saveDraft(Map<String, dynamic> data) async {
    try {
      _memoryStorage['partner_registration_draft'] = jsonEncode(data);
      if (kDebugMode) {
        debugPrint('[LocalRegistrationCache] Auto-saved draft data.');
      }
    } catch (e) {
      debugPrint('[LocalRegistrationCache] Failed to save draft: $e');
    }
  }

  static Future<Map<String, dynamic>?> getDraft() async {
    try {
      final raw = _memoryStorage['partner_registration_draft'];
      if (raw != null) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('[LocalRegistrationCache] Failed to read draft: $e');
    }
    return null;
  }

  static Future<void> clearDraft() async {
    _memoryStorage.remove('partner_registration_draft');
    if (kDebugMode) {
      debugPrint('[LocalRegistrationCache] Cleared registration draft.');
    }
  }
}
