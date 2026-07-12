import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Fetch all service bookings for the current logged-in customer
final userBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  
  final List<dynamic> response = await Supabase.instance.client
      .from('bookings')
      .select()
      .eq('customer_id', user.id)
      .order('created_at', ascending: false);
      
  return List<Map<String, dynamic>>.from(response);
});

// Fetch all product orders for the current logged-in customer
final userOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  
  final List<dynamic> response = await Supabase.instance.client
      .from('orders')
      .select()
      .eq('customer_id', user.id)
      .order('created_at', ascending: false);
      
  return List<Map<String, dynamic>>.from(response);
});
