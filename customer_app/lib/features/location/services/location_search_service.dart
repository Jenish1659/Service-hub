import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_location_model.dart';

class LocationSearchService {
  Future<List<SearchLocationModel>> searchLocation(String query) async {
    final String trimmed = query.trim();
    if (trimmed.length < 2) return [];

    final encodedQuery = Uri.encodeComponent(trimmed);
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$encodedQuery&format=json&addressdetails=1&limit=10&countrycodes=in',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'User-Agent': 'ServiceHubApp/1.0 (com.servicehub.customer)',
          'Accept-Language': 'en-US,en;q=0.9',
        },
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.map((item) => SearchLocationModel.fromNominatimJson(item as Map<String, dynamic>)).toList();
      }
    } catch (_) {}

    return [];
  }
}
