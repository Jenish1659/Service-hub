import 'dart:io';
import 'package:flutter/material.dart';

/// Top bar with hamburger menu, ServiceHub branding, notification badge, and avatar
class DeliveryDashboardHeader extends StatelessWidget {
  final String agentName;
  final bool isOnline;
  final int unreadNotificationsCount;
  final String? photoPath;
  final VoidCallback? onMenuTap;
  final VoidCallback? onNotificationsTap;
  final VoidCallback? onProfileTap;

  const DeliveryDashboardHeader({
    super.key,
    required this.agentName,
    this.isOnline = true,
    this.unreadNotificationsCount = 2,
    this.photoPath,
    this.onMenuTap,
    this.onNotificationsTap,
    this.onProfileTap,
  });

  Widget _buildRiderAvatar() {
    final clean = photoPath?.trim() ?? '';
    if (clean.isNotEmpty) {
      final isNetwork = clean.startsWith('http://') || clean.startsWith('https://');
      if (!isNetwork) {
        final f = File(clean);
        if (f.existsSync()) {
          return ClipOval(child: Image.file(f, fit: BoxFit.cover, width: 38, height: 38));
        }
      } else {
        return ClipOval(
          child: Image.network(
            clean,
            fit: BoxFit.cover,
            width: 38,
            height: 38,
            errorBuilder: (_, __, ___) => _buildInitials(),
          ),
        );
      }
    }
    return _buildInitials();
  }

  Widget _buildInitials() {
    return Text(
      agentName.isNotEmpty ? agentName[0].toUpperCase() : 'D',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Delivery Partner Badge Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFFEA580C), size: 24),
            ),
            const SizedBox(width: 12),

            // ServiceHub Delivery Partner Branding
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'ServiceHub',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: const Text(
                            'PARTNER',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEA580C),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'Express Delivery Portal',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Notification Bell with Badge
            Material(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onNotificationsTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 42,
                  height: 42,
                  alignment: Alignment.center,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_outlined, color: Color(0xFF334155), size: 22),
                      if (unreadNotificationsCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Rider Avatar with Live Online Dot
            Tooltip(
              message: 'Rider Profile',
              child: GestureDetector(
                onTap: onProfileTap,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: _buildRiderAvatar(),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
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
}

/// Dynamic Greeting Section with Verified Partner Badge
class DeliveryGreetingSection extends StatelessWidget {
  final String agentName;
  final String memberSince;
  final bool isVerified;

  const DeliveryGreetingSection({
    super.key,
    required this.agentName,
    this.memberSince = 'Aug 2024',
    this.isVerified = true,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final displayName = agentName.split(' ').first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '$greeting, $displayName 👋',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Ready to deliver and make a difference!',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),

          // Verified Partner Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified_rounded, color: Color(0xFF16A34A), size: 14),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    isVerified ? 'VERIFIED PARTNER' : 'VERIFICATION UNDER REVIEW',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF15803D),
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
}

/// Shift & Status Card with Online/Offline toggle, shift timings, city, and scooter art
class DeliveryShiftStatusCard extends StatelessWidget {
  final bool isOnline;
  final ValueChanged<bool> onToggleOnline;
  final String shiftHours;
  final String locationCity;
  final VoidCallback? onLocationTap;

  const DeliveryShiftStatusCard({
    super.key,
    required this.isOnline,
    required this.onToggleOnline,
    this.shiftHours = '9:00 AM – 8:00 PM',
    this.locationCity = 'Rajkot, Gujarat',
    this.onLocationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isOnline ? const Color(0xFFFED7AA) : const Color(0xFFE2E8F0),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isOnline
                ? const Color(0xFFEA580C).withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left side: Status, Shift, Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Switch & Indicator
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isOnline ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                        boxShadow: isOnline
                            ? [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isOnline ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: isOnline ? const Color(0xFF15803D) : const Color(0xFF64748B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.85,
                      child: Switch(
                        value: isOnline,
                        activeThumbColor: Colors.white,
                        activeTrackColor: const Color(0xFF16A34A),
                        inactiveThumbColor: Colors.white,
                        inactiveTrackColor: const Color(0xFFCBD5E1),
                        onChanged: onToggleOnline,
                      ),
                    ),
                  ],
                ),
                Text(
                  isOnline ? 'Receiving orders nearby' : 'Switch online to accept deliveries',
                  style: TextStyle(
                    fontSize: 11,
                    color: isOnline ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),

                // Shift Hours
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Shift: $shiftHours',
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Location Picker Row
                InkWell(
                  onTap: onLocationTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFFEA580C)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          locationCity,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 14, color: Color(0xFF94A3B8)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Right side: Stylized Scooter / Delivery Graphic
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF7ED), Color(0xFFFFEDD5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  bottom: 12,
                  child: Container(
                    width: 55,
                    height: 8,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const Icon(
                  Icons.two_wheeler_rounded,
                  color: Color(0xFFEA580C),
                  size: 42,
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEA580C),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_shipping, color: Colors.white, size: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
