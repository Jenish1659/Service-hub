import '../models/service_area_model.dart';
import 'distance_service.dart';

class ServiceAreaCheckResult {
  final bool isAvailable;
  final String matchedCity;
  final double distanceKm;
  final String statusMessage;

  ServiceAreaCheckResult({
    required this.isAvailable,
    required this.matchedCity,
    required this.distanceKm,
    required this.statusMessage,
  });
}

class ServiceAreaService {
  static const String outsideAreaMessage =
      'Sorry, we are not available at your location. ServiceHub is currently available only in Jamnagar.';

  final List<ServiceAreaModel> _activeServiceAreas = [
    ServiceAreaModel(
      id: 'city_jamnagar',
      city: 'Jamnagar',
      state: 'Gujarat',
      country: 'India',
      active: true,
      centerLatitude: 22.4707,
      centerLongitude: 70.0577,
      radiusKm: 35.0,
    ),
  ];

  Future<bool> isServiceAvailable(String cityName, double lat, double lng) async {
    final result = checkServiceArea(cityName, lat, lng);
    return result.isAvailable;
  }

  ServiceAreaCheckResult checkServiceArea(String cityName, double lat, double lng) {
    final String cityLower = cityName.trim().toLowerCase();

    // 1. Exact or partial city name match for Jamnagar
    if (cityLower.contains('jamnagar')) {
      return ServiceAreaCheckResult(
        isAvailable: true,
        matchedCity: 'Jamnagar',
        distanceKm: 0.0,
        statusMessage: 'Verified Service Area (Jamnagar)',
      );
    }

    // 2. Lat/Lng radius distance calculation from Jamnagar center
    final jamnagar = _activeServiceAreas.first;
    if (lat != 0.0 && lng != 0.0) {
      final double dist = DistanceService.calculateDistance(
        lat,
        lng,
        jamnagar.centerLatitude,
        jamnagar.centerLongitude,
      );
      if (dist <= jamnagar.radiusKm) {
        return ServiceAreaCheckResult(
          isAvailable: true,
          matchedCity: jamnagar.city,
          distanceKm: dist,
          statusMessage: 'Within Jamnagar service radius (${dist.toStringAsFixed(1)} km)',
        );
      }
    }

    // Outside Jamnagar operational zone
    return ServiceAreaCheckResult(
      isAvailable: false,
      matchedCity: cityName.isNotEmpty ? cityName : 'Outside Jamnagar',
      distanceKm: 0.0,
      statusMessage: outsideAreaMessage,
    );
  }

  List<ServiceAreaModel> getActiveServiceAreas() {
    return _activeServiceAreas;
  }
}
