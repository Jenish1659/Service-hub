import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all credentials.')),
      );
      return;
    }

    // Local Demo / Prototype Bypass
    if (email == 'admin@servicehub.com' && password == 'admin123') {
      adminBypassLoggedIn = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mock Admin Login Successful!')),
      );
      context.go('/');
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).login(email, password);
    if (!mounted) return;
    if (success) {
      adminBypassLoggedIn = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin authenticated successfully!')),
      );
      context.go('/');
    } else {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Authentication failed.')),
      );
    }
  }

  void _showAdminTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.admin_panel_settings_outlined, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Admin Terms & Security Compliance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              '1. Authorized Access Only: Admin portal access is strictly restricted to designated platform administrators.\n\n'
              '2. Data Governance & Privacy: Customer, provider, and transaction logs must be kept confidential.\n\n'
              '3. Audit Logging: All admin actions, approvals, and dispute resolutions are logged for security auditing.\n\n'
              '4. System Integrity: Unauthorized credential sharing or automated data scraping is strictly prohibited.',
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
              child: const Text('Understand & Close', style: TextStyle(color: Colors.white)),
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
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
            border: Border.all(color: AppTheme.borderCol),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Icon(Icons.admin_panel_settings, size: 64, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Text(
                  'ServiceHub Admin Portal',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _emailController,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  hintText: 'Admin Email ID',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                enabled: !isLoading,
                decoration: const InputDecoration(
                  hintText: 'Enter Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleLogin,
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Access Dashboard'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: InkWell(
                  onTap: () => _showAdminTermsDialog(context),
                  child: const Text.rich(
                    TextSpan(
                      text: 'Protected Administrative System · ',
                      style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                      children: [
                        TextSpan(
                          text: 'Admin Terms & Compliance',
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
    ),
    );
  }
}
