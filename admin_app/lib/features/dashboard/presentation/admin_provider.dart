import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Live statistics provider for the Admin dashboard Console
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final client = Supabase.instance.client;
  
  final partnersCountRes = await client.from('profiles').select('*', count: CountOption.exact).eq('role', 'partner');
  final customersCountRes = await client.from('profiles').select('*', count: CountOption.exact).eq('role', 'customer');
  
  final bookingsRes = await client.from('bookings').select('price');
  final ordersRes = await client.from('orders').select('grand_total');
  
  double totalRevenue = 0.0;
  for (var b in bookingsRes) {
    totalRevenue += (b['price'] as num?)?.toDouble() ?? 0.0;
  }
  for (var o in ordersRes) {
    totalRevenue += (o['grand_total'] as num?)?.toDouble() ?? 0.0;
  }
  
  return {
    'partnersCount': partnersCountRes.count ?? 0,
    'customersCount': customersCountRes.count ?? 0,
    'revenue': totalRevenue,
  };
});

// Fetch unverified/pending partners for KYC approvals
final adminUnverifiedPartnersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  final List<dynamic> response = await client
      .from('profiles')
      .select()
      .eq('role', 'partner')
      .eq('is_verified', false)
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

// Fetch live settlements ledger from completed bookings and orders
final adminSettlementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  
  final bookingsRes = await client
      .from('bookings')
      .select()
      .eq('status', 'Completed')
      .order('created_at', ascending: false);
      
  final ordersRes = await client
      .from('orders')
      .select()
      .eq('status', 'Delivered')
      .order('created_at', ascending: false);
      
  final List<Map<String, dynamic>> settlementsList = [];
  
  for (var b in bookingsRes) {
    settlementsList.add({
      'id': b['id'],
      'type': 'Booking',
      'partner': b['service_name'] ?? 'Home Service',
      'amount': (b['price'] as num?)?.toDouble() ?? 0.0,
      'commission': ((b['price'] as num?)?.toDouble() ?? 0.0) * 0.10,
      'status': (b['is_settled'] == true) ? 'Settled' : 'Pending Settlement',
      'date': b['scheduled_date'] ?? 'N/A',
    });
  }
  
  for (var o in ordersRes) {
    settlementsList.add({
      'id': o['id'],
      'type': 'Order',
      'partner': o['items_summary'] ?? 'Product Delivery',
      'amount': (o['grand_total'] as num?)?.toDouble() ?? 0.0,
      'commission': ((o['grand_total'] as num?)?.toDouble() ?? 0.0) * 0.10,
      'status': (o['is_settled'] == true) ? 'Settled' : 'Pending Settlement',
      'date': 'Today',
    });
  }
  
  return settlementsList;
});

// Fetch customer support tickets
final adminSupportTicketsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  final List<dynamic> response = await client
      .from('tickets')
      .select()
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});
