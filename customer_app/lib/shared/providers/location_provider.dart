import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:hive/hive.dart';

class LocationState {
  final double? latitude;
  final double? longitude;
  final String address;
  final bool isLoading;
  final String? errorMessage;
  final bool isOutsideRange;

  LocationState({
    this.latitude,
    this.longitude,
    this.address = 'Digvijay Plot, Jamnagar',
    this.isLoading = false,
    this.errorMessage,
    this.isOutsideRange = false,
  });

  LocationState copyWith({
    double? latitude,
    double? longitude,
    String? address,
    bool? isLoading,
    String? errorMessage,
    bool? isOutsideRange,
  }) {
    return LocationState(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      isOutsideRange: isOutsideRange ?? this.isOutsideRange,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier() : super(LocationState()) {
    _initLocation();
  }

  void _initLocation() {
    try {
      final box = Hive.box('customer_cache');
      final address = box.get('location_address') as String?;
      final lat = box.get('location_latitude') as double?;
      final lng = box.get('location_longitude') as double?;
      if (address != null && lat != null && lng != null) {
        state = LocationState(
          address: address,
          latitude: lat,
          longitude: lng,
          isOutsideRange: _checkOutsideRange(address, lat, lng),
          isLoading: false,
        );
        return;
      }
    } catch (_) {}
    // If no cached location, fetch location automatically
    fetchLocation();
  }

  void _saveToCache(double lat, double lng, String address) {
    try {
      final box = Hive.box('customer_cache');
      box.put('location_address', address);
      box.put('location_latitude', lat);
      box.put('location_longitude', lng);
    } catch (_) {}
  }

  bool _checkOutsideRange(String address, double? lat, double? lng) {
    if (address.toLowerCase().contains('jamnagar')) {
      return false;
    }
    if (lat != null && lng != null) {
      // Center of Jamnagar coordinates
      final double distance = Geolocator.distanceBetween(lat, lng, 22.4707, 70.0577);
      if (distance <= 25000) {
        return false;
      }
    }
    return true;
  }

  Future<void> fetchLocation() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          address: 'Digvijay Plot, Jamnagar',
          latitude: 22.4725,
          longitude: 70.0610,
          isOutsideRange: false,
          isLoading: false,
          errorMessage: 'Location services are disabled. Defaulting to Jamnagar.',
        );
        _saveToCache(22.4725, 70.0610, 'Digvijay Plot, Jamnagar');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            address: 'Digvijay Plot, Jamnagar',
            latitude: 22.4725,
            longitude: 70.0610,
            isOutsideRange: false,
            isLoading: false,
            errorMessage: 'Location permission denied. Defaulting to Jamnagar.',
          );
          _saveToCache(22.4725, 70.0610, 'Digvijay Plot, Jamnagar');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          address: 'Digvijay Plot, Jamnagar',
          latitude: 22.4725,
          longitude: 70.0610,
          isOutsideRange: false,
          isLoading: false,
          errorMessage: 'Location permissions are permanently denied. Defaulting to Jamnagar.',
        );
        _saveToCache(22.4725, 70.0610, 'Digvijay Plot, Jamnagar');
        return;
      }

      // Fetch position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Perform Geocoding
      String readableAddress = 'Jamnagar, Gujarat';
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
            readableAddress = place.name ?? '$locality, Gujarat';
          }
        }
      } catch (e) {
        readableAddress = 'Digvijay Plot, Jamnagar';
      }

      final isOutside = _checkOutsideRange(readableAddress, position.latitude, position.longitude);

      state = LocationState(
        latitude: position.latitude,
        longitude: position.longitude,
        address: readableAddress,
        isOutsideRange: isOutside,
        isLoading: false,
      );
      _saveToCache(position.latitude, position.longitude, readableAddress);
    } catch (e) {
      state = state.copyWith(
        address: 'Digvijay Plot, Jamnagar',
        latitude: 22.4725,
        longitude: 70.0610,
        isOutsideRange: false,
        isLoading: false,
        errorMessage: 'Error: ${e.toString()}. Defaulting to Jamnagar.',
      );
      _saveToCache(22.4725, 70.0610, 'Digvijay Plot, Jamnagar');
    }
  }

  void updateCustomLocation(double lat, double lng, String address) {
    final isOutside = _checkOutsideRange(address, lat, lng);
    state = LocationState(
      latitude: lat,
      longitude: lng,
      address: address,
      isOutsideRange: isOutside,
      isLoading: false,
    );
    _saveToCache(lat, lng, address);
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier();
});
