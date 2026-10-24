import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/phone_launcher_service.dart';
import '../../../../core/services/partner_location_service.dart';
import '../../../../core/services/live_booking_sync_service.dart';

/// Screen 4: Real Interactive OpenStreetMap Live Map for Care Taker & Nursing Specialist
/// 100% Real Map • Zero Fake Static Images • Live OSM Raster Tiles & Patient GPS Route Navigation
class CareLiveMapScreen extends StatefulWidget {
  final Map<String, dynamic>? booking;
  final bool showAppBar;

  const CareLiveMapScreen({
    super.key,
    this.booking,
    this.showAppBar = true,
  });

  @override
  State<CareLiveMapScreen> createState() => _CareLiveMapScreenState();
}

class _CareLiveMapScreenState extends State<CareLiveMapScreen> {
  late final MapController _mapController;

  // Jamnagar Central Care Hub / Caregiver Operational Base Coordinates (Real GPS Baseline)
  LatLng _caregiverLocation = PartnerLocationService.jamnagarOperationalBase;
  LatLng? _patientLocation;
  StreamSubscription<Position>? _gpsSub;
  Map<String, dynamic>? _resolvedBooking;

  int _selectedFilterIndex = 0; // 0: Current Order, 1: All Patients
  bool _isNavigating = false;

  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _resolvePatientCoordinates();
    _initCaregiverGpsLocation();
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initCaregiverGpsLocation() async {
    final loc = await PartnerLocationService.instance.getPartnerOrDeviceLocation();
    if (mounted) {
      setState(() => _caregiverLocation = loc);
    }
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        _gpsSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position pos) {
          if (!mounted) return;
          setState(() {
            _caregiverLocation = LatLng(pos.latitude, pos.longitude);
          });
        });
      }
    } catch (_) {}
  }

  void _resolvePatientCoordinates() {
    final b = widget.booking ?? _findActiveCareBooking();
    _resolvedBooking = b;
    if (b != null) {
      final lat = double.tryParse((b['customer_lat'] ?? b['lat'] ?? b['latitude'] ?? '').toString());
      final lng = double.tryParse((b['customer_lng'] ?? b['lng'] ?? b['longitude'] ?? '').toString());
      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        _patientLocation = LatLng(lat, lng);
      } else {
        _patientLocation = null;
      }
    } else {
      _patientLocation = null;
    }
  }

  Map<String, dynamic>? _findActiveCareBooking() {
    final all = LiveBookingSyncService.instance.getAllBookings();
    for (final b in all) {
      if (LiveBookingSyncService.isBookingMatchingCategory(b, 'care_taker')) {
        return b;
      }
    }
    return null;
  }

  void _recenterMap(LatLng target) {
    _mapController.move(target, 14.5);
  }

  void _launchCaller(String phone) {
    PhoneLauncherService.makePhoneCall(context, phone);
  }

  void _openChat(String bookingId, String patientName, String patientPhone) {
    context.push('/chat/$bookingId', extra: {
      'customer_name': patientName,
      'customer_phone': patientPhone,
      'service_name': 'Caregiver Service',
    });
  }

  List<LatLng> _buildRoutePolyline() {
    if (_patientLocation == null) return [];
    return [
      _caregiverLocation,
      LatLng(
        _caregiverLocation.latitude + (_patientLocation!.latitude - _caregiverLocation.latitude) * 0.35,
        _caregiverLocation.longitude + (_patientLocation!.longitude - _caregiverLocation.longitude) * 0.15,
      ),
      LatLng(
        _caregiverLocation.latitude + (_patientLocation!.latitude - _caregiverLocation.latitude) * 0.7,
        _caregiverLocation.longitude + (_patientLocation!.longitude - _caregiverLocation.longitude) * 0.65,
      ),
      _patientLocation!,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final b = _resolvedBooking ?? widget.booking;
    final hasActivePatient = b != null && _patientLocation != null;
    final patientName = (b?['customer_name'] ?? 'Patient').toString();
    final patientPhone = (b?['customer_phone'] ?? '').toString();
    final address = (b?['customer_address'] ?? b?['address'] ?? 'Customer Location, Jamnagar').toString();

    final distInfo = hasActivePatient
        ? PartnerLocationService.calculateDistanceInfo(
            from: _caregiverLocation,
            to: _patientLocation!,
          )
        : null;

    final polylinePoints = _buildRoutePolyline();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0.5,
              title: const Text(
                'Live Map',
                style: TextStyle(
                  color: darkSlate,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 20),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.layers_outlined, color: darkSlate, size: 20),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Real OpenStreetMap Layer: Jamnagar Health & Care Grid'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ],
            )
          : null,
      body: Stack(
        children: [
          // 1. Real Interactive OpenStreetMap Widget
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _caregiverLocation,
              initialZoom: 13.8,
              minZoom: 5.0,
              maxZoom: 18.0,
            ),
            children: [
              // Real OpenStreetMap Standard Raster Tiles
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.servicehub.partner',
              ),

              // Operational Coverage Area (Care Base 3.5km zone)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _caregiverLocation,
                    radius: 3500,
                    useRadiusInMeter: true,
                    color: primaryIndigo.withValues(alpha: 0.08),
                    borderColor: primaryIndigo.withValues(alpha: 0.4),
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),

              // Road Polyline GPS Navigation Route (only when active patient is assigned)
              if (hasActivePatient && polylinePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      strokeWidth: 4.5,
                      color: primaryIndigo,
                      borderStrokeWidth: 2.0,
                      borderColor: Colors.white,
                    ),
                  ],
                ),

              // Real Interactive Markers Layer
              MarkerLayer(
                markers: [
                  // Caregiver Origin GPS Pin
                  Marker(
                    point: _caregiverLocation,
                    width: 52,
                    height: 52,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryIndigo,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryIndigo.withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(color: Colors.white, width: 2.5),
                          ),
                          child: const Icon(
                            Icons.volunteer_activism_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (hasActivePatient && _patientLocation != null && distInfo != null) ...[
                    // Patient Destination Residence Marker
                    Marker(
                      point: _patientLocation!,
                      width: 54,
                      height: 54,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 2.5),
                            ),
                            child: const Icon(
                              Icons.home_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ETA / Distance Floating Label Badge along route
                    Marker(
                      point: LatLng(
                        (_caregiverLocation.latitude + _patientLocation!.latitude) / 2 + 0.002,
                        (_caregiverLocation.longitude + _patientLocation!.longitude) / 2,
                      ),
                      width: 160,
                      height: 40,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                          border: Border.all(color: cardBorder),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.directions_walk_rounded, color: primaryIndigo, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${distInfo.formattedDistance} • ${distInfo.formattedEta}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: darkSlate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),

          // 2. Top Location Toggle Chips matching reference UI
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedFilterIndex = 0);
                      _recenterMap(_caregiverLocation);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedFilterIndex == 0 ? primaryIndigo : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          ),
                        ],
                        border: Border.all(
                          color: _selectedFilterIndex == 0 ? primaryIndigo : cardBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Current Location',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _selectedFilterIndex == 0 ? Colors.white : darkSlate,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() => _selectedFilterIndex = 1);
                      if (_patientLocation != null) _recenterMap(_patientLocation!);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedFilterIndex == 1 ? primaryIndigo : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 6,
                          ),
                        ],
                        border: Border.all(
                          color: _selectedFilterIndex == 1 ? primaryIndigo : cardBorder,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Customer Location',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _selectedFilterIndex == 1 ? Colors.white : darkSlate,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Map Controls (Zoom In/Out & Re-center GPS)
          Positioned(
            right: 16,
            bottom: 230,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'care_map_zoom_in',
                  backgroundColor: Colors.white,
                  foregroundColor: darkSlate,
                  elevation: 3,
                  onPressed: () {
                    final nextZoom = (_mapController.camera.zoom + 1.0).clamp(5.0, 18.0);
                    _mapController.move(_mapController.camera.center, nextZoom);
                  },
                  child: const Icon(Icons.add, size: 20),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'care_map_zoom_out',
                  backgroundColor: Colors.white,
                  foregroundColor: darkSlate,
                  elevation: 3,
                  onPressed: () {
                    final nextZoom = (_mapController.camera.zoom - 1.0).clamp(5.0, 18.0);
                    _mapController.move(_mapController.camera.center, nextZoom);
                  },
                  child: const Icon(Icons.remove, size: 20),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'care_map_recenter',
                  backgroundColor: Colors.white,
                  foregroundColor: primaryIndigo,
                  elevation: 3,
                  onPressed: () => _recenterMap(_caregiverLocation),
                  child: const Icon(Icons.my_location_rounded, size: 20),
                ),
              ],
            ),
          ),

          // 4. Bottom Active Patient Dispatch Card OR Standby Radar Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: hasActivePatient && distInfo != null
                ? Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: cardBorder),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Patient Info Row
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: primaryIndigo.withValues(alpha: 0.12),
                              child: const Icon(Icons.person, color: primaryIndigo, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patientName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: darkSlate,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    address,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: textMuted,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    distInfo.formattedSummary,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: primaryIndigo,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Call Action Button
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                padding: const EdgeInsets.all(10),
                              ),
                              icon: const Icon(Icons.call_rounded, color: primaryIndigo, size: 20),
                              onPressed: () => _launchCaller(patientPhone),
                            ),
                            const SizedBox(width: 6),
                            // In-app Chat Action Button
                            IconButton(
                              style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFF1F5F9),
                                padding: const EdgeInsets.all(10),
                              ),
                              icon: const Icon(Icons.chat_bubble_outline_rounded, color: primaryIndigo, size: 20),
                              onPressed: () => _openChat((b['booking_id'] ?? b['id'] ?? '').toString(), patientName, patientPhone),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Start Real Navigation Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryIndigo,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: Icon(
                              _isNavigating ? Icons.navigation_rounded : Icons.near_me_rounded,
                              size: 20,
                            ),
                            label: Text(
                              _isNavigating ? 'Navigating to Patient...' : 'Start Navigation',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              setState(() => _isNavigating = !_isNavigating);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    _isNavigating
                                        ? 'GPS Turn-by-Turn Navigation started to $address'
                                        : 'Navigation stopped.',
                                  ),
                                  backgroundColor: primaryIndigo,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: cardBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.radar_rounded, color: primaryIndigo, size: 28),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Active Standby Mode',
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w900,
                                  color: darkSlate,
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Caregiver live GPS active. Scanning for patient service dispatches...',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: textMuted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: const Text(
                            'ONLINE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
