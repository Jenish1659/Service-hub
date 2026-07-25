import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../../profile/presentation/profile_provider.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  bool _isSignUp = false;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    if (_isSignUp && name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your company/provider name.')),
      );
      return;
    }

    bool success = false;
    if (_isSignUp) {
      ref.read(loggedInPartnerNameProvider.notifier).state = name;
      // Registering partner
      success = await ref.read(authControllerProvider.notifier).signUpWithEmail(
        email,
        password,
        name,
        'partner',
      );
      if (success) {
        partnerBypassLoggedIn = true;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partner Account created! Select console to begin.'), backgroundColor: AppTheme.successColor),
        );
        context.go('/role-select');
      }
    } else {
      final rawUsername = email.contains('@') ? email.split('@').first : email;
      final displayName = rawUsername.isNotEmpty
          ? '${rawUsername[0].toUpperCase()}${rawUsername.substring(1)}'
          : 'ServiceHub Partner';
      ref.read(loggedInPartnerNameProvider.notifier).state = displayName;

      // Local Demo / Prototype Bypass
      if (email == 'partner@servicehub.com' && password == 'partner123') {
        partnerBypassLoggedIn = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Mock Partner Login Successful!'), backgroundColor: AppTheme.successColor),
        );
        context.go('/role-select');
        return;
      }

      success = await ref.read(authControllerProvider.notifier).loginWithEmail(email, password);
      if (success) {
        partnerBypassLoggedIn = true;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partner authenticated successfully!'), backgroundColor: AppTheme.successColor),
        );
        context.go('/role-select');
      }
    }

    if (!success) {
      final error = ref.read(authControllerProvider).error;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Partner login failed. Verify credentials.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  void _showPartnerTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.handshake_outlined, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Partner Terms & SLAs', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              '1. Service Level Agreement (SLA): Service providers and delivery partners must maintain prompt response times within assigned 5 km zones.\n\n'
              '2. Identity & Verification: All partners must undergo background checks and identity verification before order acceptance.\n\n'
              '3. Commission & Payouts: Weekly automated settlements. ServiceHub retains statutory platform commission fees.\n\n'
              '4. Customer Data Confidentiality: Customer contact details and exact addresses must strictly be used for service execution.',
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
              child: const Text('Agree & Close', style: TextStyle(color: Colors.white)),
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
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignUp ? 'Onboard as a Partner' : 'ServiceHub Partner Workspace',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp 
                    ? 'Register your company to offer services, sell items, or execute deliveries.' 
                    : 'Sign in to access your merchant inventory, service schedules, or delivery routes.',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 32),
              
              if (_isSignUp) ...[
                TextField(
                  controller: _nameController,
                  enabled: !isLoading,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Enter Company or Full Name',
                    prefixIcon: Icon(Icons.business, color: AppTheme.textSecondaryColor),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  hintText: 'Enter Email Address',
                  prefixIcon: Icon(Icons.email, color: AppTheme.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                obscureText: true,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  hintText: 'Enter Password',
                  prefixIcon: Icon(Icons.lock, color: AppTheme.textSecondaryColor),
                ),
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleAuth,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(_isSignUp ? 'Create Partner Profile' : 'Verify & Sign In'),
                ),
              ),
              const SizedBox(height: 16),
              
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _isSignUp = !_isSignUp;
                    });
                  },
                  child: Text(
                    _isSignUp ? 'Already a partner? Sign In' : 'Offer your services on ServiceHub? Sign Up',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Center(
                child: InkWell(
                  onTap: () => _showPartnerTermsDialog(context),
                  child: const Text.rich(
                    TextSpan(
                      text: 'By accessing ServiceHub Partner Workspace, you accept our ',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                      children: [
                        TextSpan(
                          text: 'Partner Terms & Service SLAs',
                          style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
