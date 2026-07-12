import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> with SingleTickerProviderStateMixin {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings & Orders'),
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildActiveOrders(),
          _buildPastOrders(),
        ],
      ),
    );
  }

  Widget _buildActiveOrders() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Active Booking Card (AC Service)
        Card(
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
                    const Text(
                      'Status: En Route',
                      style: TextStyle(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'AC Gas Refill & Filter Cleaning',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                ),
                const Text(
                  'Provider: Rajesh Electricals',
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.calendar_today, size: 14, color: AppTheme.textSecondaryColor),
                    SizedBox(width: 6),
                    Text('Today, 06:30 PM', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '₹1,200',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryColor),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () => context.push('/track-booking/BOOK-5892'),
                      child: const Text('Track Live', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Active Product Order Card
        Card(
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
                    const Text(
                      'Status: Packing',
                      style: TextStyle(
                        color: AppTheme.warningColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Order #ORD-2842',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                ),
                const Text(
                  'Items: AC Dust Filter x1',
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.pin_drop, size: 14, color: AppTheme.textSecondaryColor),
                    SizedBox(width: 6),
                    Text('Delivery Address: Koramangala Sector 4', style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '₹384',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.primaryColor),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        minimumSize: Size.zero,
                        backgroundColor: const Color(0xff7c3aed),
                      ),
                      onPressed: () => context.push('/track-order/ORD-2842'),
                      child: const Text('Track Order', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPastOrders() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
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
                        color: const Color(0xfff0fdf4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'COMPLETED',
                        style: TextStyle(
                          color: AppTheme.successColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Text(
                      'July 10, 2026',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Kitchen Sink Plumbing Repair',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimaryColor),
                ),
                const Text(
                  'Provider: Ramesh Electricals',
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      '₹600',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimaryColor),
                    ),
                    Text(
                      'Paid via Cash ✓',
                      style: TextStyle(color: AppTheme.successColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
