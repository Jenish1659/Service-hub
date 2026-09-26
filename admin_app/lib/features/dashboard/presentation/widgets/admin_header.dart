import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/auth_controller.dart';

class AdminHeader extends ConsumerWidget {
  final String title;
  final VoidCallback onToggleSidebar;
  final ValueChanged<String>? onSearch;
  final String dateRangeText;
  final VoidCallback? onSelectDateRange;
  final VoidCallback? onFilterTap;

  const AdminHeader({
    super.key,
    required this.title,
    required this.onToggleSidebar,
    this.onSearch,
    this.dateRangeText = '24 May 2025 - 30 May 2025',
    this.onSelectDateRange,
    this.onFilterTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 640;
        final isUltraCompact = constraints.maxWidth < 420;

        return Container(
          height: 70,
          padding: EdgeInsets.symmetric(horizontal: isUltraCompact ? 10 : 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
          ),
          child: Row(
            children: [
              // Hamburger Toggle
              IconButton(
                icon: const Icon(Icons.menu_rounded, color: Color(0xFF334155), size: 22),
                onPressed: onToggleSidebar,
              ),
              SizedBox(width: isUltraCompact ? 4 : 8),

              // Title
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: isUltraCompact ? 15 : 19,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              const Spacer(),

              if (!isCompact) ...[
                // Global Search Input
                Container(
                  width: constraints.maxWidth < 820 ? 160 : 280,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: onSearch,
                          decoration: const InputDecoration(
                            hintText: 'Search here...',
                            hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
              ],

              // Notification Bell with Badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF475569), size: 20),
                      onPressed: () {},
                    ),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Text(
                        '8',
                        style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),

              if (!isCompact) ...[
                const SizedBox(width: 10),
                // Fullscreen Toggle
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.fullscreen_rounded, color: Color(0xFF475569), size: 20),
                    onPressed: () {},
                  ),
                ),
              ],

              SizedBox(width: isUltraCompact ? 8 : 14),

              // Admin Profile Dropdown
              Container(
                padding: EdgeInsets.symmetric(horizontal: isUltraCompact ? 4 : 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 15,
                      backgroundColor: Color(0xFF2563EB),
                      child: Text('A', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: 8),
                      const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Super Admin',
                            style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 18),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'profile', child: Text('Admin Profile')),
                        const PopupMenuItem(value: 'settings', child: Text('System Settings')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(value: 'logout', child: Text('Sign Out', style: TextStyle(color: Color(0xFFEF4444)))),
                      ],
                      onSelected: (val) async {
                        if (val == 'logout') {
                          await ref.read(authControllerProvider.notifier).logout();
                          if (context.mounted) {
                            context.go('/login');
                          }
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
