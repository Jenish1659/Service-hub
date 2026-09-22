import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import 'orders_provider.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    ref.invalidate(userBookingsProvider);
    ref.invalidate(userOrdersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(userBookingsProvider);
    final ordersAsync = ref.watch(userOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings & Orders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Active Jobs'),
            Tab(text: 'Past History'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildActiveTab(bookingsAsync, ordersAsync),
            _buildPastTab(bookingsAsync, ordersAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onButtonPressed,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: const BoxDecoration(
                        color: Color(0xffeff6ff),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 46, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                        height: 1.4,
                      ),
                    ),
                    if (buttonText != null && onButtonPressed != null) ...[
                      const SizedBox(height: 24),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onButtonPressed,
                        child: Text(
                          buttonText,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActiveTab(
    AsyncValue<List<Map<String, dynamic>>> bookingsAsync,
    AsyncValue<List<Map<String, dynamic>>> ordersAsync,
  ) {
    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading active bookings: ${e.toString()}')),
      data: (bookings) {
        return ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error loading active orders: ${e.toString()}')),
          data: (orders) {
            // Filter active (exclude completed and cancelled)
            final activeBookings = bookings.where((b) {
              final s = (b['status'] ?? '').toString().toUpperCase();
              return s != 'COMPLETED' && s != 'CLOSED' && !s.contains('CANCELLED') && s != 'REJECTED';
            }).toList();

            final activeOrders = orders.where((o) {
              final s = (o['status'] ?? '').toString().toUpperCase();
              return s != 'DELIVERED' && !s.contains('CANCELLED');
            }).toList();

            if (activeBookings.isEmpty && activeOrders.isEmpty) {
              return _buildEmptyState(
                icon: Icons.assignment_outlined,
                title: 'No Active Bookings or Orders',
                message: 'You have 0 active bookings and 0 running orders right now.',
                buttonText: 'Explore Services',
                onButtonPressed: () => context.go('/discover'),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ...activeBookings.map((b) => _buildBookingCard(b, isActive: true)),
                ...activeOrders.map((o) => _buildOrderCard(o, isActive: true)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPastTab(
    AsyncValue<List<Map<String, dynamic>>> bookingsAsync,
    AsyncValue<List<Map<String, dynamic>>> ordersAsync,
  ) {
    return bookingsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading history: ${e.toString()}')),
      data: (bookings) {
        return ordersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error loading history: ${e.toString()}')),
          data: (orders) {
            // Filter past (include completed, closed, and cancelled)
            final pastBookings = bookings.where((b) {
              final s = (b['status'] ?? '').toString().toUpperCase();
              return s == 'COMPLETED' || s == 'CLOSED' || s.contains('CANCELLED') || s == 'REJECTED';
            }).toList();

            final pastOrders = orders.where((o) {
              final s = (o['status'] ?? '').toString().toUpperCase();
              return s == 'DELIVERED' || s.contains('CANCELLED');
            }).toList();

            if (pastBookings.isEmpty && pastOrders.isEmpty) {
              return _buildEmptyState(
                icon: Icons.history_toggle_off_outlined,
                title: 'No Past History',
                message: 'You have 0 past bookings or orders recorded in your history.',
                buttonText: 'Browse Services',
                onButtonPressed: () => context.go('/discover'),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                ...pastBookings.map((b) => _buildBookingCard(b, isActive: false)),
                ...pastOrders.map((o) => _buildOrderCard(o, isActive: false)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, {required bool isActive}) {
    final id = booking['id'];
    final name = booking['service_name'] ?? 'Home Service';
    final issue = (booking['problem_description'] ?? booking['issue_description'] ?? '').toString();
    final date = (booking['scheduled_date'] ?? '').toString();
    final time = (booking['scheduled_time'] ?? '').toString();
    final price = (booking['price'] as num?)?.toDouble() ?? 0.0;
    final status = (booking['status'] ?? 'Pending').toString();
    final isCancelled = status.toUpperCase().contains('CANCELLED');
    final isCompleted = status.toUpperCase() == 'COMPLETED';

    Color statusColor = AppTheme.warningColor;
    if (isCompleted) statusColor = AppTheme.successColor;
    if (isCancelled) statusColor = AppTheme.dangerColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                    color: const Color(0xffeff6ff),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'SERVICE BOOKING',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Status: $status',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
            ),
            if (issue.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                issue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
              ),
            ],
            if (date.isNotEmpty || time.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 6),
                  Text(
                    date.isNotEmpty && time.isNotEmpty
                        ? '$date · $time'
                        : date.isNotEmpty
                            ? date
                            : time,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryColor),
                ),
                if (!isCompleted && !isCancelled)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => context.push('/track-booking/$id'),
                    child: const Text('Track Live', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, {required bool isActive}) {
    final id = order['id'];
    final items = order['items_summary'] ?? 'Product Delivery';
    final grandTotal = (order['grand_total'] as num?)?.toDouble() ?? 0.0;
    final status = (order['status'] ?? 'Placed').toString();
    final address = order['shipping_address'] ?? '';
    final isCancelled = status.toUpperCase().contains('CANCELLED');
    final isDelivered = status.toUpperCase() == 'DELIVERED';

    Color statusColor = AppTheme.warningColor;
    if (isDelivered) statusColor = AppTheme.successColor;
    if (isCancelled) statusColor = AppTheme.dangerColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
                    color: const Color(0xfff5f3ff),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'PRODUCT ORDER',
                    style: TextStyle(
                      color: Color(0xff7c3aed),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Status: $status',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Order #${id.toString().length >= 8 ? id.toString().substring(0, 8).toUpperCase() : id.toString().toUpperCase()}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
            ),
            Text(
              'Items: $items',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
            ),
            if (address.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.pin_drop, size: 14, color: AppTheme.textSecondaryColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Delivery to: $address',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                    ),
                  ),
                ],
              ),
            ],
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${grandTotal.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryColor),
                ),
                if (!isDelivered && !isCancelled)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      minimumSize: Size.zero,
                      backgroundColor: const Color(0xff7c3aed),
                    ),
                    onPressed: () => context.push('/track-order/$id'),
                    child: const Text('Track Order', style: TextStyle(fontSize: 13)),
                  )
                else
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () => context.push('/track-order/$id'),
                    child: const Text('View Details', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
