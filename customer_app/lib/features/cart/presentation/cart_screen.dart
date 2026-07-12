import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  int quantity = 1;
  final int itemPrice = 349;
  final int deliveryFee = 35;
  bool _isPlacingOrder = false;

  Future<void> _placeOrder(int subtotal, int total) async {
    setState(() {
      _isPlacingOrder = true;
    });

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to place an order.'), backgroundColor: AppTheme.warningColor),
      );
      context.push('/login');
      return;
    }

    try {
      final response = await client.from('orders').insert({
        'customer_id': user.id,
        'status': 'Placed',
        'items_summary': 'AC Dust Filter (Universal) x$quantity',
        'subtotal': subtotal.toDouble(),
        'delivery_fee': deliveryFee.toDouble(),
        'grand_total': total.toDouble(),
        'delivery_pin': '2842',
        'shipping_address': 'Koramangala Sector 4, Bangalore',
      }).select().single();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order Placed Successfully!'), backgroundColor: AppTheme.successColor),
        );
        final orderId = response['id'];
        context.go('/track-order/$orderId');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPlacingOrder = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error placing order: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final int subtotal = itemPrice * quantity;
    final int total = subtotal + deliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: quantity > 0
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Items in Cart',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 12),

                  // 1. CART ITEM CARD
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: const Color(0xfff1f5f9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.ac_unit, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'AC Dust Filter',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '₹$itemPrice',
                                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700),
                                ),
                              ],
                            ),
                          ),
                          // Quantity Selector
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  setState(() {
                                    if (quantity > 0) quantity--;
                                  });
                                },
                              ),
                              Text(
                                '$quantity',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                                onPressed: () {
                                  setState(() {
                                    quantity++;
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. BILL SUMMARY CARD
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Bill Summary',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Item Subtotal', style: TextStyle(color: AppTheme.textSecondaryColor)),
                              Text('₹$subtotal', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Delivery Partner Fee', style: TextStyle(color: AppTheme.textSecondaryColor)),
                              Text('₹$deliveryFee', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Grand Total',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                              ),
                              Text(
                                '₹$total',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. INFORMATION CALLOUT
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffeff6ff),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderCol),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.pin_drop_outlined, color: AppTheme.primaryColor, size: 20),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Delivery within your 5 km zone · PIN verification required on delivery.',
                            style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),

                  // 4. BOTTOM ACTION BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isPlacingOrder ? null : () => _placeOrder(subtotal, total),
                      child: _isPlacingOrder
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Place Order · ₹$total'),
                    ),
                  ),
                ],
              ),
            )
          : const Center(
              child: Text(
                'Your cart is empty',
                style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 16),
              ),
            ),
    );
  }
}
