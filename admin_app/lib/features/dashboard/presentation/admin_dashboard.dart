import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  double serviceCommission = 10.0; // 10%
  double productCommission = 8.0;   // 8%
  double deliveryBaseFee = 30.0;    // ₹30

  // Mock partners verification queue
  final List<Map<String, String>> _verificationQueue = [
    {'name': 'Metro Plumbers Ltd', 'role': 'Service Provider', 'doc': 'Business License · Pan Card', 'status': 'Pending Verification'},
    {'name': 'Royal Hardware Store', 'role': 'Shopkeeper', 'doc': 'GST certificate · Shop License', 'status': 'Pending Verification'},
    {'name': 'Amit Patel (Delivery)', 'role': 'Delivery Agent', 'doc': 'Driving License · Aadhaar Card', 'status': 'Pending Verification'},
  ];

  void _approvePartner(int index, String name) {
    setState(() {
      _verificationQueue.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Partner \"$name\" approved and profile activated!')),
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
            onPressed: () {
              context.go('/login');
            },
          ),
        ],
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SIDE MENU (Desktop/Web Feel)
          Container(
            width: 250,
            color: Colors.white,
            border: const Border(right: BorderSide(color: AppTheme.borderCol)),
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildMenuTile(Icons.dashboard, 'Platform Console', true),
                _buildMenuTile(Icons.verified_user, ' KYC Approvals', false),
                _buildMenuTile(Icons.monetization_on, 'Settlements', false),
                _buildMenuTile(Icons.settings, 'Global Settings', false),
              ],
            ),
          ),

          // 2. MAIN PLATFORM CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'System Analytics Dashboard',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 20),

                  // 3. STATS CONSOLE (RUPEES)
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
                        child: _buildConsoleCard('Active Partners', '342', Icons.handshake, Colors.orange),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildConsoleCard('Active Agents', '87', Icons.directions_bike, Colors.purple),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 4. KYC VERIFICATION QUEUE (Left Column)
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pending Partner Verification Queue',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                            ),
                            const SizedBox(height: 12),
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
                                              Text('Role: ${item['role']} · Status: ${item['status']}', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
                                              Text('Uploaded: ${item['doc']}', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
                                            ],
                                          ),
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.cancel_outlined, color: AppTheme.dangerColor),
                                                onPressed: () {},
                                              ),
                                              ElevatedButton(
                                                onPressed: () => _approvePartner(index, item['name']!),
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
                                      padding: EdgeInsets.all(24.0),
                                      child: Center(child: Text('Verification queue is empty. All partners are verified.', style: TextStyle(color: AppTheme.textSecondaryColor))),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      // 5. GLOBAL CONFIGURATIONS PANEL (Right Column)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Platform Settings',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                            ),
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Service Commission: ${serviceCommission.toStringAsFixed(0)}%',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
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
                                    Text(
                                      'Product Commission: ${productCommission.toStringAsFixed(0)}%',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
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
                                    const Divider(height: 24),
                                    Text(
                                      'Base Delivery Fee: ₹${deliveryBaseFee.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
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
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title, bool isSelected) {
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
      onTap: () {},
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
}
