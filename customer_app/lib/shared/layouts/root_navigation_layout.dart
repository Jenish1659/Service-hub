import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';

class RootNavigationLayout extends ConsumerStatefulWidget {
  final Widget child;

  const RootNavigationLayout({super.key, required this.child});

  @override
  ConsumerState<RootNavigationLayout> createState() => _RootNavigationLayoutState();
}

class _RootNavigationLayoutState extends ConsumerState<RootNavigationLayout> {
  final Set<String> _seenNotificationIds = {};
  String? _activeNotificationTitle;
  String? _activeNotificationBody;
  bool _showBanner = false;

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    if (location == '/') return 0;
    if (location.startsWith('/discover') || location.startsWith('/services')) return 1;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/discover');
        break;
      case 2:
        context.go('/products');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);
    final bool isHome = selectedIndex == 0;

    // Listen for incoming notifications from Supabase
    ref.listen<List<AppNotification>>(notificationProvider, (previous, next) {
      if (next.isNotEmpty) {
        final newest = next.first;
        if (!_seenNotificationIds.contains(newest.id)) {
          _seenNotificationIds.add(newest.id);
          if (DateTime.now().difference(newest.createdAt).inSeconds < 30) {
            setState(() {
              _activeNotificationTitle = newest.title;
              _activeNotificationBody = newest.body;
              _showBanner = true;
            });
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) {
                setState(() {
                  _showBanner = false;
                });
              }
            });
          }
        }
      }
    });

    return PopScope(
      canPop: isHome,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!isHome) {
          context.go('/');
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            widget.child,
            if (_showBanner && _activeNotificationTitle != null)
              Positioned(
                top: 50,
                left: 16,
                right: 16,
                child: AnimatedOpacity(
                  opacity: _showBanner ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Material(
                    elevation: 10,
                    borderRadius: BorderRadius.circular(16),
                    color: const Color(0xff0f172a),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_active, color: Colors.amber, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _activeNotificationTitle!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _activeNotificationBody!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white38, size: 16),
                            onPressed: () {
                              setState(() {
                                _showBanner = false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        // Prominent Center Map Floating Action Button
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Container(
          width: 58,
          height: 58,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xff0052cc),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff0052cc).withValues(alpha: 0.4),
                blurRadius: 14,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => context.push('/map'),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          elevation: 16,
          color: Colors.white,
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 1. Home
                _buildNavItem(
                  context: context,
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: selectedIndex == 0,
                  onTap: () => _onItemTapped(0, context),
                ),

                // 2. Services
                _buildNavItem(
                  context: context,
                  icon: Icons.construction_rounded,
                  label: 'Services',
                  isSelected: selectedIndex == 1,
                  onTap: () => _onItemTapped(1, context),
                ),

                // Center Gap for Notched Map Button
                const SizedBox(width: 44),

                // 3. Products
                _buildNavItem(
                  context: context,
                  icon: Icons.shopping_bag_outlined,
                  activeIcon: Icons.shopping_bag_rounded,
                  label: 'Products',
                  isSelected: selectedIndex == 2,
                  onTap: () => _onItemTapped(2, context),
                ),

                // 4. Profile
                _buildNavItem(
                  context: context,
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  label: 'Profile',
                  isSelected: selectedIndex == 3,
                  onTap: () => _onItemTapped(3, context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    IconData? activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final color = isSelected ? const Color(0xff0052cc) : const Color(0xff94a3b8);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? (activeIcon ?? icon) : icon,
              color: color,
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
