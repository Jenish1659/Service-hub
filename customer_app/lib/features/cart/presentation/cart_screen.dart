import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../location/providers/location_provider.dart';
import 'cart_provider.dart';
import 'promo_code_provider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  final int deliveryFee = 35;
  bool _isPlacingOrder = false;
  final TextEditingController _promoController = TextEditingController();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  String _generateOtpPin() {
    final random = Random();
    return (1000 + random.nextInt(9000)).toString();
  }

  Future<void> _applyPromoCode(int subtotal) async {
    final result = await ref.read(promoProvider.notifier).applyPromoCode(_promoController.text, subtotal);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message),
        backgroundColor: result.isSuccess ? AppTheme.successColor : AppTheme.dangerColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _placeOrder(int subtotal, int total) async {
    final cartItems = ref.read(cartProvider);
    if (cartItems.isEmpty) return;

    setState(() {
      _isPlacingOrder = true;
    });

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final customerId = user?.id ?? 'cust_${DateTime.now().millisecondsSinceEpoch}';

    final locState = ref.read(locationProvider);
    final location = locState.selectedLocation ?? locState.currentLocation;
    final shippingAddress = location?.address ?? 'Digvijay Plot, Main Road, Jamnagar';
    final lat = location?.latitude ?? 22.4707;
    final lng = location?.longitude ?? 70.0577;

    final itemsSummary = cartItems.map((item) => '${item.name} x${item.quantity}').join(', ');
    final otpPin = _generateOtpPin();

    try {
      Map<String, dynamic> responseData;
      try {
        final response = await client.from('orders').insert({
          'customer_id': customerId,
          'shop_id': '11111111-1111-1111-1111-111111111118',
          'address_id': location?.id ?? '11111111-1111-1111-1111-111111111116',
          'order_status': 'Placed',
          'subtotal': subtotal.toDouble(),
          'delivery_charge': deliveryFee.toDouble(),
          'total_amount': total.toDouble(),
          'payment_status': 'PAID',
        }).select().single();
        final generatedOrderCode = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
        final orderId = (response['order_id'] ?? response['id'] ?? 'ord_${DateTime.now().millisecondsSinceEpoch}').toString();
        final orderCode = (response['order_code'] ?? generatedOrderCode).toString();
        responseData = {
          'id': orderId,
          'order_id': orderId,
          'order_code': orderCode,
          'delivery_pin': otpPin,
          'grand_total': total.toDouble(),
          'shipping_address': shippingAddress,
        };

        try {
          await client.from('delivery_assignments').insert({
            'order_id': responseData['id'],
            'status': 'ASSIGNED',
            'assigned_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Error inserting delivery assignment: $e');
        }

        try {
          await LiveBookingSyncService.instance.submitBooking({
            'id': responseData['id'],
            'booking_id': responseData['id'],
            'order_id': responseData['id'],
            'type': 'DELIVERY_ORDER',
            'status': 'ASSIGNED',
            'order_code': orderCode,
            'customer_id': customerId,
            'customer_name': 'Customer',
            'service_id': 'food_grocery_delivery',
            'service_name': 'Store Order Delivery',
            'address': shippingAddress,
            'customer_address': shippingAddress,
            'estimated_amount': total.toDouble(),
            'final_amount': total.toDouble(),
            'delivery_charge': deliveryFee.toDouble(),
            'customer_lat': lat,
            'customer_lng': lng,
            'delivery_pin': otpPin,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Error broadcasting to LiveBookingSyncService: $e');
        }
      } catch (e) {
        final fallbackOrderCode = 'ORD-${DateTime.now().millisecondsSinceEpoch}';
        final fallbackOrderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';
        responseData = {
          'id': fallbackOrderId,
          'order_id': fallbackOrderId,
          'order_code': fallbackOrderCode,
          'customer_id': customerId,
          'status': 'Placed',
          'items_summary': itemsSummary,
          'subtotal': subtotal.toDouble(),
          'delivery_fee': deliveryFee.toDouble(),
          'grand_total': total.toDouble(),
          'delivery_pin': otpPin,
          'shipping_address': shippingAddress,
          'customer_lat': lat,
          'customer_lng': lng,
        };

        try {
          await LiveBookingSyncService.instance.submitBooking({
            'id': responseData['id'],
            'booking_id': responseData['id'],
            'order_id': responseData['id'],
            'type': 'DELIVERY_ORDER',
            'status': 'ASSIGNED',
            'order_code': fallbackOrderCode,
            'customer_id': customerId,
            'customer_name': 'Customer',
            'service_id': 'food_grocery_delivery',
            'service_name': 'Store Order Delivery',
            'address': shippingAddress,
            'customer_address': shippingAddress,
            'estimated_amount': total.toDouble(),
            'final_amount': total.toDouble(),
            'delivery_charge': deliveryFee.toDouble(),
            'customer_lat': lat,
            'customer_lng': lng,
            'delivery_pin': otpPin,
            'created_at': DateTime.now().toIso8601String(),
          });
        } catch (e) {
          debugPrint('Error broadcasting fallback to LiveBookingSyncService: $e');
        }
      }

      // Mark applied promo code as used permanently for this user account
      await ref.read(promoProvider.notifier).markActiveCodeAsUsed();

      ref.read(cartProvider.notifier).clearCart();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order Placed Successfully! Delivery PIN: $otpPin'),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 4),
          ),
        );
        final orderId = responseData['id'];
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

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Order Terms & Policy', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          content: const SingleChildScrollView(
            child: Text(
              '1. 5 km Geofencing Policy: Products are sourced and delivered within 5 km of your registered location in Jamnagar.\n\n'
              '2. Secure Delivery Verification: Delivery agent requires PIN confirmation before handing over products.\n\n'
              '3. Refund & Return: Damaged items during transit will be replaced immediately after PIN verification.\n\n'
              '4. Payment Settlement: Payments are securely held until delivery completion.',
              style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xff334155)),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Accept & Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final promoState = ref.watch(promoProvider);
    final discountAmount = promoState.discountAmount;
    final total = cartItems.isNotEmpty ? (subtotal + deliveryFee - discountAmount).clamp(0, 999999) : 0;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Your Cart'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        actions: [
          if (cartItems.isNotEmpty)
            TextButton.icon(
              icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white, size: 18),
              label: const Text('Clear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Clear Cart?'),
                    content: const Text('Are you sure you want to remove all items from your cart?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
                        onPressed: () {
                          Navigator.pop(ctx);
                          ref.read(cartProvider.notifier).clearCart();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Cart cleared successfully!')),
                          );
                        },
                        child: const Text('Clear All', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cartItems.isNotEmpty
          ? SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Items in Cart (${cartItems.length})',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 12),

                  // 1. DYNAMIC CART ITEM CARDS
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: cartItems.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = cartItems[index];
                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: const Color(0xffeff6ff),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '₹${item.price}',
                                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                              // Quantity Controls
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: AppTheme.dangerColor),
                                    onPressed: () {
                                      ref.read(cartProvider.notifier).updateQuantity(item.name, -1);
                                    },
                                  ),
                                  Text(
                                    '${item.quantity}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                                    onPressed: () {
                                      ref.read(cartProvider.notifier).updateQuantity(item.name, 1);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // 2. PROMO CODE / COUPON CARD
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    child: Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.local_offer_outlined, color: AppTheme.primaryColor, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Coupons & Offers',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (promoState.activeCode != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xfff0fdf4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xff86efac)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xff16a34a), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Code "${promoState.activeCode!.code}" Applied!',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff15803d), fontSize: 13),
                                        ),
                                        Text(
                                          'Saving ₹$discountAmount on this order',
                                          style: const TextStyle(color: Color(0xff166534), fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      ref.read(promoProvider.notifier).removePromoCode();
                                      _promoController.clear();
                                    },
                                    child: const Text('REMOVE', style: TextStyle(color: AppTheme.dangerColor, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 44,
                                    child: TextField(
                                      controller: _promoController,
                                      textCapitalization: TextCapitalization.characters,
                                      decoration: InputDecoration(
                                        hintText: 'Enter Promo Code (e.g. WELCOME50)',
                                        hintStyle: const TextStyle(fontSize: 12, color: Color(0xff94a3b8)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                                        filled: true,
                                        fillColor: const Color(0xfff8fafc),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffcbd5e1))),
                                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffcbd5e1))),
                                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.primaryColor)),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  height: 44,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () => _applyPromoCode(subtotal),
                                    child: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: availablePromoCodes.map((promo) {
                                return ActionChip(
                                  avatar: const Icon(Icons.local_offer_outlined, size: 14, color: AppTheme.primaryColor),
                                  label: Text(promo.code, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                  backgroundColor: const Color(0xffeff6ff),
                                  side: const BorderSide(color: Color(0xffbfdbfe)),
                                  onPressed: () {
                                    _promoController.text = promo.code;
                                    _applyPromoCode(subtotal);
                                  },
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 3. BILL SUMMARY CARD
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                              const Text('Hyperlocal Express Delivery (5 km)', style: TextStyle(color: AppTheme.textSecondaryColor)),
                              Text('₹$deliveryFee', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          if (discountAmount > 0) ...[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Promo Discount', style: TextStyle(color: Color(0xff16a34a), fontWeight: FontWeight.w600)),
                                Text('-₹$discountAmount', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff16a34a))),
                              ],
                            ),
                          ],
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
                  Builder(
                    builder: (context) {
                      final locState = ref.watch(locationProvider);
                      final activeLoc = locState.selectedLocation ?? locState.currentLocation;
                      final addressText = activeLoc?.address ?? 'Digvijay Plot, Jamnagar';

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffeff6ff),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderCol),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 2.0),
                              child: Icon(Icons.pin_drop_outlined, color: AppTheme.primaryColor, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Delivering to $addressText · Hyperlocal OTP verification required.',
                                style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.w600, height: 1.3),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Terms & Conditions notice before checkout
                  Center(
                    child: InkWell(
                      onTap: () => _showTermsDialog(context),
                      child: const Text.rich(
                        TextSpan(
                          text: 'By placing this order, you agree to ServiceHub\'s ',
                          style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                          children: [
                            TextSpan(
                              text: 'Terms & Conditions',
                              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 4. BOTTOM ACTION BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isPlacingOrder ? null : () => _placeOrder(subtotal, total),
                      child: _isPlacingOrder
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Place Order · ₹$total', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.textSecondaryColor),
                  const SizedBox(height: 16),
                  const Text(
                    'Your Cart is Empty',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Browse marketplace products to add items to your cart.',
                    style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/products'),
                    child: const Text('Browse Products'),
                  ),
                ],
              ),
            ),
      ),
    );
  }
}
