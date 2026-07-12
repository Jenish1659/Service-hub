import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class LocationState {
  final double? latitude;
  final double? longitude;
  final String address;
  final bool isLoading;
  final String? errorMessage;

  LocationState({
    this.latitude,
    this.longitude,
    this.address = 'Koramangala, Bengaluru',
    this.isLoading = false,
    this.errorMessage,
  });

  LocationState copyWith({
    double? latitude,
    double? longitude,
    String? address,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState()) {
    // Automatically try to retrieve user location on startup
    fetchLocation();
  }

  Future<void> fetchLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          address: 'HSR Layout Sector 3, Bengaluru',
          latitude: 12.9103,
          longitude: 77.6433,
          isLoading: false,
          errorMessage: 'Location services are disabled. Defaulting to HSR Layout.',
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            address: 'HSR Layout Sector 3, Bengaluru',
            latitude: 12.9103,
            longitude: 77.6433,
            isLoading: false,
            errorMessage: 'Location permission denied. Defaulting to HSR Layout.',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          address: 'HSR Layout Sector 3, Bengaluru',
          latitude: 12.9103,
          longitude: 77.6433,
          isLoading: false,
          errorMessage: 'Location permissions are permanently denied. Defaulting to HSR Layout.',
        );
        return;
      }

      // Fetch position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Perform Geocoding
      String readableAddress = 'Bengaluru, Karnataka';
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          final Placemark place = placemarks.first;
          final String subLocality = place.subLocality ?? '';
          final String locality = place.locality ?? '';
          if (subLocality.isNotEmpty && locality.isNotEmpty) {
            readableAddress = '$subLocality, $locality';
          } else {
            readableAddress = place.name ?? '$locality, Karnataka';
          }
        }
      } catch (e) {
        // Fallback geocoding if it fails (e.g. web mock/offline)
        readableAddress = 'Latitude: ${position.latitude.toStringAsFixed(4)}, Longitude: ${position.longitude.toStringAsFixed(4)}';
      }

      state = LocationState(
        latitude: position.latitude,
        longitude: position.longitude,
        address: readableAddress,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        address: 'HSR Layout Sector 3, Bengaluru',
        latitude: 12.9103,
        longitude: 77.6433,
        isLoading: false,
        errorMessage: 'Error: ${e.toString()}. Defaulting to HSR Layout.',
      );
    }
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
