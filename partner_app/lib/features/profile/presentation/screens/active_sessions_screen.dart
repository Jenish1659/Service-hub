import 'package:flutter/material.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';

class ActiveSessionsScreen extends StatefulWidget {
  final ProfileController controller;

  const ActiveSessionsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ActiveSessionsScreen> createState() => _ActiveSessionsScreenState();
}

class _ActiveSessionsScreenState extends State<ActiveSessionsScreen> {
  final List<Map<String, dynamic>> _otherSessions = [
    {
      'id': 'sess_2',
      'device': 'Chrome Browser on Windows 11',
      'location': 'Jamnagar, Gujarat',
      'ip': '103.24.182.44',
      'lastActive': 'Yesterday at 08:30 PM',
      'icon': Icons.laptop_chromebook_rounded,
    },
    {
      'id': 'sess_3',
      'device': 'Samsung Galaxy Tab A8',
      'location': 'Rajkot, Gujarat',
      'ip': '157.34.201.12',
      'lastActive': '3 days ago',
      'icon': Icons.tablet_android_rounded,
    },
  ];

  void _revokeSession(String id) {
    setState(() {
      _otherSessions.removeWhere((s) => s['id'] == id);
    });
    TopToast.show(context, 'Session revoked and logged out', isError: false);
  }

  void _logOutAllOthers() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out All Other Devices?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('You will be logged out of all other active browsers, tablets, and phones except this device.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _otherSessions.clear();
              });
              TopToast.show(context, 'Logged out of all other devices', isError: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Log Out All'),
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
                    onTap: () => Navigator.pop(context),
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
                          'Active Sessions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Manage your logged-in devices and platforms',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Current Device
                    _buildSectionHeader('CURRENT ACTIVE DEVICE'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.phone_android_rounded, color: Color(0xFF2563EB), size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Android Phone Client', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                                      child: const Text('Active Now', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                const Text('ServiceHub Partner v1.0.0 • SM-S928B', style: TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
                                const SizedBox(height: 4),
                                const Text('Jamnagar, Gujarat • IP: 103.24.182.12', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Section 2: Other Devices
                    _buildSectionHeader('OTHER CONNECTED SESSIONS (${_otherSessions.length})'),
                    if (_otherSessions.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE2E8F0))),
                        child: const Column(
                          children: [
                            Icon(Icons.devices_other_rounded, size: 36, color: Color(0xFF94A3B8)),
                            SizedBox(height: 8),
                            Text('No other active sessions', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            SizedBox(height: 2),
                            Text('You are only logged in on this current device.', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                          ],
                        ),
                      )
                    else ...[
                      ..._otherSessions.map((s) => Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                                  child: Icon(s['icon'] as IconData, color: const Color(0xFF475569), size: 20),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(s['device'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      const SizedBox(height: 2),
                                      Text('${s['location']} • IP: ${s['ip']}', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      const SizedBox(height: 2),
                                      Text('Last active: ${s['lastActive']}', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                                    ],
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => _revokeSession(s['id'] as String),
                                  child: const Text('Log Out', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                ),
                              ],
                            ),
                          )),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _logOutAllOthers,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.logout_rounded, size: 16, color: Color(0xFFDC2626)),
                          label: const Text('Log Out All Other Devices', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),

                    // Security Info Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Security Tip: If you notice any unfamiliar device or city in your active sessions, revoke the session immediately and change your account password.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.7),
      ),
    );
  }
}
