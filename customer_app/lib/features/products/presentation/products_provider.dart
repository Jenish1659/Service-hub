import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/providers/location_provider.dart';

// Riverpod provider to fetch geofenced products
final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final locationState = ref.watch(locationProvider);
  final client = Supabase.instance.client;

  // If user location is fetched successfully, run the PostGIS RPC function for 5km geofencing
  if (!locationState.isLoading && locationState.latitude != 0.0) {
    try {
      final List<dynamic> response = await client.rpc(
        'get_products_in_range',
        params: {
          'customer_lat': locationState.latitude,
          'customer_lng': locationState.longitude,
          'range_meters': 5000.0, // 5 km strict geofencing
        },
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      // Fallback to standard fetch if RPC fails (e.g. if PostGIS is not fully loaded locally)
      final List<dynamic> response = await client
          .from('products')
          .select();
      return List<Map<String, dynamic>>.from(response);
    }
  } else {
    // If location is loading or not available, fetch all products
    final List<dynamic> response = await client
        .from('products')
        .select();
    return List<Map<String, dynamic>>.from(response);
  }
});
