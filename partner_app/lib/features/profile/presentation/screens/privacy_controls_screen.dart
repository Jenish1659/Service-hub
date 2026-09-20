import 'package:flutter/material.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';

class PrivacyControlsScreen extends StatefulWidget {
  final ProfileController controller;

  const PrivacyControlsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<PrivacyControlsScreen> createState() => _PrivacyControlsScreenState();
}

class _PrivacyControlsScreenState extends State<PrivacyControlsScreen> {
  bool _phoneMasking = true;
  bool _addressProtection = true;
  bool _completedJobPrivacy = true;
  bool _radarDiscoverability = true;
  bool _showRatingPublicly = true;
  bool _crashDiagnostics = false;

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
                          'Privacy Controls',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Manage your personal data visibility and protection',
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
                    // Section 1: Contact & Address Protection
                    _buildSectionHeader('CONTACT & LOCATION PRIVACY'),
                    _buildCard([
                      _buildSwitchTile(
                        icon: Icons.phone_locked_outlined,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Phone Number Masking',
                        subtitle: 'Mask your personal number via virtual proxy bridge during customer coordination calls.',
                        value: _phoneMasking,
                        onChanged: (v) {
                          setState(() => _phoneMasking = v);
                          TopToast.show(context, 'Phone masking ${v ? "enabled" : "disabled"}', isError: false);
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),
                      _buildSwitchTile(
                        icon: Icons.shield_outlined,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Precise Location Protection',
                        subtitle: 'Only reveal your approximate area to customers until you accept their booking.',
                        value: _addressProtection,
                        onChanged: (v) {
                          setState(() => _addressProtection = v);
                          TopToast.show(context, 'Location protection ${v ? "enabled" : "disabled"}', isError: false);
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),
                      _buildSwitchTile(
                        icon: Icons.receipt_long_outlined,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                        title: 'Completed Job Privacy',
                        subtitle: 'Automatically redact customer phone and addresses from past completed receipts.',
                        value: _completedJobPrivacy,
                        onChanged: (v) {
                          setState(() => _completedJobPrivacy = v);
                          TopToast.show(context, 'Completed job privacy ${v ? "enabled" : "disabled"}', isError: false);
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Section 2: Directory & Discovery
                    _buildSectionHeader('DISCOVERABILITY IN SERVICE RADAR'),
                    _buildCard([
                      _buildSwitchTile(
                        icon: Icons.radar_rounded,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        title: 'Radar Discoverability',
                        subtitle: 'Allow nearby customers to find your profile when searching for services.',
                        value: _radarDiscoverability,
                        onChanged: (v) {
                          setState(() => _radarDiscoverability = v);
                          TopToast.show(context, 'Discoverability ${v ? "active" : "paused"}', isError: false);
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),
                      _buildSwitchTile(
                        icon: Icons.star_outline_rounded,
                        iconBg: const Color(0xFFFFEDD5),
                        iconColor: const Color(0xFFEA580C),
                        title: 'Show Customer Ratings Publicly',
                        subtitle: 'Display your star rating and verified reviews on your partner profile card.',
                        value: _showRatingPublicly,
                        onChanged: (v) {
                          setState(() => _showRatingPublicly = v);
                          TopToast.show(context, 'Rating visibility updated', isError: false);
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Section 3: Diagnostic Data
                    _buildSectionHeader('ANALYTICS & DIAGNOSTICS'),
                    _buildCard([
                      _buildSwitchTile(
                        icon: Icons.analytics_outlined,
                        iconBg: const Color(0xFFF1F5F9),
                        iconColor: const Color(0xFF475569),
                        title: 'Share Crash Diagnostics',
                        subtitle: 'Send anonymous performance and crash logs to help improve app stability.',
                        value: _crashDiagnostics,
                        onChanged: (v) {
                          setState(() => _crashDiagnostics = v);
                          TopToast.show(context, 'Diagnostic reporting updated', isError: false);
                        },
                      ),
                    ]),
                    const SizedBox(height: 22),

                    // Policy Badge
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Data Privacy Guarantee: ServiceHub will never sell or share your personal contact or banking data with any third-party advertisers.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.3),
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

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
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
                Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 3),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: const Color(0xFF2563EB),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
