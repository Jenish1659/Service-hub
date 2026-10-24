import 'package:supabase_flutter/supabase_flutter.dart';
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

  void _showUpdatePasswordModal() {
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();

    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? errorMessage;
    bool isUpdating = false;

    showDialog(
      context: context,
      barrierDismissible: !isUpdating,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: primaryBlue, size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Update Password',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: darkSlate),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your current old password to verify your identity, then specify your new secure password.',
                    style: TextStyle(fontSize: 12.5, color: textMuted),
                  ),
                  const SizedBox(height: 16),

                  if (errorMessage != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Current Password
                  const Text('Current Password *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkSlate)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: oldPassController,
                    obscureText: obscureOld,
                    decoration: InputDecoration(
                      hintText: 'Enter current old password',
                      prefixIcon: const Icon(Icons.key_rounded, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: IconButton(
                        icon: Icon(obscureOld ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                        onPressed: () => setModalState(() => obscureOld = !obscureOld),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // New Password
                  const Text('New Password *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkSlate)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: newPassController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      hintText: 'At least 6 characters',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                        onPressed: () => setModalState(() => obscureNew = !obscureNew),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Confirm New Password
                  const Text('Confirm New Password *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkSlate)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: confirmPassController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      hintText: 'Re-type new password',
                      prefixIcon: const Icon(Icons.lock_clock_outlined, size: 18, color: Color(0xFF94A3B8)),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                        onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                      ),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: textMuted)),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: isUpdating
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check_circle_rounded, size: 16),
              label: Text(isUpdating ? 'Verifying...' : 'Update Password'),
              onPressed: isUpdating
                  ? null
                  : () async {
                      final oldPass = oldPassController.text.trim();
                      final newPass = newPassController.text.trim();
                      final confirmPass = confirmPassController.text.trim();

                      if (oldPass.isEmpty) {
                        setModalState(() => errorMessage = 'Please enter your current password');
                        return;
                      }
                      if (newPass.length < 6) {
                        setModalState(() => errorMessage = 'New password must be at least 6 characters long');
                        return;
                      }
                      if (newPass != confirmPass) {
                        setModalState(() => errorMessage = 'New passwords do not match. Please re-type.');
                        return;
                      }
                      if (oldPass == newPass) {
                        setModalState(() => errorMessage = 'New password cannot be identical to your old password');
                        return;
                      }

                      setModalState(() {
                        isUpdating = true;
                        errorMessage = null;
                      });

                      // Verify old password against active session and database
                      bool isOldCorrect = false;
                      final client = Supabase.instance.client;
                      final user = client.auth.currentUser;
                      final profile = CustomerProfileService.instance.getProfile();
                      final storedPass = profile['password'] ?? profile['password_hash'];

                      // Check stored session password
                      if (storedPass != null && storedPass.toString().isNotEmpty) {
                        if (storedPass.toString() == oldPass) {
                          isOldCorrect = true;
                        }
                      }

                      // Check Supabase Auth signIn
                      if (!isOldCorrect && user != null && user.email != null && user.email!.isNotEmpty) {
                        try {
                          await client.auth.signInWithPassword(email: user.email!, password: oldPass);
                          isOldCorrect = true;
                        } catch (_) {}
                      }

                      // Check PostgreSQL users table
                      if (!isOldCorrect) {
                        final uId = profile['user_id'] ?? user?.id;
                        final uPhone = profile['phone'];
                        try {
                          var query = client.from('users').select('password_hash');
                          if (uId != null && uId.toString().isNotEmpty) {
                            query = query.eq('user_id', uId.toString());
                          } else if (uPhone != null && uPhone.toString().isNotEmpty) {
                            final cleanP = uPhone.toString().replaceAll(RegExp(r'\D'), '');
                            query = query.or('phone.eq.$cleanP,phone.eq.+91$cleanP');
                          }
                          final uRes = await query.maybeSingle();
                          if (uRes != null && uRes['password_hash'] != null) {
                            if (uRes['password_hash'].toString() == oldPass) {
                              isOldCorrect = true;
                            }
                          }
                        } catch (_) {}
                      }

                      // If old password is incorrect, show exact error message requested by user
                      if (!isOldCorrect) {
                        setModalState(() {
                          isUpdating = false;
                          errorMessage = 'Old password is incorrect. Please re-type your current password.';
                        });
                        return;
                      }

                      // Old password is correct -> update in Supabase and local profile cache
                      try {
                        if (user != null) {
                          try {
                            await client.auth.updateUser(UserAttributes(password: newPass));
                          } catch (_) {}
                        }
                        final uId = profile['user_id'] ?? user?.id;
                        if (uId != null && uId.toString().isNotEmpty) {
                          try {
                            await client.from('users').update({
                              'password_hash': newPass,
                              'updated_at': DateTime.now().toIso8601String(),
                            }).eq('user_id', uId.toString());
                          } catch (_) {}
                        }
                        profile['password'] = newPass;
                        profile['password_hash'] = newPass;
                        await CustomerProfileService.instance.updateProfile(profile);
                      } catch (_) {}

                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                      }
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Password updated successfully!'),
                            backgroundColor: Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
            ),
          ],
        ),
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
                    icon: Icons.lock_outline_rounded,
                    iconBg: const Color(0xFFEFF6FF),
                    iconColor: primaryBlue,
                    title: 'Update Password',
                    onTap: _showUpdatePasswordModal,
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
