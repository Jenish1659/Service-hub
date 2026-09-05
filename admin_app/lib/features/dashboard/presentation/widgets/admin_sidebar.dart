import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final String activeTab;
  final Function(String tab) onTabSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const AdminSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    this.isCollapsed = false,
    required this.onToggleCollapse,
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
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                _buildNavItem('Dashboard', Icons.dashboard_rounded),

                _buildGroupHeader('BOOKINGS'),
                _buildNavItem('AC Service Bookings', Icons.calendar_month_rounded),
                _buildNavItem('All Bookings', Icons.list_alt_rounded),

                _buildGroupHeader('PARTNER OPERATIONS'),
                _buildNavItem('Partner Verification', Icons.verified_user_rounded),
                _buildNavItem('Service Partners', Icons.handshake_rounded),

                _buildGroupHeader('PLATFORM MANAGEMENT'),
                _buildNavItem('Customers', Icons.people_rounded),
                _buildNavItem('Services', Icons.home_repair_service_rounded),
                _buildNavItem('Finance', Icons.account_balance_wallet_rounded),
                _buildNavItem('Support Tickets', Icons.support_agent_rounded),
                _buildNavItem('AI Operations', Icons.psychology_rounded),
                _buildNavItem('Settings', Icons.settings_rounded),
              ],
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

  Widget _buildNavItem(String title, IconData icon) {
    final isSelected = activeTab == title;
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
            Icon(icon, size: 17, color: isSelected ? Colors.white : const Color(0xFF94A3B8)),
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
            ],
          ],
        ),
      ),
    );
  }
}
