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
                      'Financial & Payout Ledger',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor),
                        title: const Text('Partner Earnings & Escrow Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: const Text('View daily payouts, platform commission (10%) & bank settlement', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
                        onTap: () => _showPartnerPayoutSheet(context),
                      ),
                    ),
                    const SizedBox(height: 12),

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

  void _showPartnerPayoutSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Partner Escrow & Earnings',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimaryColor),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xfff0fdf4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xffbbf7d0)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available Balance', style: TextStyle(color: Color(0xff15803d), fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('₹4,890.00', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xff166534))),
                          SizedBox(height: 4),
                          Text('Net 90% Partner Share', style: TextStyle(color: Color(0xff15803d), fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xffeff6ff),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xffdbeafe)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Escrow Holding', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          SizedBox(height: 4),
                          Text('₹1,200.00', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.primaryColor)),
                          SizedBox(height: 4),
                          Text('Disbursed on OTP/PIN', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text('Recent Earnings Ledger', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.check_circle, color: AppTheme.successColor),
                title: Text('AC Deep Service Job', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Completion OTP Validated • Net: ₹1,080 (Fee 10%: ₹120)', style: TextStyle(fontSize: 11)),
                trailing: Text('+₹1,080', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor)),
              ),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.delivery_dining, color: AppTheme.primaryColor),
                title: Text('E-Commerce Delivery Trip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Delivery PIN Validated • Flat Rate', style: TextStyle(fontSize: 11)),
                trailing: Text('+₹45', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.account_balance),
                  label: const Text('Request Instant Bank Settlement'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Bank Settlement Request Submitted! Funds dispatched to UPI/Bank account.'),
                        backgroundColor: AppTheme.successColor,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
