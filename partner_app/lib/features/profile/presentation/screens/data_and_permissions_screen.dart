import 'package:flutter/material.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';

class DataAndPermissionsScreen extends StatefulWidget {
  final ProfileController controller;

  const DataAndPermissionsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<DataAndPermissionsScreen> createState() => _DataAndPermissionsScreenState();
}

class _DataAndPermissionsScreenState extends State<DataAndPermissionsScreen> {
  double _cacheSizeMb = 24.6;
  bool _isClearing = false;

  void _handleClearCache() {
    setState(() => _isClearing = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _cacheSizeMb = 0.0;
        _isClearing = false;
      });
      TopToast.show(context, 'App cache and temporary files cleared successfully!', isError: false);
    });
  }

  void _handleExportData() {
    TopToast.show(context, 'Data export request submitted. You will receive an email archive within 24 hours.', isError: false);
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
                          'Data & Permissions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Manage device hardware access and storage usage',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Hardware & System Permissions
                    _buildSectionHeader('DEVICE PERMISSIONS STATUS'),
                    _buildCard([
                      _buildPermissionRow(
                        icon: Icons.location_on_outlined,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Location Services',
                        status: 'Always Allowed (High Accuracy GPS)',
                        description: 'Required to match service bookings and navigate to customer addresses.',
                        isGranted: true,
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),
                      _buildPermissionRow(
                        icon: Icons.camera_alt_outlined,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Camera Access',
                        status: 'Granted',
                        description: 'Used for capturing before/after job evidence and KYC verification photos.',
                        isGranted: true,
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),
                      _buildPermissionRow(
                        icon: Icons.folder_outlined,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                        title: 'Storage & Media',
                        status: 'Granted',
                        description: 'Used to store downloadable invoices, tax certificates, and offline map tiles.',
                        isGranted: true,
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),
                      _buildPermissionRow(
                        icon: Icons.notifications_active_outlined,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        title: 'Sound & Notifications',
                        status: 'Granted (High Priority)',
                        description: 'Ensures you never miss an incoming service dispatch opportunity.',
                        isGranted: true,
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Section 2: Storage & Cache Management
                    _buildSectionHeader('LOCAL STORAGE & APP CACHE'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2))],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Cached Temporary Data', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              Text(
                                '${_cacheSizeMb.toStringAsFixed(1)} MB',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF2563EB)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Includes cached profile photos, map thumbnail previews, and temporary network buffers.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: OutlinedButton.icon(
                              onPressed: _cacheSizeMb > 0 && !_isClearing ? _handleClearCache : null,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: _cacheSizeMb > 0 ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: _isClearing
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)))
                                  : const Icon(Icons.cleaning_services_rounded, size: 18),
                              label: Text(
                                _isClearing ? 'Clearing Cache...' : (_cacheSizeMb > 0 ? 'Clear Cache & Temp Files' : 'Cache is Clean'),
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Data Export
                    _buildSectionHeader('DATA PORTABILITY'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Export Account History', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          const Text(
                            'Download an encrypted ZIP archive containing all your completed job records, customer invoices, and payouts history.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                          ),
                          const SizedBox(height: 14),
                          OutlinedButton.icon(
                            onPressed: _handleExportData,
                            icon: const Icon(Icons.download_rounded, size: 16),
                            label: const Text('Request Data Archive', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildPermissionRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String status,
    required String description,
    required bool isGranted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Allowed', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(status, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF16A34A))),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
