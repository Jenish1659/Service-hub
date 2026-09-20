import 'package:flutter/material.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';

class ChangePasswordScreen extends StatefulWidget {
  final ProfileController controller;

  const ChangePasswordScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPassCtrl = TextEditingController();
  final TextEditingController _newPassCtrl = TextEditingController();
  final TextEditingController _confirmPassCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  bool get _hasMinLength => _newPassCtrl.text.length >= 8;
  bool get _hasUppercase => _newPassCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasDigit => _newPassCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial => _newPassCtrl.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  int get _strengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasDigit) score++;
    if (_hasSpecial) score++;
    return score;
  }

  String get _strengthLabel {
    switch (_strengthScore) {
      case 0:
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return 'Weak';
    }
  }

  Color get _strengthColor {
    switch (_strengthScore) {
      case 0:
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFEAB308);
      case 3:
        return const Color(0xFF3B82F6);
      case 4:
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFFEF4444);
    }
  }

  void _handleUpdatePassword() {
    if (_currentPassCtrl.text.trim().isEmpty) {
      TopToast.show(context, 'Please enter your current password', isError: true);
      return;
    }
    if (_newPassCtrl.text.length < 8) {
      TopToast.show(context, 'New password must be at least 8 characters long', isError: true);
      return;
    }
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      TopToast.show(context, 'New passwords do not match', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _isSaving = false);
      TopToast.show(context, 'Password updated successfully!', isError: false);
      Navigator.pop(context);
    });
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
                          'Change Password',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Keep your partner account safe with a strong password',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Password
                    _buildLabel('CURRENT PASSWORD'),
                    TextField(
                      controller: _currentPassCtrl,
                      obscureText: _obscureCurrent,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Enter current password',
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF64748B)),
                          onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // New Password
                    _buildLabel('NEW PASSWORD'),
                    TextField(
                      controller: _newPassCtrl,
                      obscureText: _obscureNew,
                      style: const TextStyle(fontSize: 13.5),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF64748B)),
                          onPressed: () => setState(() => _obscureNew = !_obscureNew),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Password Strength Bar
                    if (_newPassCtrl.text.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Strength: $_strengthLabel', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _strengthColor)),
                          Text('$_strengthScore/4 checks passed', style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _strengthScore / 4.0,
                          backgroundColor: const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Confirm New Password
                    _buildLabel('CONFIRM NEW PASSWORD'),
                    TextField(
                      controller: _confirmPassCtrl,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(fontSize: 13.5),
                      decoration: InputDecoration(
                        hintText: 'Re-enter new password',
                        filled: true,
                        fillColor: Colors.white,
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: const Color(0xFF64748B)),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Requirements Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Password Requirements:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 10),
                          _buildRequirementItem('Minimum 8 characters long', _hasMinLength),
                          _buildRequirementItem('At least one uppercase letter (A-Z)', _hasUppercase),
                          _buildRequirementItem('At least one numeric digit (0-9)', _hasDigit),
                          _buildRequirementItem('At least one special character (!@#\$...)', _hasSpecial),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Update Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleUpdatePassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: Text(
                          _isSaving ? 'Updating...' : 'Save New Password',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
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

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 2),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.7),
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 16,
            color: met ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              color: met ? const Color(0xFF15803D) : const Color(0xFF64748B),
              fontWeight: met ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
