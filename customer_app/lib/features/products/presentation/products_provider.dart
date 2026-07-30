import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/providers/location_provider.dart';

final List<Map<String, dynamic>> defaultMarketplaceProducts = [
  {
    'id': 'prod_ac_1',
    'name': 'AC Dust Filter (Universal)',
    'price': 349,
    'original_price': 599,
    'discount': '41% OFF',
    'category': 'AC',
    'rating': 4.8,
  },
  {
    'id': 'prod_ac_2',
    'name': 'Copper Coil Cleaner Spray',
    'price': 299,
    'original_price': 450,
    'discount': '33% OFF',
    'category': 'AC',
    'rating': 4.9,
  },
  {
    'id': 'prod_plumb_1',
    'name': 'Stainless Steel Tap Valve',
    'price': 199,
    'original_price': 350,
    'discount': '43% OFF',
    'category': 'Plumbing',
    'rating': 4.7,
  },
  {
    'id': 'prod_plumb_2',
    'name': 'Waterproof Pipe Sealing Tape',
    'price': 99,
    'original_price': 150,
    'discount': '34% OFF',
    'category': 'Plumbing',
    'rating': 4.8,
  },
  {
    'id': 'prod_car_1',
    'name': 'Synthetic Engine Oil 1L',
    'price': 699,
    'original_price': 950,
    'discount': '26% OFF',
    'category': 'Car',
    'rating': 4.9,
  },
  {
    'id': 'prod_car_2',
    'name': 'All-Weather Wiper Blades',
    'price': 449,
    'original_price': 700,
    'discount': '35% OFF',
    'category': 'Car',
    'rating': 4.6,
  },
  {
    'id': 'prod_cook_1',
    'name': 'Cold Pressed Mustard Oil 1L',
    'price': 220,
    'original_price': 280,
    'discount': '21% OFF',
    'category': 'Cooking',
    'rating': 4.9,
  },
  {
    'id': 'prod_laundry_1',
    'name': 'Concentrated Fabric Softener',
    'price': 180,
    'original_price': 250,
    'discount': '28% OFF',
    'category': 'Laundry',
    'rating': 4.8,
  },
  {
    'id': 'prod_care_1',
    'name': 'Digital Pulse Oximeter',
    'price': 899,
    'original_price': 1499,
    'discount': '40% OFF',
    'category': 'Care Taker',
    'rating': 4.9,
  },
  {
    'id': 'prod_care_2',
    'name': 'Ergonomic Support Walking Cane',
    'price': 499,
    'original_price': 799,
    'discount': '37% OFF',
    'category': 'Care Taker',
    'rating': 4.8,
  },
];

// Riverpod provider to fetch geofenced products with local fallbacks
final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final locationState = ref.watch(locationProvider);
  final client = Supabase.instance.client;

  try {
    if (!locationState.isLoading && locationState.latitude != 0.0) {
      final List<dynamic> response = await client.rpc(
        'get_products_in_range',
        params: {
          'customer_lat': locationState.latitude,
          'customer_lng': locationState.longitude,
          'range_meters': 5000.0,
        },
      );
      if (response.isNotEmpty) {
        return List<Map<String, dynamic>>.from(response);
      }
    }
    final List<dynamic> response = await client.from('products').select();
    if (response.isNotEmpty) {
      return List<Map<String, dynamic>>.from(response);
    }
    return defaultMarketplaceProducts;
  } catch (e) {
    return defaultMarketplaceProducts;
  }
});
