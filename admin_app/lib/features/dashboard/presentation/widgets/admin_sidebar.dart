import 'package:flutter/material.dart';

class AdminSidebar extends StatelessWidget {
  final String activeTab;
  final Function(String) onTabSelected;
  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  const AdminSidebar({
    super.key,
    required this.activeTab,
    required this.onTabSelected,
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  @override
  Widget build(BuildContext context) {
    const sidebarBg = Colors.white;
    const activeBg = Color(0xFFEEF2FF); // Soft indigo background
    const activeText = Color(0xFF4F46E5); // Indigo accent
    const inactiveText = Color(0xFF64748B);
    const subheaderColor = Color(0xFF94A3B8);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? 76 : 248,
      decoration: const BoxDecoration(
        color: sidebarBg,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        children: [
          // Logo Header
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.centerLeft,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2563EB).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(Icons.hub_rounded, color: Colors.white, size: 22),
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ServiceHub',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Admin Panel',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Nav Items Scroll List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
              children: [
                // Top Item: Dashboard
                _buildNavItem(
                  title: 'Dashboard',
                  icon: Icons.dashboard_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                const SizedBox(height: 14),

                // SECTION: BOOKINGS
                _buildSectionHeader('BOOKINGS', subheaderColor),
                _buildNavItem(
                  title: 'All Bookings',
                  icon: Icons.calendar_today_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'AC Service Bookings',
                  icon: Icons.ac_unit_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                  badge: 'AC',
                  badgeColor: const Color(0xFF0284C7),
                ),
                _buildNavItem(
                  title: 'Booking Requests',
                  icon: Icons.dynamic_feed_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Assigned Bookings',
                  icon: Icons.assignment_ind_outlined,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Ongoing Services',
                  icon: Icons.pending_actions_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Completed Services',
                  icon: Icons.check_circle_outline_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Cancelled Bookings',
                  icon: Icons.cancel_outlined,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Reviews & Ratings',
                  icon: Icons.star_border_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                const SizedBox(height: 14),

                // SECTION: USERS & PARTNERS
                _buildSectionHeader('USERS & PARTNERS', subheaderColor),
                _buildNavItem(
                  title: 'Customers',
                  icon: Icons.people_outline_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Service Partners',
                  icon: Icons.handshake_outlined,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Partner Applications',
                  icon: Icons.assignment_outlined,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Partner Verification',
                  icon: Icons.verified_user_outlined,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                  badge: 'AI',
                  badgeColor: const Color(0xFF10B981),
                ),
                _buildNavItem(
                  title: 'Partner Documents',
                  icon: Icons.description_outlined,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                const SizedBox(height: 14),

                // SECTION: SERVICES & SETTINGS
                _buildSectionHeader('SERVICES & SETTINGS', subheaderColor),
                _buildNavItem(
                  title: 'Services',
                  icon: Icons.grid_view_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'AC Service Types',
                  icon: Icons.mode_fan_off_outlined,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Service Areas',
                  icon: Icons.location_on_outlined,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Pricing & Charges',
                  icon: Icons.currency_rupee_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Coupons & Offers',
                  icon: Icons.local_offer_outlined,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'System Settings',
                  icon: Icons.settings_outlined,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                const SizedBox(height: 14),

                // SECTION: FINANCE
                _buildSectionHeader('FINANCE', subheaderColor),
                _buildNavItem(
                  title: 'Transactions',
                  icon: Icons.receipt_long_outlined,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Payouts',
                  icon: Icons.payments_outlined,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Earnings',
                  icon: Icons.trending_up_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Refunds',
                  icon: Icons.undo_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                const SizedBox(height: 14),

                // SECTION: SUPPORT & CONTENT
                _buildSectionHeader('SUPPORT & CONTENT', subheaderColor),
                _buildNavItem(
                  title: 'Support Tickets',
                  icon: Icons.support_agent_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'Notifications',
                  icon: Icons.notifications_none_rounded,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
                _buildNavItem(
                  title: 'CMS & Pages',
                  icon: Icons.article_outlined,
                  activeBg: activeBg,
                  activeText: activeText,
                  inactiveText: inactiveText,
                ),
              ],
            ),
          ),

          // Collapse Toggle Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.spaceBetween,
              children: [
                if (!isCollapsed)
                  const Expanded(
                    child: Text(
                      'Collapse Sidebar',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                InkWell(
                  onTap: onToggleCollapse,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Icon(
                      isCollapsed ? Icons.chevron_right_rounded : Icons.chevron_left_rounded,
                      size: 18,
                      color: const Color(0xFF475569),
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

  Widget _buildSectionHeader(String title, Color color) {
    if (isCollapsed) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Divider(color: Color(0xFFF1F5F9), thickness: 1, indent: 8, endIndent: 8),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required String title,
    required IconData icon,
    required Color activeBg,
    required Color activeText,
    required Color inactiveText,
    String? badge,
    Color? badgeColor,
  }) {
    final isSelected = activeTab == title;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTabSelected(title),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? activeBg : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: isSelected ? activeText : inactiveText,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? activeText : const Color(0xFF334155),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (badgeColor ?? activeText).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: badgeColor ?? activeText,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
