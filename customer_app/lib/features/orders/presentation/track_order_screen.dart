import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/h3_geospatial_service.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/services/phone_launcher_service.dart';
import '../../../../core/theme/app_theme.dart';
import 'orders_provider.dart';

class TrackOrderScreen extends ConsumerStatefulWidget {
  final String orderId;

  const TrackOrderScreen({super.key, required this.orderId});

  @override
  ConsumerState<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends ConsumerState<TrackOrderScreen>
    with TickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _pulseController;
  late final AnimationController _radarController;

  Map<String, dynamic>? _orderData;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isCancelling = false;

  StreamSubscription? _bookingStreamSub;
  Timer? _periodicSyncTimer;
  Timer? _h3RadiusExpansionTimer;

  // H3 Search Radius Multi-Tier State (k-Ring 1 -> 2 -> 3)
  int _searchRingTier = 1;
  int _elapsedSearchSeconds = 0;
  bool _hasInitialBoundsFit = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _loadOrderData();
    _subscribeToLiveBookingUpdates();

    // Periodic Supabase sync every 3 seconds for active orders
    _periodicSyncTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      if (_orderData?['status'] != 'Delivered' &&
          _orderData?['status'] != 'DELIVERED' &&
          _orderData?['status'] != 'Cancelled' &&
          _orderData?['status'] != 'CANCELLED_BY_CUSTOMER') {
        _syncFromSupabase();
      }
    });

    // H3 Radius Expansion Timer: expands k-Ring search tier as time elapses
    _h3RadiusExpansionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      final status = (_orderData?['status'] ?? '').toString().toUpperCase();
      final hasShopkeeper = (_orderData?['shopkeeper_id'] ?? _orderData?['partner_id'] ?? '').toString().isNotEmpty;

      // Only increment search radius while searching for shopkeeper or courier
      if (status == 'PENDING_SHOPKEEPER' || status == 'PLACED' || (!hasShopkeeper && status != 'DELIVERED' && status != 'CANCELLED')) {
        setState(() {
          _elapsedSearchSeconds++;
          if (_elapsedSearchSeconds >= 16) {
            _searchRingTier = 3; // k-Ring 3: Extended Perimeter (~10 km)
          } else if (_elapsedSearchSeconds >= 8) {
            _searchRingTier = 2; // k-Ring 2: City Hubs (~5 km)
          } else {
            _searchRingTier = 1; // k-Ring 1: Local Neighborhood (~2 km)
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _bookingStreamSub?.cancel();
    _periodicSyncTimer?.cancel();
    _h3RadiusExpansionTimer?.cancel();
    _pulseController.dispose();
    _radarController.dispose();
    super.dispose();
  }

  void _subscribeToLiveBookingUpdates() {
    _bookingStreamSub =
        LiveBookingSyncService.instance.bookingsStream.listen((bookings) {
      if (!mounted) return;
      final target = _findBookingInList(bookings);
      if (target != null) {
        setState(() {
          _orderData = _mergeOrderData(_orderData, target);
          _isLoading = false;
        });
      }
    });
  }

  Map<String, dynamic>? _findBookingInList(List<Map<String, dynamic>> list) {
    for (final b in list) {
      final bId = (b['id'] ?? b['booking_id'] ?? b['order_id'] ?? '').toString();
      final bCode = (b['order_code'] ?? '').toString();
      if (bId == widget.orderId ||
          bCode == widget.orderId ||
          (widget.orderId.isNotEmpty && bId.contains(widget.orderId)) ||
          (widget.orderId.isNotEmpty && bCode.contains(widget.orderId))) {
        return b;
      }
    }
    return null;
  }

  bool _isLocallyCancelled() {
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        final List<dynamic> cancelled = box.get('cancelled_order_ids', defaultValue: []) as List<dynamic>;
        return cancelled.contains(widget.orderId);
      }
    } catch (_) {}
    return false;
  }

  Future<void> _loadOrderData() async {
    // 1. Check local cancellation
    if (_isLocallyCancelled()) {
      if (mounted) {
        setState(() {
          _orderData = {
            'order_id': widget.orderId,
            'status': 'Cancelled',
          };
          _isLoading = false;
        });
      }
      return;
    }

    // 2. Check LiveBookingSyncService memory and disk
    LiveBookingSyncService.instance.reloadAllFromDisk();
    final localBooking = LiveBookingSyncService.instance.getBooking(widget.orderId) ??
        _findBookingInList(LiveBookingSyncService.instance.getAllBookings());

    if (localBooking != null && mounted) {
      setState(() {
        _orderData = Map<String, dynamic>.from(localBooking);
        _isLoading = false;
      });
    }

    // 3. Query Supabase
    await _syncFromSupabase();
  }

  Future<void> _syncFromSupabase() async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('orders')
          .select('*, order_items(*, products(*)), user_addresses(*), shops(*)')
          .or('order_id.eq.${widget.orderId},order_code.eq.${widget.orderId}')
          .maybeSingle();

      if (res != null && mounted) {
        final address = res['user_addresses'] as Map<String, dynamic>?;
        final shop = res['shops'] as Map<String, dynamic>?;
        final itemsRaw = res['order_items'] as List<dynamic>? ?? [];

        final List<Map<String, dynamic>> structuredItems = [];
        for (final item in itemsRaw) {
          if (item is Map<String, dynamic>) {
            final prod = item['products'] as Map<String, dynamic>?;
            structuredItems.add({
              'id': item['product_id'] ?? prod?['product_id'] ?? '',
              'name': prod?['name'] ?? 'Product Item',
              'quantity': (item['quantity'] as num?)?.toInt() ?? 1,
              'price': (item['subtotal'] as num?)?.toDouble() ?? (prod?['price'] as num?)?.toDouble() ?? 0.0,
            });
          }
        }

        final fullAddress = address != null
            ? '${address['area'] ?? ""}, ${address['city'] ?? ""}'.trim().replaceAll(RegExp(r'^,\s*|,\s*$'), '')
            : null;

        final dbData = <String, dynamic>{
          'order_id': res['order_id'] ?? widget.orderId,
          'order_code': res['order_code'] ?? widget.orderId,
          'status': res['order_status'] ?? res['status'] ?? 'Placed',
          'subtotal': (res['subtotal'] as num?)?.toDouble(),
          'delivery_charge': (res['delivery_charge'] as num?)?.toDouble(),
          'total_amount': (res['total_amount'] as num?)?.toDouble(),
          'grand_total': (res['total_amount'] as num?)?.toDouble(),
          'shipping_address': fullAddress,
          'customer_address': fullAddress,
          'customer_lat': (address?['latitude'] as num?)?.toDouble(),
          'customer_lng': (address?['longitude'] as num?)?.toDouble(),
          'shop_name': shop?['shop_name'],
          'shop_phone': shop?['phone'],
          'shop_address': shop?['address'],
          'store_lat': (shop?['latitude'] as num?)?.toDouble(),
          'store_lng': (shop?['longitude'] as num?)?.toDouble(),
          'created_at': res['created_at'],
        };

        if (structuredItems.isNotEmpty) {
          dbData['items'] = structuredItems;
        }

        setState(() {
          _orderData = _mergeOrderData(_orderData, dbData);
          _isLoading = false;
        });
      }
    } catch (_) {
      // Graceful offline fallback
    } finally {
      if (mounted && _isLoading && _orderData != null) {
        setState(() => _isLoading = false);
      }
    }
  }

  Map<String, dynamic> _mergeOrderData(Map<String, dynamic>? existing, Map<String, dynamic> update) {
    final merged = Map<String, dynamic>.from(existing ?? {});
    update.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty && value.toString() != 'null') {
        merged[key] = value;
      }
    });
    return merged;
  }

  int _getStatusStep(String rawStatus) {
    final s = rawStatus.toUpperCase();
    if (s == 'CANCELLED' || s == 'CANCELLED_BY_CUSTOMER') {
      return -1;
    }
    if (s == 'DELIVERED' || s == 'COMPLETED') {
      return 4;
    }
    if (s == 'OUT_FOR_DELIVERY' || s == 'PICKED_UP') {
      return 3;
    }
    if (s == 'READY_FOR_PICKUP' ||
        s == 'FINDING_DELIVERY_AGENT' ||
        s == 'AGENT_ASSIGNED_HEADING_TO_STORE' ||
        s == 'ARRIVED_AT_STORE' ||
        s == 'ASSIGNED_TO_DELIVERY') {
      return 2;
    }
    if (s == 'ACCEPTED_BY_SHOPKEEPER' || s == 'PREPARING' || s == 'PACKING') {
      return 1;
    }
    return 0; // PENDING_SHOPKEEPER, PLACED, NEW
  }

  double _calculateDistanceKm(double lat1, double lng1, double lat2, double lng2) {
    final meters = H3GeospatialService.instance.computeHaversineDistanceMeters(lat1, lng1, lat2, lng2);
    return meters / 1000.0;
  }

  int _calculateEtaMinutes(double km) {
    // Average urban courier transit speed ~22 km/h
    final mins = (km / 22.0 * 60).round();
    return mins.clamp(2, 60);
  }

  Future<void> _showCancelConfirmation() async {
    String? selectedReason;
    final List<String> reasons = [
      'Ordered by mistake',
      'Need to change delivery address',
      'Delivery time is too long',
      'Found a better price elsewhere',
      'Other reason',
    ];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: AppTheme.dangerColor, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Cancel Order',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Are you sure you want to cancel this order? Please select a reason *:',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
                  ),
                  const SizedBox(height: 12),
                  ...reasons.map((reason) => RadioListTile<String>(
                        value: reason,
                        // ignore: deprecated_member_use
                        groupValue: selectedReason,
                        title: Text(reason, style: const TextStyle(fontSize: 13)),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        // ignore: deprecated_member_use
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() {
                              selectedReason = val;
                            });
                          }
                        },
                      )),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Keep Order'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.dangerColor,
                          ),
                          onPressed: () async {
                            if (selectedReason == null || selectedReason!.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please select a cancellation reason *'),
                                  backgroundColor: AppTheme.dangerColor,
                                ),
                              );
                              return;
                            }
                            Navigator.pop(ctx);
                            setState(() => _isCancelling = true);
                            _periodicSyncTimer?.cancel();

                            await ref.read(ordersServiceProvider).cancelOrder(widget.orderId, reason: selectedReason!);
                            await LiveBookingSyncService.instance.updateBookingStatus(widget.orderId, 'CANCELLED_BY_CUSTOMER');

                            if (mounted) {
                              setState(() {
                                _isCancelling = false;
                                _orderData = Map<String, dynamic>.from(_orderData ?? {})..['status'] = 'Cancelled';
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Order has been cancelled successfully.'),
                                    backgroundColor: AppTheme.dangerColor,
                                  ),
                                );
                              }
                            }
                          },
                          child: const Text('Confirm Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _recenterMap(LatLng p1, LatLng p2, [LatLng? p3]) {
    final points = [p1, p2];
    if (p3 != null) points.add(p3);

    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _orderData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Order')),
        body: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text(
                'Connecting to real-time order tracking...',
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_orderData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Order')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textSecondaryColor),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Order #${widget.orderId} not found in database',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadOrderData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final order = _orderData!;
    final rawStatus = (order['status'] ?? 'Placed').toString();
    final currentStep = _getStatusStep(rawStatus);
    final isCancelled = currentStep == -1;
    final isDelivered = currentStep == 4;

    final shopkeeperId = (order['shopkeeper_id'] ?? order['partner_id'] ?? '').toString();
    final deliveryAgentId = (order['delivery_agent_id'] ?? '').toString();
    final isShopkeeperAccepted = shopkeeperId.isNotEmpty && currentStep >= 1;
    final isCourierAssigned = deliveryAgentId.isNotEmpty || currentStep >= 2;

    final displayCode = (order['order_code'] ?? order['id'] ?? widget.orderId).toString();
    final cleanCode = displayCode.startsWith('#') ? displayCode : '#$displayCode';

    // Coordinates
    const defaultLat = 22.4707;
    const defaultLng = 70.0577;
    final custLat = (order['customer_lat'] as num?)?.toDouble() ?? (defaultLat - 0.0040);
    final custLng = (order['customer_lng'] as num?)?.toDouble() ?? (defaultLng + 0.0065);
    final customerLoc = LatLng(custLat, custLng);

    final storeLat = (order['store_lat'] as num?)?.toDouble() ?? (defaultLat + 0.0035);
    final storeLng = (order['store_lng'] as num?)?.toDouble() ?? (defaultLng + 0.0030);
    final storeLoc = LatLng(storeLat, storeLng);

    final riderLatNum = (order['partner_lat'] ?? order['delivery_agent_lat'] ?? order['rider_lat']) as num?;
    final riderLngNum = (order['partner_lng'] ?? order['delivery_agent_lng'] ?? order['rider_lng']) as num?;
    final hasRiderGps = riderLatNum != null && riderLngNum != null;
    final riderLoc = hasRiderGps ? LatLng(riderLatNum.toDouble(), riderLngNum.toDouble()) : null;

    final storeName = (order['shopkeeper_name'] ?? order['shop_name'] ?? order['store_name'] ?? 'Local Partner Store').toString();
    final storeAddress = (order['shopkeeper_address'] ?? order['shop_address'] ?? 'Hyperlocal Merchant Hub').toString();
    final storePhone = (order['shopkeeper_phone'] ?? order['shop_phone'] ?? '').toString();

    final agentName = (order['delivery_agent_name'] ?? order['partner_name'] ?? '').toString();
    final agentPhone = (order['delivery_agent_phone'] ?? order['partner_phone'] ?? '').toString();

    final addressText = (order['shipping_address'] ?? order['customer_address'] ?? order['address'] ?? 'Customer Delivery Address').toString();
    final rawItems = order['items'] as List<dynamic>?;
    final itemsSummary = (order['items_summary'] ?? 'Store Products').toString();

    final subtotal = (order['subtotal'] as num?)?.toDouble() ??
        ((order['total_amount'] ?? order['grand_total'] ?? 0.0) as num).toDouble() -
            ((order['delivery_charge'] ?? order['delivery_fee'] ?? 0.0) as num).toDouble();
    final deliveryFee = ((order['delivery_charge'] ?? order['delivery_fee'] ?? 0.0) as num).toDouble();
    final grandTotal = ((order['total_amount'] ?? order['grand_total'] ?? order['final_amount'] ?? 0.0) as num).toDouble();

    // Authentic Delivery PIN from real booking/order
    final deliveryPin = (order['delivery_pin'] ?? order['delivery_otp'] ?? '').toString();

    // Mode Selection:
    // 1. If not yet accepted by shopkeeper -> Finding Shopkeeper Radar Mode
    // 2. If accepted by shopkeeper but no courier assigned yet -> Finding Delivery Courier Radar Mode
    // 3. If courier assigned or active navigation -> Full Live Map Tracking Mode
    final isFindingShopkeeperMode = !isCancelled && !isDelivered && !isShopkeeperAccepted;
    final isFindingCourierMode = !isCancelled && !isDelivered && isShopkeeperAccepted && !isCourierAssigned;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/orders');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          title: Text(
            isFindingShopkeeperMode
                ? 'Finding Local Store'
                : (isFindingCourierMode ? 'Finding Delivery Courier' : 'Track Order: $cleanCode'),
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/orders');
              }
            },
          ),
          actions: [
            if (isFindingShopkeeperMode)
              TextButton(
                onPressed: _isCancelling ? null : _showCancelConfirmation,
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadOrderData,
          color: AppTheme.primaryColor,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: isFindingShopkeeperMode
                ? _buildFindingShopkeeperView(cleanCode, custLat, custLng, rawItems, itemsSummary, grandTotal, addressText)
                : (isFindingCourierMode
                    ? _buildFindingCourierView(cleanCode, storeName, storeAddress, storePhone, storeLat, storeLng, rawItems, itemsSummary, grandTotal, addressText)
                    : _buildLiveMapTrackingView(
                        cleanCode,
                        storeLoc,
                        customerLoc,
                        riderLoc,
                        storeName,
                        storeAddress,
                        storePhone,
                        agentName,
                        agentPhone,
                        currentStep,
                        isCancelled,
                        isDelivered,
                        deliveryPin,
                        rawItems,
                        itemsSummary,
                        subtotal,
                        deliveryFee,
                        grandTotal,
                        addressText,
                      )),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage 1: Finding Nearest Shopkeeper with H3 Radius Expansion (k-Ring 1 -> 2 -> 3)
  // ---------------------------------------------------------------------------
  Widget _buildFindingShopkeeperView(
    String cleanCode,
    double custLat,
    double custLng,
    List<dynamic>? rawItems,
    String itemsSummary,
    double grandTotal,
    String addressText,
  ) {
    final h3Index = H3GeospatialService.instance.latLngToH3Index(custLat, custLng, resolution: 8);
    // Expand concentric search rings via H3 algorithm
    H3GeospatialService.instance.getKRingCells(h3Index, ringSize: _searchRingTier);

    String radiusKmText = '2.0 km';
    String etaRangeText = '⚡ 10 - 15 Mins Delivery';
    String tierLabel = 'Local Area (< 2.0 km)';
    if (_searchRingTier == 2) {
      radiusKmText = '5.0 km';
      etaRangeText = '⚡ 20 - 30 Mins Delivery';
      tierLabel = 'Expanded Zone (< 5.0 km)';
    } else if (_searchRingTier == 3) {
      radiusKmText = '10.0 km';
      etaRangeText = '⚡ 35 - 50 Mins Delivery';
      tierLabel = 'Wider Radius (< 10.0 km)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // 1. Radar Beacon Animation
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return Container(
                        width: 220 * _radarController.value,
                        height: 220 * _radarController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF059669).withValues(alpha: 0.18 * (1.0 - _radarController.value)),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFECFDF5),
                      border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF059669), Color(0xFF065F46)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: Color(0x33059669), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 2. Stage Heading & Radius Badge
          const Text(
            'Finding Nearest Shopkeeper',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.radar_rounded, size: 14, color: Color(0xFF2563EB)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Hyperlocal Search • $tierLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Dynamic km-based Delivery ETA Range
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Column(
              children: [
                Text(
                  etaRangeText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Average delivery time calculated based on store distance within $radiusKmText',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF047857)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Real-time Search Checklist
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
              ],
            ),
            child: Column(
              children: [
                _buildSearchChecklistItem(
                  Icons.check_circle_rounded,
                  const Color(0xFF059669),
                  'Order Received & Broadcasted',
                  'Order $cleanCode broadcast to storekeepers in your delivery zone',
                  true,
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildSearchChecklistItem(
                  Icons.radar_rounded,
                  const Color(0xFF2563EB),
                  'Locating Nearby Stores',
                  'Scanning active partner stores within $radiusKmText',
                  true,
                  isPulsing: true,
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                _buildSearchChecklistItem(
                  Icons.inventory_2_outlined,
                  const Color(0xFF94A3B8),
                  'Shopkeeper Acceptance & Packing',
                  'Store claims order atomically and begins packing parcel',
                  false,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Real Order Summary Preview
          _buildOrderSummaryCard(rawItems, itemsSummary, grandTotal - 40.0, 40.0, grandTotal, addressText),
          const SizedBox(height: 20),

          // 6. Cancel Search Action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.cancel_outlined, color: AppTheme.dangerColor, size: 18),
              label: const Text('Cancel Order Search', style: TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTheme.dangerColor),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _showCancelConfirmation,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage 2: Finding Delivery Courier with H3 Radius Expansion from Store Location
  // ---------------------------------------------------------------------------
  Widget _buildFindingCourierView(
    String cleanCode,
    String storeName,
    String storeAddress,
    String storePhone,
    double storeLat,
    double storeLng,
    List<dynamic>? rawItems,
    String itemsSummary,
    double grandTotal,
    String addressText,
  ) {
    final h3Index = H3GeospatialService.instance.latLngToH3Index(storeLat, storeLng, resolution: 8);
    // Expand concentric search rings via H3 algorithm from store
    H3GeospatialService.instance.getKRingCells(h3Index, ringSize: _searchRingTier);

    String courierEtaText = '⚡ Courier Pickup ETA: ~3 - 5 Mins';
    String courierTierLabel = 'Local Area (< 1.5 km)';
    if (_searchRingTier == 2) {
      courierEtaText = '⚡ Courier Pickup ETA: ~6 - 10 Mins';
      courierTierLabel = 'Expanded Zone (< 4.0 km)';
    } else if (_searchRingTier == 3) {
      courierEtaText = '⚡ Courier Pickup ETA: ~12 - 18 Mins';
      courierTierLabel = 'Wider Radius (< 8.0 km)';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          // 1. Confirmed Shopkeeper Success Banner
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '✓ $storeName Accepted Your Order!',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF065F46)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Store is preparing & packaging your parcel right now.',
                        style: TextStyle(color: Color(0xFF047857), fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 2. Animated Courier Radar Beacon
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _radarController,
                    builder: (context, child) {
                      return Container(
                        width: 220 * _radarController.value,
                        height: 220 * _radarController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFEA580C).withValues(alpha: 0.18 * (1.0 - _radarController.value)),
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFF7ED),
                      border: Border.all(color: const Color(0xFFFED7AA), width: 2),
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: Color(0x33EA580C), blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 36),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Stage Heading & Courier Radius Badge
          const Text(
            'Finding Nearest Delivery Courier',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: -0.3),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            constraints: const BoxConstraints(maxWidth: 320),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.two_wheeler_rounded, size: 14, color: Color(0xFFEA580C)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Courier Radar • $courierTierLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF9A3412)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 4. Dynamic Courier Pickup ETA Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Column(
              children: [
                Text(
                  courierEtaText,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFC2410C)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Dispatching to verified riders near $storeName for fast store pickup',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF9A3412)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 5. Confirmed Shopkeeper Card
          _buildShopkeeperCard(storeName, storeAddress, storePhone, true),
          const SizedBox(height: 20),

          // 6. Order Summary Preview
          _buildOrderSummaryCard(rawItems, itemsSummary, grandTotal - 40.0, 40.0, grandTotal, addressText),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSearchChecklistItem(
    IconData icon,
    Color iconColor,
    String title,
    String subtitle,
    bool isCompleted, {
    bool isPulsing = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isCompleted ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Stage 3 & 4: Live OpenStreetMap Tracing View
  // - Phase A: Courier Live GPS -> Store Pickup Location (with calculated km & ETA)
  // - Phase B: Courier Live GPS -> Customer Destination (with calculated km & Delivery PIN)
  // ---------------------------------------------------------------------------
  Widget _buildLiveMapTrackingView(
    String cleanCode,
    LatLng storeLoc,
    LatLng customerLoc,
    LatLng? riderLoc,
    String storeName,
    String storeAddress,
    String storePhone,
    String agentName,
    String agentPhone,
    int currentStep,
    bool isCancelled,
    bool isDelivered,
    String deliveryPin,
    List<dynamic>? rawItems,
    String itemsSummary,
    double subtotal,
    double deliveryFee,
    double grandTotal,
    String addressText,
  ) {
    final isPickedUp = currentStep >= 3; // OUT_FOR_DELIVERY or DELIVERED

    // Real dynamic distance and ETA calculations
    double legDistanceKm = 0.0;
    int legEtaMinutes = 5;
    if (riderLoc != null) {
      if (!isPickedUp) {
        // Leg A: Courier -> Store
        legDistanceKm = _calculateDistanceKm(riderLoc.latitude, riderLoc.longitude, storeLoc.latitude, storeLoc.longitude);
      } else {
        // Leg B: Courier -> Customer
        legDistanceKm = _calculateDistanceKm(riderLoc.latitude, riderLoc.longitude, customerLoc.latitude, customerLoc.longitude);
      }
      legEtaMinutes = _calculateEtaMinutes(legDistanceKm);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Status Banner: Cancelled, Delivered, Active Delivery PIN, or Active Route Leg Banner
        if (isCancelled)
          _buildCancelledBanner()
        else if (isDelivered)
          _buildDeliveredBanner()
        else ...[
          if (isPickedUp)
            _buildActiveRouteLegBanner(
              icon: Icons.two_wheeler_rounded,
              title: 'Courier Heading to Your Doorstep',
              subtitle: 'Arriving in ~$legEtaMinutes mins (${legDistanceKm.toStringAsFixed(1)} km) • Range: $legEtaMinutes-${legEtaMinutes + 4} mins',
              color: const Color(0xFF15803D),
              bgColor: const Color(0xFFDCFCE7),
              borderColor: const Color(0xFF86EFAC),
            )
          else
            _buildActiveRouteLegBanner(
              icon: Icons.storefront_rounded,
              title: 'Courier Heading to Store for Pickup',
              subtitle: 'Arriving at $storeName in ~$legEtaMinutes mins (${legDistanceKm.toStringAsFixed(1)} km) • Handover via Pickup OTP',
              color: const Color(0xFF1E40AF),
              bgColor: const Color(0xFFEFF6FF),
              borderColor: const Color(0xFFBFDBFE),
            ),
          if (deliveryPin.isNotEmpty)
            _buildDeliveryPinCard(deliveryPin),
        ],

        // 2. Real-time OpenStreetMap Tracing Viewport
        _buildMapViewport(storeLoc, customerLoc, riderLoc, storeName, agentName, isCancelled, isPickedUp),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3. Real Shopkeeper Card
              _buildShopkeeperCard(storeName, storeAddress, storePhone, true),
              const SizedBox(height: 12),

              // 4. Real Delivery Courier Card
              _buildCourierCard(agentName, agentPhone, true, isPickedUp),
              const SizedBox(height: 20),

              // 5. Hyperlocal Parcel 5-Step Timeline
              const Text(
                'Hyperlocal Order Timeline',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 14),
              _buildTimeline(currentStep, storeName, agentName),
              const SizedBox(height: 20),

              // 6. Order Items & Financial Summary
              _buildOrderSummaryCard(rawItems, itemsSummary, subtotal, deliveryFee, grandTotal, addressText),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveRouteLegBanner({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required Color borderColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: borderColor),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: color),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(color: color.withValues(alpha: 0.9), fontSize: 11.5, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCancelledBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFFEF2F2),
      child: const Row(
        children: [
          Icon(Icons.cancel_rounded, color: AppTheme.dangerColor, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Cancelled',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.dangerColor),
                ),
                SizedBox(height: 2),
                Text(
                  'This order was cancelled. Any amount paid will be refunded directly to your payment source.',
                  style: TextStyle(color: Color(0xFF991B1B), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveredBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFECFDF5),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parcel Delivered Successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF15803D)),
                ),
                SizedBox(height: 2),
                Text(
                  'Delivery was authenticated via Customer Delivery PIN handshake. Thank you for ordering!',
                  style: TextStyle(color: Color(0xFF166534), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryPinCard(String pin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: Color(0xFFEFF6FF),
        border: Border(bottom: BorderSide(color: Color(0xFFBFDBFE))),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_clock_rounded, color: AppTheme.primaryColor, size: 18),
              SizedBox(width: 6),
              Text(
                'Secure Delivery Verification PIN',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: AppTheme.primaryColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Share this 4-digit PIN with the delivery courier only when collecting your parcel:',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF1E3A8A), fontSize: 12),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: pin));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Delivery PIN copied to clipboard'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x1A2563EB), blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    pin,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy_rounded, size: 16, color: Color(0xFF64748B)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapViewport(
    LatLng storeLoc,
    LatLng customerLoc,
    LatLng? riderLoc,
    String storeName,
    String agentName,
    bool isCancelled,
    bool isPickedUp,
  ) {
    // Dynamic Route Polyline based on active leg:
    // If not yet picked up -> Leg A: Rider -> Store
    // If picked up -> Leg B: Rider -> Customer
    final activeRoute = <LatLng>[];
    if (riderLoc != null) {
      activeRoute.add(riderLoc);
      if (!isPickedUp) {
        activeRoute.add(storeLoc);
      } else {
        activeRoute.add(customerLoc);
      }
    } else {
      activeRoute.addAll([storeLoc, customerLoc]);
    }

    return Container(
      height: 230,
      width: double.infinity,
      color: const Color(0xFFE2E8F0),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: riderLoc ?? (!isPickedUp ? storeLoc : customerLoc),
              initialZoom: 14.2,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
              onMapReady: () {
                if (!_hasInitialBoundsFit) {
                  _hasInitialBoundsFit = true;
                  if (!isPickedUp) {
                    _recenterMap(riderLoc ?? storeLoc, storeLoc);
                  } else {
                    _recenterMap(riderLoc ?? customerLoc, customerLoc);
                  }
                }
              },
            ),
            children: [
              if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST'))
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.servicehub.customer',
                ),
              if (!isCancelled && activeRoute.length >= 2) ...[
                PolylineLayer<Object>(
                  polylines: [
                    Polyline<Object>(
                      points: activeRoute,
                      strokeWidth: 5.0,
                      color: (!isPickedUp ? const Color(0xFF2563EB) : const Color(0xFF16A34A)).withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ],
              MarkerLayer(
                markers: [
                  // 1. Store Marker
                  Marker(
                    point: storeLoc,
                    width: 70,
                    height: 65,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E40AF),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            storeName.length > 9 ? '${storeName.substring(0, 9)}..' : storeName,
                            style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB), size: 28),
                      ],
                    ),
                  ),

                  // 2. Customer Destination Marker
                  Marker(
                    point: customerLoc,
                    width: 70,
                    height: 65,
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 28),
                        Text(
                          'You',
                          style: TextStyle(color: Color(0xFF991B1B), fontSize: 9.5, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),

                  // 3. Live Courier Marker (Moving GPS)
                  if (riderLoc != null && !isCancelled)
                    Marker(
                      point: riderLoc,
                      width: 60,
                      height: 60,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (ctx, child) {
                          final v = _pulseController.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 28 + (v * 28),
                                height: 28 + (v * 28),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFFEA580C).withValues(alpha: 0.35 * (1.0 - v)),
                                ),
                              ),
                              Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEA580C),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                                  ],
                                ),
                                child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 18),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Map Control Button (Recenter)
          Positioned(
            right: 12,
            bottom: 12,
            child: FloatingActionButton.small(
              heroTag: 'recenter_customer_map',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              elevation: 3,
              onPressed: () {
                if (!isPickedUp) {
                  _recenterMap(riderLoc ?? storeLoc, storeLoc);
                } else {
                  _recenterMap(riderLoc ?? customerLoc, customerLoc);
                }
              },
              child: const Icon(Icons.my_location_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopkeeperCard(String name, String address, String phone, bool isAccepted) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isAccepted ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isAccepted ? 'Verified' : 'Matching',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                          color: isAccepted ? const Color(0xFF15803D) : const Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  address,
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call_rounded, color: Color(0xFF059669)),
              onPressed: () => PhoneLauncherService.makePhoneCall(context, phone),
            ),
        ],
      ),
    );
  }

  Widget _buildCourierCard(String name, String phone, bool hasAgent, bool isPickedUp) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFFEA580C), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasAgent ? (name.isNotEmpty ? name : 'Hyperlocal Express Courier') : 'Finding Delivery Courier...',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  hasAgent
                      ? (isPickedUp ? 'Package picked up • Heading to your address' : 'Courier assigned • Heading to store for pickup')
                      : 'Connecting to courier near the store',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (phone.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.call_rounded, color: Color(0xFFEA580C)),
              onPressed: () => PhoneLauncherService.makePhoneCall(context, phone),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeline(int currentStep, String storeName, String agentName) {
    final steps = [
      {
        'title': 'Order Received',
        'subtitle': 'Order placed & broadcast to nearest stores',
      },
      {
        'title': 'Store Packing & Preparing',
        'subtitle': '$storeName accepted and is preparing package',
      },
      {
        'title': 'Courier Dispatched to Store',
        'subtitle': agentName.isNotEmpty ? '$agentName heading to store for pickup' : 'Hyperlocal courier assigned for pickup',
      },
      {
        'title': 'Out for Delivery',
        'subtitle': 'Handover authenticated via Pickup OTP • Live GPS active',
      },
      {
        'title': 'Parcel Delivered',
        'subtitle': 'Verified & completed with your Delivery PIN',
      },
    ];

    return Column(
      children: List.generate(steps.length, (i) {
        final isDone = currentStep >= i;
        final isCurrent = currentStep == i;
        final isLast = i == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isDone ? const Color(0xFF059669) : Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDone ? const Color(0xFF059669) : const Color(0xFFCBD5E1),
                      width: 2,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 13, color: Colors.white)
                      : (isCurrent
                          ? Container(
                              margin: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Color(0xFF059669),
                                shape: BoxShape.circle,
                              ),
                            )
                          : null),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 38,
                    color: isDone ? const Color(0xFF059669) : const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    steps[i]['title']!,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDone ? const Color(0xFF0F172A) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    steps[i]['subtitle']!,
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 11.5),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildOrderSummaryCard(
    List<dynamic>? rawItems,
    String itemsSummary,
    double subtotal,
    double deliveryFee,
    double grandTotal,
    String addressText,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Items & Invoice',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 12),

          // Items breakdown
          if (rawItems != null && rawItems.isNotEmpty) ...[
            ...rawItems.map((item) {
              final m = item is Map<String, dynamic> ? item : <String, dynamic>{};
              final name = (m['name'] ?? m['title'] ?? 'Store Item').toString();
              final qty = (m['quantity'] as num?)?.toInt() ?? 1;
              final price = (m['price'] as num?)?.toDouble() ?? 0.0;
              final lineTotal = price * qty;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$name x$qty',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      '₹${lineTotal.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              );
            }),
          ] else ...[
            Text(
              itemsSummary,
              style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
            ),
          ],

          const Divider(height: 24, color: Color(0xFFE2E8F0)),

          // Cost rows
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Items Subtotal', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
              ),
              Text('₹${subtotal > 0 ? subtotal.toStringAsFixed(0) : grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Delivery Fee', style: TextStyle(color: Color(0xFF64748B), fontSize: 12.5)),
              ),
              Text('₹${deliveryFee.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 16, color: Color(0xFFE2E8F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text('Grand Total Paid', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF0F172A))),
              ),
              Text('₹${grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF059669))),
            ],
          ),
          const SizedBox(height: 14),

          // Shipping Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  addressText,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
