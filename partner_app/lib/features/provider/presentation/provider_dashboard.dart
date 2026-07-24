import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'provider_provider.dart';

class ProviderDashboard extends ConsumerStatefulWidget {
  const ProviderDashboard({super.key});

  @override
  ConsumerState<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends ConsumerState<ProviderDashboard> {
  bool isOnline = true;
  final TextEditingController _otpController = TextEditingController();

  void _showOtpDialog(String bookingId) {
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
              onPressed: () => _verifyCompletionOtp(bookingId),
              child: const Text('Verify & Payout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyCompletionOtp(String bookingId) async {
    if (_otpController.text == '5892') {
      Navigator.pop(context);
      try {
        await Supabase.instance.client
            .from('bookings')
            .update({'status': 'Completed'})
            .eq('id', bookingId);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service Completed! Payout added to wallet.'), backgroundColor: AppTheme.successColor),
        );
        _otpController.clear();
        _refreshAll();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP code. Please retry.'), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  Future<void> _acceptBooking(String bookingId) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'En Route'})
          .eq('id', bookingId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request accepted! Driving to customer.'), backgroundColor: AppTheme.successColor),
      );
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  Future<void> _declineBooking(String bookingId) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'Declined'})
          .eq('id', bookingId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request declined.'), backgroundColor: AppTheme.warningColor),
      );
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  void _refreshAll() {
    ref.invalidate(providerPendingBookingsProvider);
    ref.invalidate(providerActiveTasksProvider);
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(providerPendingBookingsProvider);
    final activeTasksAsync = ref.watch(providerActiveTasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Provider Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshAll,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
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
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
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
                          activeThumbColor: AppTheme.successColor,
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

                // 2. QUICK STATS ROW
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
                  children: [
                    const Text(
                      'Incoming Booking Requests',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                    ),
                    pendingAsync.when(
                      loading: () => const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                      error: (_, __) => const SizedBox(),
                      data: (list) => Text(
                        'Active (${list.length})',
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                pendingAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error loading requests: ${e.toString()}')),
                  data: (requests) {
                    if (requests.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No incoming service requests right now.',
                              style: TextStyle(color: AppTheme.textSecondaryColor),
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: requests.map((req) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: _buildBookingRequestCard(
                            id: req['id'],
                            customer: 'Customer ID: ${req['customer_id'].toString().substring(0, 5)}',
                            address: 'Within 5 km hyperlocal radius',
                            time: '${req['scheduled_date']} · ${req['scheduled_time']}',
                            service: req['service_name'] ?? 'Home Service',
                            price: '₹${(req['price'] as num?)?.toStringAsFixed(0) ?? '0'}',
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // 4. ACTIVE TASK
                const Text(
                  'Ongoing Service Tasks',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                ),
                const SizedBox(height: 12),
                
                activeTasksAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error loading tasks: ${e.toString()}')),
                  data: (tasks) {
                    if (tasks.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No ongoing service jobs.',
                              style: TextStyle(color: AppTheme.textSecondaryColor),
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: tasks.map((task) {
                        final id = task['id'];
                        final service = task['service_name'] ?? '';
                        final status = task['status'] ?? 'En Route';
                        final isStarted = status == 'Started';

                        return Card(
                          color: const Color(0xffeff6ff),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: const BorderSide(color: Color(0xffbfdbfe)),
                          ),
                          margin: const EdgeInsets.only(bottom: 12),
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
                                      decoration: BoxDecoration(
                                        color: isStarted ? AppTheme.successColor : AppTheme.primaryColor,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Text(
                                      isStarted ? 'Work Commenced' : 'Driving to customer',
                                      style: TextStyle(
                                        color: isStarted ? AppTheme.successColor : AppTheme.primaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text('Task: $service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const Text('Location: Hyperlocal 5km radius zone', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        icon: const Icon(Icons.navigation),
                                        label: const Text('Navigate'),
                                        onPressed: () {
                                          context.push(
                                            '/navigation',
                                            extra: {
                                              'taskId': id,
                                              'customerName': 'Jenish Bheda',
                                              'address': 'Digvijay Plot, Jamnagar',
                                              'serviceName': service,
                                              'price': '₹${(task['price'] as num?)?.toStringAsFixed(0) ?? '1,100'}',
                                              'type': 'service',
                                            },
                                          );
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        icon: const Icon(Icons.check),
                                        label: Text(isStarted ? 'Complete' : 'Verify PIN'),
                                        onPressed: () => _showOtpDialog(id),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
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
    required String id,
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
                  onPressed: () => _declineBooking(id),
                  child: const Text('Decline'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => _acceptBooking(id),
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
