import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/presentation/auth_controller.dart';
import '../../data/customer_profile_service.dart';

class CustomerSettingsScreen extends ConsumerStatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  ConsumerState<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends ConsumerState<CustomerSettingsScreen> {
  String _selectedLanguage = 'English';
  bool _pushNotifications = true;
  bool _smsAlerts = true;

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Language', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['English', 'हिंदी (Hindi)', 'ગુજરાતી (Gujarati)'].map((lang) {
            final key = lang.split(' ').first;
            final isSelected = _selectedLanguage == key;
            return ListTile(
              title: Text(lang, style: TextStyle(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
              trailing: isSelected ? const Icon(Icons.check_rounded, color: primaryBlue) : null,
              onTap: () {
                setState(() => _selectedLanguage = key);
                Navigator.pop(ctx);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showNotificationSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Notification Preferences', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkSlate)),
                const SizedBox(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: primaryBlue,
                  title: const Text('Push Notifications', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Instant updates on booking progress', style: TextStyle(fontSize: 12, color: textMuted)),
                  value: _pushNotifications,
                  onChanged: (val) {
                    setState(() => _pushNotifications = val);
                    setModalState(() {});
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: primaryBlue,
                  title: const Text('SMS Updates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('OTP and important security alerts', style: TextStyle(fontSize: 12, color: textMuted)),
                  value: _smsAlerts,
                  onChanged: (val) {
                    setState(() => _smsAlerts = val);
                    setModalState(() {});
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPolicySheet(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, scrollController) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkSlate)),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Text(
                      content,
                      style: const TextStyle(fontSize: 13.5, color: darkSlate, height: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out of your ServiceHub account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(authControllerProvider.notifier).logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully logged out')),
        );
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Settings',
          style: TextStyle(color: darkSlate, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Settings Cards Container
            Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: borderGrey),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  _buildSettingsRow(
                    icon: Icons.shield_outlined,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: primaryBlue,
                    title: 'Account & Security',
                    onTap: () {
                      final p = CustomerProfileService.instance.getProfile();
                      _showPolicySheet(
                        'Account & Security',
                        'User: ${p['full_name']}\nPhone: ${p['phone']}\nEmail: ${p['email']}\n\nTwo-Factor Authentication: Enabled\nEncryption: 256-bit AES SSL/TLS Active.\nYour session is verified with Supabase Auth Engine.',
                      );
                    },
                  ),
                  const Divider(height: 1, color: borderGrey, indent: 56),
                  _buildSettingsRow(
                    icon: Icons.language_rounded,
                    iconBg: const Color(0xFFFAF5FF),
                    iconColor: const Color(0xFF9333EA),
                    title: 'Language',
                    trailingText: '$_selectedLanguage >',
                    onTap: _showLanguageDialog,
                  ),
                  const Divider(height: 1, color: borderGrey, indent: 56),
                  _buildSettingsRow(
                    icon: Icons.notifications_none_rounded,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: primaryBlue,
                    title: 'Notifications',
                    onTap: _showNotificationSettings,
                  ),
                  const Divider(height: 1, color: borderGrey, indent: 56),
                  _buildSettingsRow(
                    icon: Icons.privacy_tip_outlined,
                    iconBg: const Color(0xFFECFDF5),
                    iconColor: const Color(0xFF10B981),
                    title: 'Privacy Policy',
                    onTap: () => _showPolicySheet(
                      'Privacy Policy',
                      'ServiceHub is committed to safeguarding your personal data.\n\n1. Data We Collect: When you use ServiceHub, we collect basic registration data (name, phone number, address) to fulfill service orders.\n2. Location Permissions: We use GPS coordinates strictly during booking requests and live partner navigation.\n3. Third Parties: We do not sell your data to any third party advertisers.\n4. Account Rights: You can request complete deletion of your account and personal history at any time from Help & Support.',
                    ),
                  ),
                  const Divider(height: 1, color: borderGrey, indent: 56),
                  _buildSettingsRow(
                    icon: Icons.description_outlined,
                    iconBg: const Color(0xFFFEF3C7),
                    iconColor: const Color(0xFFD97706),
                    title: 'Terms & Conditions',
                    onTap: () => _showPolicySheet(
                      'Terms & Conditions',
                      'Welcome to ServiceHub!\n\n1. Acceptance of Terms: By creating an account or placing a booking on ServiceHub, you agree to these Terms and Conditions.\n2. Service Deliveries: Service technicians and delivery agents operate under verified KYC compliance.\n3. Pricing & Fees: Final amounts payable are presented clearly at checkout before booking confirmation.\n4. Cancellations: Bookings can be cancelled free of charge prior to partner dispatch.',
                    ),
                  ),
                  const Divider(height: 1, color: borderGrey, indent: 56),
                  _buildSettingsRow(
                    icon: Icons.info_outline_rounded,
                    iconBg: const Color(0xFFF1F5F9),
                    iconColor: textMuted,
                    title: 'App Version',
                    trailingText: 'v1.0.0',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _logout,
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsRow({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: darkSlate),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            Text(
              trailingText,
              style: const TextStyle(fontSize: 13, color: textMuted),
            )
          else
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
        ],
      ),
    );
  }
}
