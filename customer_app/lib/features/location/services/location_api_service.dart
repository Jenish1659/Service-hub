import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import '../models/customer_location_model.dart';

class LocationApiService {
  static const String _boxName = 'customer_saved_locations';
  static const String _activeKey = 'active_customer_location';

  Future<void> saveCustomerLocation(CustomerLocationModel location) async {
    // 0. Strict 10-contact / saved address limit
    final existing = await getAllSavedLocations();
    final bool isUpdate = existing.any((item) => item.id == location.id);
    if (!isUpdate && existing.length >= 10) {
      throw Exception('Maximum limit of 10 contacts/saved addresses reached. Please remove an existing address first.');
    }

    // 1. Local Hive Storage
    try {
      Box box;
      if (Hive.isBoxOpen(_boxName)) {
        box = Hive.box(_boxName);
      } else {
        box = await Hive.openBox(_boxName);
      }
      await box.put(location.id, location.toJson());
      await box.put(_activeKey, location.toJson());
    } catch (_) {}

    // 2. Remote Supabase Cloud Synchronization
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        final payload = location.toJson();
        payload['customer_id'] = user.id;
        await client.from('customer_locations').upsert(payload);
      }
    } catch (_) {}
  }

  Future<List<CustomerLocationModel>> getAllSavedLocations() async {
    final List<CustomerLocationModel> locations = [];

    // Local-first read
    try {
      Box box;
      if (Hive.isBoxOpen(_boxName)) {
        box = Hive.box(_boxName);
      } else {
        box = await Hive.openBox(_boxName);
      }

      for (var key in box.keys) {
        if (key == _activeKey) continue;
        final val = box.get(key);
        if (val is Map) {
          locations.add(CustomerLocationModel.fromJson(Map<String, dynamic>.from(val)));
        }
      }
    } catch (_) {}

      // Remote sync background fetch
      try {
        final client = Supabase.instance.client;
        final user = client.auth.currentUser;
        if (user != null) {
          final response = await client
              .from('customer_locations')
              .select()
              .eq('customer_id', user.id)
              .order('created_at', ascending: false);

          if (response.isNotEmpty) {
            Box box;
            if (Hive.isBoxOpen(_boxName)) {
              box = Hive.box(_boxName);
            } else {
              box = await Hive.openBox(_boxName);
            }
            final List<CustomerLocationModel> remoteLocations = [];
            for (var item in response) {
              final loc = CustomerLocationModel.fromJson(Map<String, dynamic>.from(item));
              remoteLocations.add(loc);
              await box.put(loc.id, loc.toJson());
            }
            return remoteLocations;
          }
        }
      } catch (_) {}

    return locations;
  }

  Future<CustomerLocationModel?> getActiveLocation() async {
    try {
      Box box;
      if (Hive.isBoxOpen(_boxName)) {
        box = Hive.box(_boxName);
      } else {
        box = await Hive.openBox(_boxName);
      }
      final data = box.get(_activeKey);
      if (data != null && data is Map) {
        return CustomerLocationModel.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {}
    return null;
  }

  Future<void> setActiveLocation(CustomerLocationModel location) async {
    try {
      Box box;
      if (Hive.isBoxOpen(_boxName)) {
        box = Hive.box(_boxName);
      } else {
        box = await Hive.openBox(_boxName);
      }
      await box.put(_activeKey, location.toJson());
    } catch (_) {}
  }

  Future<void> deleteLocation(String locationId) async {
    try {
      Box box;
      if (Hive.isBoxOpen(_boxName)) {
        box = Hive.box(_boxName);
      } else {
        box = await Hive.openBox(_boxName);
      }
      await box.delete(locationId);
    } catch (_) {}

    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        await client.from('customer_locations').delete().eq('id', locationId).eq('customer_id', user.id);
      }
    } catch (_) {}
  }
}
