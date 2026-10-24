import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/widgets/delivery_recent_and_nav_widget.dart';
import '../controllers/delivery_agent_profile_controller.dart';
import 'delivery_edit_profile_screen.dart';

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

  Widget _buildAvatar() {
    final photo = (_controller.agentData?['profile_image'] ?? _controller.agentData?['avatar_url'] ?? _controller.agentData?['photo_path'])?.toString().trim();
    if (photo != null && photo.isNotEmpty) {
      final isNetwork = photo.startsWith('http://') || photo.startsWith('https://');
      if (!isNetwork) {
        final f = File(photo);
        if (f.existsSync()) {
          return ClipOval(child: Image.file(f, fit: BoxFit.cover, width: 72, height: 72));
        }
      } else {
        return ClipOval(
          child: Image.network(
            photo,
            fit: BoxFit.cover,
            width: 72,
            height: 72,
            errorBuilder: (_, __, ___) => _buildInitials(),
          ),
        );
      }
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    final clean = _controller.agentName.trim();
    if (clean.isNotEmpty && clean != 'Delivery Partner') {
      return Center(
        child: Text(
          clean[0].toUpperCase(),
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.deliveryOrangeDark),
        ),
      );
    }
    return const Center(child: Icon(Icons.two_wheeler_rounded, size: 38, color: AppColors.deliveryOrangeDark));
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 22),
            ),
            const SizedBox(width: 12),
            const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of your Delivery Partner account? You will stop receiving order dispatches.',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
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

  Widget _buildTopBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: Color(0x20EA580C), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
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
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ServiceHub DELIVERY PARTNER',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFFFFEDD5)),
                ),
                Text(
                  'Rider Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () async {
              await context.push('/profile/delivery/settings', extra: _controller);
              _controller.loadDeliveryProfile();
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.notifications_outlined, size: 20, color: Colors.white),
            ),
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
        child: (_controller.isLoading && _controller.agentData == null && _controller.agentName == 'Delivery Partner')
            ? const Center(child: CircularProgressIndicator(color: orangeColor))
            : SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  children: [
                    // Top Delivery Partner Header Banner (Inside scroll view - scrolls with content)
                    _buildTopBanner(context),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Main Rider Identity Card (Screen 1 with Camera Badge & Verified Status)
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
                                BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 4)),
                              ],
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Avatar with Camera Icon Overlay
                                    GestureDetector(
                                      onTap: () async {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (_) => DeliveryEditProfileScreen(controller: _controller)),
                                        );
                                        _controller.loadDeliveryProfile();
                                      },
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 72,
                                            height: 72,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFEDD5),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: orangeColor, width: 2.5),
                                            ),
                                            child: _buildAvatar(),
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              padding: const EdgeInsets.all(5),
                                              decoration: const BoxDecoration(
                                                color: orangeColor,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                            ),
                                          ),
                                        ],
                                      ),
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
                                              const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF16A34A)),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
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
                                          const SizedBox(height: 2),
                                          Text(
                                            _controller.accountNumber.isNotEmpty
                                                ? (_controller.bankName.isNotEmpty
                                                    ? '${_controller.bankName} • Acc ${_controller.accountNumber}'
                                                    : 'Acc ${_controller.accountNumber}')
                                                : 'No Bank Account Linked',
                                            style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFDCFCE7),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 12),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      'Verified Rider ✓',
                                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
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

                          // Delivery Metrics Row (Screen 1: 4 Cards Starting Strictly at Zero)
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

                          // Availability Beacon Banner
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                              boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _controller.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.power_settings_new_rounded,
                                    color: _controller.isOnline ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _controller.isOnline ? 'Online Status: ACTIVE' : 'Online Status: OFFLINE',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A)),
                                      ),
                                      Text(
                                        _controller.isOnline
                                            ? 'Receiving orders in Jamnagar zone'
                                            : 'Go online to receive delivery requests',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: _controller.isOnline,
                                  activeTrackColor: orangeColor,
                                  onChanged: (v) => _controller.toggleOnline(v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Section Header: PROFILE MANAGEMENT
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                'PROFILE & WORKSPACE',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF94A3B8)),
                              ),
                            ),
                          ),

                          // 7 Core Menu Items (Screen 1 Redesign with Live Sync & Controller Injection)
                          _buildModernMenuTile(
                            icon: Icons.person_outline_rounded,
                            iconColor: const Color(0xFF2563EB),
                            iconBg: const Color(0xFFEFF6FF),
                            title: 'Edit Profile',
                            subtitle: 'Personal details, photo, email & phone',
                            onTap: () async {
                              await context.push('/profile/delivery/edit', extra: _controller);
                              _controller.loadDeliveryProfile();
                            },
                          ),
                          _buildModernMenuTile(
                            icon: Icons.access_time_rounded,
                            iconColor: const Color(0xFF059669),
                            iconBg: const Color(0xFFDCFCE7),
                            title: 'Availability & Shift',
                            subtitle: 'Working days, duty timings & auto-offline',
                            onTap: () async {
                              await context.push('/profile/delivery/shift', extra: _controller);
                              _controller.loadDeliveryProfile();
                            },
                          ),
                          _buildModernMenuTile(
                            icon: Icons.location_on_outlined,
                            iconColor: orangeColor,
                            iconBg: const Color(0xFFFFEDD5),
                            title: 'Delivery Area',
                            subtitle: 'Operating radius (5-40 km) & preferred hubs',
                            onTap: () async {
                              await context.push('/profile/delivery/area', extra: _controller);
                              _controller.loadDeliveryProfile();
                            },
                          ),
                          _buildModernMenuTile(
                            icon: Icons.verified_user_outlined,
                            iconColor: const Color(0xFF7C3AED),
                            iconBg: const Color(0xFFF3E8FF),
                            title: 'Vehicle & Driving Documents',
                            subtitle: 'RC book, DL, Aadhaar, PAN & UPI status',
                            onTap: () async {
                              await context.push('/profile/delivery/documents', extra: _controller);
                              _controller.loadDeliveryProfile();
                            },
                          ),
                          _buildModernMenuTile(
                            icon: Icons.account_balance_wallet_outlined,
                            iconColor: const Color(0xFF0D9488),
                            iconBg: const Color(0xFFCCFBF1),
                            title: 'Earnings & Payouts',
                            subtitle: 'Daily breakdown, payout history & trip logs',
                            onTap: () async {
                              await context.push('/profile/delivery/earnings', extra: _controller);
                              _controller.loadDeliveryProfile();
                            },
                          ),
                          _buildModernMenuTile(
                            icon: Icons.settings_outlined,
                            iconColor: const Color(0xFF475569),
                            iconBg: const Color(0xFFF1F5F9),
                            title: 'Settings',
                            subtitle: 'Security, notifications & preferences',
                            onTap: () async {
                              await context.push('/profile/delivery/settings', extra: _controller);
                              _controller.loadDeliveryProfile();
                            },
                          ),
                          _buildModernMenuTile(
                            icon: Icons.help_outline_rounded,
                            iconColor: const Color(0xFFEA580C),
                            iconBg: const Color(0xFFFFEDD5),
                            title: 'Help & Support',
                            subtitle: '24/7 hotline, emergency SOS & FAQs',
                            onTap: () async {
                              await context.push('/profile/delivery/help', extra: _controller);
                              _controller.loadDeliveryProfile();
                            },
                          ),

                          const SizedBox(height: 12),

                          // Sign Out Button (Screen 15 Modal Trigger)
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFFEE2E2)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showSignOutDialog,
                                borderRadius: BorderRadius.circular(16),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.logout_rounded, color: Color(0xFFEF4444), size: 18),
                                      SizedBox(width: 8),
                                      Text(
                                        'Sign Out from Partner Portal',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFFEF4444)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: DeliveryBottomCurvedNavBar(
        currentIndex: 4,
        onHomeTap: () => context.go('/dashboard/delivery'),
        onOrdersTap: () => context.go('/dashboard/delivery'),
        onOpenMap: () => context.push('/delivery/map'),
        onEarningsTap: () async {
          await context.push('/profile/delivery/earnings', extra: _controller);
          _controller.loadDeliveryProfile();
        },
        onProfileTap: () {},
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
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
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

  Widget _buildModernMenuTile({
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
        boxShadow: const [BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
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
