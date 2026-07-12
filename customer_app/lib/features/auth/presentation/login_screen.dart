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
        const SnackBar(content: Text('Please enter your name for sign up.')),
      );
      return;
    }

    bool success = false;
    if (_isSignUp) {
      success = await ref.read(authControllerProvider.notifier).signUpWithEmail(
        email,
        password,
        name,
        'customer',
      );
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully! Welcome!'), backgroundColor: AppTheme.successColor),
        );
        context.go('/');
      }
    } else {
      success = await ref.read(authControllerProvider.notifier).loginWithEmail(email, password);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logged in successfully!'), backgroundColor: AppTheme.successColor),
        );
        context.go('/');
      }
    }

    if (!success) {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Authentication failed. Please verify credentials.'),
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
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create Account' : 'Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isSignUp ? 'Join ServiceHub' : 'Welcome back',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isSignUp ? 'Register to start booking services near you.' : 'Log in to your hyperlocal service account.',
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
                    hintText: 'Enter your Full Name',
                    prefixIcon: Icon(Icons.person, color: AppTheme.textSecondaryColor),
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
                      : Text(_isSignUp ? 'Create Account' : 'Verify & Login'),
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
                    _isSignUp ? 'Already have an account? Sign In' : 'New to ServiceHub? Create Account',
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
