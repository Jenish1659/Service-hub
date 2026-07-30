import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// StreamProvider to poll available delivery jobs in real time
final deliveryPendingJobsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final List<dynamic> response = await client
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      
      final pending = response.where((o) {
        final st = o['status'] ?? 'Placed';
        return st == 'Ready for Pickup' || st == 'Placed' || st == 'Packing';
      }).toList();

      yield List<Map<String, dynamic>>.from(pending);
    } catch (e) {
      yield [
        {
          'id': 'ord_1001',
          'customer_id': 'cust_987',
          'status': 'Ready for Pickup',
          'items_summary': 'AC Dust Filter (Universal) x1',
          'grand_total': 384.0,
          'delivery_fee': 35.0,
          'delivery_pin': '2842',
          'shipping_address': 'Digvijay Plot, Main Road, Jamnagar',
          'shop_address': 'ServiceHub Central Store, Jamnagar',
        },
      ];
    }
    await Future.delayed(const Duration(seconds: 2));
  }
});

// StreamProvider to poll jobs currently assigned to this delivery agent
final deliveryAssignedJobStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final user = client.auth.currentUser;
      final userId = user?.id;

      final List<dynamic> response = await client
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      final assigned = response.where((o) {
        final st = o['status'] ?? '';
        final agentId = o['agent_id'];
        return st == 'Out for Delivery' || (agentId != null && agentId == userId && st != 'Delivered');
      }).toList();

      yield List<Map<String, dynamic>>.from(assigned);
    } catch (e) {
      yield [];
    }
    await Future.delayed(const Duration(seconds: 2));
  }
});

// Backward compatible providers
final deliveryPendingJobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final stream = ref.watch(deliveryPendingJobsStreamProvider);
  return stream.asData?.value ?? [];
});

final deliveryAssignedJobProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final stream = ref.watch(deliveryAssignedJobStreamProvider);
  return stream.asData?.value ?? [];
});
