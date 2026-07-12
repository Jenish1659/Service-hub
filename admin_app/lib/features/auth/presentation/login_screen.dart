import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mock Admin Login Successful!')),
      );
      context.go('/');
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).login(email, password);
    if (success) {
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

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Center(
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
            ],
          ),
        ),
      ),
    );
  }
}
