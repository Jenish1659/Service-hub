import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'seller_provider.dart';

class SellerDashboard extends ConsumerStatefulWidget {
  const SellerDashboard({super.key});

  @override
  ConsumerState<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends ConsumerState<SellerDashboard> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  String _selectedCategory = 'AC';

  void _refreshAll() {
    ref.invalidate(sellerProductsProvider);
    ref.invalidate(sellerActiveOrdersProvider);
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await Supabase.instance.client
          .from('orders')
          .update({'status': newStatus})
          .eq('id', orderId);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order status updated to $newStatus!'), backgroundColor: AppTheme.successColor),
      );
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  Future<void> _addProduct() async {
    final name = _nameController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    final stock = int.tryParse(_stockController.text.trim()) ?? 10;

    if (name.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid product name and price.'), backgroundColor: AppTheme.warningColor),
      );
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('products').insert({
        'seller_id': user.id,
        'name': name,
        'price': price,
        'category': _selectedCategory,
        'stock': stock,
        'latitude': 12.9103, // Default shop location coordinates (HSR Layout)
        'longitude': 77.6433,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully!'), backgroundColor: AppTheme.successColor),
        );
        _nameController.clear();
        _priceController.clear();
        _stockController.clear();
        _refreshAll();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding product: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
        );
      }
    }
  }

  Future<void> _seedSampleProducts() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('products').insert([
        {
          'seller_id': user.id,
          'name': 'AC Dust Filter (Premium)',
          'price': 349.0,
          'category': 'AC',
          'stock': 12,
          'latitude': 12.9103,
          'longitude': 77.6433,
        },
        {
          'seller_id': user.id,
          'name': 'Brass Washers (1/2 inch)',
          'price': 15.0,
          'category': 'Plumbing',
          'stock': 4,
          'latitude': 12.9103,
          'longitude': 77.6433,
        },
        {
          'seller_id': user.id,
          'name': 'Laundry Gel Liquid Refill',
          'price': 280.0,
          'category': 'Laundry',
          'stock': 28,
          'latitude': 12.9103,
          'longitude': 77.6433,
        }
      ]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sample inventory seeded!'), backgroundColor: AppTheme.successColor),
      );
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error seeding: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
      );
    }
  }

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Product to Catalog'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(hintText: 'Product Name (e.g. AC Filter)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Price (₹)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _stockController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Initial Stock Count (e.g. 10)'),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: const [
                        DropdownMenuItem(value: 'AC', child: Text('AC Service')),
                        DropdownMenuItem(value: 'Plumbing', child: Text('Plumbing')),
                        DropdownMenuItem(value: 'Laundry', child: Text('Laundry')),
                        DropdownMenuItem(value: 'Car', child: Text('Car Service')),
                        DropdownMenuItem(value: 'Cooking', child: Text('Cooking')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _addProduct,
                  child: const Text('Add Product'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(sellerProductsProvider);
    final ordersAsync = ref.watch(sellerActiveOrdersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopkeeper Dashboard'),
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
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Anita\'s Laundry & Supplies',
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

                // 2. QUICK BUSINESS KPI ROW
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
                
                ordersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error loading orders: ${e.toString()}')),
                  data: (orders) {
                    if (orders.isEmpty) {
                      return const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24.0),
                          child: Center(
                            child: Text(
                              'No active customer orders right now.',
                              style: TextStyle(color: AppTheme.textSecondaryColor),
                            ),
                          ),
                        ),
                      );
                    }
                    return Column(
                      children: orders.map((order) {
                        final id = order['id'];
                        final items = order['items_summary'] ?? '';
                        final total = (order['grand_total'] as num?)?.toDouble() ?? 0.0;
                        final status = order['status'] ?? 'Placed';
                        
                        String buttonText = 'Mark Ready';
                        String nextStatus = 'Ready for Pickup';
                        if (status == 'Placed') {
                          buttonText = 'Start Packing';
                          nextStatus = 'Packing';
                        } else if (status == 'Packing') {
                          buttonText = 'Mark Ready';
                          nextStatus = 'Ready for Pickup';
                        } else if (status == 'Ready for Pickup') {
                          buttonText = 'Hand Over to Agent';
                          nextStatus = 'Out for Delivery';
                        }

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
                                    Text('Order #${id.toString().substring(0, 8).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text('₹${total.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w800)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('Items: $items', style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                                const Text('Delivery Zone: Within 5 km hyperlocal radius', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
                                const Divider(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Status: ${status.toUpperCase()}',
                                      style: const TextStyle(color: AppTheme.warningColor, fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    if (status != 'Out for Delivery')
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.check_circle_outline, size: 16),
                                        label: Text(buttonText),
                                        onPressed: () => _updateOrderStatus(id, nextStatus),
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
                const SizedBox(height: 28),

                // 4. INVENTORY MANAGEMENT LIST
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Inventory Management',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                    ),
                    Row(
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Seed Samples'),
                          onPressed: _seedSampleProducts,
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Product'),
                          onPressed: _showAddProductDialog,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                productsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, s) => Center(child: Text('Error loading inventory: ${e.toString()}')),
                  data: (products) {
                    if (products.isEmpty) {
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Column(
                              children: [
                                const Text('Your store inventory is empty.', style: TextStyle(color: AppTheme.textSecondaryColor)),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _seedSampleProducts,
                                  child: const Text('Seed Sample Products'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final item = products[index];
                        final stock = item['stock'] ?? 0;
                        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                        final isLowStock = stock <= 5;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item['name'] ?? 'Product', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            subtitle: Row(
                              children: [
                                Text('Stock: $stock',
                                    style: TextStyle(
                                      color: isLowStock ? AppTheme.dangerColor : AppTheme.textSecondaryColor,
                                      fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                    )),
                                const SizedBox(width: 12),
                                Text('Price: ₹${price.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            trailing: Switch(
                              value: stock > 0,
                              onChanged: (val) {},
                            ),
                          ),
                        );
                      },
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
