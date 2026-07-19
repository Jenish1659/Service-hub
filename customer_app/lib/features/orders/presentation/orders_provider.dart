import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../auth/presentation/auth_controller.dart';

// Fetch all service bookings for the current logged-in customer
final userBookingsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.value;
  if (user == null) return [];
  
  if (user.id.startsWith('mock_')) {
    return [
      {
        'id': 'b1',
        'service_name': 'AC Deep Cleaning',
        'status': 'Scheduled',
        'booking_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'total_price': 450.0,
        'completion_otp': '1234',
        'provider_name': 'SuperClean Services',
        'provider_phone': '+91 98765 43210',
      },
      {
        'id': 'b2',
        'service_name': 'Emergency Pipe Leakage Repair',
        'status': 'Completed',
        'booking_date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        'total_price': 250.0,
        'completion_otp': '5678',
        'provider_name': 'FlowFix Plumbers',
        'provider_phone': '+91 87654 32109',
      }
    ];
  }

  try {
    final List<dynamic> response = await Supabase.instance.client
        .from('bookings')
        .select()
        .eq('customer_id', user.id)
        .order('created_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  } catch (_) {
    return [];
  }
});

// Fetch all product orders for the current logged-in customer
final userOrdersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.watch(authControllerProvider);
  final user = authState.value;
  if (user == null) return [];
  
  if (user.id.startsWith('mock_')) {
    return [
      {
        'id': 'o1',
        'status': 'In Transit',
        'items_summary': 'AC Dust Filter (Universal) x1',
        'subtotal': 349.0,
        'delivery_pin': '9988',
        'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      }
    ];
  }

  try {
    final List<dynamic> response = await Supabase.instance.client
        .from('orders')
        .select()
        .eq('customer_id', user.id)
        .order('created_at', ascending: false);
        
    return List<Map<String, dynamic>>.from(response);
  } catch (_) {
    return [];
  }
});
