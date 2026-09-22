import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/widgets/profile_avatar_widget.dart';
import 'package:service_hub_partner/features/profile/presentation/widgets/profile_metric_card.dart';
import 'package:service_hub_partner/features/profile/presentation/widgets/profile_menu_item_tile.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/my_services_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/availability_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/earnings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/service_area_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/settings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/documents_and_verification_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/help_and_support_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final ProfileController _controller = ProfileController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onControllerUpdate);
    _controller.loadProfileData();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    _controller.dispose();
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
        content: const Text('Are you sure you want to logout from your account?', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
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
              await LocalRegistrationCache.logout();
              if (mounted) {
                TopToast.show(context, 'Signed out successfully', isError: false);
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
                        context.go('/dashboard');
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
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
                          'My Profile',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Manage your account and preferences',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  // Notification Bell with Badge
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_none_rounded, size: 20, color: Color(0xFF1E293B)),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '0',
                            style: TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Mini Avatar
                  ProfileAvatarWidget(
                    photoPath: _controller.profilePhotoPath,
                    name: _controller.partnerName,
                    size: 34,
                    showCameraBadge: false,
                  ),
                ],
              ),
            ),

            // Scrollable Profile Content with Zero-Overflow Guarantee
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _controller.loadProfileData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Main Partner Identity Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEFF6FF), Colors.white],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFDBEAFE), width: 1.2),
                        boxShadow: const [
                          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Large Avatar with Camera Icon
                              ProfileAvatarWidget(
                                photoPath: _controller.profilePhotoPath,
                                name: _controller.partnerName,
                                size: 76,
                                showCameraBadge: true,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => EditProfileScreen(controller: _controller)),
                                  );
                                },
                              ),
                              const SizedBox(width: 14),

                              // Name, Category, Verified Badge, Rating
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            _controller.partnerName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF2563EB)),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _controller.categoryTitle,
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                                    ),
                                    const SizedBox(height: 6),
                                    // Status Pill Badge
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Container(
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
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF16A34A),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            const Text(
                                              'Verified Partner',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF15803D),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Rating and Experience Row
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFEAB308)),
                                          const SizedBox(width: 3),
                                          Text(
                                            _controller.averageRating.toStringAsFixed(1),
                                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                          ),
                                          const SizedBox(width: 8),
                                          const Text('|', style: TextStyle(color: Color(0xFFCBD5E1))),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.work_outline_rounded, size: 14, color: Color(0xFF64748B)),
                                          const SizedBox(width: 4),
                                          Text(
                                            _controller.experienceYears,
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
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

                          // Tagline Motto Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9).withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '“Good Service Builds Better Tomorrows”',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 3 Metric Cards (Real Database State: Jobs Completed, Earnings, Ratings)
                    Row(
                      children: [
                        ProfileMetricCard(
                          icon: Icons.work_outline_rounded,
                          iconBgColor: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF16A34A),
                          value: '${_controller.jobsCompletedThisMonth}',
                          label: 'Jobs Completed',
                          subLabel: 'This Month',
                        ),
                        const SizedBox(width: 10),
                        ProfileMetricCard(
                          icon: Icons.account_balance_wallet_outlined,
                          iconBgColor: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF2563EB),
                          value: '₹${_controller.totalEarnings == 0 ? "0" : _controller.totalEarnings.toStringAsFixed(0)}',
                          label: 'Earnings',
                          subLabel: 'Total Earned',
                        ),
                        const SizedBox(width: 10),
                        ProfileMetricCard(
                          icon: Icons.star_rounded,
                          iconBgColor: const Color(0xFFFEF3C7),
                          iconColor: const Color(0xFFD97706),
                          value: _controller.averageRating.toStringAsFixed(1),
                          label: 'Ratings',
                          subLabel: 'From Customers',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Menu Options
                    ProfileMenuItemTile(
                      icon: Icons.person_outline_rounded,
                      iconBgColor: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Edit Profile',
                      subtitle: 'Update your personal and business details',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EditProfileScreen(controller: _controller)),
                        );
                      },
                    ),
                    ProfileMenuItemTile(
                      icon: Icons.business_center_outlined,
                      iconBgColor: const Color(0xFFFDF4FF),
                      iconColor: const Color(0xFFC026D3),
                      title: 'My Services',
                      subtitle: 'Manage the services you offer',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => MyServicesScreen(controller: _controller)),
                        );
                      },
                    ),
                    ProfileMenuItemTile(
                      icon: Icons.access_time_rounded,
                      iconBgColor: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Availability',
                      subtitle: 'Set your working hours and days',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => AvailabilityScreen(controller: _controller)),
                        );
                      },
                    ),
                    ProfileMenuItemTile(
                      icon: Icons.location_on_outlined,
                      iconBgColor: const Color(0xFFFFF1F2),
                      iconColor: const Color(0xFFE11D48),
                      title: 'Service Area',
                      subtitle: 'Manage your working area and service radius',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ServiceAreaScreen(controller: _controller)),
                        );
                      },
                    ),
                    ProfileMenuItemTile(
                      icon: Icons.description_outlined,
                      iconBgColor: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Documents & Verification',
                      subtitle: 'View and manage your documents',
                      trailingBadge: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DocumentsAndVerificationScreen(controller: _controller)),
                        );
                      },
                    ),
                    ProfileMenuItemTile(
                      icon: Icons.account_balance_wallet_outlined,
                      iconBgColor: const Color(0xFFECFDF5),
                      iconColor: const Color(0xFF059669),
                      title: 'Earnings',
                      subtitle: 'View your earnings and payment history',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => EarningsScreen(controller: _controller)),
                        );
                      },
                    ),
                    ProfileMenuItemTile(
                      icon: Icons.settings_outlined,
                      iconBgColor: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Settings',
                      subtitle: 'App preferences, notifications and privacy',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SettingsScreen(controller: _controller)),
                        );
                      },
                    ),
                    ProfileMenuItemTile(
                      icon: Icons.help_outline_rounded,
                      iconBgColor: const Color(0xFFF5F3FF),
                      iconColor: const Color(0xFF7C3AED),
                      title: 'Help & Support',
                      subtitle: 'Get help, FAQs and contact support',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => HelpAndSupportScreen(controller: _controller)),
                        );
                      },
                    ),
                    ProfileMenuItemTile(
                      icon: Icons.logout_rounded,
                      iconBgColor: const Color(0xFFFEE2E2),
                      iconColor: const Color(0xFFDC2626),
                      title: 'Sign Out',
                      subtitle: 'Logout from your account',
                      isDestructive: true,
                      onTap: _showSignOutDialog,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),

            // Bottom Navigation Bar
            _buildBottomNavBar(context),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                icon: Icons.home_outlined,
                label: 'Dashboard',
                isSelected: false,
                onTap: () => context.go('/dashboard'),
              ),
              _buildNavItem(
                icon: Icons.business_center_outlined,
                label: 'Jobs',
                isSelected: false,
                onTap: () => context.go('/dashboard'),
              ),
              // Center Map Action Button
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: () => context.go('/dashboard'),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF38BDF8), Color(0xFF2563EB)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x402563EB),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                ),
              ),
              _buildNavItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Earnings',
                isSelected: false,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => EarningsScreen(controller: _controller)),
                  );
                },
              ),
              _buildNavItem(
                icon: Icons.person_rounded,
                label: 'Profile',
                isSelected: true,
                onTap: () {},
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                  ),
                ),
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  width: 4,
                  height: 4,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
