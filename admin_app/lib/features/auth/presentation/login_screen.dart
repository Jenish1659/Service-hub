import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/app_router.dart';
import 'auth_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController(text: 'admin@servicehub.com');
  final TextEditingController _passwordController = TextEditingController(text: 'admin123');

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter admin credentials.')),
      );
      return;
    }

    // Local Demo / Prototype Bypass
    if (email == 'admin@servicehub.com' && password == 'admin123') {
      adminBypassLoggedIn = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Executive Administrator Authenticated!'),
          backgroundColor: Color(0xff10b981),
        ),
      );
      context.go('/');
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).login(email, password);
    if (!mounted) return;
    if (success) {
      adminBypassLoggedIn = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin authenticated successfully!'),
          backgroundColor: Color(0xff10b981),
        ),
      );
      context.go('/');
    } else {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? 'Authentication failed. Check credentials.')),
      );
    }
  }

  void _showAdminTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: const Color(0xff1e293b),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.shield_rounded, color: Color(0xff38bdf8)),
              SizedBox(width: 10),
              Text('Admin Security & Policy Standard', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              '1. Executive Authority: ServiceHub Admin Console provides master control over 5 km hyperlocal geofences, commission rates, and partner KYC verification.\n\n'
              '2. Audit Logging: All transaction settlements, provider approvals, and system override events are recorded in immutable logs.\n\n'
              '3. Confidentiality: Customer and provider data must strictly be handled in compliance with India DPDP data guidelines.\n\n'
              '4. System Availability: Desktop admin dashboard is designed for high concurrency and 99.9% operational uptime.',
              style: TextStyle(fontSize: 13, height: 1.5, color: Color(0xff94a3b8)),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understand & Proceed', style: TextStyle(color: Colors.white)),
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
            colors: [Color(0xff090d16), Color(0xff0f172a), Color(0xff1e1b4b)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Container(
                width: 460,
                padding: const EdgeInsets.all(36.0),
                decoration: BoxDecoration(
                  color: const Color(0xff0f172a).withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xff334155).withValues(alpha: 0.8), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xff2563eb).withValues(alpha: 0.15),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Brand Badge Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xff1e293b),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xff38bdf8).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.workspace_premium_rounded, size: 14, color: Color(0xff38bdf8)),
                            SizedBox(width: 6),
                            Text(
                              'SERVICEHUB EXECUTIVE DESKTOP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff38bdf8),
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    const Center(
                      child: Text(
                        'Master Admin Portal',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'Hyperlocal Dispatch, Settlements & Security Console',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Color(0xff94a3b8)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Quick Credentials Display Chip
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xff1e293b),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xff334155)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.key_rounded, color: Color(0xfff59e0b), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Demo Admin Access Credentials:', style: TextStyle(fontSize: 10, color: Color(0xff94a3b8), fontWeight: FontWeight.bold)),
                                SizedBox(height: 2),
                                Text('Email: admin@servicehub.com  |  Pass: admin123', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email Field
                    const Text('ADMIN EMAIL', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff94a3b8), letterSpacing: 1)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      enabled: !isLoading,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'admin@servicehub.com',
                        hintStyle: const TextStyle(color: Color(0xff64748b)),
                        prefixIcon: const Icon(Icons.email_outlined, color: Color(0xff38bdf8)),
                        filled: true,
                        fillColor: const Color(0xff1e293b),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xff334155)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xff38bdf8), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Password Field
                    const Text('PASSWORD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff94a3b8), letterSpacing: 1)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      enabled: !isLoading,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: '••••••••',
                        hintStyle: const TextStyle(color: Color(0xff64748b)),
                        prefixIcon: const Icon(Icons.lock_outline, color: Color(0xff38bdf8)),
                        filled: true,
                        fillColor: const Color(0xff1e293b),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xff334155)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xff38bdf8), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Login Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2563eb),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 4,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('Launch Admin Console', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_rounded, size: 18),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Terms Link Footer
                    Center(
                      child: InkWell(
                        onTap: () => _showAdminTermsDialog(context),
                        child: const Text.rich(
                          TextSpan(
                            text: 'Protected System · ',
                            style: TextStyle(fontSize: 11, color: Color(0xff64748b)),
                            children: [
                              TextSpan(
                                text: 'Admin Security Policy & Terms',
                                style: TextStyle(
                                  color: Color(0xff38bdf8),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
