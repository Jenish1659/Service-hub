import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/storage/local_registration_cache.dart';

/// Screen 12: Subpage 6 - Settings for Car Service Provider
class CarSettingsScreen extends StatefulWidget {
  const CarSettingsScreen({super.key});

  @override
  State<CarSettingsScreen> createState() => _CarSettingsScreenState();
}

class _CarSettingsScreenState extends State<CarSettingsScreen> {
  bool _notificationsEnabled = true;
  String _selectedLanguage = 'English';

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  void _showChangePasswordDialog() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password updated successfully!'),
                  backgroundColor: primaryBlue,
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

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: const Text('Select Language', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        children: ['English', 'Hindi (हिंदी)', 'Gujarati (ગુજરાતી)'].map((lang) {
          return SimpleDialogOption(
            onPressed: () {
              setState(() => _selectedLanguage = lang.split(' ')[0]);
              Navigator.pop(ctx);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(lang, style: const TextStyle(fontSize: 14)),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Are you sure you want to sign out from your car service specialist account?',
          style: TextStyle(fontSize: 13, color: textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: textMuted)),
          ),
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
            child: const Text('Sign Out'),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: darkSlate,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Material(
              color: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                side: BorderSide(color: cardBorder),
              ),
              child: Column(
                children: [
                  // 1. Notifications
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.notifications_outlined, color: Color(0xFFEF4444), size: 20),
                    ),
                    title: const Text('Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
                    trailing: Switch(
                      value: _notificationsEnabled,
                      activeThumbColor: primaryBlue,
                      onChanged: (val) {
                        setState(() => _notificationsEnabled = val);
                      },
                    ),
                  ),
                  const Divider(height: 1, color: cardBorder),

                  // 2. Language
                  ListTile(
                    onTap: _showLanguageDialog,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF97316).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.language_rounded, color: Color(0xFFF97316), size: 20),
                    ),
                    title: const Text('Language', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_selectedLanguage, style: const TextStyle(fontSize: 13, color: textMuted)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textMuted),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: cardBorder),

                  // 3. Change Password
                  ListTile(
                    onTap: _showChangePasswordDialog,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.lock_outline_rounded, color: primaryBlue, size: 20),
                    ),
                    title: const Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textMuted),
                  ),
                  const Divider(height: 1, color: cardBorder),

                  // 4. Privacy Policy
                  ListTile(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ServiceHub Privacy Policy'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.shield_outlined, color: Color(0xFF10B981), size: 20),
                    ),
                    title: const Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textMuted),
                  ),
                  const Divider(height: 1, color: cardBorder),

                  // 5. Terms & Conditions
                  ListTile(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Terms & Conditions for Car Service Partners'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.description_outlined, color: Color(0xFF6366F1), size: 20),
                    ),
                    title: const Text('Terms & Conditions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textMuted),
                  ),
                  const Divider(height: 1, color: cardBorder),

                  // 6. Help & Support
                  ListTile(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('ServiceHub Partner Support Helpline: 1800-123-7890'), behavior: SnackBarBehavior.floating),
                      );
                    },
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.help_outline_rounded, color: Color(0xFF06B6D4), size: 20),
                    ),
                    title: const Text('Help & Support', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textMuted),
                  ),
                  const Divider(height: 1, color: cardBorder),

                  // 7. Logout
                  ListTile(
                    onTap: _showSignOutDialog,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.power_settings_new_rounded, color: Color(0xFFEF4444), size: 20),
                    ),
                    title: const Text('Logout', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
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
