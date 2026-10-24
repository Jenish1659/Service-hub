import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/customer_profile_service.dart';
import 'screens/customer_personal_info_screen.dart';
import 'screens/customer_addresses_screen.dart';
import 'screens/customer_payment_methods_screen.dart';
import 'screens/customer_my_bookings_screen.dart';
import 'screens/customer_saved_services_screen.dart';
import 'screens/customer_notifications_screen.dart';
import 'screens/customer_settings_screen.dart';
import 'screens/customer_help_support_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late Map<String, dynamic> _profile;
  late Map<String, dynamic> _metrics;

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);



  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _profile = CustomerProfileService.instance.getProfile();
      _metrics = CustomerProfileService.instance.getMetrics();
    });
  }

  Future<void> _navigateTo(Widget screen) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
    _loadData();
  }

  Widget _buildAvatarContent(String? avatarUrl, String? name) {
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      final clean = avatarUrl.trim();
      if (!clean.startsWith('http://') && !clean.startsWith('https://')) {
        final f = File(clean);
        if (f.existsSync()) {
          return Image.file(f, fit: BoxFit.cover, width: 84, height: 84);
        }
      } else {
        return Image.network(
          clean,
          fit: BoxFit.cover,
          width: 84,
          height: 84,
          errorBuilder: (_, __, ___) => _buildInitials(name),
        );
      }
    }
    return _buildInitials(name);
  }

  Widget _buildInitials(String? name) {
    final clean = (name ?? '').trim();
    final initial = clean.isNotEmpty ? clean[0].toUpperCase() : 'A';
    return Center(
      child: Text(
        initial,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: primaryBlue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadNotifs = CustomerProfileService.instance
        .getNotifications()
        .where((n) => n['is_read'] != true)
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: darkSlate,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: darkSlate, size: 24),
            onPressed: () => _navigateTo(const CustomerSettingsScreen()),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined, color: darkSlate, size: 24),
                onPressed: () => _navigateTo(const CustomerNotificationsScreen()),
              ),
              if (unreadNotifs > 0)
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        '$unreadNotifs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _loadData(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // 1. User Avatar, Name, and Premium User Badge
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _navigateTo(const CustomerPersonalInfoScreen()),
                          child: Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEFF6FF),
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _buildAvatarContent(
                                _profile['avatar_url']?.toString(),
                                _profile['full_name']?.toString(),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: () => _navigateTo(const CustomerPersonalInfoScreen()),
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: primaryBlue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _profile['full_name'] ?? 'Customer User',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: darkSlate,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.military_tech_rounded, color: Color(0xFFF59E0B), size: 16),
                        const SizedBox(width: 4),
                        Text(
                          _profile['tier'] ?? 'Premium User',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. 4-Metrics Row Card (Bookings, Addresses, Saved, Total Spent)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderGrey),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _buildMetricColumn(
                      count: '${_metrics['bookings_count'] ?? 0}',
                      label: 'Bookings',
                      onTap: () => _navigateTo(const CustomerMyBookingsScreen()),
                    ),
                    _buildVerticalDivider(),
                    _buildMetricColumn(
                      count: '${_metrics['addresses_count'] ?? 0}',
                      label: 'Addresses',
                      onTap: () => _navigateTo(const CustomerAddressesScreen()),
                    ),
                    _buildVerticalDivider(),
                    _buildMetricColumn(
                      count: '${_metrics['saved_count'] ?? 0}',
                      label: 'Saved',
                      onTap: () => _navigateTo(const CustomerSavedServicesScreen()),
                    ),
                    _buildVerticalDivider(),
                    _buildMetricColumn(
                      count: '₹${((_metrics['total_spent'] as num?) ?? 0).toInt()}',
                      label: 'Total Spent',
                      onTap: () => _navigateTo(const CustomerMyBookingsScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 3. Navigation Menu List Card
              Material(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: borderGrey),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildMenuItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Personal Information',
                      onTap: () => _navigateTo(const CustomerPersonalInfoScreen()),
                    ),
                    const Divider(height: 1, color: borderGrey, indent: 56),
                    _buildMenuItem(
                      icon: Icons.location_on_outlined,
                      title: 'Addresses',
                      onTap: () => _navigateTo(const CustomerAddressesScreen()),
                    ),
                    const Divider(height: 1, color: borderGrey, indent: 56),
                    _buildMenuItem(
                      icon: Icons.credit_card_outlined,
                      title: 'Payment Methods',
                      onTap: () => _navigateTo(const CustomerPaymentMethodsScreen()),
                    ),
                    const Divider(height: 1, color: borderGrey, indent: 56),
                    _buildMenuItem(
                      icon: Icons.calendar_today_outlined,
                      title: 'My Bookings',
                      onTap: () => _navigateTo(const CustomerMyBookingsScreen()),
                    ),
                    const Divider(height: 1, color: borderGrey, indent: 56),
                    _buildMenuItem(
                      icon: Icons.bookmark_outline_rounded,
                      title: 'Saved Services',
                      onTap: () => _navigateTo(const CustomerSavedServicesScreen()),
                    ),
                    const Divider(height: 1, color: borderGrey, indent: 56),
                    _buildMenuItem(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      onTap: () => _navigateTo(const CustomerNotificationsScreen()),
                    ),
                    const Divider(height: 1, color: borderGrey, indent: 56),
                    _buildMenuItem(
                      icon: Icons.headset_mic_outlined,
                      title: 'Help & Support',
                      onTap: () => _navigateTo(const CustomerHelpSupportScreen()),
                    ),
                    const Divider(height: 1, color: borderGrey, indent: 56),
                    _buildMenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Settings',
                      onTap: () => _navigateTo(const CustomerSettingsScreen()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricColumn({
    required String count,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              count,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: darkSlate,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 28,
      color: borderGrey,
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: primaryBlue, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
          color: darkSlate,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
    );
  }
}
