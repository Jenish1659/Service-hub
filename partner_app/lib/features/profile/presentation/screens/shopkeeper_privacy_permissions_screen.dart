import 'package:flutter/material.dart';
import '../controllers/shopkeeper_profile_controller.dart';

class ShopkeeperPrivacyPermissionsScreen extends StatefulWidget {
  final ShopkeeperProfileController? controller;

  const ShopkeeperPrivacyPermissionsScreen({super.key, this.controller});

  @override
  State<ShopkeeperPrivacyPermissionsScreen> createState() =>
      _ShopkeeperPrivacyPermissionsScreenState();
}

class _ShopkeeperPrivacyPermissionsScreenState
    extends State<ShopkeeperPrivacyPermissionsScreen> {
  bool _locationPermission = true;
  bool _cameraPermission = true;
  bool _storagePermission = true;

  void _showDocumentViewer(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(color: Color(0xFFE2E8F0)),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const ClampingScrollPhysics(),
                  child: Text(
                    content,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF475569),
                      height: 1.6,
                    ),
                  ),
                ),
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
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Privacy & Permissions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Hardware access, data privacy & agreements',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Data Privacy Shield Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.security_rounded,
                              color: Color(0xFF059669),
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Merchant Privacy Commitment',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF065F46),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Your store customer lists, order volumes, and financial data are end-to-end encrypted and never shared.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF047857),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Device Permissions
                    _buildSectionHeader('DEVICE PERMISSIONS STATUS'),
                    _buildCard([
                      // Location Permission
                      _buildPermissionTile(
                        icon: Icons.location_on_outlined,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Location Services',
                        subtitle: 'Matches nearby technicians and calculates delivery radius',
                        isGranted: _locationPermission,
                        onToggle: (v) {
                          setState(() => _locationPermission = v);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Location permission ${v ? "allowed" : "denied"}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),

                      // Camera Permission
                      _buildPermissionTile(
                        icon: Icons.camera_alt_outlined,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                        title: 'Camera Access',
                        subtitle: 'Capture shop storefront, documents & catalog spare parts',
                        isGranted: _cameraPermission,
                        onToggle: (v) {
                          setState(() => _cameraPermission = v);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Camera permission ${v ? "allowed" : "denied"}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),

                      // Storage Permission
                      _buildPermissionTile(
                        icon: Icons.folder_open_rounded,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        title: 'Storage & Gallery',
                        subtitle: 'Upload GST certificates, licenses and save settlement invoices',
                        isGranted: _storagePermission,
                        onToggle: (v) {
                          setState(() => _storagePermission = v);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Storage permission ${v ? "allowed" : "denied"}'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Section 2: Legal & Compliance
                    _buildSectionHeader('LEGAL POLICIES & TERMS'),
                    _buildCard([
                      // Privacy Policy Tile
                      _buildLegalTile(
                        icon: Icons.policy_outlined,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Merchant Privacy Policy',
                        subtitle: 'How we collect, store, and safeguard your store data',
                        onTap: () {
                          _showDocumentViewer(
                            'Merchant Privacy Policy',
                            'ServiceHub Technologies India Pvt. Ltd. ("ServiceHub", "we", "us", or "our") values the privacy of our Shopkeeper and Merchant Partners.\n\n'
                            '1. Information We Collect:\n'
                            'We collect store details including shop registration numbers, GSTIN, business bank account numbers for daily settlement, shopkeeper KYC (Aadhaar & PAN), catalog items, and order fulfillment history.\n\n'
                            '2. Use of Information:\n'
                            'Data is used strictly to process technician part orders, verify genuine store ownership, execute direct-to-bank NEFT/IMPS settlements, and provide order dispatch tracking.\n\n'
                            '3. Data Protection & Security:\n'
                            'All store databases and financial ledgers are encrypted with AES-256 and SSL/TLS standards. We do not sell merchant contact numbers or transaction history to third-party ad networks.\n\n'
                            '4. Your Rights:\n'
                            'You may request a complete export of your store sales records or request permanent account deletion via Account & Security settings.',
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),

                      // Terms & Conditions Tile
                      _buildLegalTile(
                        icon: Icons.description_outlined,
                        iconBg: const Color(0xFFF0FDF4),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Store Partner Terms & Conditions',
                        subtitle: 'Merchant agreement, fulfillment rules & commissions',
                        onTap: () {
                          _showDocumentViewer(
                            'Store Partner Terms & Conditions',
                            'Welcome to ServiceHub Merchant Network.\n\n'
                            '1. Genuine Parts Guarantee:\n'
                            'As an onboarded shop partner, all spare parts and hardware items sold through ServiceHub must be genuine, properly graded, and adhere to manufacturer warranties.\n\n'
                            '2. Order Pickup & Dispatch:\n'
                            'Orders accepted by the shopkeeper must be packed and ready for delivery partner pickup within 15 minutes of acceptance during active operating hours.\n\n'
                            '3. Settlements & Commissions:\n'
                            'ServiceHub charges an agreed low commission per fulfilled order. Store payouts are settled directly into your linked bank account every evening.\n\n'
                            '4. Account Termination:\n'
                            'Repeated fulfillment failures, counterfeit spare parts, or violations of platform guidelines may result in merchant suspension.',
                          );
                        },
                      ),
                    ]),
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
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildPermissionTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isGranted,
    required ValueChanged<bool> onToggle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isGranted ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isGranted ? 'Allowed' : 'Disabled',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isGranted ? const Color(0xFF15803D) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isGranted,
            activeTrackColor: const Color(0xFF16A34A),
            onChanged: onToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildLegalTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
