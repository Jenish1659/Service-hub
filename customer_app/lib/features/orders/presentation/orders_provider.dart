import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import '../../auth/presentation/auth_controller.dart';

class OrdersService {
  final Ref _ref;
  OrdersService(this._ref);

  Future<bool> cancelOrder(String orderId, {String reason = 'Cancelled by customer'}) async {
    // 1. Local Cache persistence
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        final List<dynamic> cancelled = box.get('cancelled_order_ids', defaultValue: []) as List<dynamic>;
        final list = List<String>.from(cancelled);
        if (!list.contains(orderId)) {
          list.add(orderId);
          box.put('cancelled_order_ids', list);
        }
      }
    } catch (_) {}

    // 2. Remote Supabase update
    try {
      final client = Supabase.instance.client;
      await client
          .from('orders')
          .update({'status': 'Cancelled'})
          .eq('id', orderId);
    } catch (_) {}

    _ref.invalidate(userOrdersProvider);
    return true;
  }

  Future<bool> cancelBooking(String bookingId, {String reason = 'Cancelled by customer'}) async {
    // 1. Local Cache persistence
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        final List<dynamic> cancelled = box.get('cancelled_booking_ids', defaultValue: []) as List<dynamic>;
        final list = List<String>.from(cancelled);
        if (!list.contains(bookingId)) {
          list.add(bookingId);
          box.put('cancelled_booking_ids', list);
        }
      }
    } catch (_) {}

    // 2. Remote Supabase update
    try {
      final client = Supabase.instance.client;
      await client
          .from('bookings')
          .update({'status': 'CANCELLED_BY_CUSTOMER'})
          .eq('id', bookingId);
    } catch (_) {}

    _ref.invalidate(userBookingsProvider);
    return true;
  }
}

final ordersServiceProvider = Provider<OrdersService>((ref) {
  return OrdersService(ref);
});

// Fetch all service bookings for the current logged-in customer
final userBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.value;
  
  List<String> cancelledIds = [];
  try {
    if (Hive.isBoxOpen('customer_cache')) {
      final box = Hive.box('customer_cache');
      cancelledIds = List<String>.from(box.get('cancelled_booking_ids', defaultValue: []) as List<dynamic>);
    }
  } catch (_) {}

  List<Map<String, dynamic>> result = [];

  if (user != null && !user.id.startsWith('mock_')) {
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);
          
      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty) {
        result = list;
      }
    } catch (_) {}
  }

  if (result.isEmpty) {
    result = [
      {
        'id': 'b1',
        'service_name': 'AC Deep Cleaning & Repair',
        'status': 'En Route',
        'scheduled_date': 'Today',
        'scheduled_time': '06:30 PM',
        'issue_description': 'Filter replacement and cooling optimization',
        'price': 450.0,
        'completion_otp': '1234',
      },
      {
        'id': 'b2',
        'service_name': 'Emergency Pipe Leakage Repair',
        'status': 'Completed',
        'scheduled_date': 'Yesterday',
        'scheduled_time': '02:00 PM',
        'issue_description': 'Kitchen sink pipe repair',
        'price': 250.0,
        'completion_otp': '5678',
      }
    ];
  }

  return result.map((b) {
    if (cancelledIds.contains(b['id'])) {
      return Map<String, dynamic>.from(b)..['status'] = 'CANCELLED_BY_CUSTOMER';
    }
    return b;
  }).toList();
});

// Fetch all product orders for the current logged-in customer
final userOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.value;
  
  List<String> cancelledIds = [];
  try {
    if (Hive.isBoxOpen('customer_cache')) {
      final box = Hive.box('customer_cache');
      cancelledIds = List<String>.from(box.get('cancelled_order_ids', defaultValue: []) as List<dynamic>);
    }
  } catch (_) {}

  List<Map<String, dynamic>> result = [];

  if (user != null && !user.id.startsWith('mock_')) {
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);
          
      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty) {
        result = list;
      }
    } catch (_) {}
  }

  if (result.isEmpty) {
    result = [
      {
        'id': 'o1',
        'status': 'Placed',
        'items_summary': 'AC Dust Filter (Universal) x1',
        'subtotal': 349.0,
        'delivery_fee': 35.0,
        'grand_total': 384.0,
        'delivery_pin': '2842',
        'shipping_address': 'Digvijay Plot, Jamnagar',
      }
    ];
  }

  return result.map((o) {
    if (cancelledIds.contains(o['id'])) {
      return Map<String, dynamic>.from(o)..['status'] = 'Cancelled';
    }
    return o;
  }).toList();
});
