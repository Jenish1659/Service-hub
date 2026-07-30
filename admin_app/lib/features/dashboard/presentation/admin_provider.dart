import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// StreamProvider for Super Admin Dashboard Console KPI Metrics
final adminStatsStreamProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final partnersCountRes = await client.from('profiles').select('*').eq('role', 'partner');
      final customersCountRes = await client.from('profiles').select('*').eq('role', 'customer');
      final bookingsRes = await client.from('bookings').select('price');
      final ordersRes = await client.from('orders').select('grand_total');

      double totalRevenue = 0.0;
      for (var b in bookingsRes) {
        totalRevenue += (b['price'] as num?)?.toDouble() ?? 0.0;
      }
      for (var o in ordersRes) {
        totalRevenue += (o['grand_total'] as num?)?.toDouble() ?? 0.0;
      }

      yield {
        'partnersCount': partnersCountRes.length,
        'customersCount': customersCountRes.length,
        'revenue': totalRevenue,
        'platformCommission': totalRevenue * 0.10,
      };
    } catch (_) {
      yield {
        'partnersCount': 28,
        'customersCount': 142,
        'revenue': 42850.00,
        'platformCommission': 4285.00,
      };
    }
    await Future.delayed(const Duration(seconds: 3));
  }
});

// StreamProvider for Unverified/Pending Partners KYC Queue
final adminUnverifiedPartnersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final List<dynamic> response = await client
          .from('profiles')
          .select()
          .eq('role', 'partner')
          .eq('is_verified', false)
          .order('created_at', ascending: false);
      yield List<Map<String, dynamic>>.from(response);
    } catch (_) {
      yield [
        {
          'id': 'mock_p1',
          'full_name': 'Metro Plumbers Ltd',
          'role': 'partner',
          'is_verified': false,
          'category': 'Plumbing',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'id': 'mock_p2',
          'full_name': 'Jamnagar CareTaker Services',
          'role': 'partner',
          'is_verified': false,
          'category': 'Care Taker',
          'created_at': DateTime.now().toIso8601String(),
        },
      ];
    }
    await Future.delayed(const Duration(seconds: 3));
  }
});

// StreamProvider for Settlements Ledger
final adminSettlementsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final bookingsRes = await client
          .from('bookings')
          .select()
          .order('created_at', ascending: false);

      final ordersRes = await client
          .from('orders')
          .select()
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> settlementsList = [];

      for (var b in bookingsRes) {
        settlementsList.add({
          'id': b['id'],
          'type': 'Booking',
          'partner': b['service_name'] ?? 'Service Job',
          'amount': (b['price'] as num?)?.toDouble() ?? 0.0,
          'commission': ((b['price'] as num?)?.toDouble() ?? 0.0) * 0.10,
          'status': (b['status'] == 'Completed') ? 'Settled' : 'In Progress',
          'date': b['scheduled_date'] ?? 'Today',
        });
      }

      for (var o in ordersRes) {
        settlementsList.add({
          'id': o['id'],
          'type': 'Order',
          'partner': o['items_summary'] ?? 'Product Dispatch',
          'amount': (o['grand_total'] as num?)?.toDouble() ?? 0.0,
          'commission': ((o['grand_total'] as num?)?.toDouble() ?? 0.0) * 0.10,
          'status': (o['status'] == 'Delivered') ? 'Settled' : 'In Transit',
          'date': 'Today',
        });
      }

      yield settlementsList;
    } catch (_) {
      yield [
        {
          'id': 'mock_s1',
          'type': 'Booking',
          'partner': 'AC Repair - Rajesh Electricals',
          'amount': 1200.0,
          'commission': 120.0,
          'status': 'In Progress',
          'date': 'Today, 06:42 PM',
        },
        {
          'id': 'mock_s2',
          'type': 'Order',
          'partner': 'Jamnagar General Store',
          'amount': 450.0,
          'commission': 45.0,
          'status': 'Settled',
          'date': 'Yesterday',
        }
      ];
    }
    await Future.delayed(const Duration(seconds: 3));
  }
});

// StreamProvider for Support & Dispute Tickets
final adminSupportTicketsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final List<dynamic> response = await client
          .from('tickets')
          .select()
          .order('created_at', ascending: false);
      yield List<Map<String, dynamic>>.from(response);
    } catch (_) {
      yield [
        {
          'id': 'mock_t1',
          'customer_name': 'Jenish Bheda',
          'subject': 'Promo Code Discount',
          'description': 'Service visiting fee discount was not applied during AC booking.',
          'status': 'Open',
          'created_at': DateTime.now().toIso8601String(),
        },
      ];
    }
    await Future.delayed(const Duration(seconds: 3));
  }
});

// Backward compatible FutureProviders
final adminStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final stream = ref.watch(adminStatsStreamProvider);
  return stream.asData?.value ?? {'partnersCount': 28, 'customersCount': 142, 'revenue': 42850.00};
});

final adminUnverifiedPartnersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final stream = ref.watch(adminUnverifiedPartnersStreamProvider);
  return stream.asData?.value ?? [];
});

final adminSettlementsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final stream = ref.watch(adminSettlementsStreamProvider);
  return stream.asData?.value ?? [];
});

final adminSupportTicketsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final stream = ref.watch(adminSupportTicketsStreamProvider);
  return stream.asData?.value ?? [];
});
