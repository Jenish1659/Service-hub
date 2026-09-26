import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'delivery_next_and_shortcuts_widget.dart';

/// Recent completed deliveries section matching the mockup with "View All >" button,
/// clean zero-state, and completed delivery cards with status badges and earnings pills.
class DeliveryRecentDeliveriesSection extends StatelessWidget {
  /// The list of completed delivery items.
  /// Expected keys per item:
  /// - `order_code` (e.g. '#SH10247')
  /// - `store_name` (e.g. 'CityMart')
  /// - `timestamp` / `time` (e.g. '8:24 PM')
  /// - `status` (e.g. 'Delivered', 'Picked Up', 'Cancelled')
  /// - `earning` / `earnings` (e.g. 120.0, 40.0, '+₹40.00')
  /// - `icon` (optional IconData)
  final List<Map<String, dynamic>> recentDeliveries;

  /// Callback when the "View All >" button is tapped.
  final VoidCallback? onViewAll;

  /// Callback when a specific delivery item row is tapped.
  final ValueChanged<Map<String, dynamic>>? onDeliveryTap;

  /// Custom text for the "View All >" button (defaults to "View All >").
  final String viewAllText;

  const DeliveryRecentDeliveriesSection({
    super.key,
    this.recentDeliveries = const [],
    this.onViewAll,
    this.onDeliveryTap,
    this.viewAllText = 'View All >',
  });

  /// Deliveries list (100% real Supabase data)
  static const List<Map<String, dynamic>> sampleMockupDeliveries = [];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: "Recent Deliveries" with "View All >" button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Color(0xFFEA580C),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Recent Deliveries',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onViewAll,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    viewAllText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Body: Clean zero-state when empty OR list of completed delivery items
          if (recentDeliveries.isEmpty)
            _buildEmptyZeroState()
          else
            _buildDeliveriesList(context),
        ],
      ),
    );
  }

  /// Clean zero-state when empty:
  /// "No deliveries completed yet today. Your completed trips will appear here."
  Widget _buildEmptyZeroState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Color(0xFF94A3B8),
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'No deliveries completed yet today. Your completed trips will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  /// Card containing list of completed delivery items with dividers
  Widget _buildDeliveriesList(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < recentDeliveries.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 14,
                endIndent: 14,
                color: Color(0xFFF1F5F9),
              ),
            _buildDeliveryRowItem(context, recentDeliveries[i], i),
          ],
        ],
      ),
    );
  }

  /// Builds a single completed delivery row
  Widget _buildDeliveryRowItem(BuildContext context, Map<String, dynamic> trip, int index) {
    final rawOrder = trip['order_code'] ?? trip['order_id'] ?? trip['code'] ?? trip['id'] ?? trip['items_summary'] ?? '#SH10247';
    final orderCode = rawOrder.toString().startsWith('#') ? rawOrder.toString() : '#$rawOrder';
    final storeName = (trip['store_name'] ?? trip['shop_name'] ?? trip['vendor_name'] ?? 'Local Store').toString();
    final time = (trip['timestamp'] ?? trip['time'] ?? trip['delivered_at'] ?? 'Just now').toString();
    final status = (trip['status'] ?? 'Delivered').toString();
    final earning = trip['earning'] ?? trip['earnings'] ?? trip['amount'] ?? trip['delivery_charge'] ?? 40.0;
    final icon = (trip['icon'] as IconData?) ?? (index == 0 ? Icons.inventory_2_outlined : Icons.shopping_bag_outlined);

    return InkWell(
      onTap: () => onDeliveryTap?.call(trip),
      borderRadius: BorderRadius.vertical(
        top: index == 0 ? const Radius.circular(16) : Radius.zero,
        bottom: index == recentDeliveries.length - 1 ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Adaptive layout ensuring zero horizontal overflow on small screens (< 540px)
            if (constraints.maxWidth >= 540) {
              return Row(
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: const Color(0xFF475569),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    orderCode,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      storeName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(status),
                  const SizedBox(width: 8),
                  _buildEarningsPill(earning),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: Color(0xFF94A3B8),
                  ),
                ],
              );
            } else {
              // Compact multi-line fallback for narrow views (< 310px)
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: 16, color: const Color(0xFF475569)),
                      const SizedBox(width: 6),
                      Text(
                        orderCode,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          storeName,
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF475569),
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        time,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildStatusBadge(status),
                          const SizedBox(width: 6),
                          _buildEarningsPill(earning),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  /// Status badge ("Delivered", "Picked Up", "Cancelled") matching mockup pills
  Widget _buildStatusBadge(String rawStatus) {
    final status = rawStatus.trim();
    final lower = status.toLowerCase();

    Color bgColor;
    Color textColor;
    Widget leading;

    if (lower.contains('delivered') || lower.contains('completed')) {
      bgColor = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
      leading = const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A));
    } else if (lower.contains('picked') || lower.contains('transit') || lower.contains('way')) {
      bgColor = const Color(0xFFE0F2FE);
      textColor = const Color(0xFF0284C7);
      leading = Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF0284C7),
          shape: BoxShape.circle,
        ),
      );
    } else if (lower.contains('cancel')) {
      bgColor = const Color(0xFFF1F5F9);
      textColor = const Color(0xFF64748B);
      leading = Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: Color(0xFF64748B),
          shape: BoxShape.circle,
        ),
      );
    } else {
      bgColor = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
      leading = const Icon(Icons.info_rounded, size: 12, color: Color(0xFFD97706));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading,
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  /// Earnings pill formatted as "+₹40.00" or "+ ₹120"
  Widget _buildEarningsPill(dynamic earning) {
    final String formatted;
    if (earning == null) {
      formatted = '+₹40.00';
    } else if (earning is String) {
      formatted = earning.startsWith('+') ? earning : '+₹$earning';
    } else if (earning is num) {
      if (earning == 40 || earning == 40.0) {
        formatted = '+₹40.00';
      } else if (earning % 1 == 0) {
        formatted = '+ ₹${earning.toInt()}';
      } else {
        formatted = '+₹${earning.toStringAsFixed(2)}';
      }
    } else {
      formatted = '+₹40.00';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFBBF7D0).withValues(alpha: 0.7)),
      ),
      child: Text(
        formatted,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF16A34A),
        ),
      ),
    );
  }
}

/// Floating curved pill bottom navigation bar with rounded corners, elevated shadow,
/// safe area handling, and an elevated circular center Map button that triggers OpenStreetMap.
///
/// 5 items:
/// 1. Home (active orange #EA580C)
/// 2. Orders
/// 3. Elevated circular center Map button (blue/orange elevated circular button with scooter/map icon) that triggers OpenStreetMap
/// 4. Earnings
/// 5. Profile (navigates to `/profile/delivery`)
class DeliveryBottomCurvedNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onOpenMap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onOrdersTap;
  final VoidCallback? onEarningsTap;
  final VoidCallback? onHomeTap;

  /// Active tab accent color (defaults to orange #EA580C matching mockup).
  final Color activeColor;

  /// Inactive tab icon/text color.
  final Color inactiveColor;

  /// Elevated center button color (orange #EA580C or blue #2563EB).
  final Color centerButtonColor;

  /// Optional gradient colors for elevated center button.
  final List<Color>? centerButtonGradientColors;

  /// Icon in the elevated center button (defaults to folded map icon).
  final IconData centerIcon;

  const DeliveryBottomCurvedNavBar({
    super.key,
    this.currentIndex = 0,
    this.onTabSelected,
    this.onOpenMap,
    this.onProfileTap,
    this.onOrdersTap,
    this.onEarningsTap,
    this.onHomeTap,
    this.activeColor = const Color(0xFFEA580C),
    this.inactiveColor = const Color(0xFF64748B),
    this.centerButtonColor = const Color(0xFFEA580C),
    this.centerButtonGradientColors,
    this.centerIcon = Icons.map_rounded,
  });

  void _handleMapTap(BuildContext context) {
    onTabSelected?.call(2);
    if (onOpenMap != null) {
      onOpenMap!();
    } else {
      try {
        GoRouter.maybeOf(context)?.push('/delivery/map');
      } catch (_) {
        try {
          DeliveryLiveMapModal.show(context);
        } catch (_) {}
      }
    }
  }

  void _handleProfileTap(BuildContext context) {
    onTabSelected?.call(4);
    if (onProfileTap != null) {
      onProfileTap!();
    } else {
      try {
        GoRouter.maybeOf(context)?.push('/profile/delivery');
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: true,
      child: Container(
        height: 78,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Pill Bar Container
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // 1. Home (active orange #EA580C by default)
                  _buildNavItem(
                    context: context,
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () {
                      onTabSelected?.call(0);
                      onHomeTap?.call();
                    },
                  ),

                  // 2. Orders
                  _buildNavItem(
                    context: context,
                    index: 1,
                    icon: Icons.description_outlined,
                    label: 'Orders',
                    onTap: () {
                      onTabSelected?.call(1);
                      onOrdersTap?.call();
                    },
                  ),

                  // 3. Center Map Slot (under elevated circular button)
                  Expanded(
                    child: InkWell(
                      onTap: () => _handleMapTap(context),
                      borderRadius: BorderRadius.circular(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const SizedBox(height: 28),
                          Text(
                            'Map',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: currentIndex == 2 ? FontWeight.bold : FontWeight.w600,
                              color: currentIndex == 2 ? activeColor : inactiveColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ),

                  // 4. Earnings
                  _buildEarningsNavItem(context),

                  // 5. Profile (navigates to /profile/delivery)
                  _buildNavItem(
                    context: context,
                    index: 4,
                    icon: Icons.person_outline_rounded,
                    label: 'Profile',
                    onTap: () => _handleProfileTap(context),
                  ),
                ],
              ),
            ),

            // Elevated Circular Center Map Button (protrudes neatly above the pill)
            Positioned(
              top: 0,
              child: GestureDetector(
                key: const Key('elevated_map_circle_button'),
                onTap: () => _handleMapTap(context),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: centerButtonGradientColors ?? [centerButtonColor, const Color(0xFFF97316)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: Colors.white, width: 3.5),
                    boxShadow: [
                      BoxShadow(
                        color: centerButtonColor.withValues(alpha: 0.38),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      centerIcon,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsNavItem(BuildContext context) {
    final isSelected = currentIndex == 3;
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: InkWell(
        onTap: () {
          onTabSelected?.call(3);
          onEarningsTap?.call();
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 1.6),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.currency_rupee_rounded,
                size: 13,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Earnings',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
