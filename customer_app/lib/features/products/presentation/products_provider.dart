import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/providers/location_provider.dart';

final List<Map<String, dynamic>> defaultMarketplaceProducts = [
  {
    'id': 'prod_ac_1',
    'name': 'AC Dust Filter (Universal)',
    'price': 349,
    'original_price': 599,
    'discount': '41% OFF',
    'category': 'AC Repair',
    'stock': 100,
    'rating': 4.8,
    'images': [
      'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1581094288338-2314dddb7ece?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?auto=format&fit=crop&w=800&q=80',
    ],
  },
  {
    'id': 'prod_ac_2',
    'name': 'Copper Coil Cleaner Spray',
    'price': 299,
    'original_price': 450,
    'discount': '33% OFF',
    'category': 'AC Repair',
    'stock': 8, // Demo: Only 8 left in stock!
    'rating': 4.9,
    'images': [
      'https://images.unsplash.com/photo-1581094288338-2314dddb7ece?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=800&q=80',
    ],
  },
  {
    'id': 'prod_plumb_1',
    'name': 'Stainless Steel Tap Valve',
    'price': 199,
    'original_price': 350,
    'discount': '43% OFF',
    'category': 'Plumbing',
    'stock': 100,
    'rating': 4.7,
    'images': [
      'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1504148455328-c376907d081c?auto=format&fit=crop&w=800&q=80',
    ],
  },
  {
    'id': 'prod_plumb_2',
    'name': 'Waterproof Pipe Sealing Tape',
    'price': 99,
    'original_price': 150,
    'discount': '34% OFF',
    'category': 'Plumbing',
    'stock': 5, // Demo: Only 5 left in stock!
    'rating': 4.8,
    'images': [
      'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?auto=format&fit=crop&w=800&q=80',
    ],
  },
  {
    'id': 'prod_car_1',
    'name': 'Synthetic Engine Oil 1L',
    'price': 699,
    'original_price': 950,
    'discount': '26% OFF',
    'category': 'Car Service',
    'stock': 100,
    'rating': 4.9,
    'images': [
      'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=800&q=80',
    ],
  },
  {
    'id': 'prod_car_2',
    'name': 'All-Weather Wiper Blades',
    'price': 449,
    'original_price': 700,
    'discount': '35% OFF',
    'category': 'Car Service',
    'stock': 100,
    'rating': 4.6,
    'images': [
      'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=800&q=80',
    ],
  },
  {
    'id': 'prod_cook_1',
    'name': 'Cold Pressed Mustard Oil 1L',
    'price': 220,
    'original_price': 280,
    'discount': '21% OFF',
    'category': 'Cooking',
    'stock': 100,
    'rating': 4.9,
    'images': [
      'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&w=800&q=80',
    ],
  },
  {
    'id': 'prod_laundry_1',
    'name': 'Concentrated Fabric Softener',
    'price': 180,
    'original_price': 250,
    'discount': '28% OFF',
    'category': 'Laundry',
    'stock': 100,
    'rating': 4.8,
    'images': [
      'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1517677208171-0bc6725a3e60?auto=format&fit=crop&w=800&q=80',
    ],
  },
  {
    'id': 'prod_care_1',
    'name': 'Digital Pulse Oximeter',
    'price': 899,
    'original_price': 1499,
    'discount': '40% OFF',
    'category': 'Care Taker',
    'stock': 100,
    'rating': 4.9,
    'images': [
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
    ],
  },
  {
    'id': 'prod_care_2',
    'name': 'Ergonomic Support Walking Cane',
    'price': 499,
    'original_price': 799,
    'discount': '37% OFF',
    'category': 'Care Taker',
    'stock': 100,
    'rating': 4.8,
    'images': [
      'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=800&q=80',
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=800&q=80',
    ],
  },
];

// Riverpod provider to fetch geofenced products with local Hive store fallbacks
final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final locationState = ref.watch(locationProvider);
  final client = Supabase.instance.client;

  // Read admin custom added products from Hive cache
  List<Map<String, dynamic>> localAdminProducts = [];
  try {
    final box = Hive.box('customer_cache');
    final rawList = box.get('admin_custom_products', defaultValue: <dynamic>[]) as List<dynamic>;
    localAdminProducts = rawList.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  } catch (_) {}

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
        final dbList = List<Map<String, dynamic>>.from(response);
        return [...localAdminProducts, ...dbList];
      }
    }
    final List<dynamic> response = await client.from('products').select();
    if (response.isNotEmpty) {
      final dbList = List<Map<String, dynamic>>.from(response);
      return [...localAdminProducts, ...dbList];
    }
    return [...localAdminProducts, ...defaultMarketplaceProducts];
  } catch (e) {
    return [...localAdminProducts, ...defaultMarketplaceProducts];
  }
});
