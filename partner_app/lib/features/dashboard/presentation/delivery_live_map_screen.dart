import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Represents a nearby logistics/fulfillment dispatch hub displayed on the radar map.
class DeliveryHubInfo {
  final String id;
  final String name;
  final LatLng location;
  final String demandLevel;
  final int activeCouriers;

  const DeliveryHubInfo({
    required this.id,
    required this.name,
    required this.location,
    required this.demandLevel,
    required this.activeCouriers,
  });
}

class DeliveryLiveMapScreen extends StatefulWidget {
  final Map<String, dynamic> task;

  const DeliveryLiveMapScreen({
    super.key,
    this.task = const {},
  });

  @override
  State<DeliveryLiveMapScreen> createState() => _DeliveryLiveMapScreenState();
}

class _DeliveryLiveMapScreenState extends State<DeliveryLiveMapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;

  late LatLng _riderLocation;
  late LatLng _storeLocation;
  late LatLng _customerLocation;

  late String _orderCode;
  late String _storeName;
  late String _storePhone;
  late String _customerName;
  late String _customerAddress;
  late String _customerPhone;
  late double _earning;
  late String _deliveryStatus; // 'ON_THE_WAY_TO_STORE', 'ARRIVED_AT_STORE', 'OUT_FOR_DELIVERY', 'DELIVERED', 'STANDBY'

  List<DeliveryHubInfo> _nearbyHubs = [];

  bool get _isRadarMode {
    if (widget.task.isEmpty) return true;
    if (widget.task['is_radar_mode'] == true || widget.task['mode'] == 'radar') return true;
    final hasActiveOrder = widget.task['order_code'] != null ||
        widget.task['order_id'] != null ||
        widget.task['assignment_id'] != null;
    return !hasActiveOrder;
  }

  Timer? _simulationTimer;
  bool _isActionProcessing = false;
  bool _hasCenteredInitially = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _parseTaskData();
    _fetchRealGpsLocation();
    _startSimulatedMovement();
  }

  void _parseTaskData() {
    final t = widget.task;

    // Base coordinates (Jamnagar city center baseline)
    const baseLat = 22.4707;
    const baseLng = 70.0577;

    final riderLat = (t['rider_lat'] as num?)?.toDouble() ?? baseLat;
    final riderLng = (t['rider_lng'] as num?)?.toDouble() ?? baseLng;
    _riderLocation = LatLng(riderLat, riderLng);

    // Initialize nearby delivery hubs around rider location
    _nearbyHubs = [
      DeliveryHubInfo(
        id: 'HUB-01',
        name: 'Central Dispatch Hub (Zone A)',
        location: LatLng(riderLat + 0.0055, riderLng + 0.0050),
        demandLevel: 'High Demand',
        activeCouriers: 6,
      ),
      DeliveryHubInfo(
        id: 'HUB-02',
        name: 'East Express Station (Zone B)',
        location: LatLng(riderLat - 0.0062, riderLng + 0.0130),
        demandLevel: 'Normal Demand',
        activeCouriers: 3,
      ),
      DeliveryHubInfo(
        id: 'HUB-03',
        name: 'West Fulfillment Center',
        location: LatLng(riderLat + 0.0028, riderLng - 0.0125),
        demandLevel: 'Surge Demand',
        activeCouriers: 8,
      ),
    ];

    if (_isRadarMode) {
      _orderCode = 'ZONE-RADAR';
      _storeName = 'Nearby Delivery Hubs';
      _storePhone = '+91 1800 200 9999';
      _customerName = 'Zone Standby';
      _customerAddress = 'Within active service perimeter';
      _customerPhone = '';
      _earning = 0.0;
      _deliveryStatus = 'STANDBY';
      _storeLocation = _nearbyHubs.first.location;
      _customerLocation = _nearbyHubs[1].location;
      return;
    }

    final storeLat = (t['store_lat'] as num?)?.toDouble() ?? (baseLat + 0.004);
    final storeLng = (t['store_lng'] as num?)?.toDouble() ?? (baseLng + 0.003);
    _storeLocation = LatLng(storeLat, storeLng);

    final custLat = (t['customer_lat'] as num?)?.toDouble() ?? (baseLat + 0.012);
    final custLng = (t['customer_lng'] as num?)?.toDouble() ?? (baseLng + 0.016);
    _customerLocation = LatLng(custLat, custLng);

    _orderCode = (t['order_code'] ?? t['order_id'] ?? t['items_summary'] ?? 'ORD-8942').toString();
    if (!_orderCode.startsWith('#') && !_orderCode.startsWith('Order #')) {
      _orderCode = '#$_orderCode';
    }

    _storeName = (t['shop_name'] ?? t['store_name'] ?? 'FreshMart Supermarket').toString();
    _storePhone = (t['shop_phone'] ?? t['store_phone'] ?? '+91 98250 12345').toString();

    _customerName = (t['customer_name'] ?? 'Priya Sharma').toString();
    _customerAddress = (t['customer_address'] ?? t['address'] ?? 'Flat 402, Radhe Residency, Patel Colony').toString();
    _customerPhone = (t['customer_phone'] ?? '+91 99090 67890').toString();

    _earning = (t['earning'] as num?)?.toDouble() ?? 55.0;

    final rawStatus = (t['status'] ?? 'ACCEPTED').toString().toUpperCase();
    if (rawStatus == 'PICKED_UP' || rawStatus == 'OUT_FOR_DELIVERY') {
      _deliveryStatus = 'OUT_FOR_DELIVERY';
    } else if (rawStatus == 'DELIVERED') {
      _deliveryStatus = 'DELIVERED';
    } else {
      _deliveryStatus = 'ON_THE_WAY_TO_STORE';
    }
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
            _riderLocation = LatLng(pos.latitude, pos.longitude);
            if (_isRadarMode) {
              _nearbyHubs = [
                DeliveryHubInfo(
                  id: 'HUB-01',
                  name: 'Central Dispatch Hub (Zone A)',
                  location: LatLng(pos.latitude + 0.0055, pos.longitude + 0.0050),
                  demandLevel: 'High Demand',
                  activeCouriers: 6,
                ),
                DeliveryHubInfo(
                  id: 'HUB-02',
                  name: 'East Express Station (Zone B)',
                  location: LatLng(pos.latitude - 0.0062, pos.longitude + 0.0130),
                  demandLevel: 'Normal Demand',
                  activeCouriers: 3,
                ),
                DeliveryHubInfo(
                  id: 'HUB-03',
                  name: 'West Fulfillment Center',
                  location: LatLng(pos.latitude + 0.0028, pos.longitude - 0.0125),
                  demandLevel: 'Surge Demand',
                  activeCouriers: 8,
                ),
              ];
            }
          });
        }
      }
    } catch (_) {
      // Fallback coordinates are already configured safely
    }
  }

  void _startSimulatedMovement() {
    if (_isRadarMode) return;

    _simulationTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _deliveryStatus == 'DELIVERED') return;

      LatLng target;
      if (_deliveryStatus == 'ON_THE_WAY_TO_STORE') {
        target = _storeLocation;
      } else {
        target = _customerLocation;
      }

      final dLat = (target.latitude - _riderLocation.latitude) * 0.08;
      final dLng = (target.longitude - _riderLocation.longitude) * 0.08;

      final distToTarget = _calculateDistanceKm(_riderLocation, target);

      if (distToTarget < 0.15) {
        if (_deliveryStatus == 'ON_THE_WAY_TO_STORE') {
          setState(() {
            _deliveryStatus = 'ARRIVED_AT_STORE';
          });
        }
      } else {
        setState(() {
          _riderLocation = LatLng(
            _riderLocation.latitude + dLat,
            _riderLocation.longitude + dLng,
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
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

  double get _totalDistanceKm {
    if (_isRadarMode) return 0.0;
    if (_deliveryStatus == 'ON_THE_WAY_TO_STORE' || _deliveryStatus == 'ARRIVED_AT_STORE') {
      final leg1 = _calculateDistanceKm(_riderLocation, _storeLocation);
      final leg2 = _calculateDistanceKm(_storeLocation, _customerLocation);
      return leg1 + leg2;
    } else {
      return _calculateDistanceKm(_riderLocation, _customerLocation);
    }
  }

  int get _calculatedEtaMins {
    if (_isRadarMode) return 0;
    // Average urban courier speed ~22 km/h
    final mins = (_totalDistanceKm / 22.0 * 60.0).round();
    return mins.clamp(2, 60);
  }

  void _zoomIn() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1.0);
  }

  void _zoomOut() {
    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1.0);
  }

  void _recenterMap() {
    if (_isRadarMode) {
      final points = [_riderLocation, ..._nearbyHubs.map((h) => h.location)];
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(top: 140, bottom: 200, left: 45, right: 45),
        ),
      );
    } else {
      final bounds = LatLngBounds.fromPoints([_riderLocation, _storeLocation, _customerLocation]);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.only(top: 140, bottom: 220, left: 45, right: 45),
        ),
      );
    }
  }

  void _centerOnRider() {
    _mapController.move(_riderLocation, 16.0);
  }

  void _showCallBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                const Text(
                  'Quick Contact Support',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Direct call dispatch for orders in progress',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 20),

                // Call Store Tile
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  tileColor: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB)),
                  ),
                  title: Text(
                    _storeName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    'Store Pickup Partner • $_storePhone',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2563EB),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling Store: $_storeName ($_storePhone)...'),
                        backgroundColor: const Color(0xFF2563EB),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // Call Customer Tile
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  tileColor: const Color(0xFFF8FAFC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFFECFDF5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF16A34A)),
                  ),
                  title: Text(
                    _customerName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    'Customer (Dropoff) • $_customerPhone',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.phone_rounded, color: Colors.white, size: 18),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Calling Customer: $_customerName ($_customerPhone)...'),
                        backgroundColor: const Color(0xFF16A34A),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompleteDeliveryOtpDialog() {
    final otpController = TextEditingController();
    final expectedOtp = widget.task['delivery_pin']?.toString() ?? '4829';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 26),
            SizedBox(width: 8),
            Text('Confirm Handover', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hand packages to $_customerName at $_customerAddress.\n\nAsk customer for the 4-digit Delivery PIN:',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '----',
                counterText: '',
                helperText: 'Demo Verification PIN: $expectedOtp',
                helperStyle: const TextStyle(color: Color(0xFF16A34A), fontSize: 11),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final entered = otpController.text.trim();
              if (entered.isNotEmpty && entered != expectedOtp) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Invalid PIN. Please enter correct 4-digit PIN ($expectedOtp)'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.pop(ctx);
              await _completeDeliveryAction();
            },
            child: const Text('Verify & Settle', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _completeDeliveryAction() async {
    setState(() => _isActionProcessing = true);

    final assignmentId = widget.task['assignment_id'] ?? widget.task['id'];
    final orderId = widget.task['order_id'] ?? widget.task['id'] ?? widget.task['order_code'];
    final syncBookingId = (widget.task['booking_id'] ?? widget.task['order_id'] ?? widget.task['assignment_id'] ?? widget.task['id'] ?? _orderCode).toString();

    // 1. Update delivery_assignments in Supabase
    try {
      if (assignmentId != null) {
        final client = Supabase.instance.client;
        try {
          await client.from('delivery_assignments').update({
            'status': 'DELIVERED',
            'delivered_at': DateTime.now().toIso8601String(),
          }).eq('assignment_id', assignmentId);
        } catch (_) {}

        // Record tracking
        try {
          await client.from('delivery_tracking').insert({
            'assignment_id': assignmentId,
            'latitude': _riderLocation.latitude,
            'longitude': _riderLocation.longitude,
            'accuracy': 4.0,
            'speed': 0.0,
            'recorded_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}

        // Record history
        try {
          await client.from('delivery_status_history').insert({
            'assignment_id': assignmentId,
            'status': 'DELIVERED',
            'latitude': _riderLocation.latitude,
            'longitude': _riderLocation.longitude,
            'remarks': 'Delivered via OpenStreetMap Live Navigation',
            'changed_at': DateTime.now().toIso8601String(),
          });
        } catch (_) {}
      }
    } catch (_) {}

    // 2. Update orders status to 'Delivered' in Supabase
    try {
      if (orderId != null) {
        final client = Supabase.instance.client;
        try {
          await client.from('orders').update({
            'status': 'Delivered',
            'order_status': 'Delivered',
            'delivered_at': DateTime.now().toIso8601String(),
          }).eq('order_id', orderId);
        } catch (_) {
          try {
            final cleanCode = _orderCode.replaceAll('#', '').trim();
            await client.from('orders').update({
              'status': 'Delivered',
              'order_status': 'Delivered',
              'delivered_at': DateTime.now().toIso8601String(),
            }).eq('order_code', cleanCode);
          } catch (_) {}
        }
      }
    } catch (_) {}

    // 3. Update LiveBookingSyncService milestone and status to 'DELIVERED'
    try {
      await LiveBookingSyncService.instance.updateMilestone(syncBookingId, 'DELIVERED');
      await LiveBookingSyncService.instance.updateBookingStatus(syncBookingId, 'DELIVERED');
      final existingBooking = LiveBookingSyncService.instance.getBooking(syncBookingId);
      if (existingBooking != null) {
        await LiveBookingSyncService.instance.submitBooking({
          ...existingBooking,
          'status': 'DELIVERED',
          'service_status': 'COMPLETED',
          'delivered_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (_) {}

    if (!mounted) return;

    setState(() {
      _deliveryStatus = 'DELIVERED';
      _isActionProcessing = false;
    });

    // 4. Pop and return to delivery dashboard with success notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '✓ Delivery Completed! Order $_orderCode marked delivered. ₹${_earning.toStringAsFixed(0)} credited.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );

    if (Navigator.canPop(context)) {
      Navigator.pop(context, true);
    } else {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        context.go('/dashboard/delivery');
      }
    }
  }

  Future<void> completeDelivery() async {
    await _completeDeliveryAction();
  }

  Widget _buildPulseRiderMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final v = _pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outermost pulsing ring
            Container(
              width: 32 + (v * 38),
              height: 32 + (v * 38),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.deliveryOrangePrimary.withValues(alpha: 0.35 * (1.0 - v)),
                border: Border.all(
                  color: AppColors.deliveryOrangePrimary.withValues(alpha: 0.6 * (1.0 - v)),
                  width: 1.5,
                ),
              ),
            ),
            // Inner secondary ring
            Container(
              width: 28 + (((v + 0.5) % 1.0) * 26),
              height: 28 + (((v + 0.5) % 1.0) * 26),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.deliveryOrangePrimary.withValues(alpha: 0.2 * (1.0 - ((v + 0.5) % 1.0))),
              ),
            ),
            // Rider scooter center badge
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.deliveryOrangePrimary, AppColors.deliveryOrangeDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x66EA580C),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.two_wheeler_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStoreMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFF1E40AF),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Text(
            'STORE PICKUP',
            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  Widget _buildCustomerMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFDC2626),
            borderRadius: BorderRadius.circular(6),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
          ),
          child: const Text(
            'CUSTOMER DROP',
            style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
            ],
          ),
          child: const Icon(Icons.flag_rounded, color: Colors.white, size: 22),
        ),
      ],
    );
  }

  Widget _buildHubMarker(DeliveryHubInfo hub) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${hub.name}: ${hub.demandLevel} • ${hub.activeCouriers} active couriers'),
            backgroundColor: const Color(0xFF4F46E5),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(6),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Text(
              hub.name,
              style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF4F46E5),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.hub_rounded, color: Colors.white, size: 19),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderTopCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Order code & ETA/Distance chip row
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.inventory_2_rounded, size: 14, color: AppColors.deliveryOrangePrimary),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _orderCode,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: AppColors.deliveryOrangePrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${_totalDistanceKm.toStringAsFixed(1)} km',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$_calculatedEtaMins min ETA',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Store name
          Row(
            children: [
              const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF2563EB)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Pickup: $_storeName',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Customer address
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFEF4444)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Dropoff: $_customerAddress',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadarTopCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.radar_rounded, size: 14, color: Color(0xFF16A34A)),
                    SizedBox(width: 4),
                    Text(
                      'DELIVERY ZONE RADAR',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Color(0xFF16A34A),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hub_rounded, size: 13, color: Color(0xFF2563EB)),
                    const SizedBox(width: 4),
                    Text(
                      '${_nearbyHubs.length} Nearby Hubs',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Live Courier Radar & Fleet View',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.location_searching_rounded, size: 14, color: Color(0xFF64748B)),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Monitoring active coverage zone • Ready to accept new orders',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveOrderBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Call Customer / Store Action Button
          Expanded(
            flex: 4,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: Color(0xFF2563EB)),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Call Support',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              onPressed: _showCallBottomSheet,
            ),
          ),
          const SizedBox(width: 8),

          // Complete Delivery / Milestone Action Button
          Expanded(
            flex: 6,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _deliveryStatus == 'ARRIVED_AT_STORE'
                    ? const Color(0xFF2563EB)
                    : AppColors.deliveryOrangePrimary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _isActionProcessing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Icon(
                      _deliveryStatus == 'ARRIVED_AT_STORE'
                          ? Icons.shopping_bag_outlined
                          : Icons.check_circle_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _isActionProcessing
                      ? 'Processing...'
                      : (_deliveryStatus == 'ARRIVED_AT_STORE' ? 'Confirm Store Pickup' : 'Complete Delivery'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              onPressed: _isActionProcessing
                  ? null
                  : () {
                      if (_deliveryStatus == 'ARRIVED_AT_STORE') {
                        setState(() {
                          _deliveryStatus = 'OUT_FOR_DELIVERY';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Order picked up! En route to customer dropoff.'),
                            backgroundColor: Color(0xFF2563EB),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else if (widget.task['require_otp'] == false) {
                        _completeDeliveryAction();
                      } else {
                        _showCompleteDeliveryOtpDialog();
                      }
                    },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadarBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Focus GPS
          Expanded(
            flex: 5,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.my_location_rounded, size: 16, color: AppColors.deliveryOrangePrimary),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Focus My GPS',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
              ),
              onPressed: _centerOnRider,
            ),
          ),
          const SizedBox(width: 8),

          // Return to Orders / Dashboard
          Expanded(
            flex: 5,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deliveryOrangePrimary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.dashboard_rounded, size: 16, color: Colors.white),
              label: const FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Orders Queue',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                  ),
                ),
              ),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/dashboard/delivery');
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routePoints = [_riderLocation, _storeLocation, _customerLocation];

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full interactive OpenStreetMap powered by flutter_map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _riderLocation,
              initialZoom: 14.5,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              onMapReady: () {
                if (!_hasCenteredInitially) {
                  _hasCenteredInitially = true;
                  _recenterMap();
                }
              },
            ),
            children: [
              // 2. Real OpenStreetMap TileLayer with userAgent com.servicehub.partner
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.servicehub.partner',
              ),

              // 4. Route polyline connecting rider -> store -> destination
              PolylineLayer<Object>(
                polylines: _isRadarMode
                    ? <Polyline<Object>>[]
                    : <Polyline<Object>>[
                        // High contrast road casing polyline
                        Polyline<Object>(
                          points: routePoints,
                          strokeWidth: 8.0,
                          color: const Color(0x33EA580C),
                        ),
                        // Core navigation route line
                        Polyline<Object>(
                          points: routePoints,
                          strokeWidth: 4.5,
                          color: AppColors.deliveryOrangePrimary,
                        ),
                      ],
              ),

              // 3. Real markers
              MarkerLayer(
                markers: _isRadarMode
                    ? [
                        // Rider live location marker with delivery scooter icon and pulse ring
                        Marker(
                          point: _riderLocation,
                          width: 76,
                          height: 76,
                          child: _buildPulseRiderMarker(),
                        ),

                        // Nearby delivery hubs
                        for (final hub in _nearbyHubs)
                          Marker(
                            point: hub.location,
                            width: 130,
                            height: 64,
                            child: _buildHubMarker(hub),
                          ),
                      ]
                    : [
                        // Rider live location marker with delivery scooter icon and pulse ring
                        Marker(
                          point: _riderLocation,
                          width: 76,
                          height: 76,
                          child: _buildPulseRiderMarker(),
                        ),

                        // Store pickup location marker
                        Marker(
                          point: _storeLocation,
                          width: 90,
                          height: 80,
                          child: _buildStoreMarker(),
                        ),

                        // Customer dropoff location marker (destination flag/pin)
                        Marker(
                          point: _customerLocation,
                          width: 96,
                          height: 80,
                          child: _buildCustomerMarker(),
                        ),
                      ],
              ),
            ],
          ),

          // 5. Top Bar: Back Button & Top Information Card
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button row
                Row(
                  children: [
                    Material(
                      color: Colors.white,
                      shape: const CircleBorder(),
                      elevation: 4,
                      shadowColor: Colors.black26,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          } else {
                            context.go('/dashboard/delivery');
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A), size: 22),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF16A34A),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                              child: Text(
                                'LIVE GPS TRACKING ACTIVE',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF16A34A),
                                  letterSpacing: 0.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Top Card showing active order code OR Delivery Zone Radar
                _isRadarMode ? _buildRadarTopCard() : _buildActiveOrderTopCard(),
              ],
            ),
          ),

          // 5. Interactive Side Controls: Zoom In / Out & GPS Re-center
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // GPS Re-center button (Focus Rider)
                Material(
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _centerOnRider,
                    child: const Padding(
                      padding: EdgeInsets.all(11),
                      child: Icon(Icons.my_location_rounded, color: AppColors.deliveryOrangePrimary, size: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Re-center full route bounds
                Material(
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black26,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _recenterMap,
                    child: const Padding(
                      padding: EdgeInsets.all(11),
                      child: Icon(Icons.route_rounded, color: Color(0xFF2563EB), size: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Zoom in / Zoom out buttons (+ / -)
                Material(
                  color: Colors.white,
                  elevation: 4,
                  shadowColor: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: _zoomIn,
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.add, color: Color(0xFF0F172A), size: 20),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFE2E8F0)),
                      InkWell(
                        onTap: _zoomOut,
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.remove, color: Color(0xFF0F172A), size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 5. Bottom Action Bar: "Call Customer / Store" and "Complete Delivery" (or Radar Controls)
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 14,
            child: _isRadarMode ? _buildRadarBottomBar() : _buildActiveOrderBottomBar(),
          ),
        ],
      ),
    );
  }
}
