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
  final TextEditingController _contactController = TextEditingController(text: 'partner@servicehub.com');
  final TextEditingController _passwordController = TextEditingController(text: 'partner123');
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    final contact = _contactController.text.trim();
    final password = _passwordController.text.trim();

    if (contact.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your contact phone/email and password.')),
      );
      return;
    }

    final rawUsername = contact.contains('@') ? contact.split('@').first : contact;
    final displayName = rawUsername.isNotEmpty
        ? '${rawUsername[0].toUpperCase()}${rawUsername.substring(1)}'
        : 'ServiceHub Partner';
    ref.read(loggedInPartnerNameProvider.notifier).state = displayName;

    // Auto-detect role and redirect directly to partner workspace dashboard
    final role = ref.read(loggedInPartnerRoleProvider);
    String targetRoute = '/provider-dashboard';
    if (role == 'seller') targetRoute = '/seller-dashboard';
    if (role == 'delivery') targetRoute = '/delivery-dashboard';

    // Demo Account Bypass
    if ((contact == 'partner@servicehub.com' || contact == '9876543210') && password == 'partner123') {
      partnerBypassLoggedIn = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Authenticated successfully! Auto-navigating to workspace...'), backgroundColor: AppTheme.successColor),
      );
      context.go(targetRoute);
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).loginWithEmail(contact, password);
    if (success) {
      partnerBypassLoggedIn = true;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Authenticated successfully! Auto-navigating to workspace...'), backgroundColor: AppTheme.successColor),
      );
      context.go(targetRoute);
    } else {
      final error = ref.read(authControllerProvider).error;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error?.toString() ?? 'Authentication failed. Please check your credentials.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  void dispose() {
    _contactController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. Sleek Corporate Brand Header Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff0f172a), Color(0xff1e3a8a)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0x1a0f172a), blurRadius: 20, offset: Offset(0, 8)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                        child: const Icon(Icons.handshake_rounded, color: Colors.white, size: 34),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'ServiceHub Partner',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.3),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Business & Field Workspace Portal',
                        style: TextStyle(fontSize: 13, color: Colors.blue[100]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 2. Authentication Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Color(0x0a000000), blurRadius: 16, offset: Offset(0, 4)),
                    ],
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sign In to Workspace',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Enter your registered contact details and password.',
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                      const SizedBox(height: 20),

                      // Contact Input Field
                      const Text('Contact Phone Number or Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _contactController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor),
                          hintText: 'e.g. 9876543210 or partner@servicehub.com',
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xffcbd5e1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Input Field
                      const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppTheme.primaryColor),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: AppTheme.textSecondaryColor,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          hintText: 'Enter password',
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xffcbd5e1)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sign In Button
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Sign In to Partner Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // 3. Bottom Register Action Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Don\'t have an account?', style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor)),
                          SizedBox(height: 2),
                          Text('Join ServiceHub Ecosystem', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor)),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/onboarding'),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                        label: const Text('Register as Partner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xffeff6ff),
                          foregroundColor: AppTheme.primaryColor,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
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
