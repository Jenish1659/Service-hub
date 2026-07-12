import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Riverpod provider to fetch available services from Supabase
final servicesProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  final List<dynamic> response = await client
      .from('services')
      .select()
      .order('price', ascending: true);
  return List<Map<String, dynamic>>.from(response);
});
