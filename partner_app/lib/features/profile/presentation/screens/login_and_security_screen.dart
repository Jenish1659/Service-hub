import 'package:flutter/material.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/change_password_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/phone_and_email_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/active_sessions_screen.dart';

class LoginAndSecurityScreen extends StatefulWidget {
  final ProfileController controller;

  const LoginAndSecurityScreen({
    super.key,
    required this.controller,
  });

  @override
  State<LoginAndSecurityScreen> createState() => _LoginAndSecurityScreenState();
}

class _LoginAndSecurityScreenState extends State<LoginAndSecurityScreen> {
  bool _twoFactorEnabled = true;
  bool _biometricEnabled = true;

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

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
                          'Login & Security',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Manage your account credentials and protection',
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
                    // Security Health Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
                            child: const Icon(Icons.shield_rounded, color: Color(0xFF2563EB), size: 28),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'High Security Protection',
                                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                ),
                                SizedBox(height: 3),
                                Text(
                                  'Your partner profile is guarded by 2FA verification and biometric device binding.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Authentication
                    _buildSectionHeader('AUTHENTICATION & PASSWORDS'),
                    _buildCard([
                      _buildTile(
                        icon: Icons.lock_outline_rounded,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Password',
                        subtitle: 'Last updated 30 days ago',
                        trailing: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => ChangePasswordScreen(controller: c)),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            side: const BorderSide(color: Color(0xFF2563EB)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Change', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.verified_user_outlined, color: Color(0xFF2563EB), size: 20),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Two-Factor Authentication', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  Text('Require SMS OTP for every new device login', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Switch(
                              value: _twoFactorEnabled,
                              activeThumbColor: const Color(0xFF2563EB),
                              onChanged: (v) {
                                setState(() => _twoFactorEnabled = v);
                                TopToast.show(context, '2FA ${v ? "enabled" : "disabled"}', isError: false);
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(10)),
                              child: const Icon(Icons.fingerprint_rounded, color: Color(0xFF9333EA), size: 20),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Biometric Authentication', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  Text('Use Fingerprint or Face ID for fast login', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            Switch(
                              value: _biometricEnabled,
                              activeThumbColor: const Color(0xFF9333EA),
                              onChanged: (v) {
                                setState(() => _biometricEnabled = v);
                                TopToast.show(context, 'Biometrics ${v ? "enabled" : "disabled"}', isError: false);
                              },
                            ),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Section 2: Contact Identifiers
                    _buildSectionHeader('VERIFIED RECOVERY IDENTIFIERS'),
                    _buildCard([
                      _buildTile(
                        icon: Icons.phone_android_rounded,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Mobile Number',
                        subtitle: c.phoneNumber.isNotEmpty ? c.phoneNumber : '+91 98765 43210',
                        trailingBadge: 'Verified',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PhoneAndEmailScreen(controller: c)),
                          );
                        },
                      ),
                      const Divider(height: 1, color: Color(0xFFF1F5F9), indent: 56),
                      _buildTile(
                        icon: Icons.mail_outline_rounded,
                        iconBg: const Color(0xFFFDF4FF),
                        iconColor: const Color(0xFFC026D3),
                        title: 'Email Address',
                        subtitle: c.emailAddress.isNotEmpty ? c.emailAddress : 'partner@servicehub.in',
                        trailingBadge: 'Verified',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PhoneAndEmailScreen(controller: c)),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Section 3: Sessions
                    _buildSectionHeader('DEVICE SESSIONS'),
                    _buildCard([
                      _buildTile(
                        icon: Icons.devices_rounded,
                        iconBg: const Color(0xFFFFEDD5),
                        iconColor: const Color(0xFFEA580C),
                        title: 'Active Sessions',
                        subtitle: '1 active phone session in Jamnagar',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ActiveSessionsScreen(controller: c)),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // Section 4: Security Activity Log
                    _buildSectionHeader('RECENT SECURITY ACTIVITY'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Column(
                        children: [
                          _ActivityRow(
                            title: 'Successful Login',
                            time: 'Today • 09:42 AM',
                            device: 'Android Client • Jamnagar (Current)',
                            icon: Icons.check_circle_rounded,
                            iconColor: Color(0xFF16A34A),
                          ),
                          Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _ActivityRow(
                            title: '2FA OTP Verification Passed',
                            time: 'Yesterday • 06:15 PM',
                            device: 'SMS to registered mobile',
                            icon: Icons.phonelink_ring_rounded,
                            iconColor: Color(0xFF2563EB),
                          ),
                          Divider(height: 16, color: Color(0xFFF1F5F9)),
                          _ActivityRow(
                            title: 'Password Verified',
                            time: '30 days ago',
                            device: 'Account setup & credential verification',
                            icon: Icons.key_rounded,
                            iconColor: Color(0xFF64748B),
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

  Widget _buildTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailingBadge,
    Widget? trailing,
    VoidCallback? onTap,
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
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                ],
              ),
            ),
            if (trailing != null) trailing,
            if (trailingBadge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(8)),
                child: Text(trailingBadge, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
              ),
              const SizedBox(width: 6),
            ],
            if (onTap != null) const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  final String title;
  final String time;
  final String device;
  final IconData icon;
  final Color iconColor;

  const _ActivityRow({
    required this.title,
    required this.time,
    required this.device,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  Text(time, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                ],
              ),
              const SizedBox(height: 2),
              Text(device, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ),
      ],
    );
  }
}
