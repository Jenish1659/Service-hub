import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:service_hub_partner/core/services/routing_service.dart';

void main() {
  group('Partner RoutingService & Haversine Tests', () {
    test('Haversine distance calculation is accurate within Jamnagar', () {
      final dist = OsrmRoutingService.computeHaversineDistanceKm(
        22.4640,
        70.0650,
        22.4700,
        70.0720,
      );

      expect(dist, greaterThan(0.5));
      expect(dist, lessThan(2.0));
    });

    test('Haversine fallback produces reasonable road distance and ETA', () async {
      final service = OsrmRoutingService(baseUrl: 'http://invalid-host-should-fail.local');

      final route = await service.calculateRoute(
        startLat: 22.4707,
        startLng: 70.0577,
        destLat: 22.4640,
        destLng: 70.0650,
      );

      expect(route.distanceKm, greaterThan(0));
      expect(route.durationMinutes, greaterThan(0));
      expect(route.polyline.length, greaterThan(1));
      expect(route.isFallback, isTrue);
    });

    test('Matrix calculation produces duration and distance matrix', () async {
      final service = OsrmRoutingService(baseUrl: 'http://invalid-host-should-fail.local');

      final sources = [
        const LatLng(22.4707, 70.0577),
        const LatLng(22.4640, 70.0650),
      ];
      final destinations = [
        const LatLng(22.4720, 70.0600),
      ];

      final matrix = await service.calculateMatrix(
        sources: sources,
        destinations: destinations,
      );

      expect(matrix.durationsMinutes.length, equals(2));
      expect(matrix.distancesKm.length, equals(2));
      expect(matrix.durationsMinutes[0].length, equals(1));
      expect(matrix.distancesKm[0].length, equals(1));
      expect(matrix.distancesKm[0][0], greaterThan(0));
      expect(matrix.durationsMinutes[0][0], greaterThan(0));
    });
  });
}
