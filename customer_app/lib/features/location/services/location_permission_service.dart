import 'package:geolocator/geolocator.dart';

enum LocationPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class LocationPermissionService {
  Future<LocationPermissionStatus> checkPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      return LocationPermissionStatus.granted;
    } else if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.permanentlyDenied;
    } else {
      return LocationPermissionStatus.denied;
    }
  }

  Future<LocationPermissionStatus> requestPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationPermissionStatus.serviceDisabled;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
      return LocationPermissionStatus.granted;
    } else if (permission == LocationPermission.deniedForever) {
      return LocationPermissionStatus.permanentlyDenied;
    } else {
      return LocationPermissionStatus.denied;
    }
  }

  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }
}
