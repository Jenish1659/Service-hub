import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  double currentDistance = 125.0; // Distance in meters from shop
  bool pinLocked = true;
  final TextEditingController _pinController = TextEditingController();

  void _simulateApproach() {
    setState(() {
      if (currentDistance > 5.0) {
        currentDistance = 3.0; // Agent has approached close (within 5m)
        pinLocked = false;    // PIN inputs are unlocked
      } else {
        currentDistance = 125.0; // Reset
        pinLocked = true;
      }
    });
  }

  void _verifyPin() {
    if (_pinController.text == '8942') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification Successful! Package Pickup Authorized.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Verification PIN code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. DELIVERY AGENT HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(color: Color(0xffeff6ff), shape: BoxShape.circle),
                        child: const Icon(Icons.directions_bike, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Ravi Kumar',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                          ),
                          Text(
                            'Delivery Executive · Active',
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xfffffbeb),
                      foregroundColor: const Color(0xffd97706),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: _simulateApproach,
                    child: Text(
                      currentDistance > 5.0 ? 'Simulate Arrive (<=5m)' : 'Reset Distance',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. STATS ROW (RUPEES)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Trips Completed', '8', Icons.check_circle_outline, Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Today\'s Payout', '₹450', Icons.currency_rupee, Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Distance Travelled', '18.4 km', Icons.map_outlined, Colors.purple),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 3. ACTIVE ASSIGNED DELIVERY TASK
              const Text(
                'Assigned Delivery Job',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Job #JOB-8841', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('Payout: ₹45.00', style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.w800, fontSize: 15)),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.storefront, color: AppTheme.primaryColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Pickup: Anita\'s Laundry Supplies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('HSR Layout Sector 2, Bangalore', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.person_pin_circle, color: AppTheme.dangerColor, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Drop-off: Jenish Bheda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                Text('HSR Layout Sector 3, Bangalore', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // 4. GPS-FENCED PIN DECRYPTION ZONE
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: pinLocked ? const Color(0xfffafafa) : const Color(0xfff0fdf4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: pinLocked ? AppTheme.borderCol : const Color(0xffbbf7d0),
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  pinLocked ? Icons.lock : Icons.lock_open,
                                  color: pinLocked ? AppTheme.textSecondaryColor : AppTheme.successColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  pinLocked ? 'PIN Verification Locked' : 'PIN Verification Unlocked!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: pinLocked ? AppTheme.textPrimaryColor : AppTheme.successColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Current Location Proximity: ${currentDistance.toStringAsFixed(1)} meters',
                              style: TextStyle(
                                fontSize: 12,
                                color: pinLocked ? AppTheme.textSecondaryColor : const Color(0xff15803d),
                              ),
                            ),
                            if (pinLocked) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'Must be <= 5.0 meters away from shop coordinates to unlock pickup PIN entry.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor),
                              ),
                            ] else ...[
                              const SizedBox(height: 16),
                              TextField(
                                controller: _pinController,
                                keyboardType: TextInputType.number,
                                textAlign: TextAlign.center,
                                decoration: const InputDecoration(
                                  hintText: 'Enter 4-Digit Pickup PIN (Code: 8942)',
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: _verifyPin,
                                child: const Text('Verify PIN'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
