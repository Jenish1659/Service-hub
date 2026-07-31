import 'package:hive/hive.dart';
import '../models/search_location_model.dart';

class LocationHistoryService {
  static const String _boxName = 'recent_location_searches';

  Future<void> saveRecentSearch(SearchLocationModel location) async {
    try {
      Box box;
      if (Hive.isBoxOpen(_boxName)) {
        box = Hive.box(_boxName);
      } else {
        box = await Hive.openBox(_boxName);
      }

      final existing = box.values.toList();
      // Remove duplicate if already present
      existing.removeWhere((item) => item is Map && item['displayAddress'] == location.displayAddress);

      final newItem = {
        'name': location.name,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'displayAddress': location.displayAddress,
        'timestamp': DateTime.now().toIso8601String(),
      };

      existing.insert(0, newItem);
      // Keep top 5 recent searches
      final trimmed = existing.take(5).toList();

      await box.clear();
      for (int i = 0; i < trimmed.length; i++) {
        await box.add(trimmed[i]);
      }
    } catch (_) {}
  }

  Future<List<SearchLocationModel>> getRecentSearches() async {
    try {
      Box box;
      if (Hive.isBoxOpen(_boxName)) {
        box = Hive.box(_boxName);
      } else {
        box = await Hive.openBox(_boxName);
      }

      final List<SearchLocationModel> results = [];
      for (var val in box.values) {
        if (val is Map) {
          results.add(
            SearchLocationModel(
              name: val['name'] as String? ?? 'Location',
              latitude: (val['latitude'] as num).toDouble(),
              longitude: (val['longitude'] as num).toDouble(),
              displayAddress: val['displayAddress'] as String? ?? '',
            ),
          );
        }
      }
      return results;
    } catch (_) {
      return [];
    }
  }

  Future<void> clearRecentSearches() async {
    try {
      Box box;
      if (Hive.isBoxOpen(_boxName)) {
        box = Hive.box(_boxName);
      } else {
        box = await Hive.openBox(_boxName);
      }
      await box.clear();
    } catch (_) {}
  }
}
