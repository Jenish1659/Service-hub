import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Pure Dynamic Stats Stream Provider (100% Real Database Data)
final adminStatsStreamProvider = StreamProvider<Map<String, dynamic>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    int totalBookings = 0;
    int completedServices = 0;
    int ongoingServices = 0;
    int confirmedServices = 0;
    int cancelledServices = 0;
    int totalCustomers = 0;
    int totalPartners = 0;
    int underVerificationCount = 0;
    int activePartners = 0;
    double totalRevenue = 0.0;
    final Map<String, int> serviceBookingCounts = {};
    final Map<String, double> serviceRevenue = {};

    try {
      final bookingsRes = await client
          .from('bookings')
          .select('id, status, final_amount, estimated_amount, price, service_name');
      totalBookings = bookingsRes.length;

      for (var b in bookingsRes) {
        final status = (b['status'] ?? '').toString().toUpperCase();
        final amt = (b['final_amount'] as num?)?.toDouble() ??
            (b['estimated_amount'] as num?)?.toDouble() ??
            (b['price'] as num?)?.toDouble() ??
            0.0;
        totalRevenue += amt;

        if (status == 'COMPLETED' || status == 'SERVICE_COMPLETED' || status == 'DELIVERED') {
          completedServices++;
        } else if (status == 'ONGOING' || status == 'SERVICE_STARTED' || status == 'ASSIGNED' || status == 'PICKED_UP') {
          ongoingServices++;
        } else if (status == 'CONFIRMED' || status == 'ACCEPTED' || status == 'PENDING') {
          confirmedServices++;
        } else if (status == 'CANCELLED' || status == 'REJECTED') {
          cancelledServices++;
        }

        final sName = (b['service_name'] ?? 'General Service').toString();
        serviceBookingCounts[sName] = (serviceBookingCounts[sName] ?? 0) + 1;
        serviceRevenue[sName] = (serviceRevenue[sName] ?? 0.0) + amt;
      }
    } catch (_) {}

    try {
      final partnersRes = await client.from('partners').select('partner_id, verification_status');
      totalPartners = partnersRes.length;
      for (var p in partnersRes) {
        final st = (p['verification_status'] ?? '').toString().toUpperCase();
        if (st == 'VERIFIED' || st == 'APPROVED') {
          activePartners++;
        }
      }
    } catch (_) {}

    try {
      final verRes = await client
          .from('verification_requests')
          .select('verification_id, status')
          .or('status.eq.PENDING,status.eq.UNDER_REVIEW,status.eq.SUBMITTED,status.eq.IN_REVIEW');
      underVerificationCount = verRes.length;
    } catch (_) {}

    try {
      final customersRes = await client
          .from('users')
          .select('user_id, roles!inner(role_name)')
          .eq('roles.role_name', 'customer');
      totalCustomers = customersRes.length;
    } catch (_) {}

    yield {
      'totalBookings': totalBookings,
      'completedServices': completedServices,
      'ongoingServices': ongoingServices,
      'confirmedServices': confirmedServices,
      'cancelledServices': cancelledServices,
      'totalCustomers': totalCustomers,
      'totalPartners': totalPartners,
      'underVerificationCount': underVerificationCount,
      'activePartners': activePartners,
      'totalRevenue': totalRevenue,
      'serviceBookingCounts': serviceBookingCounts,
      'serviceRevenue': serviceRevenue,
    };

    await Future.delayed(const Duration(seconds: 2));
  }
});

final adminStatsProvider = adminStatsStreamProvider;

// Global persistent registry for pending partner verification requests
final Map<String, Map<String, dynamic>> _persistedPendingPartners = {};
final Set<String> _resolvedPartnerIds = {};

void markPartnerResolved(String id) {
  final cleanId = id.trim();
  if (cleanId.isNotEmpty) {
    _resolvedPartnerIds.add(cleanId);
    _persistedPendingPartners.remove(cleanId);
    _persistedPendingPartners.removeWhere((k, v) =>
        k == cleanId ||
        v['id'] == cleanId ||
        v['verification_id'] == cleanId ||
        v['user_id'] == cleanId ||
        v['partner_id'] == cleanId);
  }
}

// 2. Real-time Unverified / Pending Partners Provider (Multi-source with State Retention)
final adminUnverifiedPartnersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    // Pure Real-Time Cloud Supabase Verification Source
    // Discard any resolved partners from persistence
    _persistedPendingPartners.removeWhere((k, v) => _resolvedPartnerIds.contains(k));


    // Helper to parse KYC data from remarks
    String extractFromRemarks(String? remarks, String label) {
      if (remarks == null || remarks.isEmpty) return '';
      final match = RegExp('$label:\\s*([^|]+)').firstMatch(remarks);
      return match?.group(1)?.trim() ?? '';
    }

    // Prune recently resolved verification requests (APPROVED, VERIFIED, REJECTED)
    try {
      final resolvedRows = await client
          .from('verification_requests')
          .select('verification_id, user_id, status')
          .or('status.eq.APPROVED,status.eq.VERIFIED,status.eq.REJECTED')
          .order('reviewed_at', ascending: false)
          .limit(50);
      for (var r in resolvedRows) {
        final rId = r['verification_id']?.toString() ?? '';
        final rUid = r['user_id']?.toString() ?? '';
        if (rId.isNotEmpty) markPartnerResolved(rId);
        if (rUid.isNotEmpty) markPartnerResolved(rUid);
      }
    } catch (_) {}

    // Source C: Cloud Supabase (verification_requests with relationship disambiguation and resilient fallback)
    try {
      List<dynamic> response;
      try {
        response = await client
            .from('verification_requests')
            .select('*, users:users!verification_requests_user_id_fkey(*, user_profiles(*), roles(*), partners(*, shopkeeper_profiles(*), delivery_agent_profiles(*), service_provider_profiles(*)))')
            .or('status.eq.PENDING,status.eq.IN_REVIEW,status.eq.UNDER_REVIEW,status.eq.SUBMITTED')
            .order('submitted_at', ascending: false)
            .timeout(const Duration(milliseconds: 10000));
      } catch (joinErr) {
        debugPrint('Source C rich join error, falling back to basic join: $joinErr');
        try {
          response = await client
              .from('verification_requests')
              .select('*, users:users!verification_requests_user_id_fkey(*, user_profiles(*))')
              .or('status.eq.PENDING,status.eq.IN_REVIEW,status.eq.UNDER_REVIEW,status.eq.SUBMITTED')
              .order('submitted_at', ascending: false)
              .timeout(const Duration(milliseconds: 10000));
        } catch (_) {
          response = await client
              .from('verification_requests')
              .select('*')
              .or('status.eq.PENDING,status.eq.IN_REVIEW,status.eq.UNDER_REVIEW,status.eq.SUBMITTED')
              .order('submitted_at', ascending: false)
              .timeout(const Duration(milliseconds: 10000));
        }
      }

      for (var item in response) {
        final id = item['verification_id']?.toString() ?? '';
        final uId = item['user_id']?.toString() ?? '';
        if (id.isNotEmpty) {
          _resolvedPartnerIds.remove(id);
          if (uId.isNotEmpty) _resolvedPartnerIds.remove(uId);

          final user = item['users'] is Map ? item['users'] as Map<String, dynamic> : {};
          Map<String, dynamic> profile = {};
          if (user['user_profiles'] is Map) {
            profile = user['user_profiles'] as Map<String, dynamic>;
          } else if (user['user_profiles'] is List && (user['user_profiles'] as List).isNotEmpty) {
            profile = (user['user_profiles'] as List).first as Map<String, dynamic>;
          }
          final fName = (profile['first_name'] ?? '').toString();
          final lName = (profile['last_name'] ?? '').toString();
          final fullName = '$fName $lName'.trim();
          final remarks = item['remarks']?.toString() ?? '';

          final bNameFromRemarks = extractFromRemarks(remarks, 'Business').isNotEmpty
              ? extractFromRemarks(remarks, 'Business')
              : extractFromRemarks(remarks, 'ShopName');
          final phoneFromRemarks = extractFromRemarks(remarks, 'Phone');
          final cityFromRemarks = extractFromRemarks(remarks, 'City');
          final addrFromRemarks = extractFromRemarks(remarks, 'Address');

          final displayName = fullName.isNotEmpty
              ? fullName
              : (user['username'] ?? user['email'] ?? (bNameFromRemarks.isNotEmpty ? bNameFromRemarks : 'Partner Candidate')).toString();
          final realPhone = (user['phone'] ?? profile['phone'] ?? (phoneFromRemarks.isNotEmpty ? phoneFromRemarks : '')).toString();
          final realEmail = (user['email'] ?? '').toString();

          final aadhaar = (item['aadhaar_number'] ?? extractFromRemarks(remarks, 'Aadhaar')).toString();
          final pan = (item['pan_number'] ?? extractFromRemarks(remarks, 'PAN')).toString();
          final bank = (item['bank_name'] ?? extractFromRemarks(remarks, 'Bank')).toString();
          final acc = (item['account_number'] ?? extractFromRemarks(remarks, 'Acc')).toString();
          final ifsc = (item['ifsc_code'] ?? extractFromRemarks(remarks, 'IFSC')).toString();
          final holder = (item['account_holder_name'] ?? extractFromRemarks(remarks, 'Holder')).toString();

          final roleFromRemarks = extractFromRemarks(remarks, 'Role').toLowerCase();
          final catFromRemarks = extractFromRemarks(remarks, 'Category');
          final vTypeFromRemarks = extractFromRemarks(remarks, 'VehicleType');
          final vNoFromRemarks = extractFromRemarks(remarks, 'VehicleNo');
          final dlFromRemarks = extractFromRemarks(remarks, 'DL');

          // Extract database relational clues
          final rolesMap = user['roles'] is Map ? user['roles'] as Map<String, dynamic> : null;
          final dbRoleName = (rolesMap?['role_name'] ?? '').toString().toLowerCase();

          final partnerData = user['partners'] is Map
              ? user['partners'] as Map<String, dynamic>
              : (user['partners'] is List && (user['partners'] as List).isNotEmpty
                  ? (user['partners'] as List).first as Map<String, dynamic>
                  : null);

          final rawShop = partnerData?['shopkeeper_profiles'];
          final shopProfile = rawShop is Map
              ? rawShop as Map<String, dynamic>
              : (rawShop is List && rawShop.isNotEmpty
                  ? rawShop.first as Map<String, dynamic>
                  : null);

          final rawDelivery = partnerData?['delivery_agent_profiles'];
          final deliveryProfile = rawDelivery is Map
              ? rawDelivery as Map<String, dynamic>
              : (rawDelivery is List && rawDelivery.isNotEmpty
                  ? rawDelivery.first as Map<String, dynamic>
                  : null);

          final pId = partnerData?['partner_id']?.toString() ?? '';

          // Authoritative Role Resolution Priority:
          // 1. Database users.roles.role_name (Source of Truth)
          // 2. remarks 'Role: ...'
          // 3. verification_type / document_type
          // 4. Clues from category or remarks
          String parsedRole;
          if (dbRoleName == 'delivery_agent') {
            parsedRole = 'delivery_agent';
          } else if (dbRoleName == 'shopkeeper') {
            parsedRole = 'shopkeeper';
          } else if (dbRoleName == 'service_provider') {
            parsedRole = 'service_provider';
          } else if (roleFromRemarks == 'delivery_agent' || roleFromRemarks == 'delivery_partner' || roleFromRemarks.contains('rider')) {
            parsedRole = 'delivery_agent';
          } else if (roleFromRemarks == 'shopkeeper' || roleFromRemarks.contains('shop') || roleFromRemarks.contains('store')) {
            parsedRole = 'shopkeeper';
          } else if (roleFromRemarks == 'service_provider' || roleFromRemarks.contains('technician') || roleFromRemarks.contains('expert')) {
            parsedRole = 'service_provider';
          } else if (item['verification_type']?.toString().toUpperCase() == 'DRIVING_LICENSE' || item['document_type'] == 'DELIVERY_ONBOARDING' || (vTypeFromRemarks.isNotEmpty && vNoFromRemarks.isNotEmpty)) {
            parsedRole = 'delivery_agent';
          } else if (item['verification_type']?.toString().toUpperCase() == 'SHOP_LICENSE' || item['document_type'] == 'SHOPKEEPER_ONBOARDING') {
            parsedRole = 'shopkeeper';
          } else if (catFromRemarks.toLowerCase().contains('parts') || catFromRemarks.toLowerCase().contains('store') || catFromRemarks.toLowerCase().contains('shop') || catFromRemarks.toLowerCase().contains('grocery') || catFromRemarks.toLowerCase().contains('hardware')) {
            parsedRole = 'shopkeeper';
          } else if (shopProfile != null && deliveryProfile == null) {
            parsedRole = 'shopkeeper';
          } else if (deliveryProfile != null && shopProfile == null) {
            parsedRole = 'delivery_agent';
          } else {
            parsedRole = 'service_provider';
          }

          final isDelivery = parsedRole == 'delivery_agent';
          final isShop = parsedRole == 'shopkeeper';

          final parsedCategory = isDelivery
              ? 'delivery_agent'
              : (isShop ? (catFromRemarks.isNotEmpty ? catFromRemarks : 'shopkeeper') : (catFromRemarks.isNotEmpty ? catFromRemarks : 'ac_service'));
          final parsedCategoryName = isDelivery
              ? (vTypeFromRemarks.isNotEmpty ? 'Delivery Partner ($vTypeFromRemarks)' : 'Delivery Partner')
              : (isShop
                  ? (catFromRemarks.isNotEmpty ? 'Shopkeeper ($catFromRemarks)' : 'Shopkeeper (Store Vendor)')
                  : (item['category_name'] ?? 'AC Service Provider'));

          final dbShopBName = shopProfile?['business_name']?.toString() ?? '';
          final bName = dbShopBName.isNotEmpty
              ? dbShopBName
              : (item['business_name'] ?? (bNameFromRemarks.isNotEmpty ? bNameFromRemarks : '')).toString();
          final bAddr = (item['business_address'] ?? (addrFromRemarks.isNotEmpty ? addrFromRemarks : '')).toString();

          final vType = isDelivery ? (deliveryProfile?['vehicle_type']?.toString() ?? vTypeFromRemarks) : '';
          final vNo = isDelivery ? (deliveryProfile?['vehicle_number']?.toString() ?? vNoFromRemarks) : '';
          final dl = isDelivery ? (deliveryProfile?['driving_license_number']?.toString() ?? dlFromRemarks) : '';

          _persistedPendingPartners[id] = {
            'id': id,
            'verification_id': id,
            'user_id': uId,
            'partner_id': pId,
            'shop_id': isShop ? (shopProfile?['shopkeeper_id']?.toString() ?? '') : '',
            'delivery_agent_id': isDelivery ? (deliveryProfile?['delivery_agent_id']?.toString() ?? '') : '',
            'name': displayName,
            'full_name': displayName,
            'first_name': fName,
            'last_name': lName,
            'phone': realPhone,
            'email': realEmail,
            'business_name': bName.isNotEmpty ? bName : (isDelivery ? '$displayName Express Delivery' : (isShop ? '$displayName Store' : '$displayName Services')),
            'shop_name': bName.isNotEmpty ? bName : (isShop ? '$displayName Store' : ''),
            'business_address': bAddr,
            'address': bAddr,
            'category': parsedCategory,
            'category_name': parsedCategoryName,
            'role_name': parsedRole,
            'role': parsedRole,
            'vehicle_type': vType,
            'vehicle_number': vNo,
            'driving_license_number': dl,
            'city': profile['city'] ?? (cityFromRemarks.isNotEmpty ? cityFromRemarks : ''),
            'state': profile['state'] ?? 'Gujarat',
            'status': item['status'] ?? 'PENDING',
            'bank_name': bank,
            'account_number': acc,
            'ifsc_code': ifsc,
            'account_holder_name': holder.isNotEmpty ? holder : displayName,
            'aadhaar_number': aadhaar,
            'pan_number': pan,
            'ai_risk_score': (item['ai_risk_score'] as num?)?.toDouble() ?? 0.0,
            'trust_score': (item['trust_score'] as num?)?.toDouble() ?? 100.0,
            'ai_report': item['ai_report'] ?? {},
            'submitted_at': item['submitted_at'] ?? 'Recently',
            'document_type': isShop ? 'SHOPKEEPER_ONBOARDING' : (isDelivery ? 'DELIVERY_ONBOARDING' : 'PROVIDER_ONBOARDING'),
            'verification_type': item['verification_type'] ?? (isShop ? 'SHOP_LICENSE' : (isDelivery ? 'DRIVING_LICENSE' : 'AADHAAR')),
          };
        }
      }
    } catch (e) {
      debugPrint('Source C processing error: $e');
    }

    // Source D: Cloud Supabase (partners table directly with joined_at ordering and shopkeeper_profiles / delivery_agent_profiles)
    try {
      List<dynamic> partnerRes;
      try {
        partnerRes = await client
            .from('partners')
            .select('*, users(*, user_profiles(*)), shopkeeper_profiles(*), delivery_agent_profiles(*)')
            .or('verification_status.eq.PENDING,verification_status.eq.UNDER_REVIEW,verification_status.eq.SUBMITTED')
            .order('joined_at', ascending: false)
            .timeout(const Duration(milliseconds: 10000));
      } catch (joinErr) {
        debugPrint('Source D join error, falling back to direct partners query: $joinErr');
        partnerRes = await client
            .from('partners')
            .select('*')
            .or('verification_status.eq.PENDING,verification_status.eq.UNDER_REVIEW,verification_status.eq.SUBMITTED')
            .order('joined_at', ascending: false)
            .timeout(const Duration(milliseconds: 10000));
      }

      for (var p in partnerRes) {
        final pId = (p['partner_id'] ?? '').toString();
        final uId = (p['user_id'] ?? '').toString();
        final checkId = pId.isNotEmpty ? pId : uId;
        if (checkId.isNotEmpty) {
          _resolvedPartnerIds.remove(checkId);
          if (uId.isNotEmpty) _resolvedPartnerIds.remove(uId);

          final u = p['users'] is Map ? p['users'] as Map<String, dynamic> : {};
          Map<String, dynamic> prof = {};
          if (u['user_profiles'] is Map) {
            prof = u['user_profiles'] as Map<String, dynamic>;
          } else if (u['user_profiles'] is List && (u['user_profiles'] as List).isNotEmpty) {
            prof = (u['user_profiles'] as List).first as Map<String, dynamic>;
          }
          final fN = (prof['first_name'] ?? '').toString();
          final lN = (prof['last_name'] ?? '').toString();
          final full = '$fN $lN'.trim();
          final name = full.isNotEmpty ? full : (u['username'] ?? u['email'] ?? 'Partner Candidate').toString();
          
          final delivProf = (p['delivery_agent_profiles'] is List && (p['delivery_agent_profiles'] as List).isNotEmpty)
              ? (p['delivery_agent_profiles'] as List).first as Map<String, dynamic>
              : (p['delivery_agent_profiles'] is Map ? p['delivery_agent_profiles'] as Map<String, dynamic> : null);

          final isDelivery = delivProf != null ||
              (u['role_name'] ?? '').toString().toLowerCase().contains('delivery') ||
              (u['role_name'] ?? '').toString().toLowerCase().contains('rider') ||
              (p['category'] ?? '').toString().toLowerCase().contains('delivery');

          final shopProf = (p['shopkeeper_profiles'] is List && (p['shopkeeper_profiles'] as List).isNotEmpty)
              ? (p['shopkeeper_profiles'] as List).first as Map<String, dynamic>
              : (p['shopkeeper_profiles'] is Map ? p['shopkeeper_profiles'] as Map<String, dynamic> : null);

          final shopBName = (shopProf?['business_name'] ?? '').toString();
          final bName = shopBName.isNotEmpty ? shopBName : (p['business_name'] ?? '').toString();
          final userRoleId = (u['role_id'] ?? '').toString();
          final pCat = (p['category'] ?? '').toString().toLowerCase();
          final isExplicitProvider = (u['role_name'] ?? '').toString().toLowerCase().contains('service') ||
              (u['role_name'] ?? '').toString().toLowerCase().contains('provider') ||
              (u['role_name'] ?? '').toString().toLowerCase().contains('technician') ||
              pCat.contains('service') ||
              pCat.contains('ac_');

          final isShop = !isDelivery && !isExplicitProvider && (shopProf != null ||
              userRoleId == 'a96fc0d6-afd9-45a4-bab1-ee41363b033a' ||
              pCat.contains('shop') ||
              pCat.contains('store') ||
              pCat.contains('parts') ||
              pCat.contains('grocery') ||
              bName.toLowerCase().contains('store') ||
              bName.toLowerCase().contains('parts') ||
              bName.toLowerCase().contains('electronics') ||
              (u['role_name'] ?? '').toString().toLowerCase() == 'shopkeeper' ||
              (p['role'] ?? '').toString().toLowerCase() == 'shopkeeper');

          final cat = isDelivery ? 'delivery_agent' : (isShop ? (shopProf?['business_type'] ?? 'shopkeeper') : 'ac_service');
          final catName = isDelivery
              ? 'Delivery Partner (${delivProf?['vehicle_type'] ?? "Two Wheeler"})'
              : (isShop ? 'Shopkeeper (Store Vendor)' : 'AC Service Provider');
          final role = isDelivery ? 'delivery_agent' : (isShop ? 'shopkeeper' : 'service_provider');

          _persistedPendingPartners[checkId] = {
            'id': checkId,
            'verification_id': checkId,
            'partner_id': pId,
            'shop_id': shopProf?['shopkeeper_id']?.toString() ?? '',
            'user_id': uId,
            'name': name,
            'full_name': name,
            'first_name': fN,
            'last_name': lN,
            'phone': (u['phone'] ?? prof['phone'] ?? '').toString(),
            'email': (u['email'] ?? '').toString(),
            'business_name': bName.isNotEmpty ? bName : name,
            'shop_name': bName.isNotEmpty ? bName : (isShop ? name : ''),
            'category': cat,
            'category_name': catName,
            'role_name': role,
            'role': role,
            'vehicle_type': delivProf?['vehicle_type'] ?? '',
            'vehicle_number': delivProf?['vehicle_number'] ?? '',
            'driving_license_number': delivProf?['driving_license_number'] ?? '',
            'city': (prof['city'] ?? '').toString(),
            'state': (prof['state'] ?? '').toString(),
            'status': p['verification_status'] ?? 'PENDING',
            'submitted_at': p['joined_at'] ?? 'Recently',
            'trust_score': (p['trust_score'] as num?)?.toDouble() ?? 100.0,
            'ai_risk_score': (p['ai_risk_score'] as num?)?.toDouble() ?? 0.0,
            'document_type': isShop ? 'SHOPKEEPER_ONBOARDING' : (isDelivery ? 'DELIVERY_ONBOARDING' : 'SERVICE_ONBOARDING'),
            'verification_type': isShop ? 'SHOP_LICENSE' : (isDelivery ? 'DRIVING_LICENSE' : 'AADHAAR'),
          };
        }
      }
    } catch (e) {
      debugPrint('Source D processing error: $e');
    }

    // Source E: Cloud Supabase (Direct query on shopkeeper_profiles matching unverified partners)
    try {
      List<dynamic> shopProfiles;
      try {
        shopProfiles = await client
            .from('shopkeeper_profiles')
            .select('*, partners!inner(*, users(*, user_profiles(*)))')
            .timeout(const Duration(milliseconds: 10000));
      } catch (_) {
        shopProfiles = await client
            .from('shopkeeper_profiles')
            .select('*')
            .timeout(const Duration(milliseconds: 10000));
      }

      for (var sp in shopProfiles) {
        final partner = sp['partners'] is Map ? sp['partners'] as Map<String, dynamic> : null;
        String vStatus = '';
        String pId = (sp['partner_id'] ?? '').toString();
        String uId = '';
        Map<String, dynamic> partnerData = {};

        if (partner != null) {
          partnerData = partner;
          vStatus = (partner['verification_status'] ?? '').toString().toUpperCase();
          uId = (partner['user_id'] ?? '').toString();
        } else if (pId.isNotEmpty) {
          try {
            final pRes = await client.from('partners').select('*').eq('partner_id', pId).maybeSingle();
            if (pRes != null) {
              partnerData = pRes;
              vStatus = (pRes['verification_status'] ?? '').toString().toUpperCase();
              uId = (pRes['user_id'] ?? '').toString();
            }
          } catch (_) {}
        }

        if (vStatus.isEmpty || vStatus == 'PENDING' || vStatus == 'UNDER_REVIEW' || vStatus == 'SUBMITTED' || vStatus == 'PENDING_APPROVAL') {
          final checkId = pId.isNotEmpty ? pId : (uId.isNotEmpty ? uId : (sp['shopkeeper_id']?.toString() ?? ''));
          if (checkId.isNotEmpty) {
            _resolvedPartnerIds.remove(checkId);
            if (uId.isNotEmpty) _resolvedPartnerIds.remove(uId);

            final u = partnerData['users'] is Map ? partnerData['users'] as Map<String, dynamic> : {};
            Map<String, dynamic> prof = {};
            if (u['user_profiles'] is Map) {
              prof = u['user_profiles'] as Map<String, dynamic>;
            } else if (u['user_profiles'] is List && (u['user_profiles'] as List).isNotEmpty) {
              prof = (u['user_profiles'] as List).first as Map<String, dynamic>;
            }
            final fN = (prof['first_name'] ?? '').toString();
            final lN = (prof['last_name'] ?? '').toString();
            final full = '$fN $lN'.trim();
            final bName = (sp['business_name'] ?? partnerData['business_name'] ?? 'ServiceHub Store').toString();
            final name = full.isNotEmpty ? full : (u['username'] ?? u['email'] ?? bName).toString();
            final bType = (sp['business_type'] ?? 'ac_parts').toString();

            _persistedPendingPartners[checkId] = {
              'id': checkId,
              'verification_id': checkId,
              'partner_id': pId,
              'shop_id': sp['shopkeeper_id']?.toString() ?? '',
              'user_id': uId,
              'name': name,
              'full_name': name,
              'first_name': fN,
              'last_name': lN,
              'phone': (u['phone'] ?? prof['phone'] ?? '').toString(),
              'email': (u['email'] ?? '').toString(),
              'business_name': bName,
              'shop_name': bName,
              'category': bType,
              'category_name': 'Shopkeeper ($bType)',
              'role_name': 'shopkeeper',
              'role': 'shopkeeper',
              'city': (prof['city'] ?? '').toString(),
              'address': (prof['address'] ?? '').toString(),
              'business_address': (prof['address'] ?? '').toString(),
              'status': vStatus.isNotEmpty ? vStatus : 'PENDING',
              'submitted_at': sp['created_at'] ?? partnerData['joined_at'] ?? 'Recently',
              'trust_score': (partnerData['trust_score'] as num?)?.toDouble() ?? 100.0,
              'ai_risk_score': (partnerData['ai_risk_score'] as num?)?.toDouble() ?? 0.0,
              'document_type': 'SHOPKEEPER_ONBOARDING',
              'verification_type': 'SHOP_LICENSE',
            };
          }
        }
      }
    } catch (e) {
      debugPrint('Source E processing error: $e');
    }

    // Source F: Cloud Supabase delivery_agent_profiles directly
    try {
      List<dynamic> deliveryProfiles;
      try {
        deliveryProfiles = await client
            .from('delivery_agent_profiles')
            .select('*, partners!inner(*, users(*, user_profiles(*)))')
            .timeout(const Duration(milliseconds: 10000));
      } catch (_) {
        deliveryProfiles = await client
            .from('delivery_agent_profiles')
            .select('*')
            .timeout(const Duration(milliseconds: 10000));
      }

      for (var dp in deliveryProfiles) {
        final partner = dp['partners'] is Map ? dp['partners'] as Map<String, dynamic> : null;
        String vStatus = '';
        String pId = (dp['partner_id'] ?? '').toString();
        String uId = '';
        Map<String, dynamic> partnerData = {};

        if (partner != null) {
          partnerData = partner;
          vStatus = (partner['verification_status'] ?? '').toString().toUpperCase();
          uId = (partner['user_id'] ?? '').toString();
        } else if (pId.isNotEmpty) {
          try {
            final pRes = await client.from('partners').select('*').eq('partner_id', pId).maybeSingle();
            if (pRes != null) {
              partnerData = pRes;
              vStatus = (pRes['verification_status'] ?? '').toString().toUpperCase();
              uId = (pRes['user_id'] ?? '').toString();
            }
          } catch (_) {}
        }

        if (vStatus.isEmpty || vStatus == 'PENDING' || vStatus == 'UNDER_REVIEW' || vStatus == 'SUBMITTED' || vStatus == 'PENDING_APPROVAL') {
          final checkId = pId.isNotEmpty ? pId : (uId.isNotEmpty ? uId : (dp['delivery_agent_id']?.toString() ?? ''));
          if (checkId.isNotEmpty) {
            _resolvedPartnerIds.remove(checkId);
            if (uId.isNotEmpty) _resolvedPartnerIds.remove(uId);

            final u = partnerData['users'] is Map ? partnerData['users'] as Map<String, dynamic> : {};
            Map<String, dynamic> prof = {};
            if (u['user_profiles'] is Map) {
              prof = u['user_profiles'] as Map<String, dynamic>;
            } else if (u['user_profiles'] is List && (u['user_profiles'] as List).isNotEmpty) {
              prof = (u['user_profiles'] as List).first as Map<String, dynamic>;
            }
            final fN = (prof['first_name'] ?? '').toString();
            final lN = (prof['last_name'] ?? '').toString();
            final full = '$fN $lN'.trim();
            final name = full.isNotEmpty ? full : (u['username'] ?? u['email'] ?? 'Delivery Partner Candidate').toString();
            final vType = (dp['vehicle_type'] ?? 'Two Wheeler').toString();
            final vNum = (dp['vehicle_number'] ?? '').toString();
            final dl = (dp['driving_license_number'] ?? '').toString();

            _persistedPendingPartners[checkId] = {
              'id': checkId,
              'verification_id': checkId,
              'partner_id': pId,
              'delivery_agent_id': dp['delivery_agent_id']?.toString() ?? '',
              'user_id': uId,
              'name': name,
              'full_name': name,
              'first_name': fN,
              'last_name': lN,
              'phone': (u['phone'] ?? prof['phone'] ?? '').toString(),
              'email': (u['email'] ?? '').toString(),
              'business_name': name,
              'category': 'delivery_agent',
              'category_name': 'Delivery Partner ($vType)',
              'role_name': 'delivery_agent',
              'role': 'delivery_agent',
              'vehicle_type': vType,
              'vehicle_number': vNum,
              'driving_license_number': dl,
              'city': (prof['city'] ?? '').toString(),
              'address': (prof['address'] ?? '').toString(),
              'business_address': (prof['address'] ?? '').toString(),
              'status': vStatus.isNotEmpty ? vStatus : 'PENDING',
              'submitted_at': dp['created_at'] ?? partnerData['joined_at'] ?? 'Recently',
              'trust_score': (partnerData['trust_score'] as num?)?.toDouble() ?? 100.0,
              'ai_risk_score': (partnerData['ai_risk_score'] as num?)?.toDouble() ?? 0.0,
              'document_type': 'DELIVERY_ONBOARDING',
              'verification_type': 'DRIVING_LICENSE',
            };
          }
        }
      }
    } catch (_) {}

    // Source G: Cloud Supabase service_provider_profiles directly
    try {
      List<dynamic> provProfiles;
      try {
        provProfiles = await client
            .from('service_provider_profiles')
            .select('*, partners!inner(*, users(*, user_profiles(*)))')
            .timeout(const Duration(milliseconds: 10000));
      } catch (_) {
        provProfiles = await client
            .from('service_provider_profiles')
            .select('*')
            .timeout(const Duration(milliseconds: 10000));
      }

      for (var spp in provProfiles) {
        final partner = spp['partners'] is Map ? spp['partners'] as Map<String, dynamic> : null;
        String vStatus = '';
        String pId = (spp['partner_id'] ?? '').toString();
        String uId = '';
        Map<String, dynamic> partnerData = {};

        if (partner != null) {
          partnerData = partner;
          vStatus = (partner['verification_status'] ?? '').toString().toUpperCase();
          uId = (partner['user_id'] ?? '').toString();
        } else if (pId.isNotEmpty) {
          try {
            final pRes = await client.from('partners').select('*').eq('partner_id', pId).maybeSingle();
            if (pRes != null) {
              partnerData = pRes;
              vStatus = (pRes['verification_status'] ?? '').toString().toUpperCase();
              uId = (pRes['user_id'] ?? '').toString();
            }
          } catch (_) {}
        }

        if (vStatus.isEmpty || vStatus == 'PENDING' || vStatus == 'UNDER_REVIEW' || vStatus == 'SUBMITTED' || vStatus == 'PENDING_APPROVAL') {
          final checkId = pId.isNotEmpty ? pId : (uId.isNotEmpty ? uId : (spp['provider_id']?.toString() ?? ''));
          if (checkId.isNotEmpty) {
            _resolvedPartnerIds.remove(checkId);
            if (uId.isNotEmpty) _resolvedPartnerIds.remove(uId);

            final u = partnerData['users'] is Map ? partnerData['users'] as Map<String, dynamic> : {};
            Map<String, dynamic> prof = {};
            if (u['user_profiles'] is Map) {
              prof = u['user_profiles'] as Map<String, dynamic>;
            } else if (u['user_profiles'] is List && (u['user_profiles'] as List).isNotEmpty) {
              prof = (u['user_profiles'] as List).first as Map<String, dynamic>;
            }
            final fN = (prof['first_name'] ?? '').toString();
            final lN = (prof['last_name'] ?? '').toString();
            final full = '$fN $lN'.trim();
            final name = full.isNotEmpty ? full : (u['username'] ?? u['email'] ?? 'Service Specialist Candidate').toString();

            _persistedPendingPartners[checkId] = {
              'id': checkId,
              'verification_id': checkId,
              'partner_id': pId,
              'provider_id': spp['provider_id']?.toString() ?? '',
              'user_id': uId,
              'name': name,
              'full_name': name,
              'first_name': fN,
              'last_name': lN,
              'phone': (u['phone'] ?? prof['phone'] ?? '').toString(),
              'email': (u['email'] ?? '').toString(),
              'business_name': name,
              'category': 'ac_service',
              'category_name': 'AC Service Provider',
              'role_name': 'service_provider',
              'role': 'service_provider',
              'city': (prof['city'] ?? '').toString(),
              'address': (prof['address'] ?? '').toString(),
              'business_address': (prof['address'] ?? '').toString(),
              'status': vStatus.isNotEmpty ? vStatus : 'PENDING',
              'submitted_at': spp['created_at'] ?? partnerData['joined_at'] ?? 'Recently',
              'trust_score': (partnerData['trust_score'] as num?)?.toDouble() ?? 100.0,
              'ai_risk_score': (partnerData['ai_risk_score'] as num?)?.toDouble() ?? 0.0,
              'document_type': 'PROVIDER_ONBOARDING',
              'verification_type': 'AADHAAR',
            };
          }
        }
      }
    } catch (_) {}

    yield _persistedPendingPartners.values.toList();
    await Future.delayed(const Duration(milliseconds: 500));
  }
});

final adminUnverifiedPartnersProvider = adminUnverifiedPartnersStreamProvider;

// 3. Real-time All Partners (Pending + Verified) Provider (100% Real Supabase Data)
final adminAllPartnersStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final partnersRes = await client
          .from('partners')
          .select('*, users(*, user_profiles(*)), shopkeeper_profiles(*), delivery_agent_profiles(*), service_provider_profiles(*)')
          .order('joined_at', ascending: false)
          .timeout(const Duration(milliseconds: 3000));

      final List<Map<String, dynamic>> all = [];
      for (final p in partnersRes) {
        final u = p['users'] is Map ? p['users'] as Map<String, dynamic> : {};
        Map<String, dynamic> prof = {};
        if (u['user_profiles'] is Map) {
          prof = u['user_profiles'] as Map<String, dynamic>;
        } else if (u['user_profiles'] is List && (u['user_profiles'] as List).isNotEmpty) {
          prof = (u['user_profiles'] as List).first as Map<String, dynamic>;
        }
        final fN = (prof['first_name'] ?? '').toString();
        final lN = (prof['last_name'] ?? '').toString();
        final full = '$fN $lN'.trim();
        final name = full.isNotEmpty ? full : (u['username'] ?? u['email'] ?? 'Partner').toString();

        final shopProf = (p['shopkeeper_profiles'] is List && (p['shopkeeper_profiles'] as List).isNotEmpty)
            ? (p['shopkeeper_profiles'] as List).first as Map<String, dynamic>
            : (p['shopkeeper_profiles'] is Map ? p['shopkeeper_profiles'] as Map<String, dynamic> : null);

        final delivProf = (p['delivery_agent_profiles'] is List && (p['delivery_agent_profiles'] as List).isNotEmpty)
            ? (p['delivery_agent_profiles'] as List).first as Map<String, dynamic>
            : (p['delivery_agent_profiles'] is Map ? p['delivery_agent_profiles'] as Map<String, dynamic> : null);

        final provProf = (p['service_provider_profiles'] is List && (p['service_provider_profiles'] as List).isNotEmpty)
            ? (p['service_provider_profiles'] as List).first as Map<String, dynamic>
            : (p['service_provider_profiles'] is Map ? p['service_provider_profiles'] as Map<String, dynamic> : null);

        final isDelivery = delivProf != null || (p['category'] ?? '').toString().toLowerCase().contains('delivery');
        final isShop = !isDelivery && (shopProf != null || (p['category'] ?? '').toString().toLowerCase().contains('shop') || (p['category'] ?? '').toString().toLowerCase().contains('parts'));

        final role = isDelivery ? 'delivery_agent' : (isShop ? 'shopkeeper' : 'service_provider');
        final bName = (shopProf?['business_name'] ?? p['business_name'] ?? name).toString();

        all.add({
          'id': p['partner_id'],
          'partner_id': p['partner_id'],
          'user_id': p['user_id'],
          'shop_id': shopProf?['shopkeeper_id'],
          'delivery_agent_id': delivProf?['delivery_agent_id'],
          'provider_id': provProf?['provider_id'],
          'name': name,
          'full_name': name,
          'business_name': bName,
          'phone': (u['phone'] ?? prof['phone'] ?? '').toString(),
          'email': (u['email'] ?? '').toString(),
          'role': role,
          'role_name': role,
          'category': p['category'] ?? role,
          'category_name': isDelivery ? 'Delivery Partner' : (isShop ? 'Shopkeeper' : 'Service Provider'),
          'verification_status': p['verification_status'] ?? 'PENDING',
          'status': p['verification_status'] ?? 'PENDING',
          'availability_status': p['availability_status'] ?? 'OFFLINE',
          'joined_at': p['joined_at'],
          'city': (prof['city'] ?? '').toString(),
          'state': (prof['state'] ?? '').toString(),
        });
      }
      yield all;
    } catch (_) {
      yield <Map<String, dynamic>>[];
    }
    await Future.delayed(const Duration(seconds: 2));
  }
});

final adminAllPartnersProvider = adminAllPartnersStreamProvider;

// 4. Live All Bookings Stream Provider (100% Real Supabase Data)
final adminAllBookingsStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) async* {
  final client = Supabase.instance.client;

  while (true) {
    try {
      final supaList = await client
          .from('bookings')
          .select()
          .order('created_at', ascending: false)
          .timeout(const Duration(milliseconds: 3000));

      final List<Map<String, dynamic>> bookings = [];
      for (final sb in supaList) {
        bookings.add(Map<String, dynamic>.from(sb));
      }
      yield bookings;
    } catch (_) {
      yield <Map<String, dynamic>>[];
    }
    await Future.delayed(const Duration(seconds: 2));
  }
});

final adminAllBookingsProvider = adminAllBookingsStreamProvider;

