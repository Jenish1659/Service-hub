import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  bool _isOnline = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.primaryNavy,
        title: const Text(
          'ServiceHub Delivery Agent',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          Row(
            children: [
              Text(
                _isOnline ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _isOnline ? AppColors.secondaryGold : Colors.white60,
                ),
              ),
              Switch(
                value: _isOnline,
                activeTrackColor: AppColors.secondaryGold,
                onChanged: (val) {
                  setState(() {
                    _isOnline = val;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isOnline ? const Color(0xFF86EFAC) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isOnline ? Icons.radar : Icons.power_settings_new,
                    color: _isOnline ? const Color(0xFF15803D) : const Color(0xFF64748B),
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _isOnline ? 'Ready for Nearby Deliveries' : 'You are currently Offline',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _isOnline ? const Color(0xFF14532D) : const Color(0xFF334155),
                          ),
                        ),
                        Text(
                          _isOnline
                              ? 'Searching for active orders within 10 km radius...'
                              : 'Toggle Online switch above to start receiving delivery requests',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Today Earnings Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: "Today's Earnings",
                    value: '₹1,240',
                    icon: Icons.account_balance_wallet,
                    color: AppColors.primaryNavy,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Deliveries Done',
                    value: '8 Orders',
                    icon: Icons.check_circle,
                    color: const Color(0xFF15803D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            const Text(
              'Active Delivery Requests',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),

            // Demo Delivery Request Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'EXPRESS DELIVERY',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Earn ₹95.00',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF15803D)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Row(
                      children: [
                        Icon(Icons.storefront, color: AppColors.primaryNavy, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Pickup: ServiceHub Store (Jamnagar Main)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Row(
                      children: [
                        Icon(Icons.location_on, color: AppThemeColors.errorRed, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Drop: Park Hill Road, Jamnagar (3.2 km)',
                          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {},
                            child: const Text('Decline'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryNavy),
                            onPressed: () {},
                            child: const Text('ACCEPT TASK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
      ),
    );
  }

  Widget _buildMetricCard({required String title, required String value, required IconData icon, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}

class AppThemeColors {
  static const Color errorRed = Color(0xFFEF4444);
}
