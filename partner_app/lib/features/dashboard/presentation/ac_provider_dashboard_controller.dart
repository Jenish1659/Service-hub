import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/services/routing_service.dart';
import '../../../../core/services/partner_location_service.dart';
import '../../../core/storage/local_registration_cache.dart';

class ACProviderDashboardState {
  final String partnerId;
  final String providerId;
  final String providerName;
  final String businessName;
  final String? avatarUrl;
  final String category;
  final String categoryName;
  final String verificationStatus;
  final bool isOnline;
  final int unreadNotificationsCount;
  final String timeframe;
  final bool isLoading;

  // Income Summary Metrics (Computed from partner_earnings table)
  final double todayIncome;
  final String todayIncomeTrend;
  final double monthlyIncome;
  final String monthlyIncomeTrend;
  final double totalIncome;
  final double avgIncomePerMonth;

  // Today's Work Overview (Computed from service_bookings & booking_requests)
  final int completedAcceptedJobsToday;
  final String completedJobsTrend;
  final int declinedJobsToday;
  final String declinedJobsTrend;

  // Business Overview Metrics (Computed from real bookings & profiles)
  final int totalJobsCompleted;
  final String totalJobsTrend;
  final int totalCustomers;
  final String totalCustomersTrend;
  final double customerRating;
  final String ratingTrend;
  final int repeatCustomers;
  final String repeatCustomersTrend;

  // Lists & Active AC Job
  final List<Map<String, dynamic>> todayCompletedJobs;
  final List<Map<String, dynamic>> incomingOffers;
  final List<Map<String, dynamic>> activeBookings;
  final Map<String, dynamic>? activeJob;

  int get newRequestsCount => incomingOffers.length;
  int get inProgressCount => activeBookings.length + (activeJob != null ? 1 : 0);
  int get completedTodayCount => todayCompletedJobs.length;
  int get cancelledTodayCount => declinedJobsToday;

  const ACProviderDashboardState({
    this.partnerId = '',
    this.providerId = '',
    this.providerName = 'Partner',
    this.businessName = 'AC Service Center',
    this.avatarUrl,
    this.category = 'ac_service',
    this.categoryName = 'AC Service Provider',
    this.verificationStatus = 'VERIFIED',
    this.isOnline = true,
    this.unreadNotificationsCount = 0,
    this.timeframe = 'Today',
    this.isLoading = false,
    this.todayIncome = 0.0,
    this.todayIncomeTrend = '↑ 0% vs yesterday',
    this.monthlyIncome = 0.0,
    this.monthlyIncomeTrend = '↑ 0% vs last month',
    this.totalIncome = 0.0,
    this.avgIncomePerMonth = 0.0,
    this.completedAcceptedJobsToday = 0,
    this.completedJobsTrend = '↑ 0% vs yesterday',
    this.declinedJobsToday = 0,
    this.declinedJobsTrend = '↑ 0% vs yesterday',
    this.totalJobsCompleted = 0,
    this.totalJobsTrend = '↑ 0% vs yesterday',
    this.totalCustomers = 0,
    this.totalCustomersTrend = '↑ 0% vs yesterday',
    this.customerRating = 0.0,
    this.ratingTrend = '↑ 0.0 vs yesterday',
    this.repeatCustomers = 0,
    this.repeatCustomersTrend = '↑ 0% vs yesterday',
    this.todayCompletedJobs = const [],
    this.incomingOffers = const [],
    this.activeBookings = const [],
    this.activeJob,
  });

  ACProviderDashboardState copyWith({
    String? partnerId,
    String? providerId,
    String? providerName,
    String? businessName,
    String? avatarUrl,
    String? category,
    String? categoryName,
    String? verificationStatus,
    bool? isOnline,
    int? unreadNotificationsCount,
    String? timeframe,
    bool? isLoading,
    double? todayIncome,
    String? todayIncomeTrend,
    double? monthlyIncome,
    String? monthlyIncomeTrend,
    double? totalIncome,
    double? avgIncomePerMonth,
    int? completedAcceptedJobsToday,
    String? completedJobsTrend,
    int? declinedJobsToday,
    String? declinedJobsTrend,
    int? totalJobsCompleted,
    String? totalJobsTrend,
    int? totalCustomers,
    String? totalCustomersTrend,
    double? customerRating,
    String? ratingTrend,
    int? repeatCustomers,
    String? repeatCustomersTrend,
    List<Map<String, dynamic>>? todayCompletedJobs,
    List<Map<String, dynamic>>? incomingOffers,
    List<Map<String, dynamic>>? activeBookings,
    Map<String, dynamic>? activeJob,
    bool clearActiveJob = false,
  }) {
    return ACProviderDashboardState(
      partnerId: partnerId ?? this.partnerId,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      businessName: businessName ?? this.businessName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      category: category ?? this.category,
      categoryName: categoryName ?? this.categoryName,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isOnline: isOnline ?? this.isOnline,
      unreadNotificationsCount: unreadNotificationsCount ?? this.unreadNotificationsCount,
      timeframe: timeframe ?? this.timeframe,
      isLoading: isLoading ?? this.isLoading,
      todayIncome: todayIncome ?? this.todayIncome,
      todayIncomeTrend: todayIncomeTrend ?? this.todayIncomeTrend,
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      monthlyIncomeTrend: monthlyIncomeTrend ?? this.monthlyIncomeTrend,
      totalIncome: totalIncome ?? this.totalIncome,
      avgIncomePerMonth: avgIncomePerMonth ?? this.avgIncomePerMonth,
      completedAcceptedJobsToday: completedAcceptedJobsToday ?? this.completedAcceptedJobsToday,
      completedJobsTrend: completedJobsTrend ?? this.completedJobsTrend,
      declinedJobsToday: declinedJobsToday ?? this.declinedJobsToday,
      declinedJobsTrend: declinedJobsTrend ?? this.declinedJobsTrend,
      totalJobsCompleted: totalJobsCompleted ?? this.totalJobsCompleted,
      totalJobsTrend: totalJobsTrend ?? this.totalJobsTrend,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      totalCustomersTrend: totalCustomersTrend ?? this.totalCustomersTrend,
      customerRating: customerRating ?? this.customerRating,
      ratingTrend: ratingTrend ?? this.ratingTrend,
      repeatCustomers: repeatCustomers ?? this.repeatCustomers,
      repeatCustomersTrend: repeatCustomersTrend ?? this.repeatCustomersTrend,
      todayCompletedJobs: todayCompletedJobs ?? this.todayCompletedJobs,
      incomingOffers: incomingOffers ?? this.incomingOffers,
      activeBookings: activeBookings ?? this.activeBookings,
      activeJob: clearActiveJob ? null : (activeJob ?? this.activeJob),
    );
  }
}

class ACProviderDashboardNotifier extends StateNotifier<ACProviderDashboardState> {
  RealtimeChannel? _requestsChannel;
  RealtimeChannel? _earningsChannel;

  ACProviderDashboardNotifier() : super(const ACProviderDashboardState()) {
    initDashboard();
  }

  static Map<String, dynamic>? _asMap(dynamic val) {
    if (val is Map<String, dynamic>) return val;
    if (val is Map) return Map<String, dynamic>.from(val);
    if (val is List && val.isNotEmpty) {
      final first = val.first;
      if (first is Map<String, dynamic>) return first;
      if (first is Map) return Map<String, dynamic>.from(first);
    }
    return null;
  }

  Future<void> initDashboard() async {
    state = state.copyWith(isLoading: true);
    await _loadPartnerProfile();
    await _loadLiveBookingsAndMetrics();
    _subscribeRealtimeChanges();
  }

  Future<void> refresh() async => initDashboard();

  Future<void> _loadPartnerProfile() async {
    final activePartner = await LocalRegistrationCache.getActivePartner('service_provider') ??
        await LocalRegistrationCache.getActiveServiceProvider();
    if (activePartner != null) {
      final name = (activePartner['name'] ?? activePartner['firstName'] ?? 'Partner').toString();
      final business = (activePartner['business_name'] ?? '$name AC Service Center').toString();
      final category = (activePartner['category'] ?? 'ac_service').toString();
      final categoryName = (activePartner['category_name'] ?? 'AC Service Provider').toString();
      final verification = (activePartner['verification_status'] ?? 'VERIFIED').toString();
      final isOnline = activePartner['is_online'] as bool? ?? true;
      final photo = (activePartner['profile_photo'] ?? activePartner['profile_image'] ?? activePartner['avatarUrl'])?.toString();

      state = state.copyWith(
        partnerId: activePartner['partner_id'] ?? activePartner['id'] ?? '',
        providerId: activePartner['provider_id'] ?? '',
        providerName: name,
        businessName: business,
        avatarUrl: photo,
        category: category,
        categoryName: categoryName,
        verificationStatus: verification,
        isOnline: isOnline,
      );

      // Verify fresh status from Supabase
      if (state.partnerId.isNotEmpty) {
        try {
          final pSync = await Supabase.instance.client
              .from('partners')
              .select('availability_status, verification_status')
              .eq('partner_id', state.partnerId)
              .maybeSingle();
          if (pSync != null) {
            final freshOnline = (pSync['availability_status'] ?? '').toString().toUpperCase() == 'ONLINE';
            final freshVer = (pSync['verification_status'] ?? verification).toString();
            state = state.copyWith(isOnline: freshOnline, verificationStatus: freshVer);
          }
        } catch (_) {}
      }

      if (state.isOnline && (state.partnerId.isNotEmpty)) {
        PartnerLocationService.instance.startLiveLocationTracking(partnerId: state.partnerId);
      }
    }

    // Direct Database Resolution: Resolve authenticated partner from Supabase if cache was empty
    if (state.partnerId.isEmpty) {
      try {
        final supabase = Supabase.instance.client;
        final authUser = supabase.auth.currentUser;
        if (authUser != null) {
          final res = await supabase
              .from('partners')
              .select('partner_id, partner_code, verification_status, availability_status, users(user_id, username, phone, user_profiles(first_name, last_name, profile_photo)), service_provider_profiles(provider_id)')
              .eq('user_id', authUser.id)
              .maybeSingle();

          if (res != null) {
            final u = _asMap(res['users']);
            final prof = _asMap(u?['user_profiles']);
            final spp = _asMap(res['service_provider_profiles']);
            final pName = '${prof?['first_name'] ?? ""} ${prof?['last_name'] ?? ""}'.trim();
            final photo = prof?['profile_photo']?.toString();

            final resolvedPartnerId = res['partner_id']?.toString() ?? '';
            String resolvedProviderId = spp?['provider_id']?.toString() ?? '';

            if (resolvedProviderId.isEmpty && resolvedPartnerId.isNotEmpty) {
              try {
                final spRes = await supabase
                    .from('service_provider_profiles')
                    .select('provider_id')
                    .eq('partner_id', resolvedPartnerId)
                    .maybeSingle();
                if (spRes != null && spRes['provider_id'] != null) {
                  resolvedProviderId = spRes['provider_id'].toString();
                }
              } catch (_) {}
            }

            state = state.copyWith(
              partnerId: resolvedPartnerId,
              providerId: resolvedProviderId,
              providerName: pName.isNotEmpty ? pName : (u?['username'] ?? 'Service Provider').toString(),
              businessName: '${pName.isNotEmpty ? pName : "AC"} Service Center',
              avatarUrl: photo,
              category: 'ac_service',
              categoryName: 'AC Service Provider',
              verificationStatus: res['verification_status']?.toString() ?? 'PENDING',
              isOnline: (res['availability_status'] ?? '').toString().toUpperCase() == 'ONLINE',
            );

            if (resolvedPartnerId.isNotEmpty && state.isOnline) {
              PartnerLocationService.instance.startLiveLocationTracking(partnerId: resolvedPartnerId);
            }
          }
        }
      } catch (_) {}
    }

    // Direct Database Fallback: Resolve active online AC partner from Supabase if still empty
    if (state.partnerId.isEmpty) {
      try {
        final supabase = Supabase.instance.client;
        final res = await supabase
            .from('partners')
            .select('partner_id, partner_code, verification_status, availability_status, users(user_id, username, phone, user_profiles(first_name, last_name, profile_photo)), service_provider_profiles(provider_id, about)')
            .eq('verification_status', 'VERIFIED')
            .eq('availability_status', 'ONLINE')
            .limit(10);
        for (final row in res) {
          final sppList = row['service_provider_profiles'];
          dynamic spp = sppList is List && sppList.isNotEmpty ? sppList.first : (sppList is Map ? sppList : null);
          final about = (spp?['about'] ?? '').toString().toLowerCase();
          final isAc = (about.contains('ac') || about.contains('air conditioning') || about.contains('hvac') || about.contains('cooling')) && !about.contains('car');
          if (isAc) {
            final u = _asMap(row['users']);
            final prof = _asMap(u?['user_profiles']);
            final pName = '${prof?['first_name'] ?? ""} ${prof?['last_name'] ?? ""}'.trim();
            final resolvedPartnerId = row['partner_id']?.toString() ?? '';
            final resolvedProviderId = spp?['provider_id']?.toString() ?? '';
            state = state.copyWith(
              partnerId: resolvedPartnerId,
              providerId: resolvedProviderId,
              providerName: pName.isNotEmpty ? pName : (u?['username'] ?? 'AC Service Partner').toString(),
              businessName: '${pName.isNotEmpty ? pName : "AC"} Service Center',
              avatarUrl: prof?['profile_photo']?.toString(),
              category: 'ac_service',
              categoryName: 'AC Service Provider',
              verificationStatus: 'VERIFIED',
              isOnline: true,
            );
            if (resolvedPartnerId.isNotEmpty) {
              PartnerLocationService.instance.startLiveLocationTracking(partnerId: resolvedPartnerId);
            }
            break;
          }
        }
      } catch (_) {}
    }
  }

  Future<void> _loadLiveBookingsAndMetrics() async {
    try {
      final supabase = Supabase.instance.client;
      final partnerId = state.partnerId;

      // 1. Calculate Real Income from partner_earnings table
      double todayEarned = 0.0;
      double monthEarned = 0.0;
      double totalEarned = 0.0;

      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final monthStr = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      if (partnerId.isNotEmpty) {
        try {
          final earningsRes = await supabase
              .from('partner_earnings')
              .select()
              .eq('partner_id', partnerId);

          for (final earn in earningsRes) {
            final net = (earn['net_amount'] as num?)?.toDouble() ?? (earn['gross_amount'] as num?)?.toDouble() ?? 0.0;
            totalEarned += net;

            final earnedAt = earn['earned_at']?.toString() ?? '';
            if (earnedAt.startsWith(todayStr)) {
              todayEarned += net;
            }
            if (earnedAt.startsWith(monthStr)) {
              monthEarned += net;
            }
          }
        } catch (_) {}
      }

      // 2. Fetch live pending booking_requests AND direct bookings for AC Service
      final List<Map<String, dynamic>> offersList = [];
      final Set<String> seenBookingIds = {};

      try {
        // A. From booking_requests
        List<dynamic> requestsRes = [];
        try {
          requestsRes = await supabase
              .from('booking_requests')
              .select('*, service_bookings(*, services(service_id, name, category_id), user_addresses(area, city, latitude, longitude))')
              .eq('response_status', 'Pending')
              .order('sent_at', ascending: false);
        } catch (_) {
          try {
            requestsRes = await supabase
                .from('booking_requests')
                .select('*, service_bookings(*)')
                .eq('response_status', 'Pending')
                .order('sent_at', ascending: false);
          } catch (_) {}
        }

        for (final req in requestsRes) {
          final reqPartner = (req['partner_id'] ?? '').toString();
          final reqProvider = (req['provider_id'] ?? '').toString();
          final isForThisPartner = (state.partnerId.isNotEmpty && (reqPartner == state.partnerId || reqProvider == state.partnerId)) ||
              (state.providerId.isNotEmpty && (reqProvider == state.providerId || reqPartner == state.providerId));
          if (!isForThisPartner) {
            continue; // Strictly addressed to this partner only
          }
          final booking = _asMap(req['service_bookings']);
          if (booking != null) {
            final bStatus = (booking['status'] ?? '').toString().toUpperCase();
            final bPartner = (booking['partner_id'] ?? '').toString();
            final bId = booking['booking_id']?.toString() ?? '';
            if (bPartner.isNotEmpty) continue; // Any assigned partner means not pending
            if (bStatus == 'ACCEPTED' || bStatus == 'CONFIRMED' || bStatus == 'ASSIGNED' || bStatus == 'IN_PROGRESS' || bStatus == 'ON_THE_WAY' || bStatus == 'ARRIVED' || bStatus == 'SERVICE_STARTED' || bStatus == 'SERVICE_COMPLETED' || bStatus == 'CLOSED' || bStatus.contains('CANCEL')) continue;
            if (bId.isNotEmpty && !seenBookingIds.contains(bId) && !LiveBookingSyncService.instance.isBookingAccepted(bId)) {
              seenBookingIds.add(bId);
              final service = _asMap(booking['services']);
              final address = _asMap(booking['user_addresses']);
              final user = _asMap(booking['users']);
              final profile = _asMap(user?['user_profiles']);

              final lat = (booking['customer_latitude'] as num?)?.toDouble() ??
                  (address?['latitude'] as num?)?.toDouble() ?? 22.4707;
              final lng = (booking['customer_longitude'] as num?)?.toDouble() ??
                  (address?['longitude'] as num?)?.toDouble() ?? 70.0577;

              final distKm = OsrmRoutingService.computeHaversineDistanceKm(22.4707, 70.0650, lat, lng) * 1.35;
              final etaMin = (distKm / 25.0 * 60.0).round().clamp(5, 45);

              offersList.add({
                'request_id': req['request_id'],
                'booking_id': bId,
                'service_name': booking['service_name'] ?? service?['name'] ?? 'Professional Service',
                'price': (booking['estimated_amount'] as num?)?.toDouble() ?? (booking['final_amount'] as num?)?.toDouble() ?? 499.0,
                'customer_name': profile != null ? '${profile['first_name'] ?? ""} ${profile['last_name'] ?? ""}'.trim() : (user?['username'] ?? 'Customer').toString(),
                'customer_phone': (user?['phone'] ?? '').toString(),
                'customer_address': address != null ? '${address['area'] ?? ""}, ${address['city'] ?? ""}'.trim() : '',
                'customer_lat': lat,
                'customer_lng': lng,
                'distance_km': distKm,
                'eta_minutes': etaMin,
                'scheduled_time': booking['scheduled_time'] ?? '',
                'problem_description': booking['problem_description'] ?? 'Service Request',
                'entrance_pin': booking['entrance_pin'] ?? '',
                'completion_otp': booking['completion_otp'] ?? '',
              });
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[ACDashboard] booking_requests query note: $e');
      }

      // B. Tier-2 Resilience: Direct pending unassigned bookings when partner is ONLINE
      if (state.isOnline) {
        try {
          List<dynamic> pendingRes = [];
          try {
            pendingRes = await supabase
                .from('service_bookings')
                .select('*, services(service_id, name, category_id), user_addresses(area, city, latitude, longitude)')
                .filter('status', 'in', ['SEARCHING_PROVIDER', 'OFFERED_TO_PROVIDERS', 'PENDING', 'BROADCASTED', 'SCHEDULED'])
                .filter('partner_id', 'is', 'null')
                .order('created_at', ascending: false)
                .limit(20);
          } catch (_) {
            try {
              pendingRes = await supabase
                  .from('service_bookings')
                  .select('*')
                  .filter('status', 'in', ['SEARCHING_PROVIDER', 'OFFERED_TO_PROVIDERS', 'PENDING', 'BROADCASTED', 'SCHEDULED'])
                  .filter('partner_id', 'is', 'null')
                  .order('created_at', ascending: false)
                  .limit(20);
            } catch (_) {}
          }

          for (final b in pendingRes) {
            final bId = b['booking_id']?.toString() ?? '';
            if (bId.isEmpty || seenBookingIds.contains(bId) || LiveBookingSyncService.instance.isBookingAccepted(bId)) continue;

            final service = _asMap(b['services']);
            final cat = (service?['category_id'] ?? b['category_id'] ?? '').toString().toLowerCase();
            final sName = (b['service_name'] ?? service?['name'] ?? '').toString().toLowerCase();
            final pDesc = (b['problem_description'] ?? '').toString().toLowerCase();
            final isAcService = cat == 'ac_service' || cat == 'ac' || sName.contains('ac') || sName.contains('air condition') || pDesc.contains('ac') || pDesc.contains('cooling');
            if (!isAcService) {
              continue; // Strictly AC Service only
            }

            seenBookingIds.add(bId);
            final address = _asMap(b['user_addresses']);
            final user = _asMap(b['users']);
            final profile = _asMap(user?['user_profiles']);

            final lat = (b['customer_latitude'] as num?)?.toDouble() ??
                (address?['latitude'] as num?)?.toDouble() ?? 22.4707;
            final lng = (b['customer_longitude'] as num?)?.toDouble() ??
                (address?['longitude'] as num?)?.toDouble() ?? 70.0577;

            final distKm = OsrmRoutingService.computeHaversineDistanceKm(22.4707, 70.0650, lat, lng) * 1.35;
            final etaMin = (distKm / 25.0 * 60.0).round().clamp(5, 45);

            offersList.add({
              'request_id': null,
              'booking_id': bId,
              'service_name': b['service_name'] ?? service?['name'] ?? 'Professional AC Service',
              'price': (b['estimated_amount'] as num?)?.toDouble() ?? (b['final_amount'] as num?)?.toDouble() ?? 499.0,
              'customer_name': profile != null ? '${profile['first_name'] ?? ""} ${profile['last_name'] ?? ""}'.trim() : (user?['username'] ?? 'Customer').toString(),
              'customer_phone': (user?['phone'] ?? '').toString(),
              'customer_address': address != null ? '${address['area'] ?? ""}, ${address['city'] ?? ""}'.trim() : 'Jamnagar',
              'customer_lat': lat,
              'customer_lng': lng,
              'distance_km': distKm,
              'eta_minutes': etaMin,
              'scheduled_time': b['scheduled_time'] ?? '',
              'problem_description': b['problem_description'] ?? 'AC Service Request',
              'entrance_pin': b['entrance_pin'] ?? '',
              'completion_otp': b['completion_otp'] ?? '',
            });
          }
        } catch (e) {
          if (kDebugMode) debugPrint('[ACDashboard] pending service_bookings note: $e');
        }

        // C. Local Sync Real-time AC Offers
        try {
          final localACOffers = LiveBookingSyncService.instance.getPendingOffersForCategory('ac_service');
          for (final b in localACOffers) {
            final bId = (b['booking_id'] ?? b['id'] ?? '').toString();
            if (bId.isEmpty || seenBookingIds.contains(bId) || LiveBookingSyncService.instance.isBookingAccepted(bId)) continue;
            seenBookingIds.add(bId);

            final lat = (b['customer_lat'] as num?)?.toDouble() ?? 22.4707;
            final lng = (b['customer_lng'] as num?)?.toDouble() ?? 70.0577;
            final distKm = OsrmRoutingService.computeHaversineDistanceKm(22.4707, 70.0650, lat, lng) * 1.35;
            final etaMin = (distKm / 25.0 * 60.0).round().clamp(5, 45);

            offersList.add({
              'request_id': b['request_id'],
              'booking_id': bId,
              'service_name': b['service_name'] ?? 'Professional AC Service',
              'price': (b['price'] as num?)?.toDouble() ?? (b['final_amount'] as num?)?.toDouble() ?? 499.0,
              'customer_name': (b['customer_name'] ?? 'Customer').toString(),
              'customer_phone': (b['customer_phone'] ?? '').toString(),
              'customer_address': (b['customer_address'] ?? b['address'] ?? 'Jamnagar').toString(),
              'customer_lat': lat,
              'customer_lng': lng,
              'distance_km': distKm,
              'eta_minutes': etaMin,
              'scheduled_time': b['scheduled_time'] ?? '',
              'problem_description': b['problem_description'] ?? 'AC Service Request',
              'entrance_pin': b['entrance_pin'] ?? '',
              'completion_otp': b['completion_otp'] ?? '',
            });
          }
        } catch (_) {}
      } else {
        // Partner is OFFLINE: incoming offers must remain empty
        offersList.clear();
      }

      // 3. Fetch real rating from service_provider_profiles
      double realRating = 0.0;
      if (partnerId.isNotEmpty) {
        try {
          final profileRes = await supabase
              .from('service_provider_profiles')
              .select('rating')
              .eq('partner_id', partnerId)
              .maybeSingle();
          if (profileRes != null && profileRes['rating'] != null) {
            realRating = (profileRes['rating'] as num).toDouble();
          }
        } catch (_) {}
      }

      // 4. Fetch completed service bookings
      final List<Map<String, dynamic>> todayJobs = [];
      int totalCompleted = 0;
      final Set<String> uniqueCustomers = {};
      final Map<String, int> customerBookingCounts = {};

      try {
        if (partnerId.isNotEmpty) {
          final completedRes = await supabase
              .from('service_bookings')
              .select('*, services(*), user_addresses(*), users(*, user_profiles(*))')
              .eq('partner_id', partnerId)
              .filter('status', 'in', ['SERVICE_COMPLETED', 'PAYMENT_COMPLETED', 'REVIEWED', 'CLOSED'])
              .order('created_at', ascending: false);

          totalCompleted = completedRes.length;

        for (final b in completedRes) {
          final user = b['users'] as Map<String, dynamic>?;
          final profile = user?['user_profiles'] as Map<String, dynamic>?;
          final custId = b['customer_id']?.toString() ?? '';

          if (custId.isNotEmpty) {
            uniqueCustomers.add(custId);
            customerBookingCounts[custId] = (customerBookingCounts[custId] ?? 0) + 1;
          }

          final createdAtStr = b['created_at']?.toString() ?? '';
          final completedAtStr = b['completed_at']?.toString() ?? '';
          final isToday = (completedAtStr.isNotEmpty && completedAtStr.startsWith(todayStr)) ||
              createdAtStr.startsWith(todayStr);
          if (isToday) {
            final custName = profile != null
                ? '${profile['first_name'] ?? ""} ${profile['last_name'] ?? ""}'.trim()
                : (user?['username'] ?? 'Customer').toString();

            String formattedTime = '10:45 AM';
            if (b['completed_at'] != null) {
              try {
                formattedTime = DateFormat('hh:mm a').format(DateTime.parse(b['completed_at'].toString()));
              } catch (_) {}
            } else if (b['scheduled_time'] != null && b['scheduled_time'].toString().isNotEmpty) {
              formattedTime = b['scheduled_time'].toString();
            }

            final price = (b['final_amount'] as num?)?.toDouble() ??
                (b['estimated_amount'] as num?)?.toDouble() ??
                0.0;

            todayJobs.add({
              'booking_id': b['booking_id'],
              'customer_name': custName.isNotEmpty ? custName : 'Customer',
              'completed_at': formattedTime,
              'price': price,
              'payment_status': 'Paid',
            });
          }
        }
      }
    } catch (_) {}

      // 5. Fetch declined jobs count from booking_requests strictly for this partner
      int declinedCount = 0;
      if (partnerId.isNotEmpty) {
        try {
          final declinedRes = await supabase
              .from('booking_requests')
              .select('request_id')
              .eq('response_status', 'Rejected')
              .eq('partner_id', partnerId);
          declinedCount = declinedRes.length;
        } catch (_) {}
      }

      final repeatCount = customerBookingCounts.values.where((c) => c > 1).length;

      state = state.copyWith(
        isLoading: false,
        incomingOffers: offersList,
        todayCompletedJobs: todayJobs,
        todayIncome: todayEarned,
        monthlyIncome: monthEarned,
        totalIncome: totalEarned,
        avgIncomePerMonth: monthEarned > 0 ? monthEarned : 0.0,
        completedAcceptedJobsToday: todayJobs.length,
        declinedJobsToday: declinedCount,
        totalJobsCompleted: totalCompleted,
        totalCustomers: uniqueCustomers.length,
        customerRating: realRating,
        repeatCustomers: repeatCount,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        incomingOffers: const [],
        activeBookings: const [],
        todayCompletedJobs: const [],
        todayIncome: 0.0,
        monthlyIncome: 0.0,
        totalIncome: 0.0,
        avgIncomePerMonth: 0.0,
        completedAcceptedJobsToday: 0,
        declinedJobsToday: 0,
        totalJobsCompleted: 0,
        totalCustomers: 0,
        customerRating: 0.0,
        repeatCustomers: 0,
      );
    }
  }

  StreamSubscription? _localOffersSub;

  void _subscribeRealtimeChanges() {
    // 1. Subscribe to Local Realtime IPC Broadcast Channel (Strictly AC Service)
    _localOffersSub = LiveBookingSyncService.instance.streamIncomingOffersForCategory('ac_service').listen((_) {
      _loadLiveBookingsAndMetrics();
    });

    // 2. Also subscribe to Supabase
    try {
      final supabase = Supabase.instance.client;
      
      _requestsChannel = supabase.channel('public:booking_stream')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'booking_requests',
            callback: (_) => _loadLiveBookingsAndMetrics(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'service_bookings',
            callback: (_) => _loadLiveBookingsAndMetrics(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'bookings',
            callback: (_) => _loadLiveBookingsAndMetrics(),
          )
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'partner_earnings',
            callback: (_) => _loadLiveBookingsAndMetrics(),
          )
          ..subscribe();
    } catch (_) {}
  }

  Future<void> toggleOnlineStatus(bool online) async {
    state = state.copyWith(isOnline: online);
    await LocalRegistrationCache.updateActivePartner({'is_online': online});

    try {
      if (state.partnerId.isNotEmpty) {
        await Supabase.instance.client
            .from('partners')
            .update({'availability_status': online ? 'ONLINE' : 'OFFLINE'})
            .eq('partner_id', state.partnerId);

        if (online) {
          PartnerLocationService.instance.startLiveLocationTracking(partnerId: state.partnerId);
          try {
            await Supabase.instance.client.rpc('dispatch_pending_bookings_for_partner', params: {
              'p_partner_id': state.partnerId,
            });
          } catch (e) {
            if (kDebugMode) debugPrint('[ACDashboard] Redispatch RPC note: $e');
          }

          // Direct resilient PostgreSQL redispatch of unassigned bookings for this newly online partner
          try {
            final unassignedBookings = await Supabase.instance.client
                .from('service_bookings')
                .select('booking_id, service_id, services(category_id)')
                .filter('status', 'in', ['SEARCHING_PROVIDER', 'OFFERED_TO_PROVIDERS', 'PENDING'])
                .filter('partner_id', 'is', 'null');

            for (final b in unassignedBookings) {
              final bId = b['booking_id']?.toString() ?? '';
              if (bId.isEmpty) continue;
              final svc = _asMap(b['services']);
              final cat = (svc?['category_id'] ?? 'ac_service').toString();
              if (cat.isNotEmpty && cat != state.category && state.category != 'all') {
                continue;
              }

              // Check if a request already exists for this partner
              final existingReq = await Supabase.instance.client
                  .from('booking_requests')
                  .select('request_id')
                  .eq('booking_id', bId)
                  .eq('partner_id', state.partnerId)
                  .maybeSingle();

              if (existingReq == null) {
                await Supabase.instance.client.from('booking_requests').insert({
                  'booking_id': bId,
                  'provider_id': state.providerId.isNotEmpty ? state.providerId : null,
                  'partner_id': state.partnerId,
                  'response_status': 'Pending',
                  'sent_at': DateTime.now().toIso8601String(),
                });
              }
            }
          } catch (e) {
            if (kDebugMode) debugPrint('[ACDashboard] Direct redispatch note: $e');
          }
        } else {
          PartnerLocationService.instance.stopLiveLocationTracking();
        }
      }
    } catch (_) {}

    await _loadLiveBookingsAndMetrics();
  }

  void setTimeframe(String timeframe) {
    state = state.copyWith(timeframe: timeframe);
  }

  /// Atomic First-Accept-Wins Acceptance using PostgreSQL Stored Procedure
  Future<Map<String, dynamic>> acceptOffer(Map<String, dynamic> offer) async {
    final requestId = offer['request_id'];
    final bookingId = offer['booking_id'];
    final effectiveProviderId = state.providerId.isNotEmpty ? state.providerId : state.partnerId;

    // 1. Verify and claim atomically via PostgreSQL transaction if request_id is present
    if (requestId != null && effectiveProviderId.isNotEmpty) {
      try {
        final res = await Supabase.instance.client.rpc('atomic_accept_booking_request', params: {
          'p_request_id': requestId,
          'p_partner_id': state.partnerId.isNotEmpty ? state.partnerId : effectiveProviderId,
          'p_provider_id': effectiveProviderId,
        });

        if (res is Map && res['success'] == false) {
          // Contested job was claimed by another partner or expired
          state = state.copyWith(
            incomingOffers: state.incomingOffers.where((o) => o['booking_id'] != bookingId).toList(),
          );
          return {
            'success': false,
            'message': res['message']?.toString() ?? 'This job was already accepted by another technician.',
          };
        }
      } catch (e) {
        debugPrint('[ACProviderDashboardController] atomic_accept RPC note: $e');
      }
    }

    // 1b. Direct database check: Concurrency, Cancellation, and Expiry validation
    if (bookingId != null) {
      try {
        final currentBooking = await Supabase.instance.client
            .from('service_bookings')
            .select('status, partner_id')
            .eq('booking_id', bookingId)
            .maybeSingle();

        if (currentBooking != null) {
          final bStatus = (currentBooking['status'] ?? '').toString().toUpperCase();
          final bPartner = currentBooking['partner_id']?.toString() ?? '';

          if (bStatus == 'CANCELLED') {
            state = state.copyWith(
              incomingOffers: state.incomingOffers.where((o) => o['booking_id'] != bookingId).toList(),
            );
            return {
              'success': false,
              'message': 'This booking was cancelled by the customer.',
            };
          }

          if (bPartner.isNotEmpty && bPartner != state.partnerId && bPartner != state.providerId) {
            state = state.copyWith(
              incomingOffers: state.incomingOffers.where((o) => o['booking_id'] != bookingId).toList(),
            );
            return {
              'success': false,
              'message': 'This job has already been accepted by another technician.',
            };
          }
        }
      } catch (_) {}
    }

    if (requestId != null) {
      try {
        final reqCheck = await Supabase.instance.client
            .from('booking_requests')
            .select('response_status')
            .eq('request_id', requestId)
            .maybeSingle();

        if (reqCheck != null) {
          final rStatus = reqCheck['response_status']?.toString();
          if (rStatus == 'Expired') {
            state = state.copyWith(
              incomingOffers: state.incomingOffers.where((o) => o['booking_id'] != bookingId).toList(),
            );
            return {
              'success': false,
              'message': 'This request has expired and is no longer available.',
            };
          }
        }
      } catch (_) {}
    }

    // 2. Update Local IPC Relay with concurrency protection
    if (bookingId != null) {
      final acceptedLocally = await LiveBookingSyncService.instance.acceptBooking(bookingId, {
        'partner_id': state.partnerId,
        'partner_name': state.providerName.isNotEmpty ? state.providerName : 'Service Partner',
        'partner_phone': Supabase.instance.client.auth.currentUser?.phone ?? '',
      });

      if (!acceptedLocally && requestId == null) {
        state = state.copyWith(
          incomingOffers: state.incomingOffers.where((o) => o['booking_id'] != bookingId).toList(),
        );
        return {
          'success': false,
          'message': 'This job has already been accepted by another technician.',
        };
      }
    }

    final activeJobData = {
      ...offer,
      'status': 'CONFIRMED',
      'accepted_at': DateTime.now().toIso8601String(),
    };

    final bIdStr = (offer['booking_id'] ?? offer['id'] ?? '').toString();
    final reqIdStr = (offer['request_id'] ?? '').toString();

    state = state.copyWith(
      incomingOffers: state.incomingOffers.where((o) {
        final oBId = (o['booking_id'] ?? o['id'] ?? '').toString();
        final oReqId = (o['request_id'] ?? '').toString();
        if (bIdStr.isNotEmpty && oBId == bIdStr) return false;
        if (reqIdStr.isNotEmpty && oReqId == reqIdStr) return false;
        return true;
      }).toList(),
      activeJob: activeJobData,
      activeBookings: [...state.activeBookings, activeJobData],
    );

    // 3. Update Supabase service_bookings & booking_requests & booking_assignment
    try {
      if (bookingId != null) {
        final supabase = Supabase.instance.client;
        final nowStr = DateTime.now().toIso8601String();

        // 3a. Update service_bookings table
        try {
          await supabase
              .from('service_bookings')
              .update({
                'status': 'ACCEPTED',
                'service_status': 'ACCEPTED',
                'partner_id': state.partnerId,
                'updated_at': nowStr,
              })
              .eq('booking_id', bookingId);
        } catch (e) {
          debugPrint('[acceptOffer] service_bookings update note: $e');
        }

        // 3b. Update booking_requests: mark winning as Accepted, others as Expired
        try {
          if (requestId != null) {
            await supabase
                .from('booking_requests')
                .update({
                  'response_status': 'Accepted',
                  'response_at': nowStr,
                })
                .eq('request_id', requestId);
          }
          await supabase
              .from('booking_requests')
              .update({
                'response_status': 'Expired',
                'response_at': nowStr,
              })
              .eq('booking_id', bookingId)
              .neq('request_id', requestId ?? '');
        } catch (e) {
          debugPrint('[acceptOffer] booking_requests update note: $e');
        }

        // 3c. Insert into booking_assignment
        try {
          await supabase.from('booking_assignment').upsert({
            'booking_id': bookingId,
            'provider_id': effectiveProviderId,
            'partner_id': state.partnerId,
            'assignment_method': 'FIRST_ACCEPT',
            'status': 'ASSIGNED',
            'assigned_at': nowStr,
          });
        } catch (e) {
          debugPrint('[acceptOffer] booking_assignment note: $e');
        }

        // 3d. Insert into booking_status_history
        try {
          await supabase.from('booking_status_history').insert({
            'booking_id': bookingId,
            'status': 'ACCEPTED',
            'remarks': 'Provider accepted service request via first-accept engine',
            'changed_at': nowStr,
          });
        } catch (e) {
          debugPrint('[acceptOffer] status_history note: $e');
        }
      }
    } catch (_) {}

    return {'success': true, 'activeJob': activeJobData};
  }

  Future<void> declineOffer(Map<String, dynamic> offer) async {
    final requestId = offer['request_id'];
    final bookingId = offer['booking_id'];

    state = state.copyWith(
      incomingOffers: state.incomingOffers.where((o) => o['booking_id'] != bookingId).toList(),
      declinedJobsToday: state.declinedJobsToday + 1,
    );

    if (bookingId != null) {
      await LiveBookingSyncService.instance.declineBooking(bookingId);
    }

    try {
      if (requestId != null) {
        await Supabase.instance.client
            .from('booking_requests')
            .update({'response_status': 'Rejected', 'response_at': DateTime.now().toIso8601String()})
            .eq('request_id', requestId);
      }
    } catch (_) {}
  }

  /// Update Job Milestone (ON_THE_WAY, ARRIVED, SERVICE_STARTED)
  Future<void> updateJobMilestone(String bookingId, String newStatus) async {
    if (state.activeJob != null && state.activeJob!['booking_id'] == bookingId) {
      final updatedJob = Map<String, dynamic>.from(state.activeJob!)..['status'] = newStatus;
      state = state.copyWith(activeJob: updatedJob);
    }

    await LiveBookingSyncService.instance.updateMilestone(bookingId, newStatus);

    try {
      await Supabase.instance.client
          .from('service_bookings')
          .update({'status': newStatus})
          .eq('booking_id', bookingId);
    } catch (_) {}
    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId);
    } catch (_) {}
  }

  /// Complete Job, Verify OTP, Credit Earnings, and Update Dashboard
  Future<void> completeJobAndSettle(String bookingId, {required double grossAmount, String? completionOtp, String? remarks}) async {
    final platformFee = grossAmount * 0.15;
    final netAmount = grossAmount - platformFee;

    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    final completedJobRecord = {
      'booking_id': bookingId,
      'customer_name': state.activeJob?['customer_name'] ?? 'Customer',
      'completed_at': DateFormat('hh:mm a').format(now),
      'price': grossAmount,
      'payment_status': 'Paid',
    };

    state = state.copyWith(
      clearActiveJob: true,
      todayIncome: state.todayIncome + netAmount,
      monthlyIncome: state.monthlyIncome + netAmount,
      totalIncome: state.totalIncome + netAmount,
      completedAcceptedJobsToday: state.completedAcceptedJobsToday + 1,
      totalJobsCompleted: state.totalJobsCompleted + 1,
      todayCompletedJobs: [completedJobRecord, ...state.todayCompletedJobs],
    );

    // 1. Settle in Local IPC Engine
    await LiveBookingSyncService.instance.completeBooking(bookingId, grossAmount);

    try {
      final supabase = Supabase.instance.client;

      // 2. Update Booking Status in Supabase service_bookings & bookings
      try {
        await supabase
            .from('service_bookings')
            .update({
              'status': 'SERVICE_COMPLETED',
              'final_amount': grossAmount,
              'completed_at': nowIso,
            })
            .eq('booking_id', bookingId);
      } catch (_) {}

      try {
        await supabase
            .from('bookings')
            .update({
              'status': 'COMPLETED',
              'final_amount': grossAmount,
              'price': grossAmount,
              'completed_at': nowIso,
            })
            .eq('id', bookingId);
      } catch (_) {}

      try {
        await supabase
            .from('booking_assignment')
            .update({
              'status': 'COMPLETED',
            })
            .eq('booking_id', bookingId);
      } catch (_) {}

      try {
        await supabase
            .from('booking_status_history')
            .insert({
              'booking_id': bookingId,
              'status': 'SERVICE_COMPLETED',
              'notes': 'Job completed and validated via Customer Safety Completion OTP',
              'created_at': nowIso,
            });
      } catch (_) {}

      // 3. Insert into partner_earnings
      if (state.partnerId.isNotEmpty) {
        try {
          await supabase.from('partner_earnings').insert({
            'partner_id': state.partnerId,
            'booking_id': bookingId,
            'gross_amount': grossAmount,
            'platform_fee': platformFee,
            'net_amount': netAmount,
            'earning_status': 'CLEARED',
          });
        } catch (_) {}
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _localOffersSub?.cancel();
    _requestsChannel?.unsubscribe();
    _earningsChannel?.unsubscribe();
    super.dispose();
  }
}

final acProviderDashboardProvider = StateNotifierProvider<ACProviderDashboardNotifier, ACProviderDashboardState>((ref) {
  return ACProviderDashboardNotifier();
});
