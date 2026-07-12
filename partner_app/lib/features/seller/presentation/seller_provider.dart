import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Fetch products owned by this seller
final sellerProductsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  
  // Note: We can also default to seeding some items for the seller if they have none yet
  final List<dynamic> response = await Supabase.instance.client
      .from('products')
      .select()
      .eq('seller_id', user.id)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

// Fetch active product orders waiting to be packed/shipped
final sellerActiveOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final List<dynamic> response = await Supabase.instance.client
      .from('orders')
      .select()
      .neq('status', 'Delivered')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});
