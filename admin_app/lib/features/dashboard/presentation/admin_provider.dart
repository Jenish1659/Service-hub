import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/live_booking_sync_service.dart';

// StreamProvider for Super Admin Dashboard Console KPI Metrics (70-Table Schema)
final adminStatsStreamProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final partnersRes = await client.from('partners').select('partner_id');
      final customersRes = await client.from('users').select('user_id, roles!inner(role_name)').eq('roles.role_name', 'customer');
      final bookingsRes = await client.from('service_bookings').select('estimated_amount, final_amount');
      final ordersRes = await client.from('orders').select('total_amount');
      final earningsRes = await client.from('partner_earnings').select('gross_amount, platform_fee');

      double totalRevenue = 0.0;
      double platformFee = 0.0;

      for (var b in bookingsRes) {
        totalRevenue += (b['final_amount'] as num?)?.toDouble() ?? (b['estimated_amount'] as num?)?.toDouble() ?? 0.0;
      }
      for (var o in ordersRes) {
        totalRevenue += (o['total_amount'] as num?)?.toDouble() ?? 0.0;
      }
      for (var e in earningsRes) {
        platformFee += (e['platform_fee'] as num?)?.toDouble() ?? 0.0;
      }

      yield {
        'partnersCount': partnersRes.length,
        'customersCount': customersRes.length,
        'revenue': totalRevenue,
        'platformCommission': platformFee > 0 ? platformFee : totalRevenue * 0.15,
      };
    } catch (_) {
      yield {
        'partnersCount': 0,
        'customersCount': 0,
        'revenue': 0.0,
        'platformCommission': 0.0,
      };
    }
    await Future.delayed(const Duration(seconds: 4));
  }
});

final adminStatsProvider = adminStatsStreamProvider;

// StreamProvider for Unverified/Pending Partners KYC Queue
final adminUnverifiedPartnersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    final List<Map<String, dynamic>> pendingList = [];
    final Set<String> seenIds = {};

    // 1. Fetch from Local Live Sync Service
    try {
      final localVerifications = LiveBookingSyncService.instance.getPendingPartnerVerifications();
      for (var item in localVerifications) {
        final id = (item['id'] ?? item['verification_id'] ?? '').toString();
        if (id.isNotEmpty && !seenIds.contains(id)) {
          seenIds.add(id);
          pendingList.add({
            'id': id,
            'verification_id': id,
            'user_id': item['user_id'] ?? id,
            'name': item['full_name'] ?? item['name'] ?? 'Partner',
            'full_name': item['full_name'] ?? item['name'] ?? 'Partner',
            'phone': item['phone'] ?? '',
            'email': item['email'] ?? 'partner@servicehub.com',
            'business_name': item['business_name'] ?? 'Service Provider',
            'category': item['category'] ?? 'ac_service',
            'category_name': item['category_name'] ?? 'AC Service Specialist',
            'city': item['city'] ?? 'Jamnagar',
            'state': item['state'] ?? 'Gujarat',
            'verification_type': item['category_name'] ?? item['category'] ?? 'AC Service Specialist',
            'status': item['status'] ?? 'PENDING',
            'ai_risk_score': item['ai_risk_score'] ?? 0.02,
            'trust_score': item['trust_score'] ?? 99.8,
            'ai_report': item['ai_report'] ?? {},
            'submitted_at': item['submitted_at'] ?? 'Recently',
          });
        }
      }
    } catch (_) {}

    // 2. Fetch from Supabase
    try {
      final List<dynamic> response = await client
          .from('verification_requests')
          .select('*, users(*, user_profiles(*))')
          .eq('status', 'PENDING')
          .order('submitted_at', ascending: false);

      for (var item in response) {
        final id = item['verification_id']?.toString() ?? '';
        if (id.isNotEmpty && !seenIds.contains(id)) {
          seenIds.add(id);
          final user = item['users'] as Map<String, dynamic>?;
          final profile = user?['user_profiles'] as Map<String, dynamic>?;
          final fullName = profile != null ? '${profile['first_name']} ${profile['last_name'] ?? ""}'.trim() : (user?['username'] ?? 'Partner');

          pendingList.add({
            'id': id,
            'user_id': item['user_id'],
            'full_name': fullName,
            'verification_type': item['verification_type'] ?? 'Service Provider',
            'status': item['status'],
            'submitted_at': item['submitted_at'],
          });
        }
      }
    } catch (_) {}

    yield pendingList;
    await Future.delayed(const Duration(seconds: 2));
  }
});

final adminUnverifiedPartnersProvider = adminUnverifiedPartnersStreamProvider;

// StreamProvider for Settlements & Earnings Ledger
final adminSettlementsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final earningsRes = await client
          .from('partner_earnings')
          .select('*, partners(*, users(*, user_profiles(*))), service_bookings(*, services(*))')
          .order('earned_at', ascending: false);

      final List<Map<String, dynamic>> settlementsList = [];

      for (var e in earningsRes) {
        final partner = e['partners'] as Map<String, dynamic>?;
        final user = partner?['users'] as Map<String, dynamic>?;
        final profile = user?['user_profiles'] as Map<String, dynamic>?;
        final partnerName = profile != null ? '${profile['first_name']} ${profile['last_name'] ?? ""}'.trim() : (user?['username'] ?? 'Partner');
        final booking = e['service_bookings'] as Map<String, dynamic>?;
        final service = booking?['services'] as Map<String, dynamic>?;

        settlementsList.add({
          'id': e['earning_id'],
          'type': 'Booking Earning',
          'partner': partnerName,
          'service': service?['name'] ?? 'AC Service & Repair',
          'gross_amount': e['gross_amount'],
          'platform_fee': e['platform_fee'],
          'net_amount': e['net_amount'],
          'status': e['earning_status'],
          'date': e['earned_at'],
        });
      }

      yield settlementsList;
    } catch (_) {
      yield [];
    }
    await Future.delayed(const Duration(seconds: 4));
  }
});

final adminSettlementsProvider = adminSettlementsStreamProvider;

// StreamProvider for Support Tickets
final adminSupportTicketsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final ticketsRes = await client
          .from('support_tickets')
          .select('*, users(*, user_profiles(*))')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> ticketList = [];
      for (var t in ticketsRes) {
        final user = t['users'] as Map<String, dynamic>?;
        final profile = user?['user_profiles'] as Map<String, dynamic>?;
        final userName = profile != null ? '${profile['first_name']} ${profile['last_name'] ?? ""}'.trim() : (user?['username'] ?? 'User');

        ticketList.add({
          'id': t['ticket_id'],
          'user_id': t['user_id'],
          'user_name': userName,
          'subject': t['subject'],
          'description': t['description'],
          'priority': t['priority'],
          'status': t['status'],
          'created_at': t['created_at'],
        });
      }

      yield ticketList;
    } catch (_) {
      yield [];
    }
    await Future.delayed(const Duration(seconds: 4));
  }
});

final adminSupportTicketsProvider = adminSupportTicketsStreamProvider;

// StreamProvider for Products
final adminProductsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final productsRes = await client
          .from('products')
          .select('*, shops(*), inventory(*)')
          .order('created_at', ascending: false);

      final List<Map<String, dynamic>> productList = [];
      for (var p in productsRes) {
        final shop = p['shops'] as Map<String, dynamic>?;
        final inv = p['inventory'] as Map<String, dynamic>?;

        productList.add({
          'id': p['product_id'],
          'product_name': p['product_name'],
          'shop_name': shop?['shop_name'] ?? 'Local Shop',
          'price': p['price'],
          'discount': p['discount'],
          'current_stock': inv?['current_stock'] ?? 10,
          'status': p['status'],
        });
      }

      yield productList;
    } catch (_) {
      yield [];
    }
    await Future.delayed(const Duration(seconds: 4));
  }
});

final adminProductsProvider = adminProductsStreamProvider;
