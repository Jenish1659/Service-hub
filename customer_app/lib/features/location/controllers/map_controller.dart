import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/map_service.dart';

class ServiceHubMapController {
  final MapController mapController = MapController();

  void moveToLocation(double latitude, double longitude, {double zoom = MapService.defaultZoom}) {
    try {
      mapController.move(LatLng(latitude, longitude), zoom);
    } catch (_) {}
  }

  void zoomIn() {
    try {
      final currentZoom = mapController.camera.zoom;
      if (currentZoom < MapService.maxZoom) {
        mapController.move(mapController.camera.center, currentZoom + 1.0);
      }
    } catch (_) {}
  }

  void zoomOut() {
    try {
      final currentZoom = mapController.camera.zoom;
      if (currentZoom > MapService.minZoom) {
        mapController.move(mapController.camera.center, currentZoom - 1.0);
      }
    } catch (_) {}
  }

  LatLng? getCenterPosition() {
    try {
      return mapController.camera.center;
    } catch (_) {
      return null;
    }
  }
}
