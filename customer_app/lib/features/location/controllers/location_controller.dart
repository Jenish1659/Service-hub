import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../models/location_model.dart';
import '../services/location_service.dart';
import '../services/geocoding_service.dart';
import '../services/location_permission_service.dart';
import '../services/location_save_service.dart';

enum LocationStatus {
  initial,
  checkingPermission,
  fetchingLocation,
  success,
  error,
}

class LocationState {
  final LocationModel? currentLocation;
  final LocationModel? selectedLocation;
  final LocationStatus status;
  final bool permissionGranted;
  final bool isFollowingLocation;
  final bool isSaving;
  final String? errorMessage;

  const LocationState({
    this.currentLocation,
    this.selectedLocation,
    this.status = LocationStatus.initial,
    this.permissionGranted = false,
    this.isFollowingLocation = true,
    this.isSaving = false,
    this.errorMessage,
  });

  LocationState copyWith({
    LocationModel? currentLocation,
    LocationModel? selectedLocation,
    LocationStatus? status,
    bool? permissionGranted,
    bool? isFollowingLocation,
    bool? isSaving,
    String? errorMessage,
  }) {
    return LocationState(
      currentLocation: currentLocation ?? this.currentLocation,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      status: status ?? this.status,
      permissionGranted: permissionGranted ?? this.permissionGranted,
      isFollowingLocation: isFollowingLocation ?? this.isFollowingLocation,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}

class LocationController extends StateNotifier<LocationState> {
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();
  final LocationPermissionService _permissionService = LocationPermissionService();
  final LocationSaveService _saveService = LocationSaveService();

  LocationController() : super(const LocationState()) {
    _loadSavedLocationFromCache();
  }

  void _loadSavedLocationFromCache() {
    try {
      final box = Hive.box('customer_cache');
      final address = box.get('location_address') as String?;
      final lat = box.get('location_latitude') as double?;
      final lng = box.get('location_longitude') as double?;

      if (lat != null && lng != null) {
        final cachedModel = LocationModel(
          latitude: lat,
          longitude: lng,
          address: address ?? 'Current Location',
          area: address?.split(',').first ?? 'Current Location',
          city: 'Jamnagar',
          state: 'Gujarat',
          country: 'India',
        );
        state = state.copyWith(
          status: LocationStatus.success,
          currentLocation: cachedModel,
          selectedLocation: cachedModel,
        );
      }
    } catch (_) {}
  }

  Future<void> initializeAndDetectLocation() async {
    if (state.selectedLocation != null) return; // Use fast cached location first!

    state = state.copyWith(status: LocationStatus.checkingPermission);
    
    final permStatus = await _permissionService.checkPermission();
    if (permStatus == LocationPermissionStatus.granted) {
      await fetchCurrentGpsLocation();
    } else {
      final reqStatus = await _permissionService.requestPermission();
      if (reqStatus == LocationPermissionStatus.granted) {
        await fetchCurrentGpsLocation();
      } else {
        state = state.copyWith(
          status: LocationStatus.error,
          permissionGranted: false,
          errorMessage: 'Location permission denied. Please allow location access to find nearby services.',
        );
      }
    }
  }

  Future<void> fetchCurrentGpsLocation() async {
    state = state.copyWith(status: LocationStatus.fetchingLocation, permissionGranted: true);
    try {
      final pos = await _locationService.getCurrentLocation();
      final locationModel = await _geocodingService.getLocationFromCoordinates(pos.latitude, pos.longitude);
      
      _saveLocationToCache(locationModel);

      state = state.copyWith(
        status: LocationStatus.success,
        currentLocation: locationModel,
        selectedLocation: locationModel,
        isFollowingLocation: true,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        status: LocationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> updateSelectedLocationFromCoordinates(double lat, double lng) async {
    final updatedLocation = await _geocodingService.getLocationFromCoordinates(lat, lng);
    state = state.copyWith(
      selectedLocation: updatedLocation,
      isFollowingLocation: false,
    );
  }

  void setSelectedLocation(LocationModel location) {
    _saveLocationToCache(location);
    state = state.copyWith(
      selectedLocation: location,
      isFollowingLocation: false,
    );
  }

  void setFollowingLocation(bool following) {
    state = state.copyWith(isFollowingLocation: following);
  }

  void _saveLocationToCache(LocationModel location) {
    try {
      final box = Hive.box('customer_cache');
      final String fullAddr = '${location.area}, ${location.city}';
      box.put('location_address', fullAddr);
      box.put('location_latitude', location.latitude);
      box.put('location_longitude', location.longitude);
    } catch (_) {}
  }

  Future<bool> confirmAndSaveCurrentSelection() async {
    final locationToSave = state.selectedLocation ?? state.currentLocation;
    if (locationToSave == null) return false;

    state = state.copyWith(isSaving: true);
    try {
      _saveLocationToCache(locationToSave);
      await _saveService.confirmAndSaveLocation(locationToSave);
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, errorMessage: 'Failed to save location.');
      return false;
    }
  }
}
