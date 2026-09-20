import 'package:flutter/material.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/terms_and_conditions_screen.dart';

class AboutServiceHubScreen extends StatelessWidget {
  const AboutServiceHubScreen({super.key});

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
                          'About ServiceHub',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'App info, mission & open source licenses',
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
                  children: [
                    // Brand / Version Card
                    _buildBrandCard(context),
                    const SizedBox(height: 16),

                    // Build Specs
                    _buildBuildSpecsCard(),
                    const SizedBox(height: 16),

                    // Mission Card
                    _buildMissionCard(),
                    const SizedBox(height: 16),

                    // Official Links
                    _buildLinksCard(context),
                    const SizedBox(height: 24),

                    // Copyright & Made In India
                    _buildFooter(),
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

  Widget _buildBrandCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.build_rounded, size: 38, color: Colors.white),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'ServiceHub Partner',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: const Text(
              'v1.0.0 (Build 100) • Production',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Better Services, Brighter Tomorrows',
            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildBuildSpecsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SYSTEM & BUILD METRICS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF64748B),
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),
          _buildSpecRow('Target Platform', 'Android & Windows Hybrid'),
          _buildSpecDivider(),
          _buildSpecRow('Framework', 'Flutter 3.x (Dart 3)'),
          _buildSpecDivider(),
          _buildSpecRow('Cloud Backend', 'Supabase Cloud PostgreSQL'),
          _buildSpecDivider(),
          _buildSpecRow('Encryption Standard', 'AES-256 GCM + TLS 1.3'),
          _buildSpecDivider(),
          _buildSpecRow('Location Provider', 'Geolocator High-Accuracy GPS'),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
          Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
        ],
      ),
    );
  }

  Widget _buildSpecDivider() {
    return const Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9));
  }

  Widget _buildMissionCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.rocket_launch_rounded, size: 18, color: Color(0xFF2563EB)),
              ),
              const SizedBox(width: 10),
              const Text(
                'Our Mission',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'ServiceHub empowers local technicians, electricians, plumbers, carpenters, and beauty professionals with high-income job leads, transparent doorstep rates, same-day payouts, and instant GPS navigation—bringing dignity, reliability, and growth to India\'s service economy.',
            style: TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildLinksCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildLinkTile(
            icon: Icons.article_outlined,
            iconBg: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF9333EA),
            title: 'Terms of Service',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 56, endIndent: 12, color: Color(0xFFF1F5F9)),
          _buildLinkTile(
            icon: Icons.privacy_tip_outlined,
            iconBg: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
            title: 'Privacy Policy',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
            ),
          ),
          const Divider(height: 1, thickness: 1, indent: 56, endIndent: 12, color: Color(0xFFF1F5F9)),
          _buildLinkTile(
            icon: Icons.code_rounded,
            iconBg: const Color(0xFFFFEDD5),
            iconColor: const Color(0xFFEA580C),
            title: 'Open Source Software Licenses',
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: 'ServiceHub Partner',
                applicationVersion: '1.0.0',
                applicationLegalese: '© 2026 ServiceHub Technologies Pvt. Ltd.',
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const Center(
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Crafted with ', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              Icon(Icons.favorite_rounded, size: 14, color: Color(0xFFEF4444)),
              Text(' in India', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
            ],
          ),
          SizedBox(height: 4),
          Text(
            '© 2026 ServiceHub Technologies Pvt. Ltd. All rights reserved.',
            style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
