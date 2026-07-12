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
