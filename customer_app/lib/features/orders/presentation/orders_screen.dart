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
            // Filter active
            final activeBookings = bookings.where((b) => b['status'] != 'Completed').toList();
            final activeOrders = orders.where((o) => o['status'] != 'Delivered').toList();

            if (activeBookings.isEmpty && activeOrders.isEmpty) {
              return const Center(
                child: Text('No active jobs or deliveries.', style: TextStyle(color: AppTheme.textSecondaryColor)),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...activeBookings.map((b) => _buildBookingCard(b)),
                ...activeOrders.map((o) => _buildOrderCard(o)),
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
            // Filter past
            final pastBookings = bookings.where((b) => b['status'] == 'Completed').toList();
            final pastOrders = orders.where((o) => o['status'] == 'Delivered').toList();

            if (pastBookings.isEmpty && pastOrders.isEmpty) {
              return const Center(
                child: Text('No order history available.', style: TextStyle(color: AppTheme.textSecondaryColor)),
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...pastBookings.map((b) => _buildBookingCard(b)),
                ...pastOrders.map((o) => _buildOrderCard(o)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final id = booking['id'];
    final name = booking['service_name'] ?? 'Home Service';
    final issue = booking['issue_description'] ?? '';
    final date = booking['scheduled_date'] ?? '';
    final time = booking['scheduled_time'] ?? '';
    final price = (booking['price'] as num?)?.toDouble() ?? 0.0;
    final status = booking['status'] ?? 'Pending';

    final isCompleted = status == 'Completed';

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
                    color: isCompleted ? AppTheme.successColor : AppTheme.warningColor,
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
            if (issue.isNotEmpty)
              Text(
                issue,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 6),
                Text('$date · $time', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
              ],
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryColor),
                ),
                if (!isCompleted)
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final id = order['id'];
    final items = order['items_summary'] ?? 'Product Delivery';
    final grandTotal = (order['grand_total'] as num?)?.toDouble() ?? 0.0;
    final status = order['status'] ?? 'Placed';
    final address = order['shipping_address'] ?? '';

    final isDelivered = status == 'Delivered';

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
                    color: isDelivered ? AppTheme.successColor : AppTheme.warningColor,
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
                if (!isDelivered)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      minimumSize: Size.zero,
                      backgroundColor: const Color(0xff7c3aed),
                    ),
                    onPressed: () => context.push('/track-order/$id'),
                    child: const Text('Track Order', style: TextStyle(fontSize: 13)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
