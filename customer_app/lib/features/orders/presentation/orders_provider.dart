import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/auth_controller.dart';

// Filter state provider: 'All', 'Services', 'Products'
final orderFilterProvider = StateProvider<String>((ref) => 'All');

// Status filter state provider: 'All', 'Active', 'Completed', 'Cancelled'
final statusFilterProvider = StateProvider<String>((ref) => 'All');

// Search query provider for orders
final orderSearchQueryProvider = StateProvider<String>((ref) => '');

// Service class for managing orders and cancellations
class OrdersService {
  final SupabaseClient _client;

  OrdersService(this._client);

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        final List<String> list = List<String>.from(box.get('cancelled_order_ids', defaultValue: <dynamic>[]) as List<dynamic>);
        if (!list.contains(orderId)) {
          list.add(orderId);
          await box.put('cancelled_order_ids', list);
        }
      }

      await _client
          .from('orders')
          .update({'order_status': 'CANCELLED_BY_CUSTOMER'})
          .eq('order_id', orderId);
    } catch (_) {}
  }

  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        final List<String> list = List<String>.from(box.get('cancelled_booking_ids', defaultValue: <dynamic>[]) as List<dynamic>);
        if (!list.contains(bookingId)) {
          list.add(bookingId);
          await box.put('cancelled_booking_ids', list);
        }
      }

      await _client
          .from('service_bookings')
          .update({'status': 'CANCELLED_BY_CUSTOMER'})
          .eq('booking_id', bookingId);
    } catch (_) {}
  }
}

final ordersServiceProvider = Provider<OrdersService>((ref) {
  return OrdersService(Supabase.instance.client);
});

// Dynamic StreamProvider for Realtime Service Bookings (70-Table Schema)
final customerBookingsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final user = authState.value;
  final client = Supabase.instance.client;

  final controller = StreamController<List<Map<String, dynamic>>>();
  Timer? timer;

  Future<void> fetchBookings() async {
    if (controller.isClosed) return;

    List<String> cancelledIds = [];
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        cancelledIds = List<String>.from(box.get('cancelled_booking_ids', defaultValue: <dynamic>[]) as List<dynamic>);
      }
    } catch (_) {}

    List<Map<String, dynamic>> result = [];

    if (user != null) {
      try {
        final List<dynamic> response = await client
            .from('service_bookings')
            .select('*, services(*), user_addresses(*)')
            .eq('customer_id', user.id)
            .order('created_at', ascending: false);

        for (final item in response) {
          final service = item['services'] as Map<String, dynamic>?;
          final address = item['user_addresses'] as Map<String, dynamic>?;

          result.add({
            'id': item['booking_id'],
            'booking_code': item['booking_code'],
            'service_name': service?['name'] ?? 'Home Service',
            'status': item['status'] ?? 'PENDING',
            'scheduled_date': item['booking_date']?.toString() ?? '',
            'scheduled_time': item['scheduled_time']?.toString() ?? '',
            'problem_description': item['problem_description']?.toString() ?? '',
            'price': ((item['final_amount'] ?? item['estimated_amount']) as num?)?.toDouble() ?? 0.0,
            'completion_otp': (item['completion_otp']?.toString() ?? '').trim(),
            'entrance_pin': (item['entrance_pin']?.toString() ?? '').trim(),
            'address': address != null ? '${address['area']}, ${address['city']}' : '',
          });
        }
      } catch (_) {}
    }

    final mapped = result.map((b) {
      if (cancelledIds.contains(b['id'])) {
        return Map<String, dynamic>.from(b)..['status'] = 'CANCELLED_BY_CUSTOMER';
      }
      return b;
    }).toList();

    if (!controller.isClosed) {
      controller.add(mapped);
    }
  }

  fetchBookings();

  timer = Timer.periodic(const Duration(seconds: 15), (_) {
    fetchBookings();
  });

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});

// Dynamic StreamProvider for Realtime Product Orders (70-Table Schema)
final customerOrdersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final authState = ref.watch(authControllerProvider);
  final user = authState.value;
  final client = Supabase.instance.client;

  final controller = StreamController<List<Map<String, dynamic>>>();
  Timer? timer;

  Future<void> fetchOrders() async {
    if (controller.isClosed) return;

    List<String> cancelledIds = [];
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        cancelledIds = List<String>.from(box.get('cancelled_order_ids', defaultValue: <dynamic>[]) as List<dynamic>);
      }
    } catch (_) {}

    List<Map<String, dynamic>> result = [];

    if (user != null) {
      try {
        final List<dynamic> response = await client
            .from('orders')
            .select('*, order_items(*, products(*)), user_addresses(*)')
            .eq('customer_id', user.id)
            .order('created_at', ascending: false);

        for (final item in response) {
          final items = item['order_items'] as List<dynamic>? ?? [];
          final summary = items.isNotEmpty
              ? items.map((i) => '${i['products']?['product_name'] ?? "Item"} x${i['quantity']}').join(', ')
              : 'Product Order';
          final address = item['user_addresses'] as Map<String, dynamic>?;

          // Genuine delivery PIN or deterministically generated delivery PIN
          String deliveryPin = (item['delivery_pin'] ?? item['delivery_otp'] ?? item['otp'])?.toString() ?? '';
          if (deliveryPin.trim().isEmpty) {
            final orderCode = (item['order_code'] ?? item['order_id'] ?? '').toString();
            final numeric = orderCode.replaceAll(RegExp(r'[^0-9]'), '');
            if (numeric.length >= 4) {
              deliveryPin = numeric.substring(numeric.length - 4);
            } else if (orderCode.isNotEmpty) {
              final hash = orderCode.hashCode.abs();
              deliveryPin = (1000 + (hash % 9000)).toString();
            }
          }

          result.add({
            'id': item['order_id'],
            'order_code': item['order_code'],
            'status': item['order_status'] ?? 'Placed',
            'items_summary': summary,
            'subtotal': (item['subtotal'] as num?)?.toDouble() ?? 0.0,
            'delivery_fee': (item['delivery_charge'] as num?)?.toDouble() ?? 0.0,
            'grand_total': (item['total_amount'] as num?)?.toDouble() ?? 0.0,
            'payment_status': item['payment_status'] ?? 'PENDING',
            'delivery_pin': deliveryPin,
            'shipping_address': address != null ? '${address['area']}, ${address['city']}' : (item['shipping_address']?.toString() ?? ''),
          });
        }
      } catch (_) {}
    }

    final mapped = result.map((o) {
      if (cancelledIds.contains(o['id'])) {
        return Map<String, dynamic>.from(o)..['status'] = 'Cancelled';
      }
      return o;
    }).toList();

    if (!controller.isClosed) {
      controller.add(mapped);
    }
  }

  fetchOrders();

  timer = Timer.periodic(const Duration(seconds: 15), (_) {
    fetchOrders();
  });

  ref.onDispose(() {
    timer?.cancel();
    controller.close();
  });

  return controller.stream;
});

// Compatibility aliases for orders_screen.dart
final userBookingsProvider = customerBookingsStreamProvider;
final userOrdersProvider = customerOrdersStreamProvider;
final customerBookingsProvider = customerBookingsStreamProvider;
final customerOrdersProvider = customerOrdersStreamProvider;
