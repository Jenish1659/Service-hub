import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/core/services/h3_geospatial_service.dart';

void main() {
  group('H3GeospatialService Tests', () {
    test('1. Generates H3 Resolution 8 index for real coordinates', () {
      final h3 = H3GeospatialService.instance;
      // Coordinates for Jamnagar / Rajkot
      final cell1 = h3.latLngToH3Index(22.4707, 70.0577, resolution: 8);
      expect(cell1, isNotEmpty);
      expect(cell1.length, greaterThanOrEqualTo(14));

      // Same coordinates produce same deterministic H3 index
      final cell2 = h3.latLngToH3Index(22.4707, 70.0577, resolution: 8);
      expect(cell1, equals(cell2));

      // Different coordinates produce different H3 index
      final cellAhmedabad = h3.latLngToH3Index(23.0225, 72.5714, resolution: 8);
      expect(cell1, isNot(equals(cellAhmedabad)));
    });

    test('2. Expands H3 cell into k-ring disk neighbors (k=2)', () {
      final h3 = H3GeospatialService.instance;
      final centerCell = h3.latLngToH3Index(22.4707, 70.0577, resolution: 8);
      final kRing = h3.getKRingCells(centerCell, ringSize: 2);

      expect(kRing, isNotEmpty);
      expect(kRing.contains(centerCell), isTrue);
      // k=2 disk contains at least 7 cells (up to 19 cells for hexagon grid)
      expect(kRing.length, greaterThanOrEqualTo(7));
    });

    test('3. Computes accurate Haversine distance in meters', () {
      final h3 = H3GeospatialService.instance;
      // Distance between two points in Jamnagar ~ 2 km apart
      final distMeters = h3.computeHaversineDistanceMeters(
        22.4707, 70.0577,
        22.4800, 70.0650,
      );

      expect(distMeters, greaterThan(1000.0));
      expect(distMeters, lessThan(3000.0));
    });
  });
}
