import 'package:flutter_riverpod/flutter_riverpod.dart';

class CartItem {
  final String id;
  final String name;
  final int price;
  final String category;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.category,
    this.quantity = 1,
  });
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier()
      : super([
          CartItem(
            id: 'prod_ac_1',
            name: 'AC Dust Filter (Universal)',
            price: 349,
            category: 'AC',
            quantity: 1,
          ),
        ]);

  void addItem(Map<String, dynamic> product) {
    final name = product['name'] ?? 'ServiceHub Product';
    final priceRaw = product['price']?.toString().replaceAll('₹', '') ?? '349';
    final price = int.tryParse(priceRaw) ?? 349;
    final category = product['category'] ?? 'General';
    final id = product['id']?.toString() ?? name;

    final existingIndex = state.indexWhere((item) => item.name == name);
    if (existingIndex >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            CartItem(
              id: state[i].id,
              name: state[i].name,
              price: state[i].price,
              category: state[i].category,
              quantity: state[i].quantity + 1,
            )
          else
            state[i],
      ];
    } else {
      state = [
        ...state,
        CartItem(id: id, name: name, price: price, category: category, quantity: 1),
      ];
    }
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
          ));
        }
      } else {
        updated.add(item);
      }
    }
    state = updated;
  }

  void clearCart() {
    state = [];
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
