import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final String activeTab;
  final Function(String tab) onTabSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final int shopkeeperCount;
  final int deliveryCount;
  final int partnerCount;

  const AdminSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
    this.shopkeeperCount = 0,
    this.deliveryCount = 0,
    this.partnerCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    const primaryNavy = Color(0xFF0B192C);
    const accentBlue = Color(0xFF2563EB);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 70 : 250,
      decoration: const BoxDecoration(
        color: primaryNavy,
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1E293B), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.hub_rounded, color: Colors.white, size: 20),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ServiceHub', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        Text('Admin Panel', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Scrollable Navigation Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildNavItem('Dashboard', Icons.dashboard_rounded),

                  _buildGroupHeader('ALL SERVICES'),
                  _buildNavItem('All Services', Icons.miscellaneous_services_rounded),

                  _buildGroupHeader('SERVICES / BOOKINGS'),
                  _buildNavItem('AC Service Bookings', Icons.ac_unit_rounded),
                  _buildNavItem('Care Taker Bookings', Icons.elderly_rounded),
                  _buildNavItem('Laundry Bookings', Icons.local_laundry_service_rounded),
                  _buildNavItem('Car Service Bookings', Icons.directions_car_rounded),
                  _buildNavItem('Plumbing Bookings', Icons.plumbing_rounded),
                  _buildNavItem('Cooking Bookings', Icons.restaurant_rounded),
                  _buildNavItem('All Bookings', Icons.list_alt_rounded),

                  _buildGroupHeader('PARTNER OPERATIONS'),
                  _buildNavItem('Partner Verification', Icons.verified_user_rounded, partnerCount),
                  _buildNavItem('Shopkeeper Verification', Icons.storefront_rounded, shopkeeperCount),
                  _buildNavItem('Delivery Agent Verification', Icons.two_wheeler_rounded, deliveryCount),
                  _buildNavItem('Service Partners', Icons.handshake_rounded),

                  _buildGroupHeader('PLATFORM MANAGEMENT'),
                  _buildNavItem('Database Explorer', Icons.storage_rounded),
                  _buildNavItem('Customers', Icons.people_rounded),
                  _buildNavItem('Finance', Icons.account_balance_wallet_rounded),
                  _buildNavItem('Support Tickets', Icons.support_agent_rounded),
                  _buildNavItem('AI Operations', Icons.psychology_rounded),
                  _buildNavItem('Settings', Icons.settings_rounded),
                ],
              ),
            ),
          ),

          // Collapse Toggle
          IconButton(
            icon: Icon(isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded, color: const Color(0xFF94A3B8)),
            onPressed: onToggleCollapse,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    if (isCollapsed) return const SizedBox(height: 10);
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 6),
      child: Text(
        title,
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildNavItem(String title, IconData icon, [int badgeCount = 0]) {
    final isSelected = activeTab == title ||
        ((title == 'All Services' || title == 'Services') && (activeTab == 'All Services' || activeTab == 'Services'));
    return InkWell(
      onTap: () => onTabSelected(title),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, size: 17, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
                if (isCollapsed && badgeCount > 0)
                  Positioned(
                    right: -3,
                    top: -3,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            if (!isCollapsed) ...[
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFFE2E8F0),
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (badgeCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    badgeCount > 99 ? '99+' : '$badgeCount',
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF2563EB) : Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
