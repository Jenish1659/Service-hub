import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RouteResult {
  final double distanceKm;
  final int durationMinutes;
  final List<LatLng> polyline;
  final String provider;
  final bool isFallback;

  const RouteResult({
    required this.distanceKm,
    required this.durationMinutes,
    required this.polyline,
    required this.provider,
    this.isFallback = false,
  });

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km';
  String get formattedDuration => '$durationMinutes min';
}

class MatrixResult {
  final List<List<double>> durationsMinutes; // [sourceIndex][destIndex]
  final List<List<double>> distancesKm;     // [sourceIndex][destIndex]
  final String provider;
  final bool isFallback;

  const MatrixResult({
    required this.durationsMinutes,
    required this.distancesKm,
    required this.provider,
    this.isFallback = false,
  });
}

abstract class RoutingService {
  Future<RouteResult> calculateRoute({
    required double startLat,
    required double startLng,
    required double destLat,
    required double destLng,
  });

  Future<MatrixResult> calculateMatrix({
    required List<LatLng> sources,
    required List<LatLng> destinations,
  });
}

class OsrmRoutingService implements RoutingService {
  final http.Client _client;
  final String _baseUrl;

  OsrmRoutingService({
    http.Client? client,
    String baseUrl = 'http://router.project-osrm.org',
  })  : _client = client ?? http.Client(),
        _baseUrl = baseUrl;

  @override
  Future<RouteResult> calculateRoute({
    required double startLat,
    required double startLng,
    required double destLat,
    required double destLng,
  }) async {
    // Format: /route/v1/driving/{lng1},{lat1};{lng2},{lat2}?overview=full&geometries=geojson
    final url = '$_baseUrl/route/v1/driving/$startLng,$startLat;$destLng,$destLat?overview=full&geometries=geojson';
    try {
      final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok' && data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0.0;
          final durationSeconds = (route['duration'] as num?)?.toDouble() ?? 0.0;
          final geometry = route['geometry'];

          final List<LatLng> polylinePoints = [];
          if (geometry != null && geometry['coordinates'] != null) {
            for (final coord in geometry['coordinates']) {
              if (coord is List && coord.length >= 2) {
                polylinePoints.add(LatLng((coord[1] as num).toDouble(), (coord[0] as num).toDouble()));
              }
            }
          }

          if (polylinePoints.isEmpty) {
            polylinePoints.add(LatLng(startLat, startLng));
            polylinePoints.add(LatLng(destLat, destLng));
          }

          return RouteResult(
            distanceKm: (distanceMeters / 1000.0),
            durationMinutes: math.max(1, (durationSeconds / 60.0).round()),
            polyline: polylinePoints,
            provider: 'OSRM',
            isFallback: false,
          );
        }
      }
    } catch (e) {
      debugPrint('[OsrmRoutingService] OSRM route request failed, falling back to Haversine: $e');
    }

    return _haversineFallbackRoute(startLat, startLng, destLat, destLng);
  }

  @override
  Future<MatrixResult> calculateMatrix({
    required List<LatLng> sources,
    required List<LatLng> destinations,
  }) async {
    if (sources.isEmpty || destinations.isEmpty) {
      return const MatrixResult(
        durationsMinutes: [],
        distancesKm: [],
        provider: 'EMPTY',
        isFallback: false,
      );
    }

    // Combine all coordinates: sources first, then destinations
    // /table/v1/driving/{all_coords}?sources={indices}&destinations={indices}&annotations=duration,distance
    final allCoords = <LatLng>[...sources, ...destinations];
    final coordsString = allCoords.map((c) => '${c.longitude},${c.latitude}').join(';');

    final sourceIndices = List.generate(sources.length, (i) => i).join(';');
    final destIndices = List.generate(destinations.length, (i) => sources.length + i).join(';');

    final url =
        '$_baseUrl/table/v1/driving/$coordsString?sources=$sourceIndices&destinations=$destIndices&annotations=duration,distance';

    try {
      final response = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 'Ok') {
          final durationsRaw = data['durations'] as List?;
          final distancesRaw = data['distances'] as List?;

          final List<List<double>> durationsMinutes = [];
          final List<List<double>> distancesKm = [];

          if (durationsRaw != null) {
            for (final row in durationsRaw) {
              if (row is List) {
                durationsMinutes.add(row.map((d) {
                  if (d == null) return 999.0;
                  return (d as num).toDouble() / 60.0;
                }).toList());
              }
            }
          }

          if (distancesRaw != null) {
            for (final row in distancesRaw) {
              if (row is List) {
                distancesKm.add(row.map((d) {
                  if (d == null) return 999.0;
                  return (d as num).toDouble() / 1000.0;
                }).toList());
              }
            }
          }

          if (durationsMinutes.isNotEmpty) {
            return MatrixResult(
              durationsMinutes: durationsMinutes,
              distancesKm: distancesKm.isNotEmpty ? distancesKm : _estimateDistancesFromDurations(durationsMinutes),
              provider: 'OSRM',
              isFallback: false,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[OsrmRoutingService] OSRM table matrix request failed, falling back: $e');
    }

    return _haversineFallbackMatrix(sources, destinations);
  }

  List<List<double>> _estimateDistancesFromDurations(List<List<double>> durationsMinutes) {
    // Assuming ~25 km/h average city speed
    return durationsMinutes.map((row) {
      return row.map((m) => (m / 60.0) * 25.0).toList();
    }).toList();
  }

  RouteResult _haversineFallbackRoute(double startLat, double startLng, double destLat, double destLng) {
    final straightDistanceKm = computeHaversineDistanceKm(startLat, startLng, destLat, destLng);
    // Urban road factor (1.35x road detour multiplier)
    final roadDistanceKm = straightDistanceKm * 1.35;
    // Average urban speed ~25 km/h
    final durationMinutes = math.max(2, (roadDistanceKm / 25.0 * 60.0).round());

    // Create 5-point interpolated line between start and end
    final List<LatLng> polyline = [];
    for (int i = 0; i <= 4; i++) {
      final t = i / 4.0;
      final lat = startLat + (destLat - startLat) * t;
      final lng = startLng + (destLng - startLng) * t;
      polyline.add(LatLng(lat, lng));
    }

    return RouteResult(
      distanceKm: roadDistanceKm,
      durationMinutes: durationMinutes,
      polyline: polyline,
      provider: 'HaversineFallback',
      isFallback: true,
    );
  }

  MatrixResult _haversineFallbackMatrix(List<LatLng> sources, List<LatLng> destinations) {
    final List<List<double>> durations = [];
    final List<List<double>> distances = [];

    for (final src in sources) {
      final rowDurations = <double>[];
      final rowDistances = <double>[];
      for (final dest in destinations) {
        final straightKm = computeHaversineDistanceKm(src.latitude, src.longitude, dest.latitude, dest.longitude);
        final roadKm = straightKm * 1.35;
        final minutes = math.max(2.0, (roadKm / 25.0 * 60.0));
        rowDistances.add(roadKm);
        rowDurations.add(minutes);
      }
      durations.add(rowDurations);
      distances.add(rowDistances);
    }

    return MatrixResult(
      durationsMinutes: durations,
      distancesKm: distances,
      provider: 'HaversineFallback',
      isFallback: true,
    );
  }

  static double computeHaversineDistanceKm(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadiusKm * c;
  }

  static double _toRadians(double degree) => degree * math.pi / 180.0;
}
