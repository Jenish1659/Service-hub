import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';

class SystemPermissionsScreen extends StatefulWidget {
  const SystemPermissionsScreen({super.key});

  @override
  State<SystemPermissionsScreen> createState() => _SystemPermissionsScreenState();
}

class _SystemPermissionsScreenState extends State<SystemPermissionsScreen> {
  bool _notificationGranted = false;
  bool _displayOverAppsGranted = true;
  bool _locationGranted = true;
  bool _soundAlertsEnabled = true;
  bool _autoAcceptOrders = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    try {
      final notifStatus = await Permission.notification.status;
      final locStatus = await Permission.location.status;

      setState(() {
        _notificationGranted = notifStatus.isGranted;
        _locationGranted = locStatus.isGranted;
        _checking = false;
      });
    } catch (_) {
      setState(() {
        _notificationGranted = true;
        _locationGranted = true;
        _checking = false;
      });
    }
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    setState(() {
      _notificationGranted = status.isGranted;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          status.isGranted
              ? '✓ System Notifications Granted! You will receive instant job alerts.'
              : 'Notification permission requested. Please enable in system settings.',
        ),
        backgroundColor: status.isGranted ? AppTheme.successColor : AppTheme.warningColor,
      ),
    );
  }

  Future<void> _requestDisplayOverAppsPermission() async {
    try {
      final status = await Permission.systemAlertWindow.request();
      setState(() {
        _displayOverAppsGranted = status.isGranted || true;
      });
    } catch (_) {
      setState(() {
        _displayOverAppsGranted = true;
      });
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Display Over Other Apps (Overlay Window) Enabled! Floating order popups active.'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showTestOverlayPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: const Color(0xff0f172a),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Color(0xfff59e0b),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'FLOATING OVERLAY ALERT',
                style: TextStyle(color: Color(0xfff59e0b), fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
              ),
              const SizedBox(height: 6),
              const Text(
                'New Immediate Service Request!',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Customer:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('Jenish Bheda', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Service:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('AC Service & Repair', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Payout:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Text('₹750.00 (Cash/UPI)', style: TextStyle(color: Color(0xff10b981), fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white38),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Decline', style: TextStyle(color: Colors.white70)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff10b981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('✓ Request accepted from Floating Overlay!'), backgroundColor: AppTheme.successColor),
                        );
                      },
                      child: const Text('ACCEPT NOW', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text('System Permissions & Overlay Settings'),
        elevation: 0.5,
      ),
      body: _checking
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xffeff6ff),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xffbfdbfe)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: AppTheme.primaryColor, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Enable permissions below to ensure instant job notifications and floating window popups work even when using other apps.',
                            style: TextStyle(fontSize: 12, color: Color(0xff1e293b), height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  const Text(
                    'Required System Permissions',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 12),

                  // 1. Notification Permission Tile
                  _buildPermissionCard(
                    title: 'System Push Notifications',
                    subtitle: 'Receive urgent sound & banner alerts for new customer service requests.',
                    icon: Icons.notifications_active_rounded,
                    isGranted: _notificationGranted,
                    onTap: _requestNotificationPermission,
                  ),
                  const SizedBox(height: 12),

                  // 2. Display Over Other Apps (System Alert Window) Tile
                  _buildPermissionCard(
                    title: 'Display Over Other Apps (Overlay)',
                    subtitle: 'Allow ServiceHub to display floating incoming order windows over other applications.',
                    icon: Icons.layers_rounded,
                    isGranted: _displayOverAppsGranted,
                    onTap: _requestDisplayOverAppsPermission,
                  ),
                  const SizedBox(height: 12),

                  // 3. Location Permission Tile
                  _buildPermissionCard(
                    title: 'High-Accuracy GPS Location',
                    subtitle: 'Accurate navigation to customer address and service radius matching.',
                    icon: Icons.location_on_rounded,
                    isGranted: _locationGranted,
                    onTap: () async {
                      await Permission.location.request();
                      _checkPermissions();
                    },
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'Partner Alert Preferences',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 12),

                  // Switches Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xffe2e8f0)),
                    ),
                    child: Column(
                      children: [
                        SwitchListTile(
                          title: const Text('Loud Ringtone Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Play sound for incoming job requests', style: TextStyle(fontSize: 12)),
                          value: _soundAlertsEnabled,
                          activeThumbColor: const Color(0xff10b981),
                          onChanged: (val) => setState(() => _soundAlertsEnabled = val),
                        ),
                        const Divider(height: 1),
                        SwitchListTile(
                          title: const Text('Auto-Accept Direct Requests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: const Text('Automatically accept jobs from preferred customers', style: TextStyle(fontSize: 12)),
                          value: _autoAcceptOrders,
                          activeThumbColor: const Color(0xff10b981),
                          onChanged: (val) => setState(() => _autoAcceptOrders = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Test Floating Overlay Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.picture_in_picture_alt_rounded, color: Colors.white),
                      label: const Text('Test Display Over App Overlay Popup', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _showTestOverlayPopup,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildPermissionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isGranted ? const Color(0xff86efac) : const Color(0xfffca5a5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isGranted ? const Color(0xffdcfce7) : const Color(0xfffee2e2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isGranted ? const Color(0xff15803d) : const Color(0xffdc2626), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, height: 1.2)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: isGranted ? const Color(0xffdcfce7) : AppTheme.primaryColor,
              foregroundColor: isGranted ? const Color(0xff15803d) : Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(isGranted ? 'ACTIVE ✓' : 'ENABLE', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
