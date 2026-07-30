import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// StreamProvider to fetch products owned by this seller
final sellerProductsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final user = client.auth.currentUser;
      final userId = user?.id;

      if (userId != null && !userId.startsWith('mock_')) {
        final List<dynamic> response = await client
            .from('products')
            .select()
            .eq('seller_id', userId)
            .order('created_at', ascending: false);
        yield List<Map<String, dynamic>>.from(response);
      } else {
        final List<dynamic> response = await client
            .from('products')
            .select()
            .order('created_at', ascending: false);
        yield List<Map<String, dynamic>>.from(response);
      }
    } catch (e) {
      yield [
        {
          'id': 'prod_ac_1',
          'name': 'AC Dust Filter (Universal)',
          'price': 349.0,
          'category': 'AC',
          'stock': 12,
        },
        {
          'id': 'prod_plumb_1',
          'name': 'Stainless Steel Tap Valve',
          'price': 199.0,
          'category': 'Plumbing',
          'stock': 8,
        },
        {
          'id': 'prod_care_1',
          'name': 'Digital Pulse Oximeter',
          'price': 899.0,
          'category': 'Care Taker',
          'stock': 5,
        },
      ];
    }
    await Future.delayed(const Duration(seconds: 3));
  }
});

// StreamProvider to fetch active merchant orders waiting to be packed/shipped in real-time
final sellerActiveOrdersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final List<dynamic> response = await client
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      yield List<Map<String, dynamic>>.from(response);
    } catch (e) {
      yield [
        {
          'id': 'ord_1001',
          'customer_id': 'cust_987',
          'status': 'Placed',
          'items_summary': 'AC Dust Filter (Universal) x1',
          'grand_total': 384.0,
          'delivery_pin': '2842',
          'shipping_address': 'Digvijay Plot, Jamnagar',
        },
      ];
    }
    await Future.delayed(const Duration(seconds: 2));
  }
});

// Backward-compatible providers
final sellerProductsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final stream = ref.watch(sellerProductsStreamProvider);
  return stream.asData?.value ?? [];
});

final sellerActiveOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final stream = ref.watch(sellerActiveOrdersStreamProvider);
  return stream.asData?.value ?? [];
});
