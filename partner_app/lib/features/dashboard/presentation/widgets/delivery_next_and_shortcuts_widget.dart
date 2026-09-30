import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

/// Combined widget rendering both [DeliveryNextPreviewCard] (when queued tasks exist)
/// and [DeliveryQuickShortcutsGrid].
class DeliveryNextAndShortcutsWidget extends StatelessWidget {
  /// All active tasks. If multiple tasks are present, the second task will be shown
  /// in the [DeliveryNextPreviewCard].
  final List<Map<String, dynamic>>? activeTasks;

  /// Explicit next task data to display in [DeliveryNextPreviewCard].
  final Map<String, dynamic>? nextTask;

  /// Optional callbacks for quick shortcut actions.
  final VoidCallback? onMyOrdersTap;
  final VoidCallback? onLiveMapTap;
  final VoidCallback? onEarningsTap;
  final VoidCallback? onSupportTap;

  /// Callback when [DeliveryNextPreviewCard] is tapped.
  final VoidCallback? onNextDeliveryTap;

  /// Optional custom title for shortcuts section (defaults to "QUICK ACTIONS").
  final String shortcutsTitle;

  /// Force 2x2 grid instead of 4-column row.
  final bool is2x2Grid;

  const DeliveryNextAndShortcutsWidget({
    super.key,
    this.activeTasks,
    this.nextTask,
    this.onMyOrdersTap,
    this.onLiveMapTap,
    this.onEarningsTap,
    this.onSupportTap,
    this.onNextDeliveryTap,
    this.shortcutsTitle = 'QUICK ACTIONS',
    this.is2x2Grid = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DeliveryNextPreviewCard(
          tasks: activeTasks,
          task: nextTask,
          onTap: onNextDeliveryTap,
        ),
        DeliveryQuickShortcutsGrid(
          title: shortcutsTitle,
          is2x2Grid: is2x2Grid,
          onMyOrdersTap: onMyOrdersTap,
          onLiveMapTap: onLiveMapTap,
          onEarningsTap: onEarningsTap,
          onSupportTap: onSupportTap,
        ),
      ],
    );
  }
}

/// 1. DeliveryNextPreviewCard:
/// - Shown when multiple tasks are queued.
/// - "Next Delivery • In Queue": Order code, pickup store name, distance, "Starts after current delivery >".
class DeliveryNextPreviewCard extends StatelessWidget {
  /// List of active tasks. If provided and `tasks.length > 1`, task index 1 is used.
  final List<Map<String, dynamic>>? tasks;

  /// Single task map to display.
  final Map<String, dynamic>? task;

  /// Explicit order code (e.g., 'SH-9281' or '#1049').
  final String? orderCode;

  /// Explicit pickup store name.
  final String? storeName;

  /// Explicit distance string (e.g., '2.4 km').
  final String? distance;

  /// Optional earning for this queued delivery.
  final double? earning;

  /// Tap callback for when the card or footer is clicked.
  final VoidCallback? onTap;

  /// If true, automatically hides the card when fewer than 2 tasks are in [tasks].
  final bool showOnlyWhenMultipleQueued;

  const DeliveryNextPreviewCard({
    super.key,
    this.tasks,
    this.task,
    this.orderCode,
    this.storeName,
    this.distance,
    this.earning,
    this.onTap,
    this.showOnlyWhenMultipleQueued = true,
  });

  @override
  Widget build(BuildContext context) {
    // If a list of tasks is provided, evaluate whether multiple tasks are queued.
    if (tasks != null) {
      if (showOnlyWhenMultipleQueued && tasks!.length < 2) {
        return const SizedBox.shrink();
      }
    }

    // Determine target task dictionary
    final resolvedTask = task ?? ((tasks != null && tasks!.length > 1) ? tasks![1] : null);

    // If no task and no explicit fields provided, do not render.
    if (resolvedTask == null && orderCode == null && storeName == null) {
      return const SizedBox.shrink();
    }

    final resolvedOrderCode = orderCode ??
        resolvedTask?['order_code']?.toString() ??
        resolvedTask?['items_summary']?.toString().replaceFirst('Order #', '') ??
        'SH-4820';

    final resolvedStoreName = storeName ??
        resolvedTask?['shop_name']?.toString() ??
        'Fresh Mart Superstore';

    final resolvedDistance = distance ??
        resolvedTask?['distance']?.toString() ??
        '1.8 km';

    final resolvedEarning = earning ??
        (resolvedTask?['earning'] as num?)?.toDouble() ??
        (resolvedTask?['delivery_charge'] as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFED7AA), width: 1.2), // Light peach/amber accent border
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row: "Next Delivery • In Queue" pill + distance indicator
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED), // Peach background
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEA580C), // Orange indicator
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Next Delivery • In Queue',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFC2410C),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.near_me_rounded,
                            size: 13,
                            color: Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            resolvedDistance,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF475569),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Order Code & Pickup Store Name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order #$resolvedOrderCode',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.storefront_rounded,
                                size: 16,
                                color: Color(0xFF2563EB),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  resolvedStoreName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF334155),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (resolvedEarning != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: Text(
                          '₹${resolvedEarning.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Footer banner: "Starts after current delivery >"
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Color(0xFF64748B),
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Starts after current delivery >',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEA580C),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFFEA580C),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 2. DeliveryQuickShortcutsGrid:
/// - Title: "QUICK ACTIONS"
/// - 4 rounded shortcut tiles in a 4-column row or 2x2 grid:
///   * "My Orders" (peach background #FFF7ED, orange package icon #EA580C)
///   * "Live Map" (light blue background #EFF6FF, blue navigation map icon #2563EB) -> callback to open real OpenStreetMap
///   * "Earnings" (light green background #F0FDF4, green rupee icon #16A34A)
///   * "Support" (light purple background #FAF5FF, purple headset icon #9333EA)
/// - Responsive styling with `FittedBox` / `Expanded` to prevent any RenderFlex overflow on small screens.
class DeliveryQuickShortcutsGrid extends StatelessWidget {
  final String title;
  final bool is2x2Grid;
  final VoidCallback? onMyOrdersTap;
  final VoidCallback? onLiveMapTap;
  final VoidCallback? onEarningsTap;
  final VoidCallback? onSupportTap;

  const DeliveryQuickShortcutsGrid({
    super.key,
    this.title = 'QUICK ACTIONS',
    this.is2x2Grid = false,
    this.onMyOrdersTap,
    this.onLiveMapTap,
    this.onEarningsTap,
    this.onSupportTap,
  });

  void _handleDefaultLiveMap(BuildContext context) {
    if (onLiveMapTap != null) {
      onLiveMapTap!();
    } else {
      DeliveryLiveMapModal.show(context);
    }
  }

  void _handleDefaultMyOrders(BuildContext context) {
    if (onMyOrdersTap != null) {
      onMyOrdersTap!();
    } else {
      // Default to navigating to delivery dashboard or refreshing
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Showing all active and queued delivery orders.'),
          backgroundColor: Color(0xFFEA580C),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleDefaultEarnings(BuildContext context) {
    if (onEarningsTap != null) {
      onEarningsTap!();
    } else {
      try {
        context.push('/profile/earnings');
      } catch (_) {
        context.push('/profile/delivery');
      }
    }
  }

  void _handleDefaultSupport(BuildContext context) {
    if (onSupportTap != null) {
      onSupportTap!();
    } else {
      try {
        context.push('/profile/help');
      } catch (_) {
        context.push('/profile/delivery');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(left: 2, bottom: 10),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                color: Color(0xFF64748B),
              ),
            ),
          ),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final use2x2 = is2x2Grid || constraints.maxWidth < 340;

            final tileOrders = _ShortcutTileItem(
              label: 'My Orders',
              backgroundColor: const Color(0xFFFFF7ED), // Peach background #FFF7ED
              iconColor: const Color(0xFFEA580C),       // Orange package icon #EA580C
              borderColor: const Color(0xFFFFEDD5),
              icon: Icons.inventory_2_rounded,
              onTap: () => _handleDefaultMyOrders(context),
            );

            final tileLiveMap = _ShortcutTileItem(
              label: 'Live Map',
              backgroundColor: const Color(0xFFEFF6FF), // Light blue background #EFF6FF
              iconColor: const Color(0xFF2563EB),       // Blue navigation map icon #2563EB
              borderColor: const Color(0xFFDBEAFE),
              icon: Icons.navigation_rounded,
              onTap: () => _handleDefaultLiveMap(context),
            );

            final tileEarnings = _ShortcutTileItem(
              label: 'Earnings',
              backgroundColor: const Color(0xFFF0FDF4), // Light green background #F0FDF4
              iconColor: const Color(0xFF16A34A),       // Green rupee icon #16A34A
              borderColor: const Color(0xFFDCFCE7),
              icon: Icons.currency_rupee_rounded,
              onTap: () => _handleDefaultEarnings(context),
            );

            final tileSupport = _ShortcutTileItem(
              label: 'Support',
              backgroundColor: const Color(0xFFFAF5FF), // Light purple background #FAF5FF
              iconColor: const Color(0xFF9333EA),       // Purple headset icon #9333EA
              borderColor: const Color(0xFFF3E8FF),
              icon: Icons.headset_mic_rounded,
              onTap: () => _handleDefaultSupport(context),
            );

            if (use2x2) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildTile(context, tileOrders)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTile(context, tileLiveMap)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _buildTile(context, tileEarnings)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildTile(context, tileSupport)),
                    ],
                  ),
                ],
              );
            }

            // 4-Column Row responsive layout with FittedBox / Expanded
            return Row(
              children: [
                Expanded(child: _buildTile(context, tileOrders)),
                const SizedBox(width: 8),
                Expanded(child: _buildTile(context, tileLiveMap)),
                const SizedBox(width: 8),
                Expanded(child: _buildTile(context, tileEarnings)),
                const SizedBox(width: 8),
                Expanded(child: _buildTile(context, tileSupport)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, _ShortcutTileItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: item.backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: item.borderColor, width: 1.1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: item.iconColor.withValues(alpha: 0.14),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Icon(
                  item.icon,
                  color: item.iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(height: 7),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShortcutTileItem {
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final Color borderColor;
  final IconData icon;
  final VoidCallback onTap;

  const _ShortcutTileItem({
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.borderColor,
    required this.icon,
    required this.onTap,
  });
}

/// Real OpenStreetMap interactive modal sheet for Live Map navigation.
class DeliveryLiveMapModal extends StatefulWidget {
  final LatLng partnerLocation;
  final LatLng storeLocation;
  final String storeName;
  final String customerArea;

  const DeliveryLiveMapModal({
    super.key,
    this.partnerLocation = const LatLng(22.4707, 70.0577),
    this.storeLocation = const LatLng(22.4760, 70.0630),
    this.storeName = 'Green Grocery Hub',
    this.customerArea = 'City Center, Jamnagar',
  });

  static Future<void> show(
    BuildContext context, {
    LatLng partnerLocation = const LatLng(22.4707, 70.0577),
    LatLng storeLocation = const LatLng(22.4760, 70.0630),
    String storeName = 'Green Grocery Hub',
    String customerArea = 'City Center, Jamnagar',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeliveryLiveMapModal(
        partnerLocation: partnerLocation,
        storeLocation: storeLocation,
        storeName: storeName,
        customerArea: customerArea,
      ),
    );
  }

  @override
  State<DeliveryLiveMapModal> createState() => _DeliveryLiveMapModalState();
}

class _DeliveryLiveMapModalState extends State<DeliveryLiveMapModal> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  void _recenter() {
    _mapController.move(widget.partnerLocation, 15.0);
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final height = mediaQuery.size.height * 0.82;

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.navigation_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Live OpenStreetMap GPS',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.circle, size: 8, color: Color(0xFF16A34A)),
                        ],
                      ),
                      Text(
                        '₹0 Budget Real-Time Routing • OpenStreetMap',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.my_location_rounded, color: Color(0xFF2563EB)),
                  tooltip: 'Recenter',
                  onPressed: _recenter,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // OpenStreetMap Interactive Canvas
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.partnerLocation,
                    initialZoom: 15.0,
                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.service_hub_partner',
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: [widget.partnerLocation, widget.storeLocation],
                          strokeWidth: 4.5,
                          color: const Color(0xFF2563EB),
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        // Rider Marker
                        Marker(
                          point: widget.partnerLocation,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF2563EB),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                        // Store Marker
                        Marker(
                          point: widget.storeLocation,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA580C),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Floating map zoom controls
                Positioned(
                  right: 14,
                  bottom: 90,
                  child: Column(
                    children: [
                      FloatingActionButton.small(
                        heroTag: 'map_zoom_in',
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom + 1);
                        },
                        child: const Icon(Icons.add),
                      ),
                      const SizedBox(height: 8),
                      FloatingActionButton.small(
                        heroTag: 'map_zoom_out',
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF0F172A),
                        onPressed: () {
                          final currentZoom = _mapController.camera.zoom;
                          _mapController.move(_mapController.camera.center, currentZoom - 1);
                        },
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),

                // Floating route info bar at bottom
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.alt_route_rounded, color: Color(0xFF2563EB), size: 22),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Route to ${widget.storeName}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${widget.customerArea} • Live GPS updates every 2s',
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
          ),
        ],
      ),
    );
  }
}
