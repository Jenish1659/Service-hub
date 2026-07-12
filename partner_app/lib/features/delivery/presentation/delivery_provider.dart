import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Fetch orders ready to be picked up by delivery agents
final deliveryPendingJobsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final List<dynamic> response = await Supabase.instance.client
      .from('orders')
      .select()
      .eq('status', 'Ready for Pickup')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

// Fetch delivery jobs currently assigned to the logged-in agent
final deliveryAssignedJobProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return [];
  
  final List<dynamic> response = await Supabase.instance.client
      .from('orders')
      .select()
      .eq('agent_id', user.id)
      .eq('status', 'Out for Delivery')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});
