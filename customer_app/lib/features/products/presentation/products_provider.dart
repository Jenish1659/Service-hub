import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, dynamic> _normalizeProduct(Map<String, dynamic> raw) {
  final m = Map<String, dynamic>.from(raw);
  final id = (m['product_id'] ?? m['id'] ?? '').toString();
  final name = (m['product_name'] ?? m['name'] ?? m['title'] ?? 'Product').toString();
  final image = (m['image'] ?? m['image_url'] ?? '').toString();
  final price = (m['price'] as num?)?.toDouble() ?? 0.0;
  final mrp = (m['mrp'] as num?)?.toDouble() ?? (price > 0 ? price * 1.3 : 0.0);
  final sku = (m['sku'] ?? 'SKU-$id').toString();
  final shop = m['shops'] is Map ? m['shops'] as Map<String, dynamic> : null;
  final shopName = (shop?['shop_name'] ?? m['shop_name'] ?? 'ServiceHub Store').toString();
  final rawCategory = (shop?['shop_type'] ?? m['category'] ?? m['category_name'] ?? 'ac_parts').toString().toLowerCase();

  String normalizedCategory = 'ac_parts';
  if (rawCategory.contains('ac') || rawCategory.contains('air') || rawCategory.contains('cool')) {
    normalizedCategory = 'ac_parts';
  } else if (rawCategory.contains('car') || rawCategory.contains('auto')) {
    normalizedCategory = 'car_parts';
  } else if (rawCategory.contains('plumb') || rawCategory.contains('valve') || rawCategory.contains('pipe')) {
    normalizedCategory = 'plumbing';
  } else if (rawCategory.contains('cook') || rawCategory.contains('kitchen')) {
    normalizedCategory = 'cooking';
  } else if (rawCategory.contains('laundr') || rawCategory.contains('wash')) {
    normalizedCategory = 'laundry';
  } else if (rawCategory.contains('care') || rawCategory.contains('medic') || rawCategory.contains('health')) {
    normalizedCategory = 'care_taker';
  } else {
    normalizedCategory = rawCategory.replaceAll(' ', '_');
  }

  return {
    ...m,
    'id': id,
    'product_id': id,
    'name': name,
    'product_name': name,
    'title': name,
    'image': image,
    'image_url': image,
    'price': price,
    'mrp': mrp,
    'sku': sku,
    'shop_id': m['shop_id'],
    'shop_name': shopName,
    'category': normalizedCategory,
    'category_name': m['category_name'] ?? shopName,
    'stock': (m['stock'] ?? m['stock_quantity'] ?? 50),
    'description': m['description'] ?? '',
  };
}

// Riverpod provider to fetch live store products added by admin and synced across devices
final productsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final client = Supabase.instance.client;
  final Map<String, Map<String, dynamic>> productMap = {};

  // 1. Fetch from Supabase Cloud Database (Universal Master Catalog)
  try {
    final List<dynamic> response = await client
        .from('products')
        .select('*, shops(shop_name, shop_type)')
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 4));
    for (final item in response) {
      final normalized = _normalizeProduct(Map<String, dynamic>.from(item as Map));
      final id = normalized['id'].toString();
      if (id.isNotEmpty) productMap[id] = normalized;
    }
  } catch (e) {
    debugPrint('[ProductsProvider] Supabase products query: $e');
  }

  // 2. Fetch live products from Universal Sync Server (8088) with platform-aware host
  try {
    final host = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : '127.0.0.1';
    final res = await http
        .get(Uri.parse('http://$host:8088/api/products'))
        .timeout(const Duration(milliseconds: 1500));
    if (res.statusCode == 200) {
      final decoded = jsonDecode(res.body);
      if (decoded is List) {
        for (final item in decoded) {
          final normalized = _normalizeProduct(Map<String, dynamic>.from(item as Map));
          final id = normalized['id'].toString();
          if (id.isNotEmpty && !productMap.containsKey(id)) {
            productMap[id] = normalized;
          }
        }
      }
    }
  } catch (_) {}

  // 3. Direct Shared File IPC for Windows desktop offline sync
  if (!kIsWeb && Platform.isWindows) {
    try {
      const publicPath = r'C:\Users\Public\ServiceHub\service_hub_store_products.json';
      final file = File(publicPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is Map) {
          for (final entry in data.entries) {
            final normalized = _normalizeProduct(Map<String, dynamic>.from(entry.value as Map));
            final id = normalized['id'].toString();
            if (id.isNotEmpty && !productMap.containsKey(id)) {
              productMap[id] = normalized;
            }
          }
        } else if (data is List) {
          for (final item in data) {
            final normalized = _normalizeProduct(Map<String, dynamic>.from(item as Map));
            final id = normalized['id'].toString();
            if (id.isNotEmpty && !productMap.containsKey(id)) {
              productMap[id] = normalized;
            }
          }
        }
      }
    } catch (_) {}
  }

  // 4. Read admin custom added products from Hive cache
  try {
    if (Hive.isBoxOpen('customer_cache')) {
      final box = Hive.box('customer_cache');
      final rawList = box.get('admin_custom_products', defaultValue: <dynamic>[]) as List<dynamic>;
      for (final item in rawList) {
        final normalized = _normalizeProduct(Map<String, dynamic>.from(item as Map));
        final id = normalized['id'].toString();
        if (id.isNotEmpty && !productMap.containsKey(id)) {
          productMap[id] = normalized;
        }
      }
    }
  } catch (_) {}

  return productMap.values.toList();
});
