import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  bool isOnline = true;
  final TextEditingController _otpController = TextEditingController();

  void _showOtpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Complete Service'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the completion OTP code provided by the customer to finalize payment.'),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Enter 4-Digit OTP',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_otpController.text == '5892') {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Service Completed! Payout added to wallet.')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid OTP code. Please retry.')),
                  );
                }
              },
              child: const Text('Verify & Payout'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
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
              // 1. BUSINESS PROFILE HEADER & STATUS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(color: Color(0xffeff6ff), shape: BoxShape.circle),
                        child: const Icon(Icons.build, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Rajesh Electricals',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                          ),
                          Text(
                            'Electrician & AC Expert',
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                  // Switch Toggle
                  Row(
                    children: [
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isOnline ? AppTheme.successColor : AppTheme.textSecondaryColor,
                        ),
                      ),
                      Switch(
                        value: isOnline,
                        activeColor: AppTheme.successColor,
                        onChanged: (val) {
                          setState(() {
                            isOnline = val;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. QUICK STATS ROW (RUPEES CURRENCY)
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard('Today\'s Jobs', '4', Icons.calendar_today, Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Earnings (₹)', '₹3,450', Icons.currency_rupee, Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard('Rating', '4.8 ★', Icons.star, Colors.orange),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 3. INCOMING BOOKING REQUESTS
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Incoming Booking Requests',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  Text(
                    'Active (2)',
                    style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildBookingRequestCard(
                customer: 'Bheda Jenish',
                address: 'HSR Layout Sector 3, Bangalore',
                time: 'Today, 06:30 PM',
                service: 'AC Gas Refill & Filter Cleaning',
                price: '₹1,200',
              ),
              const SizedBox(height: 12),
              _buildBookingRequestCard(
                customer: 'Preet Shah',
                address: 'Bellandur Green Glen Layout, Bangalore',
                time: 'Tomorrow, 10:00 AM',
                service: 'Kitchen Chimney Uninstallation',
                price: '₹600',
              ),
              const SizedBox(height: 28),

              // 4. ACTIVE TASK WITH COMPLETION DRAWER TRIGGER
              const Text(
                'Ongoing Service Tasks',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 12),
              Card(
                color: const Color(0xffeff6ff),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xffbfdbfe)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(6)),
                            child: const Text('EN ROUTE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const Text(
                            'Est: 15 mins away',
                            style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text('Customer: Kunjal Vyas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const Text('Service: Fan Replacement & Socket Installation', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                      const Text('Location: Indiranagar 12th Cross, Bangalore', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.navigation),
                              label: const Text('Navigate'),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.check),
                              label: const Text('Complete'),
                              onPressed: _showOtpDialog,
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

  Widget _buildBookingRequestCard({
    required String customer,
    required String address,
    required String time,
    required String service,
    required String price,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(customer, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(price, style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 15)),
              ],
            ),
            const SizedBox(height: 6),
            Text(service, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.access_time, size: 14, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 6),
                Text(time, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.pin_drop, size: 14, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () {},
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {},
                  child: const Text('Accept Request'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
