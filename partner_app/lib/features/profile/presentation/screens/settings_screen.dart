import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/about_service_hub_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/active_sessions_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/change_password_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/data_and_permissions_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delete_account_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/documents_and_verification_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/help_and_support_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/login_and_security_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/phone_and_email_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/privacy_controls_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/report_a_problem_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/terms_and_conditions_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/widgets/profile_avatar_widget.dart';

class SettingsScreen extends StatefulWidget {
  final ProfileController controller;

  const SettingsScreen({
    super.key,
    required this.controller,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  ProfileController get c => widget.controller;

  void _showAppearanceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Choose Appearance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.light_mode_rounded, color: Color(0xFFEAB308)),
                title: const Text('Light Mode'),
                trailing: c.appearanceMode == 'Light' ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB)) : null,
                onTap: () {
                  c.setAppearanceMode('Light');
                  setState(() {});
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.dark_mode_rounded, color: Color(0xFF64748B)),
                title: const Text('Dark Mode (Coming Soon)'),
                trailing: c.appearanceMode == 'Dark' ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB)) : null,
                onTap: () {
                  c.setAppearanceMode('Dark');
                  setState(() {});
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLanguageSheet() {
    final languages = ['English', 'Hindi', 'Gujarati'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Select Language', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ...languages.map((lang) {
                final isSelected = c.selectedLanguage == lang;
                return ListTile(
                  leading: const Icon(Icons.translate_rounded, color: Color(0xFF2563EB)),
                  title: Text(lang, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: Color(0xFF2563EB)) : null,
                  onTap: () {
                    c.setSelectedLanguage(lang);
                    setState(() {});
                    Navigator.pop(ctx);
                    TopToast.show(context, 'Language set to $lang', isError: false);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out from ServiceHub Partner?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await LocalRegistrationCache.logout();
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (_) {}
              if (mounted) {
                TopToast.show(context, 'Signed out successfully', isError: false);
                final router = GoRouter.maybeOf(context);
                if (router != null) {
                  router.go('/role-selection');
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            child: const Text('Sign Out'),
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
                          'Settings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Manage your app preferences',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                  // Notification Bell with Badge (4)
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.notifications_none_rounded, size: 20, color: Color(0xFF1E293B)),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: Container(
                          padding: const EdgeInsets.all(3.5),
                          decoration: const BoxDecoration(
                            color: Color(0xFFEF4444),
                            shape: BoxShape.circle,
                          ),
                          child: const Text(
                            '4',
                            style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 10),
                  // Mini Avatar
                  ProfileAvatarWidget(
                    photoPath: c.profilePhotoPath,
                    name: c.partnerName,
                    size: 34,
                    showCameraBadge: false,
                  ),
                ],
              ),
            ),

            // Main Settings List
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- SECTION 1: ACCOUNT ---
                    _buildSectionHeader('ACCOUNT'),
                    _buildGroupCard([
                      _buildSettingsTile(
                        icon: Icons.shield_outlined,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Login & Security',
                        subtitle: 'Manage your login and security settings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => LoginAndSecurityScreen(controller: c)),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.lock_outline_rounded,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Change Password',
                        subtitle: 'Keep your account secure',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ChangePasswordScreen(controller: c)),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.mail_outline_rounded,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                        title: 'Phone & Email',
                        subtitle: 'Update your contact information',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PhoneAndEmailScreen(controller: c)),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.laptop_chromebook_rounded,
                        iconBg: const Color(0xFFFFEDD5),
                        iconColor: const Color(0xFFEA580C),
                        title: 'Active Sessions',
                        subtitle: 'Manage your logged-in devices',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ActiveSessionsScreen(controller: c)),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // --- SECTION 2: NOTIFICATIONS ---
                    _buildSectionHeader('NOTIFICATIONS'),
                    _buildGroupCard([
                      _buildSwitchTile(
                        icon: Icons.notifications_none_rounded,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                        title: 'Push Notifications',
                        subtitle: 'Receive important updates',
                        value: c.pushNotificationsEnabled,
                        onChanged: (val) {
                          c.togglePushNotifications(val);
                          setState(() {});
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.calendar_month_outlined,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Booking Requests',
                        subtitle: 'Get notified for new service requests',
                        value: c.bookingRequestsEnabled,
                        onChanged: (val) {
                          c.toggleBookingRequests(val);
                          setState(() {});
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.credit_card_rounded,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        title: 'Payment Updates',
                        subtitle: 'Get updates about payments and earnings',
                        value: c.paymentUpdatesEnabled,
                        onChanged: (val) {
                          c.togglePaymentUpdates(val);
                          setState(() {});
                        },
                      ),
                      _buildDivider(),
                      _buildSwitchTile(
                        icon: Icons.alarm_rounded,
                        iconBg: const Color(0xFFFEE2E2),
                        iconColor: const Color(0xFFEF4444),
                        title: 'Service Reminders',
                        subtitle: 'Get reminders for your scheduled services',
                        value: c.serviceRemindersEnabled,
                        onChanged: (val) {
                          c.toggleServiceReminders(val);
                          setState(() {});
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // --- SECTION 3: APP PREFERENCES ---
                    _buildSectionHeader('APP PREFERENCES'),
                    _buildGroupCard([
                      _buildSettingsTile(
                        icon: Icons.dark_mode_outlined,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF7C3AED),
                        title: 'Appearance',
                        subtitle: 'Choose light or dark mode',
                        trailingText: c.appearanceMode,
                        onTap: _showAppearanceSheet,
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.language_rounded,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Language',
                        subtitle: 'Select your preferred language',
                        trailingText: c.selectedLanguage,
                        onTap: _showLanguageSheet,
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.location_on_outlined,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Location Services',
                        subtitle: 'Allow location access for better service matching',
                        trailingText: c.locationServicesEnabled ? 'On' : 'Off',
                        onTap: () {
                          c.toggleLocationServices(!c.locationServicesEnabled);
                          setState(() {});
                          TopToast.show(
                            context,
                            'Location access ${c.locationServicesEnabled ? 'enabled' : 'disabled'}',
                            isError: false,
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // --- SECTION 4: PRIVACY & SECURITY ---
                    _buildSectionHeader('PRIVACY & SECURITY'),
                    _buildGroupCard([
                      _buildSettingsTile(
                        icon: Icons.verified_user_outlined,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Privacy Controls',
                        subtitle: 'Manage your privacy settings',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => PrivacyControlsScreen(controller: c)),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.dns_outlined,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                        title: 'Data & Permissions',
                        subtitle: 'Control your data and app permissions',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DataAndPermissionsScreen(controller: c)),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.description_outlined,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Document Security',
                        subtitle: 'Manage your document visibility and security',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DocumentsAndVerificationScreen(controller: c)),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // --- SECTION 5: SUPPORT ---
                    _buildSectionHeader('SUPPORT'),
                    _buildGroupCard([
                      _buildSettingsTile(
                        icon: Icons.headset_mic_outlined,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'Help & Support',
                        subtitle: 'Get help, FAQs and contact us',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => HelpAndSupportScreen(controller: c)),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.chat_bubble_outline_rounded,
                        iconBg: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        title: 'Report a Problem',
                        subtitle: 'Let us know if something isn\'t working',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ReportAProblemScreen(controller: c)),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.feed_outlined,
                        iconBg: const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                        title: 'Terms & Conditions',
                        subtitle: 'Read our terms and conditions',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TermsAndConditionsScreen()),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.privacy_tip_outlined,
                        iconBg: const Color(0xFFDCFCE7),
                        iconColor: const Color(0xFF16A34A),
                        title: 'Privacy Policy',
                        subtitle: 'Learn how we protect your data',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                          );
                        },
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        icon: Icons.info_outline_rounded,
                        iconBg: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        title: 'About ServiceHub',
                        subtitle: 'App version, legal info and more',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AboutServiceHubScreen()),
                          );
                        },
                      ),
                    ]),
                    const SizedBox(height: 20),

                    // --- SECTION 6: ACCOUNT ACTIONS ---
                    _buildSectionHeader('ACCOUNT ACTIONS'),
                    // Sign Out Action Card
                    _buildDestructiveActionCard(
                      icon: Icons.logout_rounded,
                      title: 'Sign Out',
                      subtitle: 'Log out from your account',
                      onTap: _showSignOutDialog,
                    ),
                    const SizedBox(height: 12),

                    // Delete Account Action Card
                    _buildDestructiveActionCard(
                      icon: Icons.delete_outline_rounded,
                      title: 'Delete Account',
                      subtitle: 'Permanently delete your account and all data',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => DeleteAccountScreen(controller: c)),
                        );
                      },
                    ),
                    const SizedBox(height: 30),

                    // Footer
                    const Center(
                      child: Column(
                        children: [
                          Text(
                            'ServiceHub  •  Version 1.0.0',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Better Services, Brighter Tomorrows',
                            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
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
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(height: 1, thickness: 1, indent: 56, endIndent: 12, color: Color(0xFFF1F5F9));
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailingText,
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
              width: 36,
              height: 36,
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
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
              const SizedBox(width: 4),
            ],
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
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
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
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

  Widget _buildDestructiveActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEE2E2)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFFEF4444)),
            ],
          ),
        ),
      ),
    );
  }
}
