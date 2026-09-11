import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/local_registration_cache.dart';

class DeliveryDashboardScreen extends StatefulWidget {
  const DeliveryDashboardScreen({super.key});

  @override
  State<DeliveryDashboardScreen> createState() => _DeliveryDashboardScreenState();
}

class _DeliveryDashboardScreenState extends State<DeliveryDashboardScreen> {
  bool _isOnline = true;
  String _agentName = 'Delivery Agent';
  double _todayEarnings = 0.0;
  int _completedDeliveries = 0;
  List<Map<String, dynamic>> _activeTasks = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAgentData();
  }

  Future<void> _loadAgentData() async {
    setState(() => _isLoading = true);
    try {
      final activeUser = await LocalRegistrationCache.getActivePartner();
      if (activeUser != null) {
        final status = (activeUser['verification_status'] ?? '').toString().toUpperCase();
        if (status != 'VERIFIED' && status != 'APPROVED') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Application is pending Admin approval. Please login after Admin approval.'),
                backgroundColor: Color(0xFFD97706),
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go('/login/delivery-agent');
            return;
          }
        }
        setState(() {
          _agentName = (activeUser['name'] ?? activeUser['username'] ?? 'Delivery Agent').toString();
        });
      }

      final client = Supabase.instance.client;
      final tasksRes = await client
          .from('delivery_assignments')
          .select('*, orders(*, shops(*), user_addresses(*))')
          .filter('status', 'in', ['ASSIGNED', 'ACCEPTED', 'PICKED_UP'])
          .order('assigned_at', ascending: false);

      final List<Map<String, dynamic>> tasks = [];
      for (final t in tasksRes) {
        final order = t['orders'] as Map<String, dynamic>?;
        final shop = order?['shops'] as Map<String, dynamic>?;
        final address = order?['user_addresses'] as Map<String, dynamic>?;

        tasks.add({
          'assignment_id': t['assignment_id'],
          'order_id': t['order_id'],
          'status': t['status'],
          'shop_name': shop?['shop_name'] ?? 'ServiceHub Store (Jamnagar Main)',
          'customer_address': address != null ? '${address['area']}, ${address['city']}' : 'Local Address',
          'earning': 95.0,
          'items_summary': order?['items_summary'] ?? 'Package Delivery',
        });
      }

      setState(() {
        _activeTasks = tasks;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptTask(Map<String, dynamic> task) async {
    final assignmentId = task['assignment_id'];
    setState(() {
      _activeTasks.removeWhere((t) => t['assignment_id'] == assignmentId);
      _completedDeliveries += 1;
      _todayEarnings += (task['earning'] as num?)?.toDouble() ?? 95.0;
    });

    try {
      if (assignmentId != null) {
        await Supabase.instance.client
            .from('delivery_assignments')
            .update({'status': 'DELIVERED', 'delivered_at': DateTime.now().toIso8601String()})
            .eq('assignment_id', assignmentId);
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery Completed! ₹${task['earning']} added to your earnings.'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.deliveryOrangeDark,
        elevation: 1,
        title: Row(
          children: [
            const Icon(Icons.two_wheeler, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              'Rider Portal — $_agentName',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () => context.go('/role-selection'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAgentData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Online / Offline Status Toggle Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isOnline ? const Color(0xFFEFF6FF) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isOnline ? const Color(0xFFBFDBFE) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isOnline ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isOnline ? Icons.radar : Icons.power_settings_new,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOnline ? 'ONLINE — Ready for Orders' : 'OFFLINE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isOnline ? const Color(0xFF1E40AF) : const Color(0xFF334155),
                            ),
                          ),
                          Text(
                            _isOnline
                                ? 'Receiving express delivery tasks in your area'
                                : 'Switch to online mode to start receiving tasks',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isOnline,
                      activeTrackColor: const Color(0xFF2563EB),
                      onChanged: (val) => setState(() => _isOnline = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Today's Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: "Today's Earnings",
                      value: '₹${_todayEarnings.toStringAsFixed(0)}',
                      icon: Icons.account_balance_wallet_rounded,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Deliveries Done',
                      value: '$_completedDeliveries Orders',
                      icon: Icons.check_circle_rounded,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Active Delivery Tasks Section
              const Text(
                'Incoming Delivery Tasks',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),

              if (_activeTasks.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.inbox_rounded, color: Color(0xFF94A3B8), size: 48),
                      SizedBox(height: 12),
                      Text(
                        'No Active Delivery Requests',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'New orders from stores will appear here in realtime.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              else
                ..._activeTasks.map((task) => _buildTaskCard(task)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> task) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('EXPRESS COURIER', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFEA580C))),
              ),
              const Spacer(),
              Text('Earn ₹${task['earning']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF16A34A))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: Color(0xFF2563EB), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Pickup: ${task['shop_name']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Drop: ${task['customer_address']}', style: const TextStyle(fontSize: 13, color: Color(0xFF475569))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deliveryOrangeDark,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _acceptTask(task),
              child: const Text('ACCEPT & DELIVER TASK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
