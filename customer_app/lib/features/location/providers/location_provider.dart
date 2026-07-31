import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/location_controller.dart';
import '../controllers/search_controller.dart';
import '../controllers/location_flow_controller.dart';
import '../controllers/map_controller.dart';
import '../services/service_area_service.dart';
import '../services/location_api_service.dart';

final locationProvider = StateNotifierProvider<LocationController, LocationState>((ref) {
  return LocationController();
});

final locationSearchProvider = StateNotifierProvider<LocationSearchController, LocationSearchState>((ref) {
  return LocationSearchController();
});

final locationFlowProvider = StateNotifierProvider<LocationFlowController, LocationFlowState>((ref) {
  return LocationFlowController();
});

final mapControllerProvider = Provider<ServiceHubMapController>((ref) {
  return ServiceHubMapController();
});

final serviceAreaServiceProvider = Provider<ServiceAreaService>((ref) {
  return ServiceAreaService();
});

final locationApiServiceProvider = Provider<LocationApiService>((ref) {
  return LocationApiService();
});
