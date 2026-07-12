import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class SellerDashboard extends StatefulWidget {
  const SellerDashboard({super.key});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  // Inventory mock data
  final List<Map<String, dynamic>> _inventory = [
    {'name': 'AC Dust Filter (Premium)', 'stock': 12, 'price': 349, 'avail': true},
    {'name': 'Brass Washers (1/2 inch)', 'stock': 4, 'price': 15, 'avail': true},
    {'name': 'Laundry Gel Liquid Refill', 'stock': 28, 'price': 280, 'avail': true},
    {'name': 'Microfiber Towels (3-pack)', 'stock': 0, 'price': 150, 'avail': false},
  ];

  void _dispatchOrder(String orderId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Order $orderId marked as READY FOR PICKUP! Delivery agent notified.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopkeeper Dashboard'),
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
              // 1. SHOP NAME HEADER
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(color: Color(0xfff5f3ff), shape: BoxShape.circle),
                    child: const Icon(Icons.storefront, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Anita\'s Laundry Supplies',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                      ),
                      Text(
                        'Merchant Partner · HSR Layout',
                        style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. QUICK BUSINESS KPI ROW (RUPEES)
              Row(
                children: [
                  Expanded(
                    child: _buildKpiCard('Today\'s Orders', '12', Icons.receipt_long, Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard('Daily Sales (₹)', '₹4,890', Icons.payments, Colors.green),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildKpiCard('Low Stock Alerts', '1 Item', Icons.warning_amber, Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // 3. ACTIVE ORDER DISPATCH QUEUE
              const Text(
                'Active Orders Queue',
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
                          Text('Order #ORD-2842', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          Text('₹698', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text('Items: AC Dust Filter x2', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                      const Text('Delivery Zone: HSR Layout Sector 1 (2.4 km)', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Status: PACKING',
                            style: TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Mark Ready'),
                            onPressed: () => _dispatchOrder('#ORD-2842'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 4. INVENTORY MANAGEMENT LIST
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Inventory Management',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Product'),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _inventory.length,
                itemBuilder: (context, index) {
                  final item = _inventory[index];
                  final isLowStock = item['stock'] <= 5;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Row(
                        children: [
                          Text('Stock: ${item['stock']}',
                              style: TextStyle(
                                color: isLowStock ? AppTheme.dangerColor : AppTheme.textSecondaryColor,
                                fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                              )),
                          const SizedBox(width: 12),
                          Text('Price: ₹${item['price']}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Switch(
                            value: item['avail'],
                            onChanged: (val) {
                              setState(() {
                                item['avail'] = val;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_note, color: AppTheme.textSecondaryColor),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard(String title, String value, IconData icon, Color color) {
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
