import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/services/phone_launcher_service.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/services/routing_service.dart';
import '../../../../core/storage/local_registration_cache.dart';

/// Modal helper to present the OpenStreetMap interactive store map
class ShopkeeperStoreMapModal {
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SizedBox(
          height: MediaQuery.of(ctx).size.height * 0.90,
          child: const ShopkeeperStoreMapScreen(isModal: true),
        ),
      ),
    );
  }
}

/// Dedicated OpenStreetMap (OSM) Screen for Shopkeepers
/// Powered by flutter_map 7.0.2 and latlong2 0.9.1
class ShopkeeperStoreMapScreen extends StatefulWidget {
  final bool isModal;
  final List<Map<String, dynamic>>? initialCouriers;
  final List<Map<String, dynamic>>? initialOrders;

  const ShopkeeperStoreMapScreen({
    super.key,
    this.isModal = false,
    this.initialCouriers,
    this.initialOrders,
  });

  @override
  State<ShopkeeperStoreMapScreen> createState() => _ShopkeeperStoreMapScreenState();
}

class _ShopkeeperStoreMapScreenState extends State<ShopkeeperStoreMapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  StreamSubscription? _bookingsSub;

  // Jamnagar store central origin coordinate
  static const LatLng _jamnagarStoreBase = LatLng(22.4707, 70.0577);
  LatLng _storeLocation = _jamnagarStoreBase;

  String _shopName = 'ServiceHub Store';
  String _shopAddress = '';
  String _shopPhone = '';
  bool _isStoreOpen = true;

  // Radius visibility filters: 2km, 5km, 10km
  final Set<int> _activeRadii = {2, 5, 10};

  // Active customer orders and couriers
  List<Map<String, dynamic>> _activeOrders = [];
  List<Map<String, dynamic>> _nearbyCouriers = [];

  bool _hasCenteredInitially = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // 1800ms repeating radar beacon pulse animation for store origin
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _loadStoreProfile();
    _initNearbyCouriers();
    _loadLiveOrders();

    _bookingsSub = LiveBookingSyncService.instance.bookingsStream.listen((_) {
      if (mounted) _loadLiveOrders();
    });

    _fetchGpsLocation();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _bookingsSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchGpsLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 3),
        );
        if (mounted) {
          setState(() {
            _storeLocation = LatLng(pos.latitude, pos.longitude);
          });
        }
      }
    } catch (_) {
      // Safely default to Jamnagar base location
    }
  }

  Future<void> _loadStoreProfile() async {
    try {
      final cached = await LocalRegistrationCache.getActiveShopkeeper() ??
          await LocalRegistrationCache.getActivePartner();
      if (cached != null && mounted) {
        setState(() {
          final bName = (cached['business_name'] ?? cached['shop_name'] ?? cached['name'] ?? '').toString();
          if (bName.isNotEmpty) _shopName = bName;
          final addr = (cached['business_address'] ?? cached['address'] ?? '').toString();
          if (addr.isNotEmpty) _shopAddress = addr;
          final phone = (cached['phone'] ?? cached['mobile'] ?? '').toString();
          if (phone.isNotEmpty) _shopPhone = phone;
        });
      }
    } catch (_) {}
  }

  void _initNearbyCouriers() {
    if (widget.initialCouriers != null) {
      _nearbyCouriers = List.from(widget.initialCouriers!);
      return;
    }

    _nearbyCouriers = [];
    try {
      final allVerifications = LiveBookingSyncService.instance.getAllPartnerVerifications();
      for (final p in allVerifications) {
        final role = (p['role'] ?? p['partner_role'] ?? '').toString().toLowerCase();
        final status = (p['status'] ?? p['verification_status'] ?? '').toString().toUpperCase();
        if (role == 'delivery_agent' || role == 'delivery' || role == 'courier') {
          if (status == 'APPROVED' || status == 'VERIFIED') {
            final lat = (p['latitude'] ?? p['lat']) as num?;
            final lng = (p['longitude'] ?? p['lng']) as num?;
            if (lat != null && lng != null) {
              final riderLoc = LatLng(lat.toDouble(), lng.toDouble());
              final distKm = OsrmRoutingService.computeHaversineDistanceKm(
                _storeLocation.latitude,
                _storeLocation.longitude,
                riderLoc.latitude,
                riderLoc.longitude,
              );
              if (distKm <= 10.0) {
                _nearbyCouriers.add({
                  'id': p['id'] ?? p['user_id'] ?? 'courier_${_nearbyCouriers.length + 1}',
                  'name': p['name'] ?? p['full_name'] ?? 'Delivery Rider',
                  'rating': (p['rating'] as num?)?.toDouble() ?? 4.9,
                  'distance_km': double.parse(distKm.toStringAsFixed(1)),
                  'status': 'Available for Pickup',
                  'vehicle': (p['vehicle_type'] ?? p['vehicle'] ?? 'Scooter').toString(),
                  'phone': (p['phone'] ?? p['mobile'] ?? '').toString(),
                  'location': riderLoc,
                });
              }
            }
          }
        }
      }
    } catch (_) {}
  }

  void _loadLiveOrders() {
    if (widget.initialOrders != null) {
      if (mounted) {
        setState(() {
          _activeOrders = List.from(widget.initialOrders!);
        });
      }
      return;
    }

    final allBookings = LiveBookingSyncService.instance.getAllBookings();
    final List<Map<String, dynamic>> parsedOrders = [];

    // Filter store orders or customer bookings
    for (final b in allBookings) {
      final status = (b['status'] ?? b['service_status'] ?? 'New').toString().toUpperCase();
      if (status == 'CANCELLED' || status == 'COMPLETED' || status == 'DELIVERED') {
        continue;
      }

      final bCode = (b['order_code'] ?? b['order_id'] ?? b['booking_id'] ?? b['id'] ?? 'ORD').toString();
      final customerName = (b['customer_name'] ?? 'Customer').toString();
      final customerPhone = (b['customer_phone'] ?? '').toString();
      final address = (b['customer_address'] ?? b['address'] ?? 'Jamnagar Central').toString();
      final title = (b['items_summary'] ?? b['service_name'] ?? b['item_title'] ?? 'Store Order Delivery').toString();
      final amt = (b['final_amount'] as num?)?.toDouble() ??
          (b['estimated_amount'] as num?)?.toDouble() ??
          (b['price'] as num?)?.toDouble() ??
          (b['total_amount'] as num?)?.toDouble() ??
          380.0;

      final lat = (b['customer_lat'] as num?)?.toDouble();
      final lng = (b['customer_lng'] as num?)?.toDouble();

      // Only include orders that have genuine GPS coordinates
      if (lat != null && lng != null && lat != 0.0 && lng != 0.0) {
        parsedOrders.add({
          'order_id': bCode.startsWith('#') ? bCode : '#$bCode',
          'raw_id': b['id'] ?? b['booking_id'] ?? bCode,
          'customer_name': customerName,
          'customer_phone': customerPhone,
          'address': address,
          'title': title,
          'amount': amt,
          'status': status,
          'location': LatLng(lat, lng),
        });
      }
    }

    if (mounted) {
      setState(() {
        _activeOrders = parsedOrders;
      });
    }
  }

  void _recenterStore() {
    _mapController.move(_storeLocation, 14.0);
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1.0);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1.0);
  }

  void _toggleRadius(int km) {
    setState(() {
      if (_activeRadii.contains(km)) {
        if (_activeRadii.length > 1) {
          _activeRadii.remove(km);
        }
      } else {
        _activeRadii.add(km);
      }
    });
  }

  void _showOrderBottomSheet(Map<String, dynamic> order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (ctx) {
        final status = (order['status'] ?? 'NEW').toString();
        final amt = (order['amount'] as num?)?.toDouble() ?? 0.0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.shopping_bag_rounded, color: Color(0xFF059669), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order['order_id']} • Customer Dropoff',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          order['customer_name'] ?? 'Customer',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Text(
                      '₹${amt.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669), fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order['title'] ?? 'Store Item',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order['address'] ?? 'Jamnagar',
                            style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.pending_actions_rounded, size: 16, color: Color(0xFF0284C7)),
                        const SizedBox(width: 8),
                        Text(
                          'Status: $status',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      icon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFF059669)),
                      label: const Text('Call Customer', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final cPhone = (order['customer_phone'] ?? order['phone'] ?? '').toString();
                        PhoneLauncherService.makePhoneCall(context, cPhone);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.two_wheeler_rounded, size: 18),
                      label: const Text('Assign Rider', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showAssignCourierDialog(order);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCourierBottomSheet(Map<String, dynamic> courier) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      backgroundColor: Colors.white,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          courier['name'] ?? 'Delivery Rider',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${courier['rating']} • ${courier['distance_km']} km away',
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Ready',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669), fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.electric_moped_rounded, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            courier['vehicle'] ?? 'Delivery Scooter',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        Text(
                          courier['status'] ?? 'Available for Pickup',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      icon: const Icon(Icons.phone_rounded, size: 18, color: Color(0xFFEA580C)),
                      label: const Text('Call Rider', style: TextStyle(color: Color(0xFFEA580C), fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final rPhone = (courier['phone'] ?? '').toString();
                        PhoneLauncherService.makePhoneCall(context, rPhone);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 18),
                      label: const Text('Dispatch Order', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Dispatch request sent to ${courier['name']}!'),
                            backgroundColor: const Color(0xFF059669),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAssignCourierDialog(Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF059669), size: 22),
            ),
            const SizedBox(width: 10),
            const Text('Dispatch Order', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a nearby rider to deliver ${order['order_id']} (${order['title']}):',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 14),
            ..._nearbyCouriers.take(3).map((c) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF7ED),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFFEA580C), size: 18),
                  ),
                  title: Text(c['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  subtitle: Text('${c['distance_km']} km away • ${c['vehicle']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Assigned ${c['name']} to ${order['order_id']} successfully!'),
                          backgroundColor: const Color(0xFF059669),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Assign', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
        ],
      ),
    );
  }

  /// Store Origin Marker with emerald green store icon, pulsing beacon, and store name
  Widget _buildStoreOriginMarker() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final v = _pulseController.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outermost animated pulse wave ring
            Container(
              width: 36 + (v * 48),
              height: 36 + (v * 48),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669).withValues(alpha: 0.32 * (1.0 - v)),
                border: Border.all(
                  color: const Color(0xFF059669).withValues(alpha: 0.65 * (1.0 - v)),
                  width: 1.5,
                ),
              ),
            ),
            // Middle ring
            Container(
              width: 30 + (((v + 0.5) % 1.0) * 32),
              height: 30 + (((v + 0.5) % 1.0) * 32),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF059669).withValues(alpha: 0.20 * (1.0 - ((v + 0.5) % 1.0))),
              ),
            ),
            // Store badge with name tag
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF065F46),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34D399),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _shopName,
                          style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x66059669),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.storefront_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Customer Active Order Drop-off Pin Marker
  Widget _buildCustomerOrderMarker(Map<String, dynamic> order) {
    final code = (order['order_id'] ?? '').toString();
    final amt = (order['amount'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: () => _showOrderBottomSheet(order),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Text(
              '$code • ₹${amt.toStringAsFixed(0)}',
              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66EF4444),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  /// Nearby Delivery Courier Scooter Marker
  Widget _buildCourierMarker(Map<String, dynamic> courier) {
    final name = (courier['name'] as String?)?.split(' ').first ?? 'Rider';
    final rating = (courier['rating'] as num?)?.toDouble() ?? 4.8;

    return GestureDetector(
      onTap: () => _showCourierBottomSheet(courier),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFC2410C),
              borderRadius: BorderRadius.circular(8),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
            ),
            child: Text(
              '$name • ${rating.toStringAsFixed(1)}★',
              style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEA580C), Color(0xFF9A3412)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2.2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66EA580C),
                  blurRadius: 6,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.two_wheeler_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Generate concentric circle markers based on active radius toggles
    final circles = <CircleMarker>[];

    // 10km Outer delivery zone (Amber tint)
    if (_activeRadii.contains(10)) {
      circles.add(
        CircleMarker(
          point: _storeLocation,
          radius: 10000,
          useRadiusInMeter: true,
          color: const Color(0xFFD97706).withValues(alpha: 0.08),
          borderColor: const Color(0xFFD97706).withValues(alpha: 0.45),
          borderStrokeWidth: 1.8,
        ),
      );
    }

    // 5km Standard delivery zone (Blue tint)
    if (_activeRadii.contains(5)) {
      circles.add(
        CircleMarker(
          point: _storeLocation,
          radius: 5000,
          useRadiusInMeter: true,
          color: const Color(0xFF2563EB).withValues(alpha: 0.10),
          borderColor: const Color(0xFF2563EB).withValues(alpha: 0.55),
          borderStrokeWidth: 2.0,
        ),
      );
    }

    // 2km Express delivery zone (Emerald tint)
    if (_activeRadii.contains(2)) {
      circles.add(
        CircleMarker(
          point: _storeLocation,
          radius: 2000,
          useRadiusInMeter: true,
          color: const Color(0xFF059669).withValues(alpha: 0.15),
          borderColor: const Color(0xFF059669).withValues(alpha: 0.65),
          borderStrokeWidth: 2.0,
        ),
      );
    }

    // Markers list
    final markers = <Marker>[
      // Store Origin Marker with pulsing beacon
      Marker(
        point: _storeLocation,
        width: 160,
        height: 120,
        alignment: Alignment.center,
        child: _buildStoreOriginMarker(),
      ),
    ];

    // Customer Active Orders dropoff markers
    for (final order in _activeOrders) {
      final loc = order['location'] as LatLng?;
      if (loc != null) {
        markers.add(
          Marker(
            point: loc,
            width: 140,
            height: 100,
            alignment: Alignment.topCenter,
            child: _buildCustomerOrderMarker(order),
          ),
        );
      }
    }

    // Nearby Delivery Courier markers
    for (final courier in _nearbyCouriers) {
      final loc = courier['location'] as LatLng?;
      if (loc != null) {
        markers.add(
          Marker(
            point: loc,
            width: 140,
            height: 100,
            alignment: Alignment.topCenter,
            child: _buildCourierMarker(courier),
          ),
        );
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full OpenStreetMap powered by flutter_map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _storeLocation,
              initialZoom: 13.8,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              onMapReady: () {
                if (!_hasCenteredInitially) {
                  _hasCenteredInitially = true;
                  _recenterStore();
                }
              },
            ),
            children: [
              // Standard OSM Tiles with required userAgentPackageName
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.servicehub.partner',
                tileProvider: NetworkTileProvider(silenceExceptions: true),
              ),

              // Concentric Delivery Radius Circles
              CircleLayer(circles: circles),

              // Marker Layer
              MarkerLayer(markers: markers),
            ],
          ),

          // 2. Top Header Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              children: [
                // Back or Close Button
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
                  ),
                  child: IconButton(
                    icon: Icon(
                      widget.isModal ? Icons.close_rounded : Icons.arrow_back_rounded,
                      color: const Color(0xFF0F172A),
                    ),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        GoRouter.maybeOf(context)?.go('/dashboard/shopkeeper');
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Store Live Map Header Badge
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
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Color(0xFF059669),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _shopName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Text(
                                'Store Delivery Zone Radar • Live',
                                style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Text(
                            '${_activeOrders.length} Orders',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Radius Toggle Chips (2km, 5km, 10km) Floating Row
          Positioned(
            top: MediaQuery.of(context).padding.top + 68,
            left: 16,
            right: 16,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildRadiusChip(
                    km: 2,
                    label: '2 km Express',
                    color: const Color(0xFF059669),
                    keyName: 'shopkeeper_map_chip_2km',
                  ),
                  const SizedBox(width: 8),
                  _buildRadiusChip(
                    km: 5,
                    label: '5 km Standard',
                    color: const Color(0xFF2563EB),
                    keyName: 'shopkeeper_map_chip_5km',
                  ),
                  const SizedBox(width: 8),
                  _buildRadiusChip(
                    km: 10,
                    label: '10 km Outer Zone',
                    color: const Color(0xFFD97706),
                    keyName: 'shopkeeper_map_chip_10km',
                  ),
                ],
              ),
            ),
          ),

          // 4. Floating Map Controls (Zoom In/Out, Re-center on Store)
          Positioned(
            right: 16,
            bottom: 175,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Re-center on Store
                FloatingActionButton.small(
                  key: const Key('shopkeeper_map_recenter_button'),
                  heroTag: 'store_map_btn_recenter',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF059669),
                  elevation: 3,
                  onPressed: _recenterStore,
                  child: const Icon(Icons.storefront_rounded),
                ),
                const SizedBox(height: 8),

                // Zoom In
                FloatingActionButton.small(
                  key: const Key('shopkeeper_map_zoom_in'),
                  heroTag: 'store_map_btn_zoom_in',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 3,
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add_rounded),
                ),
                const SizedBox(height: 6),

                // Zoom Out
                FloatingActionButton.small(
                  key: const Key('shopkeeper_map_zoom_out'),
                  heroTag: 'store_map_btn_zoom_out',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F172A),
                  elevation: 3,
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove_rounded),
                ),
              ],
            ),
          ),

          // 5. Bottom Summary Card with Store Info and Active Orders Count
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _shopName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              _shopAddress.isNotEmpty
                                  ? (_shopPhone.isNotEmpty ? '$_shopAddress • $_shopPhone' : _shopAddress)
                                  : (_shopPhone.isNotEmpty ? _shopPhone : 'Location not specified'),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _isStoreOpen = !_isStoreOpen);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(_isStoreOpen ? 'Store is now OPEN for orders' : 'Store is now CLOSED'),
                              backgroundColor: _isStoreOpen ? const Color(0xFF059669) : const Color(0xFF64748B),
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isStoreOpen ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _isStoreOpen ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _isStoreOpen ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _isStoreOpen ? 'OPEN' : 'CLOSED',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: _isStoreOpen ? const Color(0xFF059669) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      // Active Orders Metric Chip
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ACTIVE ORDERS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.shopping_bag_outlined, size: 16, color: Color(0xFF059669)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_activeOrders.length} Orders',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),

                      // Nearby Couriers Metric Chip
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('AVAILABLE RIDERS', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.two_wheeler_rounded, size: 16, color: Color(0xFFEA580C)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${_nearbyCouriers.length} Nearby',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF0F172A)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusChip({
    required int km,
    required String label,
    required Color color,
    required String keyName,
  }) {
    final isSelected = _activeRadii.contains(km);

    return FilterChip(
      key: Key(keyName),
      selected: isSelected,
      showCheckmark: false,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isSelected ? Colors.white : const Color(0xFF334155),
      ),
      backgroundColor: Colors.white,
      selectedColor: color,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? color : const Color(0xFFCBD5E1)),
      ),
      onSelected: (_) => _toggleRadius(km),
    );
  }
}
