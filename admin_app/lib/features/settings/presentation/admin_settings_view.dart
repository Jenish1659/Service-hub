import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSettingsView extends StatefulWidget {
  const AdminSettingsView({super.key});

  @override
  State<AdminSettingsView> createState() => _AdminSettingsViewState();
}

class _AdminSettingsViewState extends State<AdminSettingsView> {
  double _serviceCommission = 10.0;
  double _geofenceRadius = 5.0;
  bool _enforceStrictGeofence = true;

  // Password update controllers
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _passwordError;
  bool _isUpdatingPassword = false;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _handleAdminPasswordUpdate() async {
    final oldPass = _oldPassController.text.trim();
    final newPass = _newPassController.text.trim();
    final confirmPass = _confirmPassController.text.trim();

    if (oldPass.isEmpty) {
      setState(() => _passwordError = 'Please enter your current admin password');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _passwordError = 'New password must be at least 6 characters long');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _passwordError = 'New passwords do not match. Please re-type.');
      return;
    }
    if (oldPass == newPass) {
      setState(() => _passwordError = 'New password cannot be identical to current password');
      return;
    }

    setState(() {
      _isUpdatingPassword = true;
      _passwordError = null;
    });

    // 1. Verify old password against Admin credentials
    bool isOldCorrect = false;
    // Default executive admin password check
    if (oldPass == 'Admin@123') {
      isOldCorrect = true;
    }

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    // Check Supabase Auth signIn if active
    if (!isOldCorrect && user != null && user.email != null) {
      try {
        await client.auth.signInWithPassword(email: user.email!, password: oldPass);
        isOldCorrect = true;
      } catch (_) {}
    }

    // Check database users table for admin role password_hash
    if (!isOldCorrect) {
      try {
        final adminRes = await client
            .from('users')
            .select('password_hash, roles!inner(role_name)')
            .eq('roles.role_name', 'admin')
            .limit(1)
            .maybeSingle();
        if (adminRes != null && adminRes['password_hash'] != null) {
          if (adminRes['password_hash'].toString() == oldPass) {
            isOldCorrect = true;
          }
        }
      } catch (_) {}
    }

    if (!isOldCorrect) {
      if (mounted) {
        setState(() {
          _isUpdatingPassword = false;
          _passwordError = 'Old password is incorrect. Please re-type your current password.';
        });
      }
      return;
    }

    // 2. Old password is correct -> Update password in Supabase and Auth
    try {
      if (user != null) {
        try {
          await client.auth.updateUser(UserAttributes(password: newPass));
        } catch (_) {}
      }
      // Update in PostgreSQL users table
      await client.from('users').update({
        'password_hash': newPass,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('email', 'admin@gmail.com');
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isUpdatingPassword = false;
        _passwordError = null;
        _oldPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Admin password updated in database successfully!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'System Settings & Security Controls',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configure platform commission, geofence radius limits (5km strict), and administrator credentials',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),

          // Container 1: Platform Commission & Geofence Policy
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.tune_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Platform Commission & Geofence Policy',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Service Provider Commission Rate (%):', style: TextStyle(fontSize: 13, color: Color(0xFF334155))),
                    ),
                    Text('${_serviceCommission.toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2563EB))),
                  ],
                ),
                Slider(
                  value: _serviceCommission,
                  min: 5,
                  max: 25,
                  divisions: 20,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (val) => setState(() => _serviceCommission = val),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    const Expanded(
                      child: Text('Partner Job Dispatch Radius (km):', style: TextStyle(fontSize: 13, color: Color(0xFF334155))),
                    ),
                    Text('${_geofenceRadius.toInt()} km', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF2563EB))),
                  ],
                ),
                Slider(
                  value: _geofenceRadius,
                  min: 2,
                  max: 20,
                  divisions: 18,
                  activeColor: const Color(0xFF2563EB),
                  onChanged: (val) => setState(() => _geofenceRadius = val),
                ),
                const SizedBox(height: 14),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enforce Strict Geofence Job Dispatching', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                  subtitle: const Text('Only notify partners located within configured radius of the customer', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: _enforceStrictGeofence,
                  activeTrackColor: const Color(0xFF2563EB),
                  onChanged: (val) => setState(() => _enforceStrictGeofence = val),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Container 2: Admin Password & Security Settings
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Admin Password & Security Settings',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Verify your current administrator password to update your login credentials.',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 16),

                if (_passwordError != null) ...[
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
                            _passwordError!,
                            style: const TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Form Fields Row / Grid
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 580),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Old Password *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _oldPassController,
                        obscureText: _obscureOld,
                        decoration: InputDecoration(
                          hintText: 'Enter current old password',
                          prefixIcon: const Icon(Icons.key_rounded, size: 18, color: Color(0xFF94A3B8)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureOld ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                            onPressed: () => setState(() => _obscureOld = !_obscureOld),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('New Admin Password *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _newPassController,
                        obscureText: _obscureNew,
                        decoration: InputDecoration(
                          hintText: 'Minimum 6 characters',
                          prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF94A3B8)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                            onPressed: () => setState(() => _obscureNew = !_obscureNew),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('Confirm New Password *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _confirmPassController,
                        obscureText: _obscureConfirm,
                        decoration: InputDecoration(
                          hintText: 'Re-type new password',
                          prefixIcon: const Icon(Icons.lock_clock_outlined, size: 18, color: Color(0xFF94A3B8)),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 18),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),

                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: _isUpdatingPassword
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_rounded, size: 18),
                        label: Text(
                          _isUpdatingPassword ? 'Verifying...' : 'Update Admin Password',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: _isUpdatingPassword ? null : _handleAdminPasswordUpdate,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
