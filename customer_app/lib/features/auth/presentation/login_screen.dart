import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  bool _otpSent = false;
  String _generatedOtp = '';
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    _otpController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _sendSimulatedOtp() {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 10-digit mobile number.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your name to proceed.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    // Generate random 4-digit OTP
    final random = Random();
    _generatedOtp = (1000 + random.nextInt(9000)).toString();

    setState(() {
      _otpSent = true;
    });
    _animController.forward();

    // Show custom high-end demo OTP alert banner
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.sms_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'SIMULATED SMS OTP RECEIVED',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.white70),
                  ),
                  Text(
                    'Your ServiceHub Verification Code is: $_generatedOtp',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xff1e293b),
        duration: const Duration(seconds: 12),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        action: SnackBarAction(
          label: 'AUTO-FILL',
          textColor: AppTheme.primaryColor,
          onPressed: () {
            _otpController.text = _generatedOtp;
          },
        ),
      ),
    );
  }

  Future<void> _verifyAndLogin() async {
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();
    final otp = _otpController.text.trim();

    if (otp != _generatedOtp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid verification code. Please check the SMS banner.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).verifyPhoneOtpAndLogin(name, phone);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Logged in successfully! Welcome to ServiceHub.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      context.go('/');
    } else {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Login failed. Please retry.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.gavel_rounded, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Terms & Conditions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              '1. Service Scope: ServiceHub operates hyperlocally within designated 5 km service zones in Jamnagar.\n\n'
              '2. Identity & PIN Verification: All service completions and product deliveries require validation via secure OTP or encrypted 4-digit PIN.\n\n'
              '3. User Conduct & Safety: Users must provide accurate address details and safe working environments for service providers.\n\n'
              '4. Cancellation Policy: Free cancellations allowed prior to provider dispatch. Standard fee applies after dispatch.\n\n'
              '5. Privacy & Data Handling: Personal data is securely processed in accordance with strict data protection guidelines.',
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xff334155)),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('I Understand', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff0f172a), Color(0xff1e293b)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Card(
                elevation: 12,
                color: Colors.white.withValues(alpha: 0.95),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header logo
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bolt_rounded,
                              color: AppTheme.primaryColor,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'ServiceHub',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xff0f172a),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Secure Sign In',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0f172a),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _otpSent 
                            ? 'Enter the 4-digit code sent to your mobile.' 
                            : 'Enter your details to instantly log in or register.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xff64748b),
                        ),
                      ),
                      const SizedBox(height: 28),

                      if (!_otpSent) ...[
                        // Name input
                        const Text(
                          'FULL NAME',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff475569),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _nameController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.name,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'e.g. Jenish Bheda',
                            prefixIcon: const Icon(Icons.person_outline, size: 20),
                            filled: true,
                            fillColor: const Color(0xfff8fafc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xffe2e8f0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xffe2e8f0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Phone input
                        const Text(
                          'MOBILE NUMBER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff475569),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _phoneController,
                          enabled: !isLoading,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Enter 10-Digit Mobile Number',
                            prefixIcon: const Icon(Icons.phone_android_rounded, size: 20),
                            prefixText: '+91 ',
                            prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
                            filled: true,
                            fillColor: const Color(0xfff8fafc),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xffe2e8f0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Color(0xffe2e8f0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Send OTP Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _sendSimulatedOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 2,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Send Verification OTP',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Terms & Conditions Notice
                        Center(
                          child: InkWell(
                            onTap: () => _showTermsDialog(context),
                            child: const Text.rich(
                              TextSpan(
                                text: 'By continuing, you agree to ServiceHub\'s ',
                                style: TextStyle(fontSize: 11, color: Color(0xff64748b)),
                                children: [
                                  TextSpan(
                                    text: 'Terms & Conditions',
                                    style: TextStyle(
                                      color: AppTheme.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ] else ...[
                        // OTP Input
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'ENTER SMS OTP',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff475569),
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _otpSent = false;
                                        _otpController.clear();
                                      });
                                    },
                                    child: const Text('Change Number', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _otpController,
                                enabled: !isLoading,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(4),
                                ],
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 8.0),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '••••',
                                  hintStyle: const TextStyle(letterSpacing: 8.0),
                                  filled: true,
                                  fillColor: const Color(0xfff8fafc),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xffe2e8f0)),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: Color(0xffe2e8f0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),

                              // Verify and Login Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _verifyAndLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.successColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                        )
                                      : const Text(
                                          'Verify & Create Account',
                                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
