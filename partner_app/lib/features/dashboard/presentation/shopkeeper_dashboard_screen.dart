import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/local_registration_cache.dart';

class ShopkeeperDashboardScreen extends StatefulWidget {
  const ShopkeeperDashboardScreen({super.key});

  @override
  State<ShopkeeperDashboardScreen> createState() => _ShopkeeperDashboardScreenState();
}

class _ShopkeeperDashboardScreenState extends State<ShopkeeperDashboardScreen> {
  bool _isOpen = true;
  String _shopName = 'ServiceHub Partner Store';
  double _todaySales = 0.0;
  int _totalOrders = 0;
  List<Map<String, dynamic>> _incomingOrders = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  Future<void> _loadShopData() async {
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
            context.go('/login/shopkeeper');
            return;
          }
        }
        setState(() {
          _shopName = (activeUser['business_name'] ?? activeUser['name'] ?? 'Partner Store').toString();
        });
      }

      final client = Supabase.instance.client;
      final ordersRes = await client
          .from('orders')
          .select('*, order_items(*, products(*)), user_addresses(*)')
          .filter('order_status', 'in', ['Placed', 'Packing', 'Ready for Pickup'])
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> orders = [];
      for (final o in ordersRes) {
        final address = o['user_addresses'] as Map<String, dynamic>?;
        orders.add({
          'order_id': o['order_id'],
          'order_code': o['order_code'] ?? 'SHO12345',
          'total_amount': (o['total_amount'] as num?)?.toDouble() ?? 450.0,
          'status': o['order_status'],
          'items_summary': o['items_summary'] ?? 'Store Items',
          'customer_area': address != null ? '${address['area']}, ${address['city']}' : 'Local Area',
        });
      }

      setState(() {
        _incomingOrders = orders;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _packOrder(Map<String, dynamic> order) async {
    final orderId = order['order_id'];
    setState(() {
      _incomingOrders.removeWhere((o) => o['order_id'] == orderId);
      _totalOrders += 1;
      _todaySales += (order['total_amount'] as num?)?.toDouble() ?? 450.0;
    });

    try {
      if (orderId != null) {
        await Supabase.instance.client
            .from('orders')
            .update({'order_status': 'Ready for Pickup'})
            .eq('order_id', orderId);
      }
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order ${order['order_code']} marked Ready for Pickup!'),
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
        backgroundColor: AppColors.shopkeeperGreenDark,
        elevation: 1,
        title: Row(
          children: [
            const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              _shopName,
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
              onRefresh: _loadShopData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Store Open / Closed Switch Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isOpen ? const Color(0xFFF0FDF4) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isOpen ? const Color(0xFFBBF7D0) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isOpen ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isOpen ? Icons.storefront_rounded : Icons.lock_outline_rounded,
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
                            _isOpen ? 'STORE OPEN — Accepting Orders' : 'STORE CLOSED',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isOpen ? const Color(0xFF14532D) : const Color(0xFF334155),
                            ),
                          ),
                          Text(
                            _isOpen
                                ? 'Customers can purchase products from your catalog'
                                : 'Toggle switch to reopen your shop to customers',
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isOpen,
                      activeTrackColor: const Color(0xFF16A34A),
                      onChanged: (val) => setState(() => _isOpen = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Metrics Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: "Today's Revenue",
                      value: '₹${_todaySales.toStringAsFixed(0)}',
                      icon: Icons.currency_rupee_rounded,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Orders Processed',
                      value: '$_totalOrders Orders',
                      icon: Icons.inventory_2_rounded,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Incoming Product Orders
              const Text(
                'Store Product Orders',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 12),

              if (_incomingOrders.isEmpty)
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
                      Icon(Icons.shopping_bag_outlined, color: Color(0xFF94A3B8), size: 48),
                      SizedBox(height: 12),
                      Text(
                        'No Pending Orders',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Customer product orders will appear here in realtime.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                )
              else
                ..._incomingOrders.map((order) => _buildOrderCard(order)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
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
              Text('Order #${order['order_code']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
              const Spacer(),
              Text('₹${order['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF16A34A))),
            ],
          ),
          const SizedBox(height: 8),
          Text('Items: ${order['items_summary']}', style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
          const SizedBox(height: 4),
          Text('Delivery to: ${order['customer_area']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.shopkeeperGreenDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => _packOrder(order),
              child: const Text('PACK & READY FOR PICKUP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5)),
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
