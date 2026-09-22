import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../controllers/delivery_agent_profile_controller.dart';

class DeliveryAgentProfileScreen extends StatefulWidget {
  final DeliveryAgentProfileController? controller;
  const DeliveryAgentProfileScreen({super.key, this.controller});

  @override
  State<DeliveryAgentProfileScreen> createState() => _DeliveryAgentProfileScreenState();
}

class _DeliveryAgentProfileScreenState extends State<DeliveryAgentProfileScreen> {
  late final DeliveryAgentProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? DeliveryAgentProfileController();
    _controller.addListener(_onControllerUpdate);
    if (widget.controller == null) {
      _controller.loadDeliveryProfile();
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

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text('Are you sure you want to log out of your Delivery Partner account?', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
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
                    content: Text('Logged out of Delivery Partner account successfully'),
                    backgroundColor: Color(0xFFEA580C),
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
    const orangeColor = AppColors.deliveryOrangeDark;

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
                        context.go('/dashboard/delivery');
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
                          'Rider Profile',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Manage your delivery vehicle, shifts & payouts',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Profile Body Content
            Expanded(
              child: _controller.isLoading
                  ? const Center(child: CircularProgressIndicator(color: orangeColor))
                  : SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Main Rider Identity Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFF7ED), Colors.white],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFED7AA), width: 1.2),
                              boxShadow: const [
                                BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 68,
                                      height: 68,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFEDD5),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: orangeColor, width: 2),
                                      ),
                                      child: const Icon(Icons.two_wheeler_rounded, size: 36, color: orangeColor),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  _controller.agentName,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              const Icon(Icons.verified_rounded, size: 18, color: orangeColor),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _controller.vehicleRegNumber.isNotEmpty
                                                ? '${_controller.vehicleType} • ${_controller.vehicleRegNumber}'
                                                : '${_controller.vehicleType} • Not Linked / Upload Required',
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569), fontWeight: FontWeight.w500),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            _controller.drivingLicenseNumber.isNotEmpty
                                                ? 'DL: ${_controller.drivingLicenseNumber}'
                                                : 'DL: Not Linked / Upload Required',
                                            style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFFEDD5),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.check_circle_rounded, color: orangeColor, size: 12),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Verified Rider ✓',
                                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: orangeColor),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFFEF9C3),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 12),
                                                    const SizedBox(width: 3),
                                                    Text(
                                                      _controller.reviewCount == 0 && _controller.rating == 0.0
                                                          ? 'New Rider'
                                                          : '${_controller.rating.toStringAsFixed(1)} (${_controller.reviewCount})',
                                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF854D0E)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Delivery Metrics Row (4 Metrics - Strictly Zero Dummy Data)
                          Row(
                            children: [
                              _buildMetricCard(
                                icon: Icons.local_shipping_rounded,
                                iconColor: orangeColor,
                                iconBg: const Color(0xFFFFEDD5),
                                value: '${_controller.completedDeliveries}',
                                label: 'Deliveries',
                              ),
                              const SizedBox(width: 8),
                              _buildMetricCard(
                                icon: Icons.timer_rounded,
                                iconColor: const Color(0xFF16A34A),
                                iconBg: const Color(0xFFDCFCE7),
                                value: '${_controller.onTimeRate.toStringAsFixed(1)}%',
                                label: 'On-Time',
                              ),
                              const SizedBox(width: 8),
                              _buildMetricCard(
                                icon: Icons.currency_rupee_rounded,
                                iconColor: const Color(0xFF2563EB),
                                iconBg: const Color(0xFFEFF6FF),
                                value: _controller.totalEarnings >= 1000
                                    ? '₹${(_controller.totalEarnings / 1000).toStringAsFixed(1)}k'
                                    : '₹${_controller.totalEarnings.toStringAsFixed(0)}',
                                label: 'Earnings',
                              ),
                              const SizedBox(width: 8),
                              _buildMetricCard(
                                icon: Icons.star_rounded,
                                iconColor: const Color(0xFFEAB308),
                                iconBg: const Color(0xFFFEF9C3),
                                value: _controller.reviewCount == 0 && _controller.rating == 0.0
                                    ? 'New Rider'
                                    : _controller.rating.toStringAsFixed(1),
                                label: _controller.reviewCount == 0 && _controller.rating == 0.0
                                    ? '0.0 (0 reviews)'
                                    : 'Rating (${_controller.reviewCount})',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Menu Options
                          _buildMenuTile(
                            icon: Icons.power_settings_new_rounded,
                            iconColor: _controller.isOnline ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                            iconBg: _controller.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                            title: _controller.isOnline ? 'Online Status: ACTIVE' : 'Online Status: OFFLINE',
                            subtitle: _controller.isOnline ? 'Currently receiving local parcel delivery jobs' : 'Tap switch to start receiving delivery orders',
                            trailing: Switch(
                              value: _controller.isOnline,
                              activeTrackColor: orangeColor,
                              onChanged: (v) => _controller.toggleOnline(v),
                            ),
                          ),
                          _buildMenuTile(
                            icon: Icons.two_wheeler_rounded,
                            iconColor: orangeColor,
                            iconBg: const Color(0xFFFFEDD5),
                            title: 'Vehicle & Driving Documents',
                            subtitle: _controller.vehicleRegNumber.isNotEmpty || _controller.drivingLicenseNumber.isNotEmpty
                                ? 'RC: ${_controller.vehicleRegNumber.isNotEmpty ? _controller.vehicleRegNumber : "Not Linked"} • DL: ${_controller.drivingLicenseNumber.isNotEmpty ? _controller.drivingLicenseNumber : "Not Linked"}'
                                : 'Not Linked / Upload Required',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_controller.vehicleRegNumber.isNotEmpty
                                      ? 'Vehicle Documents: RC Book & Driving License VERIFIED ✓'
                                      : 'Vehicle Documents: Not Linked / Upload Required'),
                                  backgroundColor: orangeColor,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.account_balance_rounded,
                            iconColor: const Color(0xFF0D9488),
                            iconBg: const Color(0xFFCCFBF1),
                            title: 'Weekly Payout Account',
                            subtitle: _controller.accountNumber.isNotEmpty
                                ? (_controller.bankName.isNotEmpty
                                    ? '${_controller.bankName} • Acc ${_controller.accountNumber}'
                                    : 'Acc ${_controller.accountNumber}')
                                : 'No Bank Account Linked',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_controller.accountNumber.isNotEmpty
                                      ? 'Payout Account: ${_controller.accountNumber} (${_controller.bankName.isNotEmpty ? _controller.bankName : "Linked"})'
                                      : 'Payout Account: No Bank Account Linked'),
                                  backgroundColor: const Color(0xFF0D9488),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.emergency_rounded,
                            iconColor: const Color(0xFFEF4444),
                            iconBg: const Color(0xFFFEE2E2),
                            title: 'Rider Safety & Emergency SOS',
                            subtitle: '24/7 dedicated rider support and incident response',
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Rider SOS Hotline: 112 • Partner Support: +91 1800 200 9999'),
                                  backgroundColor: Color(0xFFEF4444),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          _buildMenuTile(
                            icon: Icons.logout_rounded,
                            iconColor: const Color(0xFFEF4444),
                            iconBg: const Color(0xFFFEE2E2),
                            title: 'Sign Out from Rider Portal',
                            subtitle: 'Safely logout of your delivery account',
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
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
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            ),
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
    VoidCallback? onTap,
    Widget? trailing,
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
          trailing: trailing ?? const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
