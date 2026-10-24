import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/providers/location_provider.dart';

// Riverpod provider to fetch live store products added by admin and synced across devices
final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final locationState = ref.watch(locationProvider);
  final client = Supabase.instance.client;

  final Map<String, Map<String, dynamic>> productMap = {};

  // 1. Fetch live products from Universal Sync Server (8088)
  try {
    final res = await http
        .get(Uri.parse('http://127.0.0.1:8088/api/products'))
        .timeout(const Duration(milliseconds: 1500));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        for (final item in decoded) {
          final m = Map<String, dynamic>.from(item as Map);
          final id = (m['id'] ?? m['product_id'] ?? '').toString();
          if (id.isNotEmpty) productMap[id] = m;
        }
      }
    }
  } catch (_) {}

  // 2. Direct Shared File IPC for 100% offline & local real sync
  try {
    const publicPath = r'C:\Users\Public\ServiceHub\service_hub_store_products.json';
    final file = File(publicPath);
    if (await file.exists()) {
      final content = await file.readAsString();
      final data = jsonDecode(content);
      if (data is Map) {
        for (final entry in data.entries) {
          final m = Map<String, dynamic>.from(entry.value as Map);
          final id = (m['id'] ?? m['product_id'] ?? entry.key).toString();
          if (id.isNotEmpty && !productMap.containsKey(id)) {
            productMap[id] = m;
          }
        }
      } else if (data is List) {
        for (final item in data) {
          final m = Map<String, dynamic>.from(item as Map);
          final id = (m['id'] ?? m['product_id'] ?? '').toString();
          if (id.isNotEmpty && !productMap.containsKey(id)) {
            productMap[id] = m;
          }
        }
      }
    }
  } catch (_) {}

  // 3. Read admin custom added products from Hive cache
  try {
    if (Hive.isBoxOpen('customer_cache')) {
      final box = Hive.box('customer_cache');
      final rawList = box.get('admin_custom_products', defaultValue: <dynamic>[]) as List<dynamic>;
      for (final item in rawList) {
        final m = Map<String, dynamic>.from(item as Map);
        final id = (m['id'] ?? m['product_id'] ?? '').toString();
        if (id.isNotEmpty && !productMap.containsKey(id)) {
          productMap[id] = m;
        }
      }
    }
  } catch (_) {}

  // 4. Supabase products table & RPC
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
          for (final item in response) {
            final m = Map<String, dynamic>.from(item as Map);
            final id = (m['id'] ?? m['product_id'] ?? '').toString();
            if (id.isNotEmpty && !productMap.containsKey(id)) {
              productMap[id] = m;
            }
          }
        }
      } catch (_) {}
    }

    final List<dynamic> response = await client.from('products').select();
    if (response.isNotEmpty) {
      for (final item in response) {
        final m = Map<String, dynamic>.from(item as Map);
        final id = (m['id'] ?? m['product_id'] ?? '').toString();
        if (id.isNotEmpty && !productMap.containsKey(id)) {
          productMap[id] = m;
        }
      }
    }
  } catch (_) {}

  return productMap.values.toList();
});
