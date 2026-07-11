import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Partner Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                      children: const [
                        Text(
                          'Partner Center',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Registered Partner ID: PTN-77312',
                          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
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
          _buildRoleSwitchTile(context, Icons.plumbing, 'Service Provider Console', '/provider-dashboard'),
          _buildRoleSwitchTile(context, Icons.storefront, 'Shopkeeper Console', '/seller-dashboard'),
          _buildRoleSwitchTile(context, Icons.directions_bike, 'Delivery Agent Console', '/delivery-dashboard'),
          
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
      ),
    );
  }

  Widget _buildRoleSwitchTile(BuildContext context, IconData icon, String title, String route) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        trailing: const Icon(Icons.swap_horiz, color: AppTheme.textSecondaryColor),
        onTap: () {
          context.go(route);
        },
      ),
    );
  }
}
