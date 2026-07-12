import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../../auth/presentation/auth_controller.dart';
import 'profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(partnerProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Profile'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(partnerProfileProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: ${e.toString()}')),
              data: (profile) {
                final String partnerName = profile?['name'] ?? 'Partner Candidate';
                final String partnerId = profile?['id'] ?? 'Pending...';
                final bool isVerified = profile?['is_verified'] ?? false;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. BUSINESS PROFILE OVERVIEW CARD
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                color: AppTheme.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.business, color: Colors.white, size: 30),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    partnerName,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'ID: ${partnerId.substring(0, 8).toUpperCase()}',
                                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isVerified ? const Color(0xfff0fdf4) : const Color(0xfffffbeb),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: isVerified ? const Color(0xffbbf7d0) : Colors.amber.shade200),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isVerified ? Icons.verified : Icons.warning_amber,
                                          color: isVerified ? AppTheme.successColor : Colors.amber.shade800,
                                          size: 14,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          isVerified ? 'KYC Verified & Active' : 'KYC Verification Pending',
                                          style: TextStyle(
                                            color: isVerified ? const Color(0xff15803d) : Colors.amber.shade900,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. SWITCH WORKSPACE OPTIONS (Role Selection)
                    const Text(
                      'Switch Workspace Role',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor),
                    ),
                    const SizedBox(height: 12),
                    _buildRoleSwitchTile(context, Icons.plumbing, 'Service Provider Console', '/provider-dashboard', isVerified),
                    _buildRoleSwitchTile(context, Icons.storefront, 'Shopkeeper Console', '/seller-dashboard', isVerified),
                    _buildRoleSwitchTile(context, Icons.directions_bike, 'Delivery Agent Console', '/delivery-dashboard', isVerified),

                    const Divider(height: 32),

                    // 3. SIGN OUT
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.logout, color: AppTheme.dangerColor),
                        label: const Text(
                          'Sign Out Partner Account',
                          style: TextStyle(color: AppTheme.dangerColor, fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.dangerColor),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () async {
                          partnerBypassLoggedIn = false;
                          await ref.read(authControllerProvider.notifier).logout();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Logged out of Partner account.')),
                            );
                            context.go('/login');
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleSwitchTile(BuildContext context, IconData icon, String title, String route, bool isVerified) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: isVerified ? AppTheme.primaryColor : Colors.grey),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isVerified ? AppTheme.textPrimaryColor : Colors.grey,
          ),
        ),
        trailing: const Icon(Icons.swap_horiz, color: AppTheme.textSecondaryColor),
        onTap: () {
          if (isVerified) {
            context.go(route);
          } else {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('KYC Approval Required'),
                content: const Text(
                  'Your profile is currently awaiting administrator review. Access to dashboard tools is locked until your KYC is verified.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
