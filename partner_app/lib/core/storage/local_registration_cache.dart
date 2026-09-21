import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocalRegistrationCache {
  static const String _boxName = 'partner_cache';
  static final Map<String, String> _memoryStorage = {};

  static Box _getBox() {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    throw Exception('Hive box $_boxName is not open');
  }

  // --- Draft Registration Methods ---
  static Future<void> saveDraft(Map<String, dynamic> data) async {
    try {
      final jsonStr = jsonEncode(data);
      _memoryStorage['partner_registration_draft'] = jsonStr;
      try {
        final box = _getBox();
        await box.put('partner_registration_draft', jsonStr);
      } catch (_) {}
      if (kDebugMode) {
        debugPrint('[LocalRegistrationCache] Auto-saved draft data.');
      }
    } catch (e) {
      debugPrint('[LocalRegistrationCache] Failed to save draft: $e');
    }
  }

  static Future<Map<String, dynamic>?> getDraft() async {
    try {
      String? raw;
      try {
        final box = _getBox();
        raw = box.get('partner_registration_draft');
      } catch (_) {}
      raw ??= _memoryStorage['partner_registration_draft'];
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
    try {
      final box = _getBox();
      await box.delete('partner_registration_draft');
    } catch (_) {}
    if (kDebugMode) {
      debugPrint('[LocalRegistrationCache] Cleared registration draft.');
    }
  }

  // --- Registered Partners Storage & Authentication ---
  static Future<void> saveRegisteredPartner(Map<String, dynamic> partnerData) async {
    try {
      final String phone = (partnerData['phone'] ?? partnerData['mobile'] ?? '').toString().trim();
      final String id = partnerData['id'] ?? 'partner_${DateTime.now().millisecondsSinceEpoch}';
      final payload = Map<String, dynamic>.from(partnerData);
      payload['id'] = id;
      if (!payload.containsKey('created_at')) {
        payload['created_at'] = DateTime.now().toIso8601String();
      }

      try {
        final box = _getBox();
        final List<dynamic> rawList = box.get('registered_partners_list', defaultValue: []) as List<dynamic>;
        final List<Map<String, dynamic>> partners = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        
        // Upsert by phone or id
        partners.removeWhere((p) => p['phone'] == phone || p['id'] == id);
        partners.add(payload);
        await box.put('registered_partners_list', partners);
        await box.put('active_partner_session', payload);
      } catch (_) {
        _memoryStorage['active_partner_session'] = jsonEncode(payload);
      }

      if (kDebugMode) {
        debugPrint('[LocalRegistrationCache] Registered partner saved: ${partnerData['name']} ($phone)');
      }
    } catch (e) {
      debugPrint('[LocalRegistrationCache] Failed to save registered partner: $e');
    }
  }

  static Future<Map<String, dynamic>?> authenticateProvider(String identifier, String password) async {
    final cleanId = identifier.trim().toLowerCase();
    final cleanPass = password.trim();

    try {
      final box = _getBox();
      final List<dynamic> rawList = box.get('registered_partners_list', defaultValue: []) as List<dynamic>;
      final List<Map<String, dynamic>> partners = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      for (final p in partners) {
        final pPhone = (p['phone'] ?? p['mobile'] ?? '').toString().toLowerCase().trim();
        final pEmail = (p['email'] ?? '').toString().toLowerCase().trim();
        final pName = (p['name'] ?? p['firstName'] ?? '').toString().toLowerCase().trim();
        final pPass = (p['password'] ?? '').toString().trim();

        if ((pPhone == cleanId || pEmail == cleanId || pName == cleanId || pPhone.endsWith(cleanId)) &&
            (pPass.isEmpty || pPass == cleanPass)) {
          await box.put('active_partner_session', p);
          return p;
        }
      }
    } catch (e) {
      debugPrint('[LocalRegistrationCache] Error during local auth: $e');
    }

    // Check active memory session as fallback
    final active = await getActivePartner();
    if (active != null) {
      final pPhone = (active['phone'] ?? active['mobile'] ?? '').toString().toLowerCase().trim();
      final pEmail = (active['email'] ?? '').toString().toLowerCase().trim();
      final pName = (active['name'] ?? '').toString().toLowerCase().trim();
      final pPass = (active['password'] ?? '').toString().trim();

      if ((pPhone == cleanId || pEmail == cleanId || pName == cleanId || pPhone.endsWith(cleanId)) &&
          (pPass.isEmpty || pPass == cleanPass)) {
        return active;
      }
    }

    return null;
  }

  static Future<Map<String, dynamic>?> getActivePartner() async {
    try {
      final box = _getBox();
      var data = box.get('active_partner_session');
      data ??= box.get('active_user_session');
      if (data != null && data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {
      final raw = _memoryStorage['active_partner_session'] ?? _memoryStorage['active_user_session'];
      if (raw != null) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getRegisteredPartner() async {
    return await getActivePartner();
  }

  static Future<void> updateActivePartner(Map<String, dynamic> updates) async {
    final current = await getActivePartner() ?? {};
    final updated = {...current, ...updates};
    _memoryStorage['active_partner_session'] = jsonEncode(updated);
    try {
      final box = _getBox();
      await box.put('active_partner_session', updated);
    } catch (_) {}
  }

  static void clearMemorySession() {
    _memoryStorage.remove('active_partner_session');
    _memoryStorage.remove('active_user_session');
  }

  static Future<void> logout() async {
    try {
      final box = _getBox();
      await box.delete('active_partner_session');
      await box.delete('active_user_session');
    } catch (_) {}
    clearMemorySession();

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }
}

