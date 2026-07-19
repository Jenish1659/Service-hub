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
      // Registering partner
      success = await ref.read(authControllerProvider.notifier).signUpWithEmail(
        email,
        password,
        name,
        'partner',
      );
      if (success) {
        partnerBypassLoggedIn = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partner Account created! Select console to begin.'), backgroundColor: AppTheme.successColor),
        );
        context.go('/role-select');
      }
    } else {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Partner authenticated successfully!'), backgroundColor: AppTheme.successColor),
        );
        context.go('/role-select');
      }
    }

    if (!success) {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Partner login failed. Verify credentials.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
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
            ],
          ),
        ),
      ),
    );
  }
}
