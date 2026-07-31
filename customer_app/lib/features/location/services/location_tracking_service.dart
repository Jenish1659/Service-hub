import 'dart:async';
import 'package:geolocator/geolocator.dart';
import '../models/location_update_model.dart';

class LocationTrackingService {
  StreamSubscription<Position>? _positionStreamSubscription;

  Stream<LocationUpdateModel> getLocationStream() {
    late StreamController<LocationUpdateModel> controller;

    controller = StreamController<LocationUpdateModel>(
      onListen: () {
        const locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 15, // Only emit when moved at least 15 meters
        );

        _positionStreamSubscription = Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen(
          (Position position) {
            controller.add(
              LocationUpdateModel(
                latitude: position.latitude,
                longitude: position.longitude,
                accuracy: position.accuracy,
                speed: position.speed,
              ),
            );
          },
          onError: (e) {
            controller.addError(e);
          },
        );
      },
      onCancel: () {
        _positionStreamSubscription?.cancel();
      },
    );

    return controller.stream;
  }

  void stopTracking() {
    _positionStreamSubscription?.cancel();
  }
}
