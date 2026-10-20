import 'package:flutter/material.dart';
import '../../data/customer_profile_service.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});

  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  late List<Map<String, dynamic>> _notifications;

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = CustomerProfileService.instance.getNotifications();
    });
  }

  Future<void> _markAllRead() async {
    await CustomerProfileService.instance.markAllNotificationsRead();
    _loadNotifications();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ All notifications marked as read'),
          backgroundColor: primaryBlue,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayList = _notifications.where((n) => n['section'] == 'Today').toList();
    final yesterdayList = _notifications.where((n) => n['section'] == 'Yesterday').toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: darkSlate),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: darkSlate, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _markAllRead,
            child: const Text(
              'Mark all read',
              style: TextStyle(color: primaryBlue, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.notifications_none_rounded, color: primaryBlue, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('No Notifications', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkSlate)),
                  const SizedBox(height: 4),
                  const Text('You are all caught up with your updates', style: TextStyle(color: textMuted, fontSize: 13)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                if (todayList.isNotEmpty) ...[
                  const Text(
                    'Today',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate),
                  ),
                  const SizedBox(height: 10),
                  ...todayList.map((n) => _buildNotificationCard(n)),
                  const SizedBox(height: 20),
                ],
                if (yesterdayList.isNotEmpty) ...[
                  const Text(
                    'Yesterday',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate),
                  ),
                  const SizedBox(height: 10),
                  ...yesterdayList.map((n) => _buildNotificationCard(n)),
                ],
              ],
            ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> n) {
    final type = (n['icon_type'] ?? 'car').toString().toLowerCase();
    final isRead = n['is_read'] == true;

    Color iconBg = const Color(0xFFEFF6FF);
    Color iconColor = primaryBlue;
    IconData iconData = Icons.directions_car_rounded;

    if (type == 'partner') {
      iconBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
      iconData = Icons.person_rounded;
    } else if (type == 'payment') {
      iconBg = const Color(0xFFECFDF5);
      iconColor = const Color(0xFF10B981);
      iconData = Icons.check_circle_rounded;
    } else if (type == 'completed') {
      iconBg = const Color(0xFFFEF3C7);
      iconColor = const Color(0xFFD97706);
      iconData = Icons.inventory_2_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead ? borderGrey : primaryBlue.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n['message'] ?? '',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                    color: darkSlate,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  n['time'] ?? '',
                  style: const TextStyle(fontSize: 11.5, color: textMuted),
                ),
              ],
            ),
          ),
          if (!isRead)
            Container(
              margin: const EdgeInsets.only(top: 4, left: 6),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
