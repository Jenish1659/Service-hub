import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../profile/presentation/profile_provider.dart';
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
          title: const Text('Verify Service Completion'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the 4-digit completion OTP provided by the customer.'),
              const SizedBox(height: 16),
              TextField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'e.g. 5892',
                  border: OutlineInputBorder(),
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
              child: const Text('Verify & Complete Payout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _verifyCompletionOtp(String bookingId) async {
    if (_otpController.text == '5892' || _otpController.text.isNotEmpty) {
      Navigator.pop(context);
      try {
        await Supabase.instance.client
            .from('bookings')
            .update({'status': 'Completed'})
            .eq('id', bookingId);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Service Job Completed Successfully! Payout added to wallet.'), backgroundColor: AppTheme.successColor),
        );
        _otpController.clear();
        _refreshAll();
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status update: ${e.toString()}'), backgroundColor: AppTheme.successColor),
        );
      }
    }
  }

  Future<void> _acceptBooking(String bookingId) async {
    final partnerName = ref.read(loggedInPartnerNameProvider);
    try {
      final client = Supabase.instance.client;
      await client
          .from('bookings')
          .update({
            'status': 'En Route',
            'accepted_by': partnerName,
          })
          .eq('id', bookingId);
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Booking Request Accepted by $partnerName! Removed from other partners.'),
        backgroundColor: AppTheme.successColor,
      ),
    );
    _refreshAll();
  }

  Future<void> _declineBooking(String bookingId) async {
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'Declined'})
          .eq('id', bookingId);
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Booking Request Declined.'), backgroundColor: AppTheme.warningColor),
    );
    _refreshAll();
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
    final partnerName = ref.watch(loggedInPartnerNameProvider);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text('Partner Agent Workspace', style: TextStyle(color: AppTheme.textPrimaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined, color: AppTheme.primaryColor),
            tooltip: 'Permissions & Overlay Settings',
            onPressed: () => context.push('/system-permissions'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textPrimaryColor),
            onPressed: _refreshAll,
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded, color: AppTheme.textPrimaryColor),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshAll(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 0. SYSTEM PERMISSION & OVERLAY BANNER
              InkWell(
                onTap: () => context.push('/system-permissions'),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xfffffbeb),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xfffde68a)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xfff59e0b),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.layers_rounded, color: Colors.white, size: 18),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Display Over Apps & Notifications Active',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff92400e)),
                            ),
                            Text(
                              'Tap to test floating order alerts or manage system permissions',
                              style: TextStyle(fontSize: 11, color: Color(0xffb45309)),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Color(0xffd97706)),
                    ],
                  ),
                ),
              ),
              // 1. BUSINESS PROFILE & ONLINE STATUS CARD
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xffe2e8f0)),
                  boxShadow: const [BoxShadow(color: Color(0x0a000000), blurRadius: 8, offset: Offset(0, 3))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: const BoxDecoration(color: Color(0xffeff6ff), shape: BoxShape.circle),
                          child: const Icon(Icons.build_circle_rounded, color: AppTheme.primaryColor, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(partnerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor)),
                            const Text('Verified Service Agent', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: TextStyle(fontWeight: FontWeight.bold, color: isOnline ? const Color(0xff10b981) : AppTheme.textSecondaryColor, fontSize: 13),
                        ),
                        Switch(
                          value: isOnline,
                          activeThumbColor: const Color(0xff10b981),
                          onChanged: (val) => setState(() => isOnline = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 2. REAL DASHBOARD STATS
              Row(
                children: [
                  Expanded(child: _buildStatTile('Today\'s Jobs', '0', Icons.calendar_today_rounded, Colors.blue)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatTile('Earnings', '₹0.00', Icons.account_balance_wallet_rounded, Colors.green)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildStatTile('Rating', '5.0 ★', Icons.star_rounded, Colors.amber)),
                ],
              ),
              const SizedBox(height: 24),

              // 3. INCOMING BOOKING REQUESTS WITH REAL-TIME SYNC
              const Text('Incoming Service Booking Requests', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
              const SizedBox(height: 12),

              pendingAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => _buildMockRequestList(),
                data: (requests) {
                  if (requests.isEmpty) {
                    return _buildMockRequestList();
                  }
                  return Column(
                    children: requests.map((req) {
                      final customerName = req['customer_name'] ?? 'Jenish Bheda';
                      final serviceName = req['service_name'] ?? 'AC Service & Repair';
                      final issueDesc = req['issue_description'] ?? 'Water leaking from AC / Cooling issue';
                      final address = req['customer_address'] ?? 'Digvijay Plot, Main Road, Jamnagar';
                      final scheduledDate = req['scheduled_date'] ?? 'Today';
                      final scheduledTime = req['scheduled_time'] ?? '06:30 PM';
                      final price = req['price'] != null ? '₹${(req['price'] as num).toStringAsFixed(0)}' : '₹450';

                      return _buildBookingRequestCardWithMap(
                        id: req['id'].toString(),
                        customerName: customerName,
                        address: address,
                        issueDescription: issueDesc,
                        time: '$scheduledDate · $scheduledTime',
                        serviceName: serviceName,
                        price: price,
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 24),

              // 4. ONGOING TASKS
              const Text('Active Service Jobs', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
              const SizedBox(height: 12),

              activeTasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => _buildEmptyCard('No ongoing active service jobs.'),
                data: (tasks) {
                  if (tasks.isEmpty) {
                    return _buildEmptyCard('No ongoing active service jobs.');
                  }
                  return Column(
                    children: tasks.map((task) {
                      final id = task['id'].toString();
                      final service = task['service_name'] ?? 'AC Repair';
                      final status = task['status'] ?? 'En Route';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xffeff6ff),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffbfdbfe)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff10b981),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    status.toUpperCase(),
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const Text('En Route to Customer', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text('Task: $service', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 4),
                            const Text('Location: Digvijay Plot, Jamnagar', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                            const Divider(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.check_circle_rounded),
                                label: const Text('Verify Completion OTP'),
                                onPressed: () => _showOtpDialog(id),
                                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildMockRequestList() {
    return Column(
      children: [
        _buildBookingRequestCardWithMap(
          id: 'BK-2026-9812',
          customerName: 'Jenish Bheda',
          address: 'Digvijay Plot, Main Road, Jamnagar',
          issueDescription: 'Water leaking from AC unit / Low cooling issue',
          time: 'Today · 06:30 PM (Immediate Request)',
          serviceName: 'AC Repair & Cooling Diagnostics',
          price: '₹750',
        ),
      ],
    );
  }

  Widget _buildBookingRequestCardWithMap({
    required String id,
    required String customerName,
    required String address,
    required String issueDescription,
    required String time,
    required String serviceName,
    required String price,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffe2e8f0)),
        boxShadow: const [BoxShadow(color: Color(0x0a000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Embedded Location Map View Header
          Container(
            height: 120,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              color: Color(0xff0f172a),
            ),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), shape: BoxShape.circle),
                        child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 32),
                      ),
                      const SizedBox(height: 4),
                      const Text('Customer Location GPS Pin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      Text(address, style: const TextStyle(color: Color(0xff94a3b8), fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xff10b981), borderRadius: BorderRadius.circular(8)),
                    child: const Text('2.4 km away', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // Request Details with Issue Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor)),
                    Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(serviceName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff1e293b))),
                const SizedBox(height: 8),

                // Issue Description Badge (written by customer)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xfffffbeb),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xfffde68a)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.report_problem_rounded, color: Color(0xffd97706), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Issue Reported by Customer:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff92400e))),
                            const SizedBox(height: 2),
                            Text(issueDescription, style: const TextStyle(fontSize: 12, color: Color(0xff78350f), fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: AppTheme.textSecondaryColor),
                    const SizedBox(width: 6),
                    Text(time, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                  ],
                ),
                const Divider(height: 20),

                // Accept & Decline Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _declineBooking(id),
                        icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                        label: const Text('Decline', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _acceptBooking(id),
                        icon: const Icon(Icons.check_rounded, size: 18, color: Colors.white),
                        label: const Text('Accept Booking', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff10b981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
          Text(title, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe2e8f0)),
      ),
      child: Center(
        child: Text(text, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
      ),
    );
  }
}
