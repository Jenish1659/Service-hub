import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/shopkeeper_profile_controller.dart';

class ShopkeeperProfileScreen extends StatefulWidget {
  final ShopkeeperProfileController? controller;

  const ShopkeeperProfileScreen({super.key, this.controller});

  @override
  State<ShopkeeperProfileScreen> createState() => _ShopkeeperProfileScreenState();
}

class _ShopkeeperProfileScreenState extends State<ShopkeeperProfileScreen> {
  late final ShopkeeperProfileController _controller;
  bool _createdInternally = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = ShopkeeperProfileController();
      _createdInternally = true;
      _controller.loadShopkeeperProfile();
    }
    _controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    if (_createdInternally) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Widget _buildStoreAvatar() {
    final photo = (_controller.shopData?['profile_image'] ??
            _controller.shopData?['store_image'] ??
            _controller.shopData?['logo_url'] ??
            _controller.shopData?['avatar_url'] ??
            _controller.shopData?['photo_path'])
        ?.toString()
        .trim();
    if (photo != null && photo.isNotEmpty) {
      final isNetwork = photo.startsWith('http://') || photo.startsWith('https://');
      if (!isNetwork) {
        final f = File(photo);
        if (f.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.file(f, fit: BoxFit.cover, width: 72, height: 72),
          );
        }
      } else {
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            photo,
            fit: BoxFit.cover,
            width: 72,
            height: 72,
            errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, size: 40, color: Colors.white),
          ),
        );
      }
    }
    return const Icon(Icons.storefront_rounded, size: 40, color: Colors.white);
  }

  void _navigateTo(String path) {
    try {
      context.push(path, extra: _controller);
    } catch (e) {
      debugPrint('[ShopkeeperProfile] Navigation failed for $path: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening $path'),
            backgroundColor: const Color(0xFF047857),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Are you sure you want to log out of your Shopkeeper portal?',
          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _controller.logout();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Logged out of Shopkeeper account'),
                    backgroundColor: Color(0xFF047857),
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
    const emeraldGradientStart = Color(0xFF065F46);
    const emeraldGradientEnd = Color(0xFF047857);
    const emeraldPrimary = Color(0xFF047857);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      bottomNavigationBar: _buildBottomNavigationBar(),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Emerald Gradient Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [emeraldGradientStart, emeraldGradientEnd],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top Row: Back button, Title & Edit Icon
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Text(
                            'Shop Profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          InkWell(
                            onTap: () => _navigateTo('/profile/shopkeeper/edit'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Store Identity Content
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Store Avatar with Camera Badge
                          GestureDetector(
                            onTap: () => _navigateTo('/profile/shopkeeper/edit'),
                            child: Stack(
                              children: [
                                Container(
                                  width: 72,
                                  height: 72,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.4),
                                      width: 2,
                                    ),
                                  ),
                                  child: _buildStoreAvatar(),
                                ),
                                Positioned(
                                  bottom: -2,
                                  right: -2,
                                  child: Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black26,
                                          blurRadius: 4,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      size: 13,
                                      color: emeraldPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Details Column
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Verified Shop Badge Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 13,
                                        color: Color(0xFF059669),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified Shop',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF065F46),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Store Name
                                Text(
                                  _controller.shopName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),

                                // Category
                                Text(
                                  _controller.category,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.88),
                                  ),
                                ),
                                const SizedBox(height: 6),

                                // Rating Pill
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.star_rounded,
                                        size: 15,
                                        color: Color(0xFFFBBF24),
                                      ),
                                      const SizedBox(width: 4),
                                        Text(
                                          _controller.reviewCount == 0 && _controller.rating == 0.0
                                              ? 'New Store'
                                              : '★ ${_controller.rating.toStringAsFixed(1)} (${_controller.reviewCount} reviews)',
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Body Menu List
            Expanded(
              child: _controller.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: emeraldPrimary),
                    )
                  : SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: Column(
                        children: [
                          // Update Reminder Banner
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFA7F3D0)),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.campaign_rounded,
                                    color: Color(0xFF047857),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Keep your profile updated',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13.5,
                                          color: Color(0xFF065F46),
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Build trust and get more orders',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF047857),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // 8 Menu Tiles in White Cards (14px rounded corners, subtle shadow)
                          _buildMenuCardTile(
                            icon: Icons.storefront_rounded,
                            iconBg: const Color(0xFFECFDF5),
                            iconColor: const Color(0xFF047857),
                            title: 'Shop Information',
                            subtitle: 'View and manage your shop details',
                            onTap: () => _navigateTo('/profile/shopkeeper/info'),
                          ),
                          _buildMenuCardTile(
                            icon: Icons.access_time_rounded,
                            iconBg: const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF2563EB),
                            title: 'Business Hours',
                            subtitle: 'Store opening & closing timings',
                            onTap: () => _navigateTo('/profile/shopkeeper/hours'),
                          ),
                          _buildMenuCardTile(
                            icon: Icons.location_on_rounded,
                            iconBg: const Color(0xFFFEF3C7),
                            iconColor: const Color(0xFFD97706),
                            title: 'Service Area',
                            subtitle: 'Delivery radius and operational area',
                            onTap: () => _navigateTo('/profile/shopkeeper/service-area'),
                          ),
                          _buildMenuCardTile(
                            icon: Icons.photo_library_rounded,
                            iconBg: const Color(0xFFF3E8FF),
                            iconColor: const Color(0xFF9333EA),
                            title: 'Shop Photos',
                            subtitle: 'Storefront and inventory images',
                            onTap: () => _navigateTo('/profile/shopkeeper/photos'),
                          ),
                          _buildMenuCardTile(
                            icon: Icons.verified_user_rounded,
                            iconBg: const Color(0xFFCCFBF1),
                            iconColor: const Color(0xFF0D9488),
                            title: 'Documents & Verification',
                            subtitle: 'GST, registration & identity proof',
                            onTap: () => _navigateTo('/profile/shopkeeper/documents'),
                          ),
                          _buildMenuCardTile(
                            icon: Icons.phone_in_talk_rounded,
                            iconBg: const Color(0xFFE0E7FF),
                            iconColor: const Color(0xFF4F46E5),
                            title: 'Contact Details',
                            subtitle: 'Phone numbers and email address',
                            onTap: () => _navigateTo('/profile/shopkeeper/contact'),
                          ),
                          _buildMenuCardTile(
                            icon: Icons.account_balance_rounded,
                            iconBg: const Color(0xFFD1FAE5),
                            iconColor: const Color(0xFF059669),
                            title: 'Bank Details',
                            subtitle: 'Payout account and IFSC information',
                            onTap: () => _navigateTo('/profile/shopkeeper/bank'),
                          ),
                          _buildMenuCardTile(
                            icon: Icons.settings_rounded,
                            iconBg: const Color(0xFFF1F5F9),
                            iconColor: const Color(0xFF475569),
                            title: 'Settings',
                            subtitle: 'Notifications, app preferences & security',
                            onTap: () => _navigateTo('/profile/shopkeeper/settings'),
                          ),

                          const SizedBox(height: 8),

                          // Sign out tile
                          _buildMenuCardTile(
                            icon: Icons.logout_rounded,
                            iconBg: const Color(0xFFFEE2E2),
                            iconColor: const Color(0xFFDC2626),
                            title: 'Sign Out',
                            subtitle: 'Log out of your shopkeeper account',
                            onTap: _showSignOutDialog,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCardTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
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
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF64748B),
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 4, // Profile tab selected
        onTap: (idx) {
          if (idx == 0) {
            context.go('/dashboard/shopkeeper');
          } else if (idx == 1) {
            context.go('/dashboard/shopkeeper');
          } else if (idx == 2) {
            context.go('/dashboard/shopkeeper');
          } else if (idx == 3) {
            context.go('/dashboard/shopkeeper');
          } else if (idx == 4) {
            // Already on Profile
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF047857),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('3'),
              backgroundColor: Color(0xFFEF4444),
              child: Icon(Icons.shopping_bag_outlined),
            ),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_rupee_rounded),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
