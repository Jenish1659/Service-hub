import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

class CartItem {
  final String id;
  final String name;
  final int price;
  final String category;
  int quantity;
  final String? shopId;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.quantity = 1,
    this.shopId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'category': category,
      'quantity': quantity,
      'shop_id': shopId,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'General',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      shopId: json['shop_id'] as String? ?? json['shopId'] as String?,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  static const String _cacheKey = 'saved_cart_items';

  CartNotifier() : super([]) {
    _loadCartFromCache();
  }

  void _loadCartFromCache() {
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        final raw = box.get(_cacheKey);
        if (raw is List) {
          final items = raw
              .whereType<Map>()
              .map((e) => CartItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
          state = items;
        }
      }
    } catch (_) {}
  }

  void _saveToCache(List<CartItem> items) {
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        final data = items.map((e) => e.toJson()).toList();
        box.put(_cacheKey, data);
      }
    } catch (_) {}
  }

  void addItem(Map<String, dynamic> product) {
    final name = product['name'] ?? 'ServiceHub Product';
    final priceRaw = product['price']?.toString().replaceAll('₹', '') ?? '349';
    final price = int.tryParse(priceRaw) ?? 349;
    final category = product['category'] ?? 'General';
    final id = product['id']?.toString() ?? name;
    final shopId = product['shop_id']?.toString() ?? product['shopId']?.toString();

    final existingIndex = state.indexWhere((item) => item.name == name);
    List<CartItem> updated;
    if (existingIndex >= 0) {
      updated = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            CartItem(
              id: state[i].id,
              name: state[i].name,
              price: state[i].price,
              category: state[i].category,
              quantity: state[i].quantity + 1,
              shopId: state[i].shopId ?? shopId,
            )
          else
            state[i],
      ];
    } else {
      updated = [
        ...state,
        CartItem(id: id, name: name, price: price, category: category, quantity: 1, shopId: shopId),
      ];
    }
    state = updated;
    _saveToCache(updated);
  }

  void updateQuantity(String name, int change) {
    final List<CartItem> updated = [];
    for (final item in state) {
      if (item.name == name) {
        final newQty = item.quantity + change;
        if (newQty > 0) {
          updated.add(CartItem(
            id: item.id,
            name: item.name,
            price: item.price,
            category: item.category,
            quantity: newQty,
            shopId: item.shopId,
          ));
        }
      } else {
        updated.add(item);
      }
    }
    state = updated;
    _saveToCache(updated);
  }

  void removeItem(String name) {
    final updated = state.where((item) => item.name != name).toList();
    state = updated;
    _saveToCache(updated);
  }

  void clearCart() {
    state = [];
    _saveToCache([]);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

final cartSubtotalProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + (item.price * item.quantity));
});

final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.fold(0, (sum, item) => sum + item.quantity);
});
