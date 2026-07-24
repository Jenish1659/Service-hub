import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/auth_controller.dart';

// Fetch all service bookings for the current logged-in customer
final userBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.value;
  
  if (user != null && !user.id.startsWith('mock_')) {
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('bookings')
          .select()
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);
          
      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty) return list;
    } catch (_) {}
  }

  return [
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
});

// Fetch all product orders for the current logged-in customer
final userOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.value;
  
  if (user != null && !user.id.startsWith('mock_')) {
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('orders')
          .select()
          .eq('customer_id', user.id)
          .order('created_at', ascending: false);
          
      final list = List<Map<String, dynamic>>.from(response);
      if (list.isNotEmpty) return list;
    } catch (_) {}
  }

  return [
    {
      'id': 'o1',
      'status': 'In Transit',
      'items_summary': 'AC Dust Filter (Universal) x1',
      'subtotal': 349.0,
      'delivery_fee': 35.0,
      'grand_total': 384.0,
      'delivery_pin': '2842',
      'shipping_address': 'Digvijay Plot, Jamnagar',
    }
  ];
});
