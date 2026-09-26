import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LocalRegistrationCache {
  static const String _boxName = 'partner_cache';
  static final Map<String, String> _memoryStorage = {};

  // Distinct Isolated Session Keys
  static const String _spSessionKey = 'active_service_provider_session';
  static const String _shopSessionKey = 'active_shopkeeper_session';
  static const String _deliverySessionKey = 'active_delivery_agent_session';
  static const String _activeRoleKey = 'current_active_role';
  static const String _legacyPartnerKey = 'active_partner_session';
  static const String _legacyUserKey = 'active_user_session';

  // SharedPreferences keys to wipe on session clear
  static const List<String> _sharedPrefKeys = [
    'partner_token',
    'partner_role',
    'saved_user_id',
    'saved_role_id',
    'cached_shopkeeper_data',
    'cached_delivery_data',
  ];

  // Hive cache keys to wipe on session clear
  static const List<String> _hiveSessionKeys = [
    _shopSessionKey,
    _spSessionKey,
    _deliverySessionKey,
    _activeRoleKey,
    _legacyPartnerKey,
    _legacyUserKey,
    'partner_registration_draft',
    'active_shopkeeper_session',
    'active_partner_session',
    'active_user_session',
    'current_active_role',
    'partner_token',
    'partner_role',
    'saved_user_id',
    'saved_role_id',
    'cached_shopkeeper_data',
    'cached_delivery_data',
    'cached_credentials',
    'user_credentials',
  ];

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

  // --- 1. Service Provider Isolated Session Methods ---
  static Future<Map<String, dynamic>?> getActiveServiceProvider() async {
    final rawMem = _memoryStorage[_spSessionKey];
    if (rawMem != null) {
      try {
        return jsonDecode(rawMem) as Map<String, dynamic>;
      } catch (_) {}
    }
    try {
      final box = _getBox();
      var data = box.get(_spSessionKey);
      if (data != null && data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}
    // Fallback: check legacy key only if role is service_provider
    try {
      final box = _getBox();
      final legacy = box.get(_legacyPartnerKey);
      if (legacy != null && legacy is Map) {
        final role = (legacy['role_name'] ?? legacy['role'] ?? '').toString().toLowerCase();
        if (role.isEmpty || role.contains('service') || role.contains('provider')) {
          return Map<String, dynamic>.from(legacy);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<void> updateActiveServiceProvider(Map<String, dynamic> updates) async {
    final current = await getActiveServiceProvider() ?? {};
    final updated = {...current, ...updates, 'role_name': 'service_provider'};
    _memoryStorage[_spSessionKey] = jsonEncode(updated);
    _memoryStorage[_activeRoleKey] = 'service_provider';
    _memoryStorage[_legacyPartnerKey] = jsonEncode(updated);
    try {
      final box = _getBox();
      box.put(_spSessionKey, updated);
      box.put(_activeRoleKey, 'service_provider');
      box.put(_legacyPartnerKey, updated);
    } catch (_) {}
  }

  static Future<void> logoutServiceProvider() async => clearActiveSession();

  // --- 2. Shopkeeper Isolated Session Methods ---
  static Future<Map<String, dynamic>?> getActiveShopkeeper() async {
    final rawMem = _memoryStorage[_shopSessionKey];
    if (rawMem != null) {
      try {
        final map = jsonDecode(rawMem) as Map<String, dynamic>;
        final role = (map['role_name'] ?? map['role'] ?? map['category'] ?? '').toString().toLowerCase();
        if (role.isEmpty || role.contains('shop') || role.contains('store')) {
          return map;
        }
      } catch (_) {}
    }
    try {
      final box = _getBox();
      var data = box.get(_shopSessionKey);
      if (data != null && data is Map) {
        final map = Map<String, dynamic>.from(data);
        final role = (map['role_name'] ?? map['role'] ?? map['category'] ?? '').toString().toLowerCase();
        if (role.isEmpty || role.contains('shop') || role.contains('store')) {
          return map;
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<void> updateActiveShopkeeper(Map<String, dynamic> updates) async {
    final current = await getActiveShopkeeper() ?? {};
    final updated = {...current, ...updates, 'role_name': 'shopkeeper'};
    _memoryStorage[_shopSessionKey] = jsonEncode(updated);
    _memoryStorage[_activeRoleKey] = 'shopkeeper';
    _memoryStorage[_legacyPartnerKey] = jsonEncode(updated);
    try {
      final box = _getBox();
      box.put(_shopSessionKey, updated);
      box.put(_activeRoleKey, 'shopkeeper');
      box.put(_legacyPartnerKey, updated);
    } catch (_) {}
  }

  static Future<void> logoutShopkeeper() async => clearActiveSession();

  // --- 3. Delivery Agent Isolated Session Methods ---
  static Future<Map<String, dynamic>?> getActiveDeliveryAgent() async {
    final rawMem = _memoryStorage[_deliverySessionKey];
    if (rawMem != null) {
      try {
        return jsonDecode(rawMem) as Map<String, dynamic>;
      } catch (_) {}
    }
    try {
      final box = _getBox();
      var data = box.get(_deliverySessionKey);
      if (data != null && data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {}
    // Fallback: check legacy key only if role matches delivery
    try {
      final box = _getBox();
      final legacy = box.get(_legacyPartnerKey);
      if (legacy != null && legacy is Map) {
        final role = (legacy['role_name'] ?? legacy['role'] ?? '').toString().toLowerCase();
        if (role == 'delivery_agent' || (role.contains('delivery') && !role.contains('shop') && !role.contains('service'))) {
          return Map<String, dynamic>.from(legacy);
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<void> updateActiveDeliveryAgent(Map<String, dynamic> updates) async {
    final current = await getActiveDeliveryAgent() ?? {};
    final updated = {...current, ...updates, 'role_name': 'delivery_agent'};
    _memoryStorage[_deliverySessionKey] = jsonEncode(updated);
    _memoryStorage[_activeRoleKey] = 'delivery_agent';
    _memoryStorage[_legacyPartnerKey] = jsonEncode(updated);
    try {
      final box = _getBox();
      box.put(_deliverySessionKey, updated);
      box.put(_activeRoleKey, 'delivery_agent');
      box.put(_legacyPartnerKey, updated);
    } catch (_) {}
  }

  static Future<void> logoutDeliveryAgent() async => clearActiveSession();


  // --- Generic Partner Methods (Role-Aware Dispatcher) ---
  static Future<Map<String, dynamic>?> getActivePartner([String? expectedRole]) async {
    if (expectedRole != null) {
      final cleanRole = expectedRole.toLowerCase();
      if (cleanRole == 'shopkeeper' || cleanRole.contains('shop') || cleanRole.contains('store')) {
        return await getActiveShopkeeper();
      }
      if (cleanRole == 'delivery_agent' || (cleanRole.contains('delivery') && !cleanRole.contains('shop') && !cleanRole.contains('service'))) {
        return await getActiveDeliveryAgent();
      }
      if (cleanRole == 'service_provider' || cleanRole.contains('provider') || cleanRole.contains('expert') || cleanRole.contains('technician')) {
        return await getActiveServiceProvider();
      }
      return null;
    }

    // Inspect current active role
    String? currentRole;
    try {
      final box = _getBox();
      currentRole = box.get(_activeRoleKey)?.toString();
    } catch (_) {
      currentRole = _memoryStorage[_activeRoleKey];
    }

    if (currentRole == 'shopkeeper') {
      return await getActiveShopkeeper();
    } else if (currentRole == 'delivery_agent') {
      return await getActiveDeliveryAgent();
    } else if (currentRole == 'service_provider') {
      return await getActiveServiceProvider();
    }

    // Fallback: check isolated keys in order if no active role specified
    final shop = await getActiveShopkeeper();
    if (shop != null) return shop;
    final deliv = await getActiveDeliveryAgent();
    if (deliv != null) return deliv;
    final sp = await getActiveServiceProvider();
    if (sp != null) return sp;

    // Legacy fallback only if a valid legacy session is present
    try {
      final box = _getBox();
      var data = box.get(_legacyPartnerKey) ?? box.get(_legacyUserKey);
      if (data != null && data is Map) {
        return Map<String, dynamic>.from(data);
      }
    } catch (_) {
      final raw = _memoryStorage[_legacyPartnerKey] ?? _memoryStorage[_legacyUserKey];
      if (raw != null) {
        try {
          return jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {}
      }
    }

    // If no active session exists, return null
    return null;
  }

  static Future<Map<String, dynamic>?> getRegisteredPartner() async {
    return await getActivePartner();
  }

  static Future<void> updateActivePartner(Map<String, dynamic> updates, [String? explicitRole]) async {
    final role = (explicitRole ?? updates['role_name'] ?? updates['role'] ?? updates['partner_type'] ?? updates['category'] ?? '').toString().toLowerCase();
    if (role == 'shopkeeper' || role.contains('shop') || role.contains('store')) {
      await updateActiveShopkeeper(updates);
    } else if (role == 'delivery_agent' || (role.contains('delivery') && !role.contains('shop') && !role.contains('service'))) {
      await updateActiveDeliveryAgent(updates);
    } else {
      await updateActiveServiceProvider(updates);
    }
  }

  static void clearMemorySession() {
    _memoryStorage.clear();
  }

  /// Completely purge active multi-role session, credentials, cache, and SharedPreferences
  static Future<void> clearActiveSession() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        final box = Hive.box(_boxName);
        for (final key in _hiveSessionKeys) {
          await box.delete(key);
        }
        await box.flush(); // CRITICAL: Flushes changes to disk before process death
      }
    } catch (_) {}
    _memoryStorage.clear();

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _sharedPrefKeys) {
        await prefs.remove(key);
      }
    } catch (_) {}

    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
  }

  static Future<void> signOut() async => clearActiveSession();

  static Future<void> logout([String? specificRole]) async => clearActiveSession();

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
      } catch (_) {}

      await updateActivePartner(payload);

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
          await updateActivePartner(p);
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
}
