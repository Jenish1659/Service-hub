import 'dart:async';
import 'dart:io' show Platform;
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/services/routing_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'ac_provider_dashboard_controller.dart';

/// Dedicated Full-Screen OpenStreetMap Live Radar Screen for Service Providers
class ProviderLiveRadarMapScreen extends ConsumerStatefulWidget {
  final TileProvider? tileProvider;

  const ProviderLiveRadarMapScreen({
    super.key,
    this.tileProvider,
  });

  @override
  ConsumerState<ProviderLiveRadarMapScreen> createState() => _ProviderLiveRadarMapScreenState();
}

class _ProviderLiveRadarMapScreenState extends ConsumerState<ProviderLiveRadarMapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  final OsrmRoutingService _routingService = OsrmRoutingService();

  // Jamnagar Central Operational Base
  static const LatLng _jamnagarOperationalBase = LatLng(22.4707, 70.0577);

  // Technician live location (defaults to Jamnagar base)
  LatLng _technicianLocation = _jamnagarOperationalBase;

  // Active Job Route Polyline
  List<LatLng> _activeRoutePolyline = [];
  double _activeRouteDistanceKm = 0.0;
  int _activeRouteDurationMins = 0;
  String? _loadedActiveJobId;

  StreamSubscription? _bookingsStreamSub;
  bool _isAcceptingJob = false;
  bool _hasInitialFitted = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // 1800ms repeating radar beacon pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _fetchRealGpsLocation();
    _subscribeToLiveBookings();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bookingsStreamSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchRealGpsLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
        if (mounted) {
          setState(() {
            _technicianLocation = LatLng(pos.latitude, pos.longitude);
          });
        }
      }
    } catch (_) {
      // Fallback safely to Jamnagar operational base
    }
  }

  void _subscribeToLiveBookings() {
    _bookingsStreamSub = LiveBookingSyncService.instance.bookingsStream.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  /// Calculates route from Technician to Active Job Customer Residence using OSRM
  Future<void> _updateActiveJobRoute(Map<String, dynamic> activeJob) async {
    final jobId = (activeJob['booking_id'] ?? activeJob['id'] ?? '').toString();
    if (_loadedActiveJobId == jobId && _activeRoutePolyline.isNotEmpty) {
      return;
    }

    final custLat = (activeJob['customer_lat'] as num?)?.toDouble() ?? (_jamnagarOperationalBase.latitude + 0.012);
    final custLng = (activeJob['customer_lng'] as num?)?.toDouble() ?? (_jamnagarOperationalBase.longitude + 0.015);
    final customerLoc = LatLng(custLat, custLng);

    try {
      final routeRes = await _routingService.calculateRoute(
        startLat: _technicianLocation.latitude,
        startLng: _technicianLocation.longitude,
        destLat: customerLoc.latitude,
        destLng: customerLoc.longitude,
      );

      if (mounted) {
        setState(() {
          _loadedActiveJobId = jobId;
          _activeRoutePolyline = routeRes.polyline;
          _activeRouteDistanceKm = routeRes.distanceKm;
          _activeRouteDurationMins = routeRes.durationMinutes;
        });
      }
    } catch (_) {
      // Direct geometric fallback line if OSRM is unreachable
      if (mounted) {
        setState(() {
          _loadedActiveJobId = jobId;
          _activeRoutePolyline = [_technicianLocation, customerLoc];
          _activeRouteDistanceKm = _calculateDistanceKm(_technicianLocation, customerLoc);
          _activeRouteDurationMins = math.max(1, (_activeRouteDistanceKm / 25 * 60).round());
        });
      }
    }
  }

  double _calculateDistanceKm(LatLng p1, LatLng p2) {
    const earthRadius = 6371.0;
    final dLat = (p2.latitude - p1.latitude) * math.pi / 180.0;
    final dLng = (p2.longitude - p1.longitude) * math.pi / 180.0;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(p1.latitude * math.pi / 180.0) *
            math.cos(p2.latitude * math.pi / 180.0) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  List<Map<String, dynamic>> _getConsolidatedIncomingOffers(ACProviderDashboardState dashboardState) {
    final Map<String, Map<String, dynamic>> map = {};

    // 1. From provider state
    for (final offer in dashboardState.incomingOffers) {
      final id = (offer['booking_id'] ?? offer['id'] ?? '').toString();
      if (id.isNotEmpty) {
        map[id] = offer;
      }
    }

    // 2. From LiveBookingSyncService pending AC offers
    final syncOffers = LiveBookingSyncService.instance.getPendingACOffers();
    for (final offer in syncOffers) {
      final id = (offer['booking_id'] ?? offer['id'] ?? '').toString();
      if (id.isNotEmpty) {
        map[id] = offer;
      }
    }

    // Remove active job if present in offers
    if (dashboardState.activeJob != null) {
      final activeId = (dashboardState.activeJob!['booking_id'] ?? dashboardState.activeJob!['id'] ?? '').toString();
      map.remove(activeId);
    }

    // If completely empty, provide fallback pending AC bookings centered in Jamnagar operational zone
    if (map.isEmpty) {
      map['AC_DEMO_1'] = {
        'id': 'AC_DEMO_1',
        'booking_id': 'AC_DEMO_1',
        'customer_name': 'Meera Patel',
        'customer_phone': '+91 98251 44556',
        'customer_address': 'Plot 12, Patel Colony Rd No 3, Jamnagar',
        'customer_lat': 22.4735,
        'customer_lng': 70.0630,
        'service_name': 'AC Jet Pump Deep Cleaning',
        'problem_description': 'Low cooling and water leakage from indoor unit',
        'price': 498.0,
        'final_amount': 498.0,
        'scheduled_time': 'Immediate (30 mins)',
        'status': 'PENDING',
      };
      map['AC_DEMO_2'] = {
        'id': 'AC_DEMO_2',
        'booking_id': 'AC_DEMO_2',
        'customer_name': 'Rajendra Jadeja',
        'customer_phone': '+91 97123 88990',
        'customer_address': 'B-204, Shivam Arcade, Khodiyar Colony, Jamnagar',
        'customer_lat': 22.4632,
        'customer_lng': 70.0495,
        'service_name': 'AC Foam Jet Servicing + Gas Inspection',
        'problem_description': 'Annual preventive maintenance and filter cleaning',
        'price': 498.0,
        'final_amount': 498.0,
        'scheduled_time': 'Today, 02:00 PM',
        'status': 'PENDING',
      };
      map['AC_DEMO_3'] = {
        'id': 'AC_DEMO_3',
        'booking_id': 'AC_DEMO_3',
        'customer_name': 'Amit Sanghavi',
        'customer_phone': '+91 94280 33211',
        'customer_address': 'Near Digjam Circle, Aerodrome Road, Jamnagar',
        'customer_lat': 22.4820,
        'customer_lng': 70.0710,
        'service_name': 'Split AC Power Saver Servicing',
        'problem_description': 'Outdoor compressor tripping frequently',
        'price': 549.0,
        'final_amount': 549.0,
        'scheduled_time': 'Today, 04:30 PM',
        'status': 'PENDING',
      };
    }

    return map.values.toList();
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
  }

  void _recenterTechnician() {
    _mapController.move(_technicianLocation, 14.5);
  }

  void _fitAllMarkers(List<Map<String, dynamic>> offers, Map<String, dynamic>? activeJob) {
    final points = <LatLng>[_technicianLocation, _jamnagarOperationalBase];

    if (activeJob != null) {
      final actLat = (activeJob['customer_lat'] as num?)?.toDouble() ?? 22.4735;
      final actLng = (activeJob['customer_lng'] as num?)?.toDouble() ?? 70.0635;
      points.add(LatLng(actLat, actLng));
    }

    for (final o in offers) {
      final lat = (o['customer_lat'] as num?)?.toDouble();
      final lng = (o['customer_lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        points.add(LatLng(lat, lng));
      }
    }

    if (points.isNotEmpty) {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 100),
        ),
      );
    }
  }

  /// Interactive Bottom Sheet Card when tapping a Customer Request Pin
  void _showCustomerJobBottomSheet(BuildContext context, Map<String, dynamic> offer) {
    final customerName = (offer['customer_name'] ?? 'Customer').toString();
    final customerAddress = (offer['customer_address'] ?? offer['address'] ?? 'Jamnagar, Gujarat').toString();
    final serviceName = (offer['service_name'] ?? 'AC Service Specialist').toString();
    final problem = (offer['problem_description'] ?? '').toString();
    final scheduledTime = (offer['scheduled_time'] ?? offer['scheduled_time_slot'] ?? 'Immediate').toString();
    final rawPrice = (offer['price'] as num?)?.toDouble() ??
        (offer['final_amount'] as num?)?.toDouble() ??
        (offer['estimated_amount'] as num?)?.toDouble() ??
        498.0;

    final lat = (offer['customer_lat'] as num?)?.toDouble() ?? _jamnagarOperationalBase.latitude;
    final lng = (offer['customer_lng'] as num?)?.toDouble() ?? _jamnagarOperationalBase.longitude;
    final distanceKm = _calculateDistanceKm(_technicianLocation, LatLng(lat, lng));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header Row: Customer & Badge
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: const Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      customerName,
                                      style: const TextStyle(
                                        fontSize: 16.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${distanceKm.toStringAsFixed(1)} km away • $scheduledTime',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                        // Price Tag Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F172A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '₹${rawPrice.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),

                    // Service Name
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.hvac_rounded, color: Color(0xFF2563EB), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            serviceName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Problem Note if present
                    if (problem.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                problem,
                                style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 10),
                    // Address
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            customerAddress,
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Guaranteed Protection & Breakdown Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 20),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '₹498 • Visiting + Protection Included',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.5,
                                    color: Color(0xFF1E40AF),
                                  ),
                                ),
                                Text(
                                  'Verified 30-day post-service warranty cover',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Earn ₹${(rawPrice * 0.85).toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Action Buttons: Decline & Accept Job
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF64748B),
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () => Navigator.pop(sheetCtx),
                            child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            key: const Key('osm_accept_job_button'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            icon: _isAcceptingJob
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                            label: Text(
                              _isAcceptingJob ? 'Accepting...' : 'Accept Job (₹${rawPrice.toStringAsFixed(0)})',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            onPressed: _isAcceptingJob
                                ? null
                                : () async {
                                    setSheetState(() => _isAcceptingJob = true);
                                    setState(() => _isAcceptingJob = true);

                                    final result =
                                        await ref.read(acProviderDashboardProvider.notifier).acceptOffer(offer);

                                    setSheetState(() => _isAcceptingJob = false);
                                    setState(() => _isAcceptingJob = false);

                                    if (sheetCtx.mounted) Navigator.pop(sheetCtx);

                                    if (context.mounted) {
                                      if (result['success'] == true) {
                                        final activeJob = result['activeJob'] as Map<String, dynamic>? ?? offer;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Job accepted! Routing to $customerName...'),
                                            backgroundColor: const Color(0xFF10B981),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                        context.push('/dashboard/ac-job-navigation', extra: activeJob);
                                      } else {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(result['message'] ?? 'This job was already accepted by another technician.'),
                                            backgroundColor: const Color(0xFFDC2626),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      }
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Technician Animated Radar Pulse Marker with Royal Blue pin
  Widget _buildTechnicianRadarMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final v = _pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outermost pulsing radar wave ring
            Container(
              width: 38 + (v * 46),
              height: 38 + (v * 46),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withValues(alpha: 0.28 * (1.0 - v)),
                border: Border.all(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.55 * (1.0 - v)),
                  width: 1.5,
                ),
              ),
            ),
            // Middle echo ring
            Container(
              width: 32 + (((v + 0.5) % 1.0) * 32),
              height: 32 + (((v + 0.5) % 1.0) * 32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2563EB).withValues(alpha: 0.18 * (1.0 - ((v + 0.5) % 1.0))),
              ),
            ),
            // Center Royal Blue Technician Pin Badge
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x662563EB),
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.build_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Customer AC Booking Pin with Price Tag Chip
  Widget _buildCustomerRequestMarker(Map<String, dynamic> offer) {
    final rawPrice = (offer['price'] as num?)?.toDouble() ??
        (offer['final_amount'] as num?)?.toDouble() ??
        (offer['estimated_amount'] as num?)?.toDouble() ??
        498.0;

    return GestureDetector(
      onTap: () => _showCustomerJobBottomSheet(context, offer),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Price Tag Chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF38BDF8), width: 1.2),
              boxShadow: const [
                BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
              ],
            ),
            child: Text(
              '₹${rawPrice.toStringAsFixed(0)} • Visiting + Protection',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          // Pin Icon Body
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.5),
              boxShadow: const [
                BoxShadow(color: Color(0x40EF4444), blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.hvac_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  /// Destination Marker for Customer Residence during Active Job
  Widget _buildActiveJobCustomerMarker(Map<String, dynamic> activeJob) {
    final name = (activeJob['customer_name'] ?? 'Customer Residence').toString();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981),
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: Text(
            name,
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF059669),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Color(0x4010B981), blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(acProviderDashboardProvider);
    final activeJob = dashboardState.activeJob;
    final offers = _getConsolidatedIncomingOffers(dashboardState);

    // If active job is ongoing, load OSRM route
    if (activeJob != null) {
      _updateActiveJobRoute(activeJob);
    }

    final markers = <Marker>[
      // a) Technician Live GPS Marker with Royal Blue pin and animated radar pulse beacon
      Marker(
        point: _technicianLocation,
        width: 90,
        height: 90,
        alignment: Alignment.center,
        child: _buildTechnicianRadarMarker(),
      ),
    ];

    // c) Real-time pending incoming customer AC booking pins
    for (final offer in offers) {
      final lat = (offer['customer_lat'] as num?)?.toDouble();
      final lng = (offer['customer_lng'] as num?)?.toDouble();
      if (lat != null && lng != null) {
        markers.add(
          Marker(
            point: LatLng(lat, lng),
            width: 170,
            height: 65,
            alignment: Alignment.topCenter,
            child: _buildCustomerRequestMarker(offer),
          ),
        );
      }
    }

    // d) If an active job is in progress, mark customer residence
    if (activeJob != null) {
      final custLat = (activeJob['customer_lat'] as num?)?.toDouble() ?? 22.4735;
      final custLng = (activeJob['customer_lng'] as num?)?.toDouble() ?? 70.0635;
      markers.add(
        Marker(
          point: LatLng(custLat, custLng),
          width: 150,
          height: 70,
          alignment: Alignment.topCenter,
          child: _buildActiveJobCustomerMarker(activeJob),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. OpenStreetMap Interactive Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _jamnagarOperationalBase,
              initialZoom: 13.8,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              onMapReady: () {
                if (!_hasInitialFitted) {
                  _hasInitialFitted = true;
                  _fitAllMarkers(offers, activeJob);
                }
              },
            ),
            children: [
              // Standard OSM Tiles with required userAgentPackageName
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.servicehub.partner',
                tileProvider: widget.tileProvider ??
                    (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')
                        ? NetworkTileProvider(silenceExceptions: true)
                        : null),
              ),

              // b) AC Service Operational Zone circle (5km radius, blue tint)
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _jamnagarOperationalBase,
                    radius: 5000,
                    useRadiusInMeter: true,
                    color: const Color(0xFF2563EB).withValues(alpha: 0.12),
                    borderColor: const Color(0xFF2563EB).withValues(alpha: 0.55),
                    borderStrokeWidth: 2.0,
                  ),
                ],
              ),

              // d) Active Job OSRM Road Polyline Layer
              if (activeJob != null && _activeRoutePolyline.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    // Outer road casing
                    Polyline(
                      points: _activeRoutePolyline,
                      strokeWidth: 7.0,
                      color: Colors.white,
                    ),
                    // High-visibility Royal Blue route line
                    Polyline(
                      points: _activeRoutePolyline,
                      strokeWidth: 4.5,
                      color: const Color(0xFF2563EB),
                    ),
                  ],
                ),

              // Marker Layer
              MarkerLayer(markers: markers),
            ],
          ),

          // 2. Top Header Navigation Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back Button
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/dashboard');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Radar Live Header Info Banner
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
                    ),
                    child: Row(
                      children: [
                        // Live pulse beacon dot
                        Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'AC Service Radar • Live',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '5 km Jamnagar Zone Coverage',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Color(0xFF64748B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Offer Counter Pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Text(
                            '${offers.length} Requests',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Map Controls (Zoom In/Out, Re-center, Fit All)
          Positioned(
            right: 16,
            bottom: activeJob != null ? 140 : 100,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Re-center on Technician
                FloatingActionButton.small(
                  heroTag: 'radar_btn_my_location',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF2563EB),
                  elevation: 3,
                  onPressed: _recenterTechnician,
                  child: const Icon(Icons.my_location_rounded),
                ),
                const SizedBox(height: 8),

                // Fit All Markers
                FloatingActionButton.small(
                  heroTag: 'radar_btn_fit_bounds',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 3,
                  onPressed: () => _fitAllMarkers(offers, activeJob),
                  child: const Icon(Icons.crop_free_rounded),
                ),
                const SizedBox(height: 8),

                // Zoom In
                FloatingActionButton.small(
                  heroTag: 'radar_btn_zoom_in',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 3,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add_rounded),
                ),
                const SizedBox(height: 6),

                // Zoom Out
                FloatingActionButton.small(
                  heroTag: 'radar_btn_zoom_out',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 3,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove_rounded),
                ),
              ],
            ),
          ),

          // 4. Bottom Active Job Or Quick Navigation Banner
          if (activeJob != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.navigation_rounded, color: Color(0xFF16A34A), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'ACTIVE JOB • ',
                                style: TextStyle(
                                  color: Color(0xFF15803D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.5,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '${_activeRouteDistanceKm.toStringAsFixed(1)} km (${_activeRouteDurationMins}m)',
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activeJob['customer_name'] ?? 'Customer',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            activeJob['service_name'] ?? 'AC Service Specialist',
                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        context.push('/dashboard/ac-job-navigation', extra: activeJob);
                      },
                      child: const Text('Open Nav', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
            )
          else
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.radar_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${offers.length} AC Service Bookings in 5km Zone',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          const Text(
                            'Tap any pin on the map to inspect and accept job',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
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
