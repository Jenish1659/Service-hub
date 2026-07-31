import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
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
    if (location.startsWith('/orders')) return 3;
    if (location.startsWith('/profile')) return 4;
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
        context.go('/orders');
        break;
      case 4:
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
          // Only show banner if the notification is fresh (created within the last 30 seconds)
          if (DateTime.now().difference(newest.createdAt).inSeconds < 30) {
            setState(() {
              _activeNotificationTitle = newest.title;
              _activeNotificationBody = newest.body;
              _showBanner = true;
            });
            // Auto dismiss after 5 seconds
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
                    color: const Color(0xff0f172a), // Ultra modern dark blue-slate bubble
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
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                spreadRadius: 1,
              )
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: selectedIndex,
            onTap: (index) => _onItemTapped(index, context),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home, color: AppTheme.primaryColor),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.build_outlined),
                activeIcon: Icon(Icons.build, color: AppTheme.primaryColor),
                label: 'Services',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined),
                activeIcon: Icon(Icons.shopping_bag, color: AppTheme.primaryColor),
                label: 'Products',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long, color: AppTheme.primaryColor),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person, color: AppTheme.primaryColor),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
