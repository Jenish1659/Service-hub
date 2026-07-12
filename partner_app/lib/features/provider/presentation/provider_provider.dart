import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Fetch all bookings that are currently waiting for acceptance ('Pending')
final providerPendingBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final List<dynamic> response = await Supabase.instance.client
      .from('bookings')
      .select()
      .eq('status', 'Pending')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});

// Fetch all ongoing bookings currently active for the provider ('En Route' or 'Started')
final providerActiveTasksProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final List<dynamic> response = await Supabase.instance.client
      .from('bookings')
      .select()
      .or('status.eq.En Route,status.eq.Started')
      .order('created_at', ascending: false);
  return List<Map<String, dynamic>>.from(response);
});
