import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final String fullName = user?.userMetadata?['name'] as String? ?? user?.email?.split('@').first ?? 'Guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. USER PROFILE CARD
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
                        child: Center(
                          child: Text(
                            fullName.substring(0, fullName.length >= 2 ? 2 : fullName.length).toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user?.phone ?? '+91 98765 43210',
                              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 2. SETTINGS LIST
              const Text(
                'Settings & Preferences',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 12),
              _buildSettingsTile(Icons.history, 'Booking History', () => context.go('/orders')),
              _buildSettingsTile(Icons.shopping_bag_outlined, 'My Orders', () => context.go('/orders')),
              _buildSettingsTile(Icons.location_on_outlined, 'Saved Addresses', () => _showSavedAddressesSheet(context, ref)),
              _buildSettingsTile(Icons.payment, 'Payment Methods', () => _showPaymentMethodsSheet(context)),
              _buildSettingsTile(Icons.account_balance_wallet_outlined, 'My Wallet (Coins)', () => _showWalletSheet(context)),
              _buildSettingsTile(Icons.help_outline, 'Help & Support', () => context.push('/support')),
              const Divider(height: 32),

              // 3. LOGOUT / SIGN OUT BUTTON
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: AppTheme.dangerColor),
                  label: const Text(
                    'Sign Out',
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
                        const SnackBar(content: Text('Successfully Signed Out')),
                      );
                      context.go('/login');
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.textSecondaryColor),
        onTap: onTap,
      ),
    );
  }

  void _showSavedAddressesSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final box = Hive.box('customer_cache');
        final List<dynamic> rawList = box.get('saved_addresses_list', defaultValue: [
          'Digvijay Plot, Jamnagar',
          'Park Colony, Jamnagar'
        ]) as List<dynamic>;
        final List<String> savedList = List<String>.from(rawList);
        final newAddressController = TextEditingController();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saved Addresses',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimaryColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (savedList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No saved addresses yet.', style: TextStyle(color: AppTheme.textSecondaryColor)),
                    )
                  else
                    ...savedList.map((addr) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.location_on, color: AppTheme.primaryColor),
                      title: Text(addr),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.dangerColor),
                        onPressed: () {
                          setModalState(() {
                            savedList.remove(addr);
                            box.put('saved_addresses_list', savedList);
                          });
                        },
                      ),
                    )),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newAddressController,
                    decoration: InputDecoration(
                      hintText: 'Add new address (e.g. Patel Colony, Jamnagar)...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                        onPressed: () {
                          final newAddr = newAddressController.text.trim();
                          if (newAddr.isNotEmpty) {
                            setModalState(() {
                              savedList.add(newAddr);
                              box.put('saved_addresses_list', savedList);
                            });
                            newAddressController.clear();
                          }
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showPaymentMethodsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final box = Hive.box('customer_cache');
        final List<dynamic> rawPayments = box.get('saved_payment_methods', defaultValue: [
          'Google Pay: ****@oksbi',
          'Visa Card: **** **** **** 4321'
        ]) as List<dynamic>;
        final List<String> savedPayments = List<String>.from(rawPayments);
        final newPaymentController = TextEditingController();

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saved Payment Methods',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimaryColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (savedPayments.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Text('No saved payment methods yet.', style: TextStyle(color: AppTheme.textSecondaryColor)),
                    )
                  else
                    ...savedPayments.map((pm) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.payment, color: AppTheme.primaryColor),
                      title: Text(pm),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppTheme.dangerColor),
                        onPressed: () {
                          setModalState(() {
                            savedPayments.remove(pm);
                            box.put('saved_payment_methods', savedPayments);
                          });
                        },
                      ),
                    )),
                   const SizedBox(height: 12),
                  TextField(
                    controller: newPaymentController,
                    decoration: InputDecoration(
                      hintText: 'Add UPI ID or Card (e.g. UPI: user@okaxis)...',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add, color: AppTheme.primaryColor),
                        onPressed: () {
                          final newPm = newPaymentController.text.trim();
                          if (newPm.isNotEmpty) {
                            setModalState(() {
                              savedPayments.add(newPm);
                              box.put('saved_payment_methods', savedPayments);
                            });
                            newPaymentController.clear();
                          }
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showWalletSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final box = Hive.box('customer_cache');
        
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            final int coins = box.get('wallet_coins', defaultValue: 500) as int;
            final double balance = box.get('wallet_balance_inr', defaultValue: 50.0) as double;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'My Wallet & Coins',
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
                            color: const Color(0xfffffbeb),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xfffef3c7)),
                          ),
                          child: Column(
                            children: [
                              const Icon(Icons.monetization_on, color: Color(0xffd97706), size: 32),
                              const SizedBox(height: 8),
                              const Text('My Coins', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Color(0xffb45309))),
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
                          child: Column(
                            children: [
                              const Icon(Icons.account_balance_wallet, color: AppTheme.primaryColor, size: 32),
                              const SizedBox(height: 8),
                              const Text('INR Balance', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text('₹${balance.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.primaryColor)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  const Text(
                    'Convert Coins to INR',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Conversion Rate: 10 Coins = ₹1 INR',
                    style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffd97706),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: coins < 10
                          ? null
                          : () {
                              final int coinsToConvert = (coins ~/ 10) * 10;
                              final double earnedINR = coinsToConvert / 10.0;
                              
                              box.put('wallet_coins', coins - coinsToConvert);
                              box.put('wallet_balance_inr', balance + earnedINR);
                              
                              setModalState(() {});

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Successfully converted $coinsToConvert coins to ₹${earnedINR.toStringAsFixed(0)}!'),
                                  backgroundColor: AppTheme.successColor,
                                ),
                              );
                            },
                      child: const Text(
                        'Convert All Eligible Coins',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
