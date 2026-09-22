import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/providers/location_provider.dart';

// Riverpod provider to fetch geofenced products with local Hive store fallbacks
final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final locationState = ref.watch(locationProvider);
  final client = Supabase.instance.client;

  // Read admin custom added products from Hive cache
  List<Map<String, dynamic>> localAdminProducts = [];
  try {
    if (Hive.isBoxOpen('customer_cache')) {
      final box = Hive.box('customer_cache');
      final rawList = box.get('admin_custom_products', defaultValue: <dynamic>[]) as List<dynamic>;
      localAdminProducts = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
  } catch (_) {}

  try {
    if (!locationState.isLoading && locationState.latitude != 0.0) {
      try {
        final List<dynamic> response = await client.rpc(
          'get_products_in_range',
          params: {
            'customer_lat': locationState.latitude,
            'customer_lng': locationState.longitude,
            'range_meters': 5000.0,
          },
        );
        if (response.isNotEmpty) {
          final dbList = List<Map<String, dynamic>>.from(response);
          return [...localAdminProducts, ...dbList];
        }
      } catch (_) {
        // Fallback to direct products table query if rpc is unavailable
      }
    }
    final List<dynamic> response = await client.from('products').select();
    if (response.isNotEmpty) {
      final dbList = List<Map<String, dynamic>>.from(response);
      return [...localAdminProducts, ...dbList];
    }
    return localAdminProducts;
  } catch (e) {
    return localAdminProducts;
  }
});
