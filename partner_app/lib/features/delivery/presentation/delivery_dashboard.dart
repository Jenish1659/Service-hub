import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'delivery_provider.dart';

class DeliveryDashboard extends ConsumerStatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  ConsumerState<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends ConsumerState<DeliveryDashboard> {
  double currentDistance = 125.0; // Distance in meters from shop/customer
  bool pinLocked = true;
  final TextEditingController _pinController = TextEditingController();
  int completedTripsCount = 8; // Mock base + dynamic completions

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

  void _refreshAll() {
    ref.invalidate(deliveryPendingJobsProvider);
    ref.invalidate(deliveryAssignedJobProvider);
  }

  Future<void> _acceptJob(String orderId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('orders')
          .update({
            'agent_id': user.id,
            'status': 'Out for Delivery',
          })
          .eq('id', orderId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery Job Accepted! En route to pickup.'), backgroundColor: AppTheme.successColor),
      );
      _refreshAll();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting job: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  Future<void> _verifyPin(String orderId, String correctPin) async {
    final enteredPin = _pinController.text.trim();
    if (enteredPin == correctPin) {
      try {
        await Supabase.instance.client
            .from('orders')
            .update({'status': 'Delivered'})
            .eq('id', orderId);

        setState(() {
          completedTripsCount++;
          currentDistance = 125.0;
          pinLocked = true;
          _pinController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification Successful! Order Marked as Delivered.'), backgroundColor: AppTheme.successColor),
        );
        _refreshAll();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing delivery: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Verification PIN code.'), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pendingJobsAsync = ref.watch(deliveryPendingJobsProvider);
    final assignedJobAsync = ref.watch(deliveryAssignedJobProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Dashboard'),
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

                // 2. STATS ROW
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard('Trips Completed', '$completedTripsCount', Icons.check_circle_outline, Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard('Today\'s Payout', '₹${completedTripsCount * 45}', Icons.currency_rupee, Colors.green),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard('Distance Travelled', '${(completedTripsCount * 2.3).toStringAsFixed(1)} km', Icons.map_outlined, Colors.purple),
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

                assignedJobAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: ${e.toString()}')),
                  data: (jobs) {
                    if (jobs.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No assigned jobs. Claim one from available jobs below.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                            ),
                          ),
                        ),
                      );
                    }

                    final job = jobs.first;
                    final jobId = job['id'];
                    final items = job['items_summary'] ?? 'Package';
                    final customerPin = job['delivery_pin'] ?? '2842';
                    final address = job['shipping_address'] ?? 'HSR Layout, Bengaluru';

                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Job #${jobId.toString().substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const Text('Payout: ₹45.00', style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.w800, fontSize: 15)),
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
                                    children: [
                                      const Text('Pickup: Store Vendor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text('Items: $items', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
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
                                    children: [
                                      const Text('Drop-off Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      Text(address, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    icon: const Icon(Icons.map_outlined),
                                    label: const Text('Navigate (Show Route Map)'),
                                    onPressed: () {
                                      context.push(
                                        '/navigation',
                                        extra: {
                                          'taskId': jobId,
                                          'customerName': 'Jenish Bheda',
                                          'address': address,
                                          'serviceName': items,
                                          'price': '₹45.00 Payout',
                                          'type': 'delivery',
                                          'deliveryPin': customerPin,
                                        },
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // GPS-Fenced Secure PIN Verification
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: pinLocked ? const Color(0xfffafafa) : const Color(0xfff0fdf4),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: pinLocked ? AppTheme.borderCol : const Color(0xffbbf7d0),
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
                                      'Must be <= 5.0 meters away from coordinates to unlock delivery PIN entry.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 10, color: AppTheme.textSecondaryColor),
                                    ),
                                  ] else ...[
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: _pinController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      decoration: InputDecoration(
                                        hintText: 'Enter Customer Delivery PIN (Code: $customerPin)',
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton(
                                      onPressed: () => _verifyPin(jobId, customerPin),
                                      child: const Text('Verify PIN & Deliver'),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 28),

                // 4. AVAILABLE OPEN DELIVERY JOBS
                const Text(
                  'Available Delivery Jobs',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                ),
                const SizedBox(height: 12),

                pendingJobsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error: ${e.toString()}')),
                  data: (jobs) {
                    if (jobs.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No pending delivery jobs in your area.',
                              style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: jobs.map((job) {
                        final jobId = job['id'];
                        final items = job['items_summary'] ?? 'Items package';
                        final address = job['shipping_address'] ?? 'HSR Layout, Bengaluru';
                        final total = (job['grand_total'] as num?)?.toDouble() ?? 0.0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Order #${jobId.toString().substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text('Value: ₹${total.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Items: $items', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                                Text('Deliver to: $address', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Estimated Payout: ₹45.00', style: TextStyle(color: AppTheme.successColor, fontWeight: FontWeight.bold, fontSize: 13)),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        minimumSize: Size.zero,
                                      ),
                                      onPressed: () => _acceptJob(jobId),
                                      child: const Text('Accept Job'),
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
}
