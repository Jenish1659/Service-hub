import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';

import '../providers/location_provider.dart';
import '../models/location_model.dart';
import '../services/map_service.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/center_location_marker.dart';
import '../widgets/location_card.dart';
import '../widgets/current_location_button.dart';
import '../widgets/map_zoom_controls.dart';
import '../widgets/nearby_provider_marker.dart';
import '../widgets/availability_popup.dart';
import '../widgets/book_for_someone_else_sheet.dart';
import 'location_search_screen.dart';

import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/services/routing_service.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final MapController _mapController = MapController();
  Timer? _dragDebounceTimer;
  bool _isMapDragging = false;
  bool _hasCenteredOnUserLocation = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final locState = ref.read(locationProvider);
      final locationNotifier = ref.read(locationProvider.notifier);

      if (locState.selectedLocation != null) {
        _mapController.move(
          LatLng(locState.selectedLocation!.latitude, locState.selectedLocation!.longitude),
          MapService.defaultZoom,
        );
        setState(() {
          _hasCenteredOnUserLocation = true;
        });
      } else {
        await locationNotifier.fetchCurrentGpsLocation();
        final cur = ref.read(locationProvider).currentLocation;
        if (cur != null && mounted) {
          _mapController.move(
            LatLng(cur.latitude, cur.longitude),
            MapService.defaultZoom,
          );
          setState(() {
            _hasCenteredOnUserLocation = true;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _dragDebounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _onMapPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      if (!_isMapDragging) {
        setState(() {
          _isMapDragging = true;
        });
      }
      _dragDebounceTimer?.cancel();
      _dragDebounceTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isMapDragging = false;
          });
          final center = camera.center;
          ref.read(locationProvider.notifier).updateSelectedLocationFromCoordinates(
                center.latitude,
                center.longitude,
              );
        }
      });
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom < MapService.maxZoom) {
      _mapController.move(_mapController.camera.center, currentZoom + 1.0);
    }
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    if (currentZoom > MapService.minZoom) {
      _mapController.move(_mapController.camera.center, currentZoom - 1.0);
    }
  }

  List<Marker> _loadRealNearbyProviderMarkers(double centerLat, double centerLng) {
    final markers = <Marker>[];
    try {
      final allVerifications = LiveBookingSyncService.instance.getAllPartnerVerifications();
      for (final p in allVerifications) {
        final status = (p['status'] ?? p['verification_status'] ?? '').toString().toUpperCase();
        if (status != 'APPROVED' && status != 'VERIFIED') continue;

        final lat = (p['latitude'] ?? p['lat']) as num?;
        final lng = (p['longitude'] ?? p['lng']) as num?;
        if (lat == null || lng == null) continue;

        final pLat = lat.toDouble();
        final pLng = lng.toDouble();

        final dist = OsrmRoutingService.computeHaversineDistanceKm(centerLat, centerLng, pLat, pLng);
        if (dist <= 10.0) {
          final name = (p['name'] ?? p['full_name'] ?? 'Provider').toString();
          final cat = (p['category_name'] ?? p['category'] ?? 'Service').toString();
          markers.add(
            Marker(
              point: LatLng(pLat, pLng),
              width: 120,
              height: 36,
              child: NearbyProviderMarker(providerName: name, category: cat),
            ),
          );
        }
      }

      // Check active jobs for real-time technician live coordinates
      final allBookings = LiveBookingSyncService.instance.getAllBookings();
      for (final b in allBookings) {
        final pLat = (b['partner_lat'] as num?)?.toDouble();
        final pLng = (b['partner_lng'] as num?)?.toDouble();
        final pName = (b['partner_name'] ?? '').toString();
        if (pLat != null && pLng != null && pName.isNotEmpty) {
          final dist = OsrmRoutingService.computeHaversineDistanceKm(centerLat, centerLng, pLat, pLng);
          if (dist <= 10.0) {
            markers.add(
              Marker(
                point: LatLng(pLat, pLng),
                width: 120,
                height: 36,
                child: NearbyProviderMarker(
                  providerName: pName,
                  category: (b['category_name'] ?? b['category'] ?? 'Technician').toString(),
                ),
              ),
            );
          }
        }
      }
    } catch (_) {}
    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final locationNotifier = ref.read(locationProvider.notifier);
    final serviceAreaService = ref.read(serviceAreaServiceProvider);

    // Auto-center map on customer's GPS location when permission/location becomes available
    ref.listen(locationProvider, (previous, next) {
      if (!_hasCenteredOnUserLocation && next.currentLocation != null) {
        _hasCenteredOnUserLocation = true;
        _mapController.move(
          LatLng(next.currentLocation!.latitude, next.currentLocation!.longitude),
          MapService.defaultZoom,
        );
      }
    });

    final selectedLoc = locationState.selectedLocation ?? locationState.currentLocation;
    final initialLat = selectedLoc?.latitude ?? MapService.defaultLatitude;
    final initialLng = selectedLoc?.longitude ?? MapService.defaultLongitude;

    final providerMarkers = _loadRealNearbyProviderMarkers(initialLat, initialLng);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // 1. Interactive OpenStreetMap Engine
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(initialLat, initialLng),
              initialZoom: MapService.defaultZoom,
              minZoom: MapService.minZoom,
              maxZoom: MapService.maxZoom,
              onPositionChanged: _onMapPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: MapService.osmTileUrl,
                userAgentPackageName: MapService.userAgentPackageName,
              ),
              MarkerLayer(markers: providerMarkers),
            ],
          ),

          // 2. Center Drag-to-Pin Marker
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 35.0),
              child: CenterLocationMarker(isMoving: _isMapDragging),
            ),
          ),

          // 3. Top Floating Search Bar & Back Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Color(0xff0052cc), size: 20),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: MapSearchBar(
                      currentSearchText: selectedLoc?.area,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
                        );
                        final updatedLoc = ref.read(locationProvider).selectedLocation;
                        if (updatedLoc != null) {
                          _mapController.move(
                            LatLng(updatedLoc.latitude, updatedLoc.longitude),
                            MapService.defaultZoom,
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Zoom Controls (+ / -)
          Positioned(
            right: 16,
            bottom: 290,
            child: MapZoomControls(
              onZoomIn: _zoomIn,
              onZoomOut: _zoomOut,
            ),
          ),

          // 5. Floating GPS Re-Center Button
          Positioned(
            right: 16,
            bottom: 230,
            child: CurrentLocationButton(
              onPressed: () async {
                await locationNotifier.fetchCurrentGpsLocation();
                final cur = ref.read(locationProvider).currentLocation;
                if (cur != null) {
                  _mapController.move(
                    LatLng(cur.latitude, cur.longitude),
                    MapService.defaultZoom,
                  );
                }
              },
            ),
          ),

          // 6. Bottom Address Confirmation Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: LocationCard(
              location: selectedLoc,
              isLoading: _isMapDragging || locationState.isSaving,
              onChangeTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
                );
              },
              onBookForSomeoneElseTap: selectedLoc == null
                  ? null
                  : () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (sheetContext) => BookForSomeoneElseSheet(
                          location: selectedLoc,
                          onSave: (recipientLoc) async {
                            try {
                              await ref.read(locationApiServiceProvider).saveCustomerLocation(recipientLoc);
                              final locationModel = LocationModel(
                                latitude: recipientLoc.latitude,
                                longitude: recipientLoc.longitude,
                                address: recipientLoc.address,
                                area: recipientLoc.area,
                                city: recipientLoc.city,
                                state: recipientLoc.state,
                                country: recipientLoc.country,
                                postalCode: recipientLoc.postalCode,
                              );
                              ref.read(locationProvider.notifier).setSelectedLocation(locationModel);
                            } catch (_) {}
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Booking address saved for ${recipientLoc.recipientName ?? "recipient"}'),
                                  backgroundColor: const Color(0xff15803d),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              if (context.canPop()) {
                                context.pop();
                              } else if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              } else {
                                context.go('/');
                              }
                            }
                          },
                        ),
                      );
                    },
              onConfirm: () async {
                if (selectedLoc == null) return;

                final isAvailable = await serviceAreaService.isServiceAvailable(
                  selectedLoc.city,
                  selectedLoc.latitude,
                  selectedLoc.longitude,
                );

                if (!isAvailable && context.mounted) {
                  showDialog(
                    context: context,
                    builder: (context) => AvailabilityPopup(
                      cityName: selectedLoc.city,
                      onSelectOtherCity: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
                        );
                      },
                    ),
                  );
                  return;
                }

                final success = await locationNotifier.confirmAndSaveCurrentSelection();
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Service location set to ${selectedLoc.area}, ${selectedLoc.city}'),
                      backgroundColor: const Color(0xff15803d),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  if (context.canPop()) {
                    context.pop();
                  } else if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    context.go('/');
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
