import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../models/location_model.dart';

class GeocodingService {
  Future<LocationModel> getLocationFromCoordinates(double lat, double lng) async {
    try {
      // 1. Primary: Native Geolocator Geocoding
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final area = place.subLocality?.isNotEmpty == true
            ? place.subLocality!
            : (place.locality?.isNotEmpty == true ? place.locality! : 'Center Area');
        final city = place.locality?.isNotEmpty == true
            ? place.locality!
            : (place.subAdministrativeArea?.isNotEmpty == true ? place.subAdministrativeArea! : 'Jamnagar');
        final state = place.administrativeArea ?? 'Gujarat';
        final postalCode = place.postalCode ?? '';
        final street = place.street?.isNotEmpty == true ? place.street! : area;
        final fullAddress = '$street, $area, $city, $state $postalCode'.replaceAll(RegExp(r'\s+'), ' ').trim();

        return LocationModel(
          latitude: lat,
          longitude: lng,
          address: fullAddress,
          city: city,
          area: area,
          state: state,
          country: place.country ?? 'India',
          postalCode: postalCode,
        );
      }
    } catch (_) {
      // Fallthrough to OpenStreetMap reverse geocoding
    }

    try {
      // 2. Secondary: OpenStreetMap Nominatim Reverse API
      final url = Uri.parse('https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1');
      final response = await http.get(url, headers: {'User-Agent': 'ServiceHubApp/1.0'}).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addressMap = data['address'] as Map<String, dynamic>? ?? {};

        final area = addressMap['suburb'] ?? addressMap['neighbourhood'] ?? addressMap['residential'] ?? addressMap['road'] ?? 'Main City Area';
        final city = addressMap['city'] ?? addressMap['town'] ?? addressMap['village'] ?? addressMap['county'] ?? 'Jamnagar';
        final state = addressMap['state'] ?? 'Gujarat';
        final postalCode = addressMap['postcode'] ?? '';
        final fullAddress = data['display_name'] ?? '$area, $city, $state';

        return LocationModel(
          latitude: lat,
          longitude: lng,
          address: fullAddress,
          city: city,
          area: area,
          state: state,
          country: addressMap['country'] ?? 'India',
          postalCode: postalCode,
        );
      }
    } catch (_) {}

    // Fallback if all services fail
    return LocationModel(
      latitude: lat,
      longitude: lng,
      address: 'Digvijay Plot, Main Road, Jamnagar',
      city: 'Jamnagar',
      area: 'Digvijay Plot',
      state: 'Gujarat',
      country: 'India',
      postalCode: '361001',
    );
  }
}
