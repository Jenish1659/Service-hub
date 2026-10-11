import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/local_registration_cache.dart';

/// Screen 12: Dedicated Settings Sub-Screen for Care Taker Specialist
class CareSettingsScreen extends StatefulWidget {
  const CareSettingsScreen({super.key});

  @override
  State<CareSettingsScreen> createState() => _CareSettingsScreenState();
}

class _CareSettingsScreenState extends State<CareSettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';

  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkSlate)),
            const SizedBox(height: 12),
            ...['English', 'Hindi (हिंदी)', 'Gujarati (ગુજરાતી)'].map((lang) {
              final isSel = _selectedLanguage.startsWith(lang.split(' ')[0]);
              return ListTile(
                title: Text(lang),
                trailing: isSel ? const Icon(Icons.check_circle_rounded, color: primaryIndigo) : null,
                onTap: () {
                  setState(() => _selectedLanguage = lang.split(' ')[0]);
                  Navigator.pop(ctx);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordModal() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryIndigo,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password updated successfully!'),
                  backgroundColor: primaryIndigo,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Are you sure you want to log out from your care specialist account?',
          style: TextStyle(fontSize: 13, color: textMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalRegistrationCache.clearActiveSession();
              if (mounted) {
                context.go('/role-selection');
              }
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Settings',
          style: TextStyle(color: darkSlate, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Preference Items matching reference UI
            Material(
              color: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                side: BorderSide(color: cardBorder),
              ),
              child: Column(
                children: [
                  // Notifications
                  ListTile(
                    leading: const Icon(Icons.notifications_outlined, color: primaryIndigo),
                    title: const Text('Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkSlate)),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      activeThumbColor: primaryIndigo,
                      onChanged: (val) => setState(() => _notificationsEnabled = val),
                    ),
                  ),
                  const Divider(height: 1, indent: 56, color: cardBorder),

                  // Language
                  ListTile(
                    leading: const Icon(Icons.language_rounded, color: primaryIndigo),
                    title: const Text('Language', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkSlate)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedLanguage, style: const TextStyle(fontSize: 13, color: textMuted)),
                        const Icon(Icons.chevron_right_rounded, color: textMuted),
                      ],
                    ),
                    onTap: _showLanguageSelector,
                  ),
                  const Divider(height: 1, indent: 56, color: cardBorder),

                  // Change Password
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded, color: primaryIndigo),
                    title: const Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkSlate)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: textMuted),
                    onTap: _showChangePasswordModal,
                  ),
                  const Divider(height: 1, indent: 56, color: cardBorder),

                  // Privacy Policy
                  ListTile(
                    leading: const Icon(Icons.privacy_tip_outlined, color: primaryIndigo),
                    title: const Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkSlate)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: textMuted),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Privacy Policy: Medical data protected per HIPAA and DPDP standards.')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: cardBorder),

                  // Terms & Conditions
                  ListTile(
                    leading: const Icon(Icons.article_outlined, color: primaryIndigo),
                    title: const Text('Terms & Conditions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkSlate)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: textMuted),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms of Service: Care Taker Partner Service Agreement active.')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: cardBorder),

                  // Help & Support
                  ListTile(
                    leading: const Icon(Icons.help_outline_rounded, color: primaryIndigo),
                    title: const Text('Help & Support', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkSlate)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: textMuted),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('24x7 Partner Caregiver Helpline: 1800-SERVICE-HUB')),
                      );
                    },
                  ),
                  const Divider(height: 1, indent: 56, color: cardBorder),

                  // Logout
                  ListTile(
                    leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
                    title: const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                    onTap: _showLogoutDialog,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
