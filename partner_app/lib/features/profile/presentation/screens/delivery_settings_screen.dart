import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/storage/local_registration_cache.dart';
import '../controllers/delivery_agent_profile_controller.dart';

class DeliverySettingsScreen extends StatefulWidget {
  final DeliveryAgentProfileController? controller;
  const DeliverySettingsScreen({super.key, this.controller});

  @override
  State<DeliverySettingsScreen> createState() => _DeliverySettingsScreenState();
}

class _DeliverySettingsScreenState extends State<DeliverySettingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Notification toggles
  bool _pushNotifications = true;
  bool _newOrderAlerts = true;
  bool _soundOnOrder = true;
  bool _vibration = true;
  bool _earningsAlerts = true;
  bool _promoAlerts = false;

  // Security toggles
  bool _twoFactorAuth = true;
  bool _biometricLogin = false;
  bool _smsAlerts = true;

  // App settings
  String _selectedLanguage = 'English (IN)';
  bool _darkMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;
    String? localError;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(modalCtx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: Color(0xFFEA580C), size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Change Password',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            'Update delivery partner portal security credentials',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (localError != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            localError!,
                            style: const TextStyle(fontSize: 12, color: Color(0xFFDC2626), fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: currentPassController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Current Password',
                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setModalState(() => obscureCurrent = !obscureCurrent),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: newPassController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setModalState(() => obscureNew = !obscureNew),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: confirmPassController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_clock_rounded, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                      onPressed: () => setModalState(() => obscureConfirm = !obscureConfirm),
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final cur = currentPassController.text.trim();
                            final nw = newPassController.text.trim();
                            final conf = confirmPassController.text.trim();

                            if (cur.isEmpty) {
                              setModalState(() => localError = 'Please enter your current password');
                              return;
                            }
                            if (nw.length < 6) {
                              setModalState(() => localError = 'New password must be at least 6 characters long');
                              return;
                            }
                            if (nw != conf) {
                              setModalState(() => localError = 'New passwords do not match');
                              return;
                            }
                            if (cur == nw) {
                              setModalState(() => localError = 'New password cannot be identical to current password');
                              return;
                            }

                            setModalState(() {
                              isSubmitting = true;
                              localError = null;
                            });

                            final messenger = ScaffoldMessenger.of(context);
                            final nav = Navigator.of(ctx);

                            try {
                              final uid = widget.controller?.agentData?['user_id']?.toString() ??
                                  (await LocalRegistrationCache.getActiveDeliveryAgent())?['user_id']?.toString();

                              final success = await SupabaseAuthService.updatePassword(
                                newPassword: nw,
                                currentPassword: cur,
                                userId: uid,
                              );

                              if (success) {
                                await LocalRegistrationCache.updateActiveDeliveryAgent({'password': nw});
                                nav.pop();
                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Password updated and synchronized with database successfully!'),
                                    backgroundColor: Color(0xFF16A34A),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              } else {
                                setModalState(() {
                                  isSubmitting = false;
                                  localError = 'Failed to update password. Please check your credentials.';
                                });
                              }
                            } catch (e) {
                              setModalState(() {
                                isSubmitting = false;
                                localError = 'Error updating password: $e';
                              });
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Update & Synchronize Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog() {
    String selectedReason = 'Switching to another platform';
    final reasons = [
      'Switching to another platform',
      'Not receiving enough orders',
      'Temporary break from delivery',
      'App technical issues',
      'Other reason',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Container(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delete Delivery Account',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          'Screen 16: Irreversible Action',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: const Text(
                  'Deleting your account will permanently wipe your delivery records, payout history, and verified rider badge. Any pending settlements will be cleared to your registered bank account within 3 business days.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please select a reason:',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
              const SizedBox(height: 8),
              ...reasons.map((reason) {
                final isSelected = selectedReason == reason;
                return InkWell(
                  onTap: () => setModalState(() => selectedReason = reason),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: isSelected ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                          size: 18,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          reason,
                          style: TextStyle(
                            fontSize: 13,
                            color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF475569),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel', style: TextStyle(color: Color(0xFF475569))),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await LocalRegistrationCache.clearActiveSession();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Account deletion request submitted.'),
                            backgroundColor: Color(0xFFEF4444),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        context.go('/role-selection');
                      },
                      child: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = AppColors.deliveryOrangeDark;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Settings & Security',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: orangeColor,
          labelColor: orangeColor,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Security'),
            Tab(text: 'Alerts'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGeneralTab(orangeColor),
          _buildSecurityTab(orangeColor),
          _buildAlertsTab(orangeColor),
        ],
      ),
    );
  }

  Widget _buildGeneralTab(Color orangeColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('APP PREFERENCES'),
        _buildSettingCard([
          ListTile(
            leading: const Icon(Icons.language_rounded, color: Color(0xFF2563EB)),
            title: const Text('App Language', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text(_selectedLanguage, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
                builder: (ctx) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: ['English (IN)', 'हिन्दी (Hindi)', 'ગુજરાતી (Gujarati)'].map((lang) {
                      return ListTile(
                        title: Text(lang),
                        trailing: _selectedLanguage == lang ? const Icon(Icons.check, color: Color(0xFFEA580C)) : null,
                        onTap: () {
                          setState(() => _selectedLanguage = lang);
                          Navigator.pop(ctx);
                        },
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode_outlined, color: Color(0xFF475569)),
            title: const Text('Dark Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Adjust display contrast for night riding', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            value: _darkMode,
            activeTrackColor: orangeColor,
            onChanged: (v) => setState(() => _darkMode = v),
          ),
        ]),
        const SizedBox(height: 16),
        _buildSectionHeader('DATA & CACHE'),
        _buildSettingCard([
          ListTile(
            leading: const Icon(Icons.cleaning_services_rounded, color: Color(0xFF059669)),
            title: const Text('Clear App Cache', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Frees up local storage (Current: 0 MB)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully (0 MB freed)'),
                  backgroundColor: Color(0xFF059669),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const Divider(height: 1, indent: 56),
          const ListTile(
            leading: Icon(Icons.map_outlined, color: Color(0xFFEA580C)),
            title: Text('Offline OpenStreetMap Pack', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: Text('Jamnagar local road tile cache up-to-date', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            trailing: Text('0 MB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
          ),
        ]),
        const SizedBox(height: 16),
        _buildSectionHeader('DANGER ZONE'),
        _buildSettingCard([
          ListTile(
            leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
            title: const Text('Delete Delivery Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
            subtitle: const Text('Permanently remove rider profile and history', style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFEF4444)),
            onTap: _showDeleteAccountDialog,
          ),
        ]),
      ],
    );
  }

  Widget _buildSecurityTab(Color orangeColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('AUTHENTICATION & ACCESS'),
        _buildSettingCard([
          ListTile(
            leading: const Icon(Icons.lock_reset_rounded, color: Color(0xFFEA580C)),
            title: const Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Update your delivery partner account login password', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
            onTap: _showChangePasswordDialog,
          ),
          const Divider(height: 1, indent: 56),
          SwitchListTile(
            secondary: const Icon(Icons.security_rounded, color: Color(0xFF059669)),
            title: const Text('Two-Factor Authentication (2FA)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Requires SMS OTP verification on every new login', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            value: _twoFactorAuth,
            activeTrackColor: orangeColor,
            onChanged: (v) => setState(() => _twoFactorAuth = v),
          ),
          const Divider(height: 1, indent: 56),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint_rounded, color: Color(0xFF2563EB)),
            title: const Text('Biometric Quick Login', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Use fingerprint or face recognition to unlock app', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            value: _biometricLogin,
            activeTrackColor: orangeColor,
            onChanged: (v) => setState(() => _biometricLogin = v),
          ),
          const Divider(height: 1, indent: 56),
          SwitchListTile(
            secondary: const Icon(Icons.sms_outlined, color: Color(0xFFEA580C)),
            title: const Text('SMS Security Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Get notified of sensitive account changes via SMS', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            value: _smsAlerts,
            activeTrackColor: orangeColor,
            onChanged: (v) => setState(() => _smsAlerts = v),
          ),
        ]),
        const SizedBox(height: 16),
        _buildSectionHeader('ACTIVE SESSIONS'),
        _buildSettingCard([
          ListTile(
            leading: const Icon(Icons.phone_android_rounded, color: Color(0xFF059669)),
            title: const Text('This Device (Active Now)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Android • Jamnagar, Gujarat • IP Verified', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
            ),
          ),
        ]),
      ],
    );
  }

  Widget _buildAlertsTab(Color orangeColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader('DELIVERY DISPATCH ALERTS'),
        _buildSettingCard([
          SwitchListTile(
            secondary: const Icon(Icons.notifications_active_rounded, color: Color(0xFFEA580C)),
            title: const Text('Push Notifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Receive push alerts when backgrounded', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            value: _pushNotifications,
            activeTrackColor: orangeColor,
            onChanged: (v) => setState(() => _pushNotifications = v),
          ),
          const Divider(height: 1, indent: 56),
          SwitchListTile(
            secondary: const Icon(Icons.delivery_dining_rounded, color: Color(0xFF2563EB)),
            title: const Text('New Order Sound Loud Ringtone', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Play audible alert ringtone for incoming delivery tasks', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            value: _newOrderAlerts,
            activeTrackColor: orangeColor,
            onChanged: (v) => setState(() => _newOrderAlerts = v),
          ),
          const Divider(height: 1, indent: 56),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_rounded, color: Color(0xFF059669)),
            title: const Text('In-App Sound Effects', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Chime sounds for pickup & delivery scans', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            value: _soundOnOrder,
            activeTrackColor: orangeColor,
            onChanged: (v) => setState(() => _soundOnOrder = v),
          ),
          const Divider(height: 1, indent: 56),
          SwitchListTile(
            secondary: const Icon(Icons.vibration_rounded, color: Color(0xFF7C3AED)),
            title: const Text('Haptic Vibration', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Vibrate phone on new delivery task offer', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            value: _vibration,
            activeTrackColor: orangeColor,
            onChanged: (v) => setState(() => _vibration = v),
          ),
        ]),
        const SizedBox(height: 16),
        _buildSectionHeader('PAYOUT & SYSTEM ALERTS'),
        _buildSettingCard([
          SwitchListTile(
            secondary: const Icon(Icons.currency_rupee_rounded, color: Color(0xFF16A34A)),
            title: const Text('Earnings & Payout Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('Instant notification when bank transfer completes', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            value: _earningsAlerts,
            activeTrackColor: orangeColor,
            onChanged: (v) => setState(() => _earningsAlerts = v),
          ),
          const Divider(height: 1, indent: 56),
          SwitchListTile(
            secondary: const Icon(Icons.campaign_outlined, color: Color(0xFF64748B)),
            title: const Text('Platform Updates & Announcements', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            subtitle: const Text('News on bonus incentives and platform upgrades', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            value: _promoAlerts,
            activeTrackColor: orangeColor,
            onChanged: (v) => setState(() => _promoAlerts = v),
          ),
        ]),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF94A3B8)),
      ),
    );
  }

  Widget _buildSettingCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(children: children),
      ),
    );
  }
}
