import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../auth/presentation/auth_controller.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  // Menu navigation state
  String _activeTab = 'Platform Console';

  // Global Settings state
  double serviceCommission = 10.0;
  double productCommission = 8.0;
  double deliveryBaseFee = 30.0;
  double geofenceRadius = 5.0; // 5 km strict radius limit
  bool enforceStrictGeofence = true;

  // Platform counts state
  int activePartnersCount = 342;
  int activeAgentsCount = 87;

  // KYC queue state
  final List<Map<String, String>> _verificationQueue = [
    {'name': 'Metro Plumbers Ltd', 'role': 'Service Provider', 'doc': 'Business License · Pan Card', 'status': 'Pending Verification'},
    {'name': 'Royal Hardware Store', 'role': 'Shopkeeper', 'doc': 'GST certificate · Shop License', 'status': 'Pending Verification'},
    {'name': 'Amit Patel (Delivery)', 'role': 'Delivery Agent', 'doc': 'Driving License · Aadhaar Card', 'status': 'Pending Verification'},
  ];

  // Settlements state
  final List<Map<String, dynamic>> _settlements = [
    {'partner': 'Rajesh Electricals', 'amount': 1200, 'commission': 120, 'status': 'Settled', 'date': 'Today, 06:42 PM'},
    {'partner': 'Anita\'s Kitchen', 'amount': 449, 'commission': 36, 'status': 'Pending Settlement', 'date': 'Today, 05:10 PM'},
    {'partner': 'Metro Plumbers Ltd', 'amount': 600, 'commission': 60, 'status': 'Settled', 'date': 'Yesterday'},
  ];

  void _approvePartner(int index, String name, String role) {
    setState(() {
      _verificationQueue.removeAt(index);
      if (role.contains('Delivery')) {
        activeAgentsCount++;
      } else {
        activePartnersCount++;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partner "$name" approved! Profile activated in $role Console.'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _rejectPartner(int index, String name) {
    setState(() {
      _verificationQueue.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partner "$name" application rejected & notified.'),
        backgroundColor: AppTheme.dangerColor,
      ),
    );
  }

  void _settlePayout(int index, String partner) {
    setState(() {
      _settlements[index]['status'] = 'Settled';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payout for "$partner" successfully processed via instant bank settlement!'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin System Portal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged out of Admin Portal.')),
                );
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SIDE MENU
          Container(
            width: 260,
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: AppTheme.borderCol)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildMenuTile(Icons.dashboard, 'Platform Console'),
                _buildMenuTile(Icons.verified_user, 'KYC Approvals'),
                _buildMenuTile(Icons.monetization_on, 'Settlements'),
                _buildMenuTile(Icons.settings, 'Global Settings'),
              ],
            ),
          ),

          // 2. MAIN PLATFORM CONTENT (Switch tab based on active navigation)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: _buildActiveTabContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 'Platform Console':
        return _buildPlatformConsole();
      case 'KYC Approvals':
        return _buildKYCApprovals();
      case 'Settlements':
        return _buildSettlements();
      case 'Global Settings':
        return _buildGlobalSettings();
      default:
        return _buildPlatformConsole();
    }
  }

  // TAB 1: Platform Console
  Widget _buildPlatformConsole() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Analytics Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildConsoleCard('Platform Revenue', '₹1,24,500', Icons.account_balance_wallet, Colors.green),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildConsoleCard('Active Customers', '1,452', Icons.people, Colors.blue),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildConsoleCard('Active Partners', '$activePartnersCount', Icons.handshake, Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildConsoleCard('Active Agents', '$activeAgentsCount', Icons.directions_bike, Colors.purple),
            ),
          ],
        ),
        const SizedBox(height: 32),
        const Text(
          'Platform Overview',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hyperlocal Operations Metrics',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 16),
                _buildMetricRow('Strict Geofencing Radius', '${geofenceRadius.toStringAsFixed(1)} km limit'),
                const Divider(),
                _buildMetricRow('Service Provider Commission Rate', '${serviceCommission.toStringAsFixed(0)}%'),
                const Divider(),
                _buildMetricRow('Delivery Partner Base Fee', '₹${deliveryBaseFee.toStringAsFixed(0)}'),
                const Divider(),
                _buildMetricRow('Pending KYC Verification Items', '${_verificationQueue.length} applicants waiting'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // TAB 2: KYC Approvals
  Widget _buildKYCApprovals() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KYC Verification & Approvals',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
        ),
        const SizedBox(height: 8),
        const Text(
          'Verify and activate incoming service provider, merchant and delivery agent accounts.',
          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
        ),
        const SizedBox(height: 24),
        _verificationQueue.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _verificationQueue.length,
                itemBuilder: (context, index) {
                  final item = _verificationQueue[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Role: ${item['role']} · Status: ${item['status']}', 
                              style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text('Uploaded Docs: ${item['doc']}', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.dangerColor,
                              side: const BorderSide(color: AppTheme.dangerColor),
                            ),
                            onPressed: () => _rejectPartner(index, item['name']!),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _approvePartner(index, item['name']!, item['role']!),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              )
            : const Card(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.verified, size: 48, color: AppTheme.successColor),
                        SizedBox(height: 12),
                        Text(
                          'KYC Queue is Empty',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'All onboarding partners are verified and active.',
                          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  // TAB 3: Settlements
  Widget _buildSettlements() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Partner Settlements Ledger',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage completed service/order payouts and view platform commissions.',
          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _settlements.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = _settlements[index];
                final isPending = item['status'] == 'Pending Settlement';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['partner'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Transaction Date: ${item['date']}', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                        ],
                      ),
                      Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Total Amount: ₹${item['amount']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Commission (₹${item['commission']})', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12)),
                            ],
                          ),
                          const SizedBox(width: 24),
                          isPending
                              ? ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warningColor),
                                  onPressed: () => _settlePayout(index, item['partner']),
                                  child: const Text('Settle Now'),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xfff0fdf4),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Settled ✓',
                                    style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  // TAB 4: Global Settings
  Widget _buildGlobalSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Global Platform Configurations',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
        ),
        const SizedBox(height: 8),
        const Text(
          'Fine-tune hyperlocal operations, commissions, and system-wide limits.',
          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Geofence Radius
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Enforce Strict Geofencing (5 km Zone)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Switch(
                      value: enforceStrictGeofence,
                      onChanged: (val) {
                        setState(() {
                          enforceStrictGeofence = val;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Geofencing Radius Threshold: ${geofenceRadius.toStringAsFixed(1)} km',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondaryColor),
                ),
                Slider(
                  min: 1.0,
                  max: 15.0,
                  value: geofenceRadius,
                  onChanged: enforceStrictGeofence
                      ? (val) {
                          setState(() {
                            geofenceRadius = val;
                          });
                        }
                      : null,
                ),
                const Divider(height: 32),

                // Service Commission
                Text(
                  'Service Provider Commission Rate: ${serviceCommission.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Text('Determines platform commission fee cut from service bookings.', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                Slider(
                  min: 5,
                  max: 30,
                  value: serviceCommission,
                  onChanged: (val) {
                    setState(() {
                      serviceCommission = val;
                    });
                  },
                ),
                const Divider(height: 32),

                // Product Commission
                Text(
                  'Product Merchant Commission Rate: ${productCommission.toStringAsFixed(0)}%',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Text('Determines commission fee cut from hyperlocal product e-commerce sales.', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                Slider(
                  min: 2,
                  max: 20,
                  value: productCommission,
                  onChanged: (val) {
                    setState(() {
                      productCommission = val;
                    });
                  },
                ),
                const Divider(height: 32),

                // Base Delivery Fee
                Text(
                  'Base Delivery Agent Fee: ₹${deliveryBaseFee.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const Text('Fixed base rate paid to delivery agents per order completion.', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                Slider(
                  min: 15,
                  max: 100,
                  value: deliveryBaseFee,
                  onChanged: (val) {
                    setState(() {
                      deliveryBaseFee = val;
                    });
                  },
                ),
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Global platform settings successfully saved!'),
                          backgroundColor: AppTheme.successColor,
                        ),
                      );
                    },
                    child: const Text('Save Configurations'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuTile(IconData icon, String title) {
    final isSelected = title == _activeTab;
    return ListTile(
      leading: Icon(icon, color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
        ),
      ),
      selected: isSelected,
      selectedTileColor: const Color(0xffeff6ff),
      onTap: () {
        setState(() {
          _activeTab = title;
        });
      },
    );
  }

  Widget _buildConsoleCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 4),
                Text(title, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor)),
        ],
      ),
    );
  }
}
