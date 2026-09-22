import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/shopkeeper_profile_controller.dart';
import 'shopkeeper_edit_profile_screen.dart';
import 'shopkeeper_documents_screen.dart';

class ShopkeeperProfileScreen extends StatefulWidget {
  final ShopkeeperProfileController? controller;
  const ShopkeeperProfileScreen({super.key, this.controller});

  @override
  State<ShopkeeperProfileScreen> createState() => _ShopkeeperProfileScreenState();
}

class _ShopkeeperProfileScreenState extends State<ShopkeeperProfileScreen> {
  late final ShopkeeperProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? ShopkeeperProfileController();
    _controller.addListener(_onControllerUpdate);
    if (widget.controller == null) {
      _controller.loadShopkeeperProfile();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  void _showTimingsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.access_time_rounded, color: Color(0xFF16A34A), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Text('Store Operating Hours', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Current Store Status', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        SizedBox(height: 2),
                        Text('Open for Customers & Orders', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                      ],
                    ),
                    Switch(
                      value: _controller.isOpen,
                      activeTrackColor: const Color(0xFF16A34A),
                      onChanged: (v) {
                        _controller.toggleStoreStatus(v);
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Opening Time', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text(_controller.openTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Closing Time', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 4),
                          Text(_controller.closeTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text('Operating Days: Mon, Tue, Wed, Thu, Fri, Sat (Sunday Closed)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Save Timings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Are you sure you want to log out of your Shopkeeper account?', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _controller.logout();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out of Shopkeeper account successfully'),
                    backgroundColor: Color(0xFF16A34A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                context.go('/role-selection');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldColor = Color(0xFF16A34A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  InkWell(
                    onTap: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      } else {
                        context.go('/dashboard/shopkeeper');
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Store Profile',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Manage your store and merchant preferences',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: emeraldColor, size: 22),
                    tooltip: 'Edit Store Details',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ShopkeeperEditProfileScreen(controller: _controller)),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Profile Body Content
            Expanded(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator(color: emeraldColor))
                  : SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Main Store Identity Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFECFDF5), Colors.white],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
                              boxShadow: const [
                                BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Store Avatar
                                    Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: emeraldColor, width: 2),
                                      ),
                                      child: const Icon(Icons.storefront_rounded, size: 36, color: emeraldColor),
                                    ),
                                    const SizedBox(width: 14),

                                    // Store Name, Owner, Category
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _controller.shopName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.verified_rounded, size: 18, color: emeraldColor),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Owner: ${_controller.ownerName}',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _controller.category,
                                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                          ),
                                          const SizedBox(height: 6),
                                          // Verified Status Pill
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFDCFCE7),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  width: 6,
                                                  height: 6,
                                                  decoration: const BoxDecoration(color: emeraldColor, shape: BoxShape.circle),
                                                ),
                                                const SizedBox(width: 5),
                                                const Text(
                                                  'Verified Merchant ✓',
                                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Address & Years in Business Row
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined, size: 14, color: Color(0xFF64748B)),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${_controller.address}, ${_controller.city}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                                        ),
                                      ),
                                      const Text('|', style: TextStyle(color: Color(0xFFCBD5E1))),
                                      const SizedBox(width: 6),
                                      Text(
                                        _controller.yearsInBusiness,
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Store Metrics Row (4 Metrics)
                          Row(
                            children: [
                              _buildMetricCard(
                                icon: Icons.category_rounded,
                                iconColor: const Color(0xFF2563EB),
                                iconBg: const Color(0xFFEFF6FF),
                                value: '${_controller.activeProductsCount}',
                                label: 'Products',
                              ),
                              const SizedBox(width: 10),
                              _buildMetricCard(
                                icon: Icons.shopping_bag_rounded,
                                iconColor: emeraldColor,
                                iconBg: const Color(0xFFDCFCE7),
                                value: '${_controller.ordersProcessedCount}',
                                label: 'Orders',
                              ),
                              const SizedBox(width: 10),
                              _buildMetricCard(
                                icon: Icons.currency_rupee_rounded,
                                iconColor: const Color(0xFFD97706),
                                iconBg: const Color(0xFFFEF3C7),
                                value: '₹34.5k',
                                label: 'Revenue',
                              ),
                              const SizedBox(width: 10),
                              _buildMetricCard(
                                icon: Icons.star_rounded,
                                iconColor: const Color(0xFFEAB308),
                                iconBg: const Color(0xFFFEF9C3),
                                value: '${_controller.rating}',
                                label: 'Rating',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Store Management Menu Options
                          _buildMenuTile(
                            icon: Icons.edit_note_rounded,
                            iconColor: const Color(0xFF2563EB),
                            iconBg: const Color(0xFFEFF6FF),
                            title: 'Edit Store Profile',
                            subtitle: 'Update shop name, contact, address & category',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ShopkeeperEditProfileScreen(controller: _controller)),
                              );
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.access_time_rounded,
                            iconColor: emeraldColor,
                            iconBg: const Color(0xFFDCFCE7),
                            title: 'Store Operating Timings',
                            subtitle: 'Set opening/closing hours and operating days',
                            onTap: _showTimingsModal,
                          ),
                          _buildMenuTile(
                            icon: Icons.verified_user_rounded,
                            iconColor: const Color(0xFF9333EA),
                            iconBg: const Color(0xFFF3E8FF),
                            title: 'Store Documents & KYC',
                            subtitle: 'Shop Licence, Aadhaar, PAN & Storefront verification',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ShopkeeperDocumentsScreen(controller: _controller)),
                              );
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.account_balance_rounded,
                            iconColor: const Color(0xFF0D9488),
                            iconBg: const Color(0xFFCCFBF1),
                            title: 'Settlement Bank Account',
                            subtitle: '${_controller.bankName} • Acc ${_controller.accountNumber}',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Registered Account: ${_controller.accountNumber} (${_controller.bankName})'),
                                  backgroundColor: const Color(0xFF0D9488),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.notifications_active_outlined,
                            iconColor: const Color(0xFFEA580C),
                            iconBg: const Color(0xFFFFF7ED),
                            title: 'Store Settings & Sound Alerts',
                            subtitle: 'Order alert chimes, notifications & preferences',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Store Sound & Order Notifications: ACTIVE ✓'),
                                  backgroundColor: Color(0xFF16A34A),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.support_agent_rounded,
                            iconColor: const Color(0xFF2563EB),
                            iconBg: const Color(0xFFEFF6FF),
                            title: 'Merchant Support & Help',
                            subtitle: 'Contact ServiceHub Merchant Helpdesk or WhatsApp',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Merchant Support: support@servicehub.com • +91 1800 200 4567'),
                                  backgroundColor: Color(0xFF2563EB),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.logout_rounded,
                            iconColor: const Color(0xFFEF4444),
                            iconBg: const Color(0xFFFEE2E2),
                            title: 'Sign Out from Store',
                            subtitle: 'Safely logout of your shopkeeper portal',
                            onTap: _showSignOutDialog,
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
