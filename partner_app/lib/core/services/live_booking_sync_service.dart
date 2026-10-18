import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../storage/local_registration_cache.dart';
import 'secure_otp_engine.dart';

/// Universal Cross-Platform Synchronization Service (Web + Desktop + Mobile + Supabase)
class LiveBookingSyncService {
  LiveBookingSyncService._internal() {
    _initializeSync();
  }

  static final LiveBookingSyncService instance = LiveBookingSyncService._internal();

  final _bookingsStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  final _verificationsStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get bookingsStream => _bookingsStreamController.stream;
  Stream<List<Map<String, dynamic>>> get verificationsStream => _verificationsStreamController.stream;

  Stream<List<Map<String, dynamic>>> get incomingOffersStream => _bookingsStreamController.stream.map((list) {
    return list.where((b) {
      final s = (b['status'] ?? '').toString().toUpperCase();
      final partnerId = (b['partner_id'] ?? '').toString();
      final id = (b['id'] ?? b['booking_id'] ?? '').toString().toLowerCase();
      final name = (b['customer_name'] ?? '').toString().toLowerCase();
      final isFakeOrTest = id.startsWith('test_') ||
          id == 'booking_unassigned_999' ||
          name.contains('rajiv patel') ||
          name.contains('meera trivedi');
      if (isFakeOrTest) return false;
      return (s == 'PENDING' || s == 'BROADCASTED' || s == 'SEARCHING_PROVIDER' || s == 'OFFERED_TO_PROVIDERS' || s == 'SCHEDULED') &&
          partnerId.isEmpty;
    }).toList();
  });

  /// Authoritative Category Matcher for Strict Multi-Service Isolation
  static bool isBookingMatchingCategory(Map<String, dynamic> b, String targetCategory) {
    final target = targetCategory.toLowerCase().trim();
    final exactCatId = (b['category_id'] ?? '').toString().toLowerCase().trim();
    if (exactCatId.isNotEmpty) {
      if (target == 'ac_service' || target == 'ac') return exactCatId == 'ac_service' || exactCatId == 'ac';
      if (target == 'car_service' || target == 'car') return exactCatId == 'car_service' || exactCatId == 'car';
      if (target == 'care_taker' || target == 'care') return exactCatId == 'care_taker' || exactCatId == 'care';
      if (target == 'plumbing') return exactCatId == 'plumbing';
      if (target == 'cooking') return exactCatId == 'cooking';
      if (target == 'laundry') return exactCatId == 'laundry';
      if (target == 'shopkeeper' || target == 'store') return exactCatId == 'store' || exactCatId == 'shopkeeper' || exactCatId == 'ecommerce';
      if (target == 'delivery' || target == 'delivery_agent') return exactCatId == 'delivery' || exactCatId == 'delivery_agent';
      if (exactCatId == target) return true;
    }

    final cat = (b['category'] ?? b['category_name'] ?? b['service_id'] ?? b['service_name'] ?? '')
        .toString()
        .toLowerCase();

    if (target == 'ac_service' || target == 'ac') {
      final isCar = (cat.contains('car ') || cat.contains('car_') || cat.contains(' car') || cat.contains('auto') || cat.contains('vehicle')) && !cat.contains('care') && !cat.contains('carpet');
      return (cat.contains('ac') || cat.contains('air conditioning') || cat.contains('hvac') || cat.contains('cooling')) && !isCar;
    } else if (target == 'care_taker' || target == 'care') {
      return cat.contains('care') || cat.contains('elderly') || cat.contains('patient') || cat.contains('babysitt') || cat.contains('nurse') || cat.contains('companion');
    } else if (target == 'cooking') {
      return cat.contains('cook') || cat.contains('chef') || cat.contains('meal') || cat.contains('kitchen') || cat.contains('culinary') || cat.contains('tiffin');
    } else if (target == 'plumbing') {
      return cat.contains('plumb') || cat.contains('pipe') || cat.contains('leak') || cat.contains('drain') || cat.contains('tap') || cat.contains('sanitat') || cat.contains('commode');
    } else if (target == 'laundry') {
      final isCar = (cat.contains('car ') || cat.contains('car_') || cat.contains(' car') || cat.contains('vehicle')) && !cat.contains('carpet');
      final isAc = cat.contains('ac') && !cat.contains('pack');
      return (cat.contains('laundry') || cat.contains('dry clean') || cat.contains('iron') || cat.contains('garment') || cat.contains('carpet') || (cat.contains('wash') && !isCar && !isAc));
    } else if (target == 'car_service' || target == 'car') {
      final isCareOrCarpet = cat.contains('care') || cat.contains('carpet');
      return !isCareOrCarpet && (cat.contains('car') || cat.contains('auto') || cat.contains('vehicle') || cat.contains('mechanic') || cat.contains('garage') || cat.contains('oil_change') || cat.contains('roadside') || cat.contains('tyre') || cat.contains('brake'));
    } else if (target == 'shopkeeper' || target == 'store' || target == 'ecommerce') {
      return (b['type'] == 'DELIVERY_ORDER' || cat.contains('store') || cat.contains('grocery') || cat.contains('mart')) && !cat.contains('laundry');
    } else if (target == 'delivery' || target == 'delivery_agent') {
      return b['type'] == 'DELIVERY_ORDER' || cat.contains('delivery') || cat.contains('courier') || cat.contains('parcel');
    }
    return cat == target || cat.contains(target);
  }

  final Set<String> _locallyAcceptedBookingIds = {};

  bool isBookingAccepted(String bookingId) {
    if (bookingId.isEmpty) return false;
    if (_locallyAcceptedBookingIds.contains(bookingId)) return true;
    final b = _inMemoryBookings[bookingId];
    if (b != null) {
      final s = (b['status'] ?? '').toString().toUpperCase();
      final p = (b['partner_id'] ?? '').toString();
      if (s == 'ACCEPTED' || s == 'CONFIRMED' || s == 'ASSIGNED' || s == 'IN_PROGRESS' || p.isNotEmpty) {
        return true;
      }
    }
    return false;
  }

  /// Category-Isolated Stream of Incoming Offers
  Stream<List<Map<String, dynamic>>> streamIncomingOffersForCategory(String categoryId) {
    return _bookingsStreamController.stream.map((list) {
      return list.where((b) {
        final bId = (b['booking_id'] ?? b['id'] ?? '').toString();
        if (bId.isNotEmpty && _locallyAcceptedBookingIds.contains(bId)) return false;
        final s = (b['status'] ?? '').toString().toUpperCase();
        final partnerId = (b['partner_id'] ?? '').toString();
        if (partnerId.isNotEmpty) return false;
        if (s == 'ACCEPTED' || s == 'CONFIRMED' || s == 'ASSIGNED' || s == 'IN_PROGRESS' || s == 'ON_THE_WAY' || s == 'ARRIVED' || s == 'SERVICE_STARTED') return false;
        final id = (b['id'] ?? b['booking_id'] ?? '').toString().toLowerCase();
        final name = (b['customer_name'] ?? '').toString().toLowerCase();
        final isFakeOrTest = id.startsWith('test_') ||
            id == 'booking_unassigned_999' ||
            name.contains('rajiv patel') ||
            name.contains('meera trivedi');
        if (isFakeOrTest) return false;
        final isPending = (s == 'PENDING' || s == 'BROADCASTED' || s == 'SEARCHING_PROVIDER' || s == 'OFFERED_TO_PROVIDERS' || s == 'SCHEDULED') &&
            partnerId.isEmpty;
        if (!isPending) return false;
        return isBookingMatchingCategory(b, categoryId);
      }).toList();
    });
  }

  /// Category-Isolated Synchronous Pending Offers
  List<Map<String, dynamic>> getPendingOffersForCategory(String categoryId) {
    reloadAllFromDisk();
    return getAllBookings().where((b) {
      final bId = (b['booking_id'] ?? b['id'] ?? '').toString();
      if (bId.isNotEmpty && _locallyAcceptedBookingIds.contains(bId)) return false;
      final status = (b['status'] ?? '').toString().toUpperCase();
      final partnerId = (b['partner_id'] ?? '').toString();
      if (partnerId.isNotEmpty) return false;
      if (status == 'ACCEPTED' || status == 'CONFIRMED' || status == 'ASSIGNED' || status == 'IN_PROGRESS' || status == 'ON_THE_WAY' || status == 'ARRIVED' || status == 'SERVICE_STARTED') return false;
      final isPending = (status == 'PENDING' || status == 'SEARCHING_PROVIDER' || status == 'OFFERED_TO_PROVIDERS' || status == 'BROADCASTED' || status == 'SCHEDULED') &&
          partnerId.isEmpty;
      if (!isPending) return false;
      return isBookingMatchingCategory(b, categoryId);
    }).toList();
  }

  Timer? _pollingTimer;

  final Map<String, Map<String, dynamic>> _inMemoryBookings = {};
  final Map<String, Map<String, dynamic>> _inMemoryVerifications = {};

  List<dynamic> _getVerificationFiles() {
    if (kIsWeb) return [];
    if (Platform.environment.containsKey('FLUTTER_TEST')) return [];
    final list = <dynamic>[];
    try {
      if (Platform.isWindows) {
        final publicDir = Directory('C:\\Users\\Public\\ServiceHub');
        if (!publicDir.existsSync()) {
          publicDir.createSync(recursive: true);
        }
        list.add(File('C:\\Users\\Public\\ServiceHub\\service_hub_partner_verifications.json'));
      }
    } catch (_) {}

    try {
      final tempDir = Directory.systemTemp;
      list.add(File('${tempDir.path}/service_hub_partner_verifications.json'));
    } catch (_) {}

    for (var f in list) {
      if (f is File && !f.existsSync()) {
        try {
          f.createSync(recursive: true);
          f.writeAsStringSync('{}');
        } catch (_) {}
      }
    }
    return list;
  }

  List<dynamic> _getBookingFiles() {
    if (kIsWeb) return [];
    if (Platform.environment.containsKey('FLUTTER_TEST')) return [];
    final list = <dynamic>[];
    try {
      if (Platform.isWindows) {
        final publicDir = Directory('C:\\Users\\Public\\ServiceHub');
        if (!publicDir.existsSync()) {
          publicDir.createSync(recursive: true);
        }
        list.add(File('C:\\Users\\Public\\ServiceHub\\service_hub_live_bookings.json'));
      }
    } catch (_) {}

    try {
      final tempDir = Directory.systemTemp;
      list.add(File('${tempDir.path}/service_hub_live_bookings.json'));
    } catch (_) {}

    for (var f in list) {
      if (f is File && !f.existsSync()) {
        try {
          f.createSync(recursive: true);
          f.writeAsStringSync('{}');
        } catch (_) {}
      }
    }
    return list;
  }

  RealtimeChannel? _realtimeChannel;

  bool _isSupabaseReady() {
    try {
      return Supabase.instance.isInitialized;
    } catch (_) {
      return false;
    }
  }

  void _setupRealtimeSubscription() {
    if (!_isSupabaseReady()) return;
    try {
      final supabase = Supabase.instance.client;
      _realtimeChannel = supabase.channel('public:service_bookings_sync')
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'service_bookings',
          callback: (_) {
            _syncWithSupabase();
          },
        )
        ..onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'booking_requests',
          callback: (_) {
            _syncWithSupabase();
          },
        )
        ..subscribe();
    } catch (e) {
      if (kDebugMode) debugPrint('[LiveBookingSyncService] Realtime setup note: $e');
    }
  }

  void _initializeSync() {
    reloadAllFromDisk();

    if (!kIsWeb) {
      try {
        if (Platform.environment.containsKey('FLUTTER_TEST') ||
            WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
          return;
        }
      } catch (_) {}
    }

    _setupRealtimeSubscription();

    _pollingTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) {
      reloadAllFromDisk();
      _pollHttpBridge();
      _syncWithSupabase();
    });

    _syncWithSupabase();
  }

  Future<void> syncWithSupabaseNow() async {
    await _syncWithSupabase();
  }

  static String _inferCategory(String catId, String sName, String pDesc) {
    final cat = catId.toLowerCase().trim();
    if (cat == 'ac_service' || cat == 'ac') return 'ac_service';
    if (cat == 'car_service' || cat == 'car') return 'car_service';
    if (cat == 'care_taker' || cat == 'care') return 'care_taker';
    if (cat == 'plumbing') return 'plumbing';
    if (cat == 'cooking') return 'cooking';
    if (cat == 'laundry') return 'laundry';
    if (cat == 'shopkeeper' || cat == 'store') return 'shopkeeper';
    if (cat == 'delivery' || cat == 'delivery_agent') return 'delivery';

    final combined = '$cat $sName $pDesc'.toLowerCase();
    if (combined.contains('care') || combined.contains('elderly') || combined.contains('patient') || combined.contains('nurse') || combined.contains('babysitt') || combined.contains('companion')) {
      return 'care_taker';
    }
    if (combined.contains('cook') || combined.contains('chef') || combined.contains('meal') || combined.contains('kitchen') || combined.contains('culinary') || combined.contains('tiffin')) {
      return 'cooking';
    }
    if (combined.contains('plumb') || combined.contains('pipe') || combined.contains('tap') || combined.contains('drain') || combined.contains('leak') || combined.contains('toilet') || combined.contains('sanitat')) {
      return 'plumbing';
    }
    if (combined.contains('laundry') || combined.contains('dry clean') || combined.contains('garment') || combined.contains('iron') || combined.contains('steam press') || (combined.contains('wash') && combined.contains('shoe'))) {
      return 'laundry';
    }
    if (combined.contains('roadside') || combined.contains('engine repair') || combined.contains('tyre') || combined.contains('brake') || combined.contains('denting') || (combined.contains('car') && !combined.contains('care') && !combined.contains('carpet'))) {
      return 'car_service';
    }
    if (combined.contains('ac') || combined.contains('air condition') || combined.contains('cooling') || combined.contains('jet wash')) {
      return 'ac_service';
    }
    return 'ac_service';
  }

  static String _defaultServiceName(String category) {
    switch (category) {
      case 'ac_service':
        return 'Split AC Deep Cleaning (Jet Wash)';
      case 'car_service':
        return 'Periodic Standard Service & Inspection';
      case 'care_taker':
        return 'Elderly & Patient Care Assistant';
      case 'cooking':
        return 'Daily Domestic Home Cook (2 Meals)';
      case 'plumbing':
        return 'Tap & Pipe Leakage Repair';
      case 'laundry':
        return 'Wash & Steam Ironing';
      default:
        return 'Professional Home Service';
    }
  }

  static String _categoryDisplayName(String category) {
    switch (category) {
      case 'ac_service':
        return 'AC Service Provider';
      case 'car_service':
        return 'Car Service Specialist';
      case 'care_taker':
        return 'Care Taker Specialist';
      case 'cooking':
        return 'Cooking Specialist';
      case 'plumbing':
        return 'Plumbing Specialist';
      case 'laundry':
        return 'Laundry Specialist';
      default:
        return 'Service Partner';
    }
  }

  Future<void> _syncWithSupabase() async {
    if (!_isSupabaseReady()) return;
    try {
      final supabase = Supabase.instance.client;

      // 1. Query pending unassigned bookings across all service categories (Immediate + Scheduled)
      List<dynamic> rows = [];
      try {
        rows = await supabase
            .from('service_bookings')
            .select('booking_id, customer_id, service_id, address_id, booking_date, scheduled_time, problem_description, estimated_amount, final_amount, status, service_status, partner_id, customer_latitude, customer_longitude, entrance_pin, completion_otp, created_at, services(service_id, name, category_id), user_addresses(area, city, latitude, longitude)')
            .filter('status', 'in', ['SEARCHING_PROVIDER', 'OFFERED_TO_PROVIDERS', 'PENDING', 'BROADCASTED', 'SCHEDULED'])
            .filter('partner_id', 'is', 'null')
            .order('created_at', ascending: false)
            .limit(50);
      } catch (_) {
        try {
          rows = await supabase
              .from('service_bookings')
              .select('*')
              .filter('status', 'in', ['SEARCHING_PROVIDER', 'OFFERED_TO_PROVIDERS', 'PENDING', 'BROADCASTED', 'SCHEDULED'])
              .filter('partner_id', 'is', 'null')
              .order('created_at', ascending: false)
              .limit(50);
        } catch (_) {}
      }

      // 2. Fetch assigned / in-progress bookings AND direct booking_requests for logged-in partner
      try {
        final cachedPartner = await LocalRegistrationCache.getActivePartner() ??
            await LocalRegistrationCache.getActiveServiceProvider();
        final pId = (cachedPartner?['partner_id'] ?? cachedPartner?['id'] ?? '').toString();
        final provId = (cachedPartner?['provider_id'] ?? '').toString();

        if (pId.isNotEmpty) {
          final assignedRows = await supabase
              .from('service_bookings')
              .select('booking_id, customer_id, service_id, address_id, booking_date, scheduled_time, problem_description, estimated_amount, final_amount, status, service_status, partner_id, customer_latitude, customer_longitude, entrance_pin, completion_otp, created_at, services(service_id, name, category_id), user_addresses(area, city, latitude, longitude)')
              .eq('partner_id', pId)
              .filter('status', 'in', ['ACCEPTED', 'ASSIGNED', 'ON_THE_WAY', 'ARRIVED', 'SERVICE_STARTED', 'IN_PROGRESS', 'COMPLETED'])
              .limit(30);
          rows.addAll(assignedRows);
        }

        // Direct candidate requests addressed to this partner
        if (pId.isNotEmpty || provId.isNotEmpty) {
          try {
            final filterCol = pId.isNotEmpty ? 'partner_id' : 'provider_id';
            final filterVal = pId.isNotEmpty ? pId : provId;
            final reqs = await supabase
                .from('booking_requests')
                .select('booking_id')
                .eq(filterCol, filterVal)
                .eq('response_status', 'Pending')
                .limit(20);
            for (final rq in reqs) {
              final bId = (rq['booking_id'] ?? '').toString();
              if (bId.isNotEmpty && !rows.any((r) => (r['booking_id'] ?? r['id'] ?? '').toString() == bId)) {
                final bRow = await supabase
                    .from('service_bookings')
                    .select('booking_id, customer_id, service_id, address_id, booking_date, scheduled_time, problem_description, estimated_amount, final_amount, status, service_status, partner_id, customer_latitude, customer_longitude, entrance_pin, completion_otp, created_at, services(service_id, name, category_id), user_addresses(area, city, latitude, longitude)')
                    .eq('booking_id', bId)
                    .maybeSingle();
                if (bRow != null) {
                  rows.add(bRow);
                }
              }
            }
          } catch (_) {}
        }
      } catch (_) {}

      bool hasChanges = false;
      for (final r in rows) {
        if (r is! Map<String, dynamic>) continue;
        final bId = (r['booking_id'] ?? r['id'] ?? '').toString();
        if (bId.isEmpty) continue;

        dynamic svc = r['services'];
        if (svc is List && svc.isNotEmpty) svc = svc.first;
        final svcMap = svc is Map<String, dynamic> ? svc : null;

        dynamic addr = r['user_addresses'];
        if (addr is List && addr.isNotEmpty) addr = addr.first;
        final addrMap = addr is Map<String, dynamic> ? addr : null;

        final rawCat = (svcMap?['category_id'] ?? r['category_id'] ?? r['category'] ?? '').toString();
        final sName = (svcMap?['name'] ?? r['service_name'] ?? '').toString();
        final pDesc = (r['problem_description'] ?? '').toString();

        final resolvedCat = _inferCategory(rawCat, sName, pDesc);

        final price = (r['final_amount'] as num?)?.toDouble() ??
            (r['estimated_amount'] as num?)?.toDouble() ?? 499.0;
        final lat = (r['customer_latitude'] as num?)?.toDouble() ??
            (addrMap?['latitude'] as num?)?.toDouble() ?? 22.4707;
        final lng = (r['customer_longitude'] as num?)?.toDouble() ??
            (addrMap?['longitude'] as num?)?.toDouble() ?? 70.0577;
        final addressText = addrMap != null
            ? '${addrMap['area'] ?? ""}, ${addrMap['city'] ?? "Jamnagar"}'.trim()
            : (r['address'] ?? 'Jamnagar').toString();

        final status = (r['status'] ?? 'PENDING').toString().toUpperCase();
        final partnerId = (r['partner_id'] ?? '').toString();

        final existing = _inMemoryBookings[bId];
        final existingStatus = (existing?['status'] ?? '').toString().toUpperCase();
        final existingPartner = (existing?['partner_id'] ?? '').toString();
        // Never revert an accepted, confirmed, or in-progress booking back to pending
        if ((existingStatus == 'ACCEPTED' || existingStatus == 'CONFIRMED' || existingStatus == 'IN_PROGRESS' || existingPartner.isNotEmpty) &&
            (status == 'PENDING' || status == 'SEARCHING_PROVIDER' || status == 'OFFERED_TO_PROVIDERS' || status == 'BROADCASTED' || status == 'SCHEDULED')) {
          continue;
        }
        if (existing == null || existing['status'] != status || existing['partner_id'] != partnerId) {
          final normalized = Map<String, dynamic>.from(existing ?? {});
          normalized['id'] = bId;
          normalized['booking_id'] = bId;
          normalized['customer_id'] = (r['customer_id'] ?? '').toString();
          normalized['customer_name'] = existing?['customer_name'] ?? 'Customer';
          normalized['customer_phone'] = existing?['customer_phone'] ?? '';
          normalized['service_id'] = (r['service_id'] ?? '').toString();
          normalized['service_name'] = sName.isNotEmpty ? sName : _defaultServiceName(resolvedCat);
          normalized['category_id'] = resolvedCat;
          normalized['category'] = resolvedCat;
          normalized['category_name'] = _categoryDisplayName(resolvedCat);
          normalized['problem_description'] = pDesc;
          normalized['status'] = status;
          normalized['service_status'] = status;
          normalized['partner_id'] = partnerId;
          normalized['price'] = price;
          normalized['final_amount'] = price;
          normalized['estimated_amount'] = price;
          normalized['scheduled_date'] = (r['booking_date'] ?? 'Today').toString();
          normalized['scheduled_time'] = (r['scheduled_time'] ?? 'Immediate').toString();
          normalized['scheduled_at'] = '${r['booking_date'] ?? ""} ${r['scheduled_time'] ?? ""}'.trim();
          normalized['customer_address'] = addressText;
          normalized['address'] = addressText;
          normalized['customer_lat'] = lat;
          normalized['customer_lng'] = lng;
          normalized['entrance_pin'] = (r['entrance_pin'] ?? '7429').toString();
          normalized['completion_otp'] = (r['completion_otp'] ?? '5892').toString();
          normalized['created_at'] = (r['created_at'] ?? DateTime.now().toIso8601String()).toString();

          _inMemoryBookings[bId] = normalized;
          hasChanges = true;
        }
      }

      if (hasChanges) {
        _writeAllBookings(_inMemoryBookings);
        _broadcastBookingChanges();
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[LiveBookingSyncService] Supabase sync note: $e');
    }
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    try {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
    } catch (_) {}
  }

  void clearBookingsForTest() {
    _inMemoryBookings.clear();
  }

  void clearVerificationsForTest() {
    _inMemoryVerifications.clear();
    if (!kIsWeb) {
      for (final file in _getVerificationFiles()) {
        try {
          if (file is File && file.existsSync()) {
            file.writeAsStringSync('{}', flush: true);
          }
        } catch (_) {}
      }
    }
    _broadcastVerificationChanges();
  }

  void dispose() {
    _pollingTimer?.cancel();
    _bookingsStreamController.close();
    _verificationsStreamController.close();
  }

  void reloadAllFromDisk() {
    _readAllBookings();
    _readAllVerifications();
    if (kIsWeb) {
      _pollHttpBridge();
    }
  }

  Future<void> _pollHttpBridge() async {
    if (!kIsWeb) {
      try {
        if (Platform.environment.containsKey('FLUTTER_TEST') ||
            WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
          return;
        }
      } catch (_) {}
    }

    final List<String> hosts = kIsWeb
        ? ['127.0.0.1', 'localhost']
        : ['10.0.2.2', '127.0.0.1', 'localhost'];

    for (final host in hosts) {
      try {
        final uriVerif = Uri.parse('http://$host:8088/api/verifications');
        final respVerif = await http.get(uriVerif).timeout(const Duration(milliseconds: 3000));
        if (respVerif.statusCode == 200) {
          final List<dynamic> list = jsonDecode(respVerif.body);
          bool hasNew = false;
          for (var item in list) {
            if (item is Map<String, dynamic>) {
              final id = (item['verification_id'] ?? item['id'] ?? '').toString();
              if (id.isNotEmpty && (!_inMemoryVerifications.containsKey(id) || _inMemoryVerifications[id]!['status'] != item['status'])) {
                _inMemoryVerifications[id] = item;
                hasNew = true;
              }
            }
          }
          if (hasNew) {
            _writeAllVerifications(_inMemoryVerifications);
          }
        }

        final uriBook = Uri.parse('http://$host:8088/api/bookings');
        final respBook = await http.get(uriBook).timeout(const Duration(milliseconds: 3000));
        if (respBook.statusCode == 200) {
          final List<dynamic> list = jsonDecode(respBook.body);
          bool hasNew = false;
          for (var item in list) {
            if (item is Map<String, dynamic>) {
              final id = (item['id'] ?? item['booking_id'] ?? '').toString();
              if (id.isNotEmpty && (!_inMemoryBookings.containsKey(id) || _inMemoryBookings[id]!['status'] != item['status'])) {
                _inMemoryBookings[id] = item;
                hasNew = true;
              }
            }
          }
          if (hasNew) {
            _writeAllBookings(_inMemoryBookings);
          }
        }
        break;
      } catch (_) {}
    }
  }

  Future<void> _broadcastToHttpBridge(String path, Map<String, dynamic> payload) async {
    if (!kIsWeb) {
      try {
        if (Platform.environment.containsKey('FLUTTER_TEST') ||
            WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
          return;
        }
      } catch (_) {}
    }

    final List<String> hosts = kIsWeb
        ? ['127.0.0.1', 'localhost']
        : ['10.0.2.2', '127.0.0.1', 'localhost'];

    for (final host in hosts) {
      try {
        final uri = Uri.parse('http://$host:8088$path');
        final resp = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(milliseconds: 3000));
        if (resp.statusCode == 200) {
          debugPrint('[SyncBridge] Broadcast to $uri successful.');
        }
        break;
      } catch (err) {
        debugPrint('[SyncBridge] Broadcast attempt to $host failed: $err');
      }
    }
  }

  // --- Bookings Operations ---
  Map<String, dynamic> _readAllBookings() {
    if (!kIsWeb) {
      for (final file in _getBookingFiles()) {
        try {
          if (file is File && file.existsSync()) {
            final content = file.readAsStringSync();
            if (content.trim().isNotEmpty) {
              final decoded = jsonDecode(content) as Map<String, dynamic>;
              decoded.forEach((k, v) {
                if (v is Map<String, dynamic>) {
                  _inMemoryBookings[k] = v;
                }
              });
            }
          }
        } catch (_) {}
      }
    }
    return _inMemoryBookings;
  }

  void _writeAllBookings(Map<String, dynamic> map) {
    map.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        _inMemoryBookings[k] = v;
      }
    });

    if (!kIsWeb) {
      final jsonStr = jsonEncode(_inMemoryBookings);
      for (final file in _getBookingFiles()) {
        try {
          if (file is File) {
            file.writeAsStringSync(jsonStr, flush: true);
          }
        } catch (_) {}
      }
    }
    _broadcastBookingChanges();
  }

  void _broadcastBookingChanges() {
    final allList = getAllBookings();
    if (!_bookingsStreamController.isClosed) {
      _bookingsStreamController.add(allList);
    }
  }

  List<Map<String, dynamic>> getAllBookings() {
    return _inMemoryBookings.values.where((b) {
      if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
        final id = (b['id'] ?? b['booking_id'] ?? '').toString().toLowerCase();
        final name = (b['customer_name'] ?? '').toString().toLowerCase();
        if (id.startsWith('test_') ||
            id == 'booking_unassigned_999' ||
            name.contains('rajiv patel') ||
            name.contains('meera trivedi')) {
          return false;
        }
      }
      return true;
    }).map((b) {
      final bId = (b['id'] ?? b['booking_id'] ?? '').toString();
      if (bId.isNotEmpty && _locallyAcceptedBookingIds.contains(bId)) {
        final copy = Map<String, dynamic>.from(b);
        final curStatus = (copy['status'] ?? '').toString().toUpperCase();
        if (curStatus == 'PENDING' || curStatus == 'SEARCHING_PROVIDER' || curStatus == 'OFFERED_TO_PROVIDERS' || curStatus == 'BROADCASTED') {
          copy['status'] = 'ACCEPTED';
          copy['service_status'] = 'ACCEPTED';
        }
        return copy;
      }
      return b;
    }).toList();
  }

  Stream<Map<String, dynamic>> streamBooking(String bookingId) async* {
    while (true) {
      reloadAllFromDisk();
      final current = getBooking(bookingId);
      if (current != null) {
        yield current;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Map<String, dynamic>? getBooking(String bookingId) {
    return _inMemoryBookings[bookingId];
  }

  Future<Map<String, dynamic>> createACBooking({
    String? id,
    String? bookingId,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? serviceName,
    String? problemDescription,
    String? scheduledDate,
    String? scheduledTime,
    String? serviceDate,
    String? serviceTime,
    String? acBrand,
    String? acAge,
    String? acType,
    String? address,
    String? paymentMethod,
    double? price,
    double? estimatedPrice,
    String? customerAddress,
    double? customerLat,
    double? customerLng,
    String? entrancePin,
    String? completionOtp,
    Map<String, dynamic>? extraData,
  }) async {
    final bId = id ?? bookingId ?? extraData?['booking_id'] ?? extraData?['id'] ?? 'AC_${DateTime.now().millisecondsSinceEpoch}';
    final effectivePrice = price ?? estimatedPrice ?? 499.0;
    final effectiveDate = scheduledDate ?? serviceDate ?? 'Today';
    final effectiveTime = scheduledTime ?? serviceTime ?? 'Immediate';
    final Map<String, dynamic> record = <String, dynamic>{
      'id': bId,
      'booking_id': bId,
      'customer_id': customerId ?? '',
      'customer_name': customerName ?? '',
      'customer_phone': customerPhone ?? '',
      'service_id': extraData?['service_id'] ?? 'ac_service',
      'service_name': serviceName ?? 'AC Service',
      'category': 'AC Service',
      'category_name': 'AC Service Specialist',
      'tracking_id': 'TRK-AC-${DateTime.now().millisecondsSinceEpoch}',
      'problem_description': problemDescription ?? '',
      'status': 'PENDING',
      'service_status': 'PENDING',
      'estimated_amount': effectivePrice,
      'final_amount': effectivePrice,
      'price': effectivePrice,
      'scheduled_date': effectiveDate,
      'scheduled_time_slot': effectiveTime,
      'scheduled_time': effectiveTime,
      'scheduled_at': '$effectiveDate $effectiveTime'.trim(),
      'payment_method': paymentMethod ?? 'Cash after Service',
      'customer_address': customerAddress ?? address ?? '',
      'address': customerAddress ?? address ?? '',
      'customer_lat': customerLat ?? 22.4707,
      'customer_lng': customerLng ?? 70.0577,
      'entrance_pin': entrancePin ?? SecureOtpEngine.instance.generateOtp(userIdOrPhone: customerPhone ?? bId, digits: 4),
      'completion_otp': completionOtp ?? SecureOtpEngine.instance.generateOtp(userIdOrPhone: customerPhone ?? bId, digits: 4),
      'created_at': DateTime.now().toIso8601String(),
    };
    if (extraData != null) {
      extraData.forEach((k, v) {
        record[k] = v;
      });
    }
    final all = _readAllBookings();
    all[bId] = record;
    _writeAllBookings(all);
    await _broadcastToHttpBridge('/api/bookings', record);
    return record;
  }

  Future<void> submitBooking(Map<String, dynamic> bookingData) async {
    final bId = (bookingData['id'] ?? bookingData['booking_id'] ?? 'AC_${DateTime.now().millisecondsSinceEpoch}').toString();
    final all = _readAllBookings();
    final scheduledDate = bookingData['scheduled_date'] ?? 'Today';
    final scheduledTime = bookingData['scheduled_time_slot'] ?? bookingData['scheduled_time'] ?? 'Immediate';
    final scheduledAt = bookingData['scheduled_at'] ?? '$scheduledDate $scheduledTime'.trim();
    final finalAmt = (bookingData['final_amount'] as num?)?.toDouble() ??
        (bookingData['price'] as num?)?.toDouble() ??
        (bookingData['estimated_amount'] as num?)?.toDouble() ??
        499.0;
    final addr = (bookingData['address'] ?? bookingData['customer_address'] ?? '').toString();

    final Map<String, dynamic> record = <String, dynamic>{
      'id': bId,
      'booking_id': bId,
      'customer_id': bookingData['customer_id'] ?? '',
      'customer_name': bookingData['customer_name'] ?? 'Customer',
      'customer_phone': bookingData['customer_phone'] ?? '',
      'service_id': bookingData['service_id'] ?? 'ac_service',
      'service_name': bookingData['service_name'] ?? 'AC Service',
      'category': bookingData['category'] ?? 'AC Service',
      'category_name': bookingData['category_name'] ?? 'AC Service Specialist',
      'status': (bookingData['status'] ?? 'PENDING').toString().toUpperCase(),
      'service_status': (bookingData['status'] ?? 'PENDING').toString().toUpperCase(),
      'partner_id': (bookingData['partner_id'] ?? '').toString(),
      'estimated_amount': (bookingData['estimated_amount'] as num?)?.toDouble() ?? finalAmt,
      'final_amount': finalAmt,
      'price': (bookingData['price'] as num?)?.toDouble() ?? finalAmt,
      'scheduled_date': scheduledDate,
      'scheduled_time_slot': scheduledTime,
      'scheduled_time': scheduledTime,
      'scheduled_at': scheduledAt,
      'address': addr,
      'customer_address': addr,
      'customer_lat': (bookingData['customer_lat'] as num?)?.toDouble() ?? 22.4707,
      'customer_lng': (bookingData['customer_lng'] as num?)?.toDouble() ?? 70.0577,
      'entrance_pin': bookingData['entrance_pin'] ?? SecureOtpEngine.instance.generateOtp(userIdOrPhone: bId, digits: 4),
      'completion_otp': bookingData['completion_otp'] ?? SecureOtpEngine.instance.generateOtp(userIdOrPhone: bId, digits: 4),
      'payment_method': bookingData['payment_method'] ?? 'Cash on Service',
      'tracking_id': bookingData['tracking_id'] ?? 'TRK-AC-${DateTime.now().millisecondsSinceEpoch}',
      'created_at': bookingData['created_at'] ?? DateTime.now().toIso8601String(),
    };

    bookingData.forEach((k, v) {
      record[k] = v;
    });

    all[bId] = record;
    _writeAllBookings(all);
    await _broadcastToHttpBridge('/api/bookings', record);
  }

  List<Map<String, dynamic>> getPendingACOffers({String? categoryId, String? serviceCategoryId}) {
    return getPendingOffersForCategory(categoryId ?? serviceCategoryId ?? 'ac_service');
  }

  Future<void> updatePartnerLocation(
    String bookingId,
    double latitude,
    double longitude, {
    double? distanceMeters,
  }) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking != null) {
      booking['partner_lat'] = latitude;
      booking['partner_lng'] = longitude;
      if (distanceMeters != null) booking['distance_meters'] = distanceMeters;
      booking['partner_location_updated_at'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _writeAllBookings(all);
      await _broadcastToHttpBridge('/api/bookings', booking);
    }
  }

  Future<void> updateBookingStatus(String bookingId, dynamic newStatusOrData) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking != null) {
      if (newStatusOrData is Map<String, dynamic>) {
        booking.addAll(newStatusOrData);
      } else {
        final statusStr = newStatusOrData.toString().toUpperCase();
        booking['status'] = statusStr;
        booking['service_status'] = statusStr;
      }
      all[bookingId] = booking;
      _writeAllBookings(all);
      await _broadcastToHttpBridge('/api/bookings', booking);

      try {
        if (_isSupabaseReady()) {
          final supabase = Supabase.instance.client;
          final statusStr = (booking['status'] ?? 'COMPLETED').toString().toUpperCase();
          await supabase.from('service_bookings').update({
            'status': statusStr,
            'service_status': statusStr,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('booking_id', bookingId);

          if (statusStr == 'COMPLETED') {
            final pId = (booking['partner_id'] ?? '').toString();
            final price = (booking['final_amount'] as num?)?.toDouble() ?? (booking['price'] as num?)?.toDouble() ?? 499.0;
            if (pId.isNotEmpty) {
              try {
                await supabase.from('partner_earnings').insert({
                  'partner_id': pId,
                  'booking_id': bookingId,
                  'gross_amount': price,
                  'net_amount': price * 0.85,
                  'platform_fee': price * 0.15,
                  'earned_at': DateTime.now().toIso8601String(),
                });
              } catch (_) {}
            }
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[LiveBookingSyncService] Supabase status update note: $e');
      }
    }
  }

  Future<void> assignPartnerToBooking({
    required String bookingId,
    required String partnerId,
    String? partnerName,
    String? partnerPhone,
  }) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking != null) {
      booking['partner_id'] = partnerId;
      booking['partner_name'] = partnerName ?? '';
      booking['partner_phone'] = partnerPhone ?? '';
      booking['status'] = 'ASSIGNED';
      booking['service_status'] = 'ASSIGNED';
      all[bookingId] = booking;
      _writeAllBookings(all);
      await _broadcastToHttpBridge('/api/bookings', booking);
    }
  }

  Future<bool> acceptBooking(String bookingId, dynamic partnerDataOrId, [String? partnerName, String? partnerPhone]) async {
    final all = _readAllBookings();
    Map<String, dynamic>? booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking == null) {
      // If not in local cache yet, attempt to fetch from Supabase
      if (_isSupabaseReady()) {
        try {
          final row = await Supabase.instance.client
              .from('service_bookings')
              .select('*, services(service_id, name, category_id), user_addresses(area, city, latitude, longitude)')
              .eq('booking_id', bookingId)
              .maybeSingle();
          if (row != null) {
            final cat = (row['services']?['category_id'] ?? row['category_id'] ?? 'ac_service').toString();
            booking = {
              'id': bookingId,
              'booking_id': bookingId,
              'category_id': cat,
              'status': 'PENDING',
              'service_status': 'PENDING',
              'price': (row['final_amount'] ?? row['estimated_amount'] ?? 499.0) as num,
            };
          }
        } catch (_) {}
      }
    }

    if (booking != null) {
      final currentStatus = (booking['status'] ?? '').toString().toUpperCase();
      // Cannot accept cancelled or expired booking
      if (currentStatus.contains('CANCELLED') || currentStatus == 'EXPIRED' || currentStatus == 'CLOSED') {
        return false;
      }
      final existingPartner = booking['partner_id']?.toString() ?? '';
      // If already claimed by another partner or already accepted, reject duplicate claim
      if (existingPartner.isNotEmpty || currentStatus == 'CONFIRMED' || currentStatus == 'ACCEPTED') {
        return false;
      }

      String pId = '';
      String pName = '';
      String pPhone = '';
      if (partnerDataOrId is Map<String, dynamic>) {
        pId = (partnerDataOrId['partner_id'] ?? partnerDataOrId['id'] ?? partnerDataOrId['user_id'] ?? partnerDataOrId['provider_id'] ?? '').toString();
        pName = (partnerDataOrId['partner_name'] ?? partnerDataOrId['name'] ?? partnerDataOrId['full_name'] ?? partnerDataOrId['username'] ?? '').toString();
        pPhone = (partnerDataOrId['partner_phone'] ?? partnerDataOrId['phone'] ?? '').toString();
      } else if (partnerDataOrId != null) {
        pId = partnerDataOrId.toString();
        pName = partnerName ?? '';
        pPhone = partnerPhone ?? '';
      }

      if (pId.isEmpty) {
        try {
          final cached = await LocalRegistrationCache.getActivePartner() ??
              await LocalRegistrationCache.getActiveServiceProvider();
          pId = (cached?['partner_id'] ?? cached?['id'] ?? cached?['user_id'] ?? cached?['provider_id'] ?? '').toString();
          if (pName.isEmpty) pName = (cached?['partner_name'] ?? cached?['name'] ?? cached?['full_name'] ?? '').toString();
          if (pPhone.isEmpty) pPhone = (cached?['partner_phone'] ?? cached?['phone'] ?? '').toString();
        } catch (_) {}
      }

      if (pId.isEmpty && _isSupabaseReady()) {
        try {
          final curr = Supabase.instance.client.auth.currentUser;
          if (curr != null) pId = curr.id;
        } catch (_) {}
      }

      _locallyAcceptedBookingIds.add(bookingId);
      final altId = (booking['id'] ?? booking['booking_id'] ?? '').toString();
      if (altId.isNotEmpty) _locallyAcceptedBookingIds.add(altId);

      booking['partner_id'] = pId;
      booking['partner_name'] = pName;
      booking['partner_phone'] = pPhone;
      booking['status'] = 'ACCEPTED';
      booking['service_status'] = 'ACCEPTED';
      booking['accepted_at'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _inMemoryBookings[bookingId] = booking;

      final acceptedAtIso = booking['accepted_at'];
      all.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          final id = (v['id'] ?? v['booking_id'] ?? '').toString();
          if (k == bookingId || id == bookingId || (altId.isNotEmpty && id == altId)) {
            v['status'] = 'ACCEPTED';
            v['service_status'] = 'ACCEPTED';
            v['partner_id'] = pId;
            v['partner_name'] = pName;
            v['partner_phone'] = pPhone;
            v['accepted_at'] = acceptedAtIso;
          }
        }
      });
      _inMemoryBookings.forEach((k, v) {
        final id = (v['id'] ?? v['booking_id'] ?? '').toString();
        if (k == bookingId || id == bookingId || (altId.isNotEmpty && id == altId)) {
          v['status'] = 'ACCEPTED';
          v['service_status'] = 'ACCEPTED';
          v['partner_id'] = pId;
          v['partner_name'] = pName;
          v['partner_phone'] = pPhone;
          v['accepted_at'] = acceptedAtIso;
        }
      });

      _writeAllBookings(all);
      _bookingsStreamController.add(getAllBookings());
      await _broadcastToHttpBridge('/api/bookings', booking);

      try {
        if (_isSupabaseReady()) {
          final supabase = Supabase.instance.client;
          final nowIso = DateTime.now().toIso8601String();
          await supabase.from('service_bookings').update({
            'status': 'ACCEPTED',
            'service_status': 'ACCEPTED',
            'partner_id': pId.isNotEmpty ? pId : null,
            'updated_at': nowIso,
          }).eq('booking_id', bookingId);

          if (pId.isNotEmpty) {
            try {
              await supabase.from('booking_requests').update({
                'response_status': 'Accepted',
                'response_at': nowIso,
              }).eq('booking_id', bookingId).filter('partner_id', 'eq', pId);
            } catch (_) {
              try {
                await supabase.from('booking_requests').update({
                  'response_status': 'Accepted',
                  'response_at': nowIso,
                }).eq('booking_id', bookingId);
              } catch (_) {}
            }

            try {
              await supabase.from('booking_requests').update({
                'response_status': 'Expired',
                'response_at': nowIso,
              }).eq('booking_id', bookingId).filter('partner_id', 'neq', pId);
            } catch (_) {}

            try {
              await supabase.from('booking_assignment').upsert({
                'booking_id': bookingId,
                'partner_id': pId,
                'assigned_at': nowIso,
                'status': 'ASSIGNED',
              });
            } catch (_) {}
          }
        }
      } catch (e) {
        if (kDebugMode) debugPrint('[LiveBookingSyncService] Supabase accept note: $e');
      }
      return true;
    }
    return false;
  }

  Future<void> declineBooking(String bookingId) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking != null) {
      booking['status'] = 'CANCELLED';
      booking['service_status'] = 'CANCELLED';
      all[bookingId] = booking;
      _writeAllBookings(all);
      await _broadcastToHttpBridge('/api/bookings', booking);
    }
  }

  Future<void> cancelBooking(String bookingId, [String reason = 'Cancelled by Customer']) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking != null) {
      booking['status'] = 'CANCELLED_BY_CUSTOMER';
      booking['service_status'] = 'CANCELLED_BY_CUSTOMER';
      booking['cancellation_reason'] = reason;
      booking['cancelled_at'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _writeAllBookings(all);
      await _broadcastToHttpBridge('/api/bookings', booking);
    }
  }

  Future<void> updateMilestone(String bookingId, String milestone) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking != null) {
      booking['current_milestone'] = milestone;
      booking['status'] = milestone;
      booking['milestone_updated_at'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _writeAllBookings(all);
      await _broadcastToHttpBridge('/api/bookings', booking);
    }
  }

  Future<void> completeBooking(String bookingId, double grossAmount) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking != null) {
      booking['status'] = 'SERVICE_COMPLETED';
      booking['service_status'] = 'COMPLETED';
      booking['price'] = grossAmount;
      booking['final_amount'] = grossAmount;
      booking['completed_at'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _writeAllBookings(all);
      await _broadcastToHttpBridge('/api/bookings', booking);
    }
  }

  // --- Partner Verification & Admin Approval Sync ---
  Map<String, dynamic> _readAllVerifications() {
    if (!kIsWeb) {
      for (final file in _getVerificationFiles()) {
        try {
          if (file is File && file.existsSync()) {
            final content = file.readAsStringSync();
            if (content.trim().isNotEmpty) {
              final decoded = jsonDecode(content) as Map<String, dynamic>;
              decoded.forEach((k, v) {
                if (v is Map<String, dynamic>) {
                  _inMemoryVerifications[k] = v;
                }
              });
            }
          }
        } catch (_) {}
      }
    }
    return _inMemoryVerifications;
  }

  void _writeAllVerifications(Map<String, dynamic> map) {
    map.forEach((k, v) {
      if (v is Map<String, dynamic>) {
        _inMemoryVerifications[k] = v;
      }
    });

    if (!kIsWeb) {
      final jsonStr = jsonEncode(_inMemoryVerifications);
      for (final file in _getVerificationFiles()) {
        try {
          if (file is File) {
            file.writeAsStringSync(jsonStr, flush: true);
          }
        } catch (_) {}
      }
    }
    _broadcastVerificationChanges();
  }

  void _broadcastVerificationChanges() {
    final allList = getAllPartnerVerifications();
    if (!_verificationsStreamController.isClosed) {
      _verificationsStreamController.add(allList);
    }
  }

  List<Map<String, dynamic>> getAllPartnerVerifications() {
    return _inMemoryVerifications.values.toList();
  }

  Stream<Map<String, dynamic>?> streamPartnerVerification(String partnerId) async* {
    yield getPartnerVerification(partnerId);
    yield* _verificationsStreamController.stream.map((_) => getPartnerVerification(partnerId));
  }

  Map<String, dynamic>? getPartnerVerification(String partnerId) {
    if (partnerId.trim().isEmpty) return null;
    final lower = partnerId.toLowerCase().trim();
    final digits = partnerId.replaceAll(RegExp(r'\D'), '');
    final last10 = digits.length >= 10 ? digits.substring(digits.length - 10) : '';

    // First check exact ID match (highest priority)
    for (final val in _inMemoryVerifications.values) {
      final vId = (val['id'] ?? '').toString().toLowerCase();
      final vVerId = (val['verification_id'] ?? '').toString().toLowerCase();
      final vPartId = (val['partner_id'] ?? '').toString().toLowerCase();

      if (vId == lower || vVerId == lower || (vPartId.isNotEmpty && vPartId == lower)) {
        return val;
      }
    }

    // Secondary match: user_id
    for (final val in _inMemoryVerifications.values) {
      final vUserId = (val['user_id'] ?? '').toString().toLowerCase();
      if (vUserId.isNotEmpty && vUserId == lower) {
        return val;
      }
    }

    // Secondary fallback: only if last10 is at least 10 digits
    if (last10.length >= 10) {
      for (final val in _inMemoryVerifications.values) {
        final vPhone = (val['phone'] ?? val['mobile'] ?? '').toString();
        final vPhoneDigits = vPhone.replaceAll(RegExp(r'\D'), '');
        if (vPhoneDigits.endsWith(last10)) {
          return val;
        }
      }
    }
    return null;
  }

  Future<void> submitPartnerVerification(Map<String, dynamic> partnerData) async {
    final verId = (partnerData['verification_id'] ?? partnerData['id'] ?? 'ver_${DateTime.now().millisecondsSinceEpoch}').toString();
    final all = _readAllVerifications();

    final aiReport = partnerData['ai_report'] as Map<String, dynamic>? ?? {};

    final Map<String, dynamic> record = Map<String, dynamic>.from(partnerData);
    record.remove('password');
    record['id'] = verId;
    record['verification_id'] = verId;
    record['user_id'] = (partnerData['user_id'] ?? partnerData['id'] ?? verId).toString();
    record['name'] = (partnerData['name'] ?? partnerData['full_name'] ?? '').toString();
    record['full_name'] = (partnerData['full_name'] ?? partnerData['name'] ?? '').toString();
    record['phone'] = (partnerData['phone'] ?? partnerData['mobile'] ?? '').toString();
    record['email'] = (partnerData['email'] ?? '').toString();
    record['business_name'] = (partnerData['business_name'] ?? (record['name'].toString().isNotEmpty ? "${record['name']} Services" : 'Service Business')).toString();
    record['category'] = (partnerData['category'] ?? partnerData['service_category_id'] ?? 'ac_service').toString();
    record['category_name'] = (partnerData['category_name'] ?? partnerData['category_title'] ?? 'AC Service Provider').toString();
    record['experience_years'] = (partnerData['experience_years'] ?? '').toString();
    record['city'] = (partnerData['city'] ?? '').toString();
    record['state'] = (partnerData['state'] ?? '').toString();
    record['status'] = (partnerData['verification_status'] ?? partnerData['status'] ?? 'PENDING').toString().toUpperCase();
    record['verification_status'] = (partnerData['verification_status'] ?? partnerData['status'] ?? 'PENDING').toString().toUpperCase();
    record['ai_risk_score'] = (partnerData['ai_risk_score'] as num?)?.toDouble() ?? 0.02;
    record['trust_score'] = (partnerData['trust_score'] as num?)?.toDouble() ?? 99.8;
    record['ai_report'] = aiReport;
    record['submitted_at'] = (partnerData['submitted_at'] ?? DateTime.now().toIso8601String()).toString();
    record['bank_name'] = (partnerData['bank_name'] ?? '').toString();
    record['account_number'] = (partnerData['account_number'] ?? partnerData['bank_account_number'] ?? '').toString();
    record['ifsc_code'] = (partnerData['ifsc_code'] ?? partnerData['bank_ifsc'] ?? '').toString();
    record['account_holder_name'] = (partnerData['account_holder_name'] ?? record['full_name'] ?? '').toString();
    record['aadhaar_number'] = (partnerData['aadhaar_number'] ?? '').toString();
    record['pan_number'] = (partnerData['pan_number'] ?? '').toString();

    // Deduplicate only if exact verId matches, or same user + same role
    final uId = (record['user_id'] ?? '').toString().trim();
    final role = (record['role'] ?? record['role_name'] ?? record['category'] ?? '').toString().toLowerCase();

    for (final existingKey in all.keys.toList()) {
      final existing = all[existingKey];
      if (existing is Map) {
        final exVerId = (existing['verification_id'] ?? existing['id'] ?? '').toString().trim();
        final exUid = (existing['user_id'] ?? '').toString().trim();
        final exRole = (existing['role'] ?? existing['role_name'] ?? existing['category'] ?? '').toString().toLowerCase();

        final isSameApplication = (verId.isNotEmpty && exVerId.isNotEmpty && verId == exVerId) ||
            (uId.isNotEmpty && exUid.isNotEmpty && uId == exUid && role.isNotEmpty && exRole.isNotEmpty && role == exRole);

        if (isSameApplication) {
          all.remove(existingKey);
          _inMemoryVerifications.remove(existingKey);
        }
      }
    }

    all[verId] = record;
    _inMemoryVerifications[verId] = record;
    _writeAllVerifications(all);
    await _broadcastToHttpBridge('/api/verifications', record);
  }

  List<Map<String, dynamic>> getPendingPartnerVerifications() {
    _readAllVerifications();
    final pending = <Map<String, dynamic>>[];
    final Set<String> seenKeys = {};

    _inMemoryVerifications.forEach((id, val) {
      final status = (val['status'] ?? val['verification_status'] ?? '').toString().toUpperCase();
      if (status == 'PENDING' || status == 'PENDING_APPROVAL' || status == 'SUBMITTED' || status == 'UNDER_REVIEW') {
        final verId = (val['verification_id'] ?? val['id'] ?? id).toString().trim();
        if (!seenKeys.contains(verId)) {
          seenKeys.add(verId);
          pending.add(val);
        }
      }
    });
    return pending;
  }

  String getPartnerVerificationStatus(String partnerId) {
    final record = getPartnerVerification(partnerId);
    if (record != null) {
      return (record['status'] ?? record['verification_status'] ?? 'PENDING').toString().toUpperCase();
    }
    return 'PENDING';
  }

      Future<void> approvePartnerVerification(String partnerId) async {
    if (partnerId.trim().isEmpty) return;
    final lower = partnerId.toLowerCase().trim();
    final digits = partnerId.replaceAll(RegExp(r'\D'), '');
    final last10 = digits.length >= 10 ? digits.substring(digits.length - 10) : '';

    final all = _readAllVerifications();
    for (final key in all.keys.toList()) {
      final val = all[key];
      final vId = (val['id'] ?? '').toString().toLowerCase();
      final vVerId = (val['verification_id'] ?? '').toString().toLowerCase();
      final vPartId = (val['partner_id'] ?? '').toString().toLowerCase();
      final vPhone = (val['phone'] ?? val['mobile'] ?? '').toString();
      final vPhoneDigits = vPhone.replaceAll(RegExp(r'\D'), '');

      final matches = key.toLowerCase() == lower ||
          vId == lower ||
          vVerId == lower ||
          (vPartId.isNotEmpty && vPartId == lower) ||
          (last10.length >= 10 && vPhoneDigits.endsWith(last10));

      if (matches) {
        val['status'] = 'APPROVED';
        val['verification_status'] = 'VERIFIED';
        val['approved_at'] = DateTime.now().toIso8601String();
        all[key] = val;
      }
    }
    _writeAllVerifications(all);
    await _broadcastToHttpBridge('/api/verifications/approve', {'id': partnerId});
  }

      Future<void> rejectPartnerVerification(String partnerId, [String? reason]) async {
    if (partnerId.trim().isEmpty) return;
    final lower = partnerId.toLowerCase().trim();
    final digits = partnerId.replaceAll(RegExp(r'\D'), '');
    final last10 = digits.length >= 10 ? digits.substring(digits.length - 10) : '';

    final all = _readAllVerifications();
    for (final key in all.keys.toList()) {
      final val = all[key];
      final vId = (val['id'] ?? '').toString().toLowerCase();
      final vVerId = (val['verification_id'] ?? '').toString().toLowerCase();
      final vPartId = (val['partner_id'] ?? '').toString().toLowerCase();
      final vPhone = (val['phone'] ?? val['mobile'] ?? '').toString();
      final vPhoneDigits = vPhone.replaceAll(RegExp(r'\D'), '');

      final matches = key.toLowerCase() == lower ||
          vId == lower ||
          vVerId == lower ||
          (vPartId.isNotEmpty && vPartId == lower) ||
          (last10.length >= 10 && vPhoneDigits.endsWith(last10));

      if (matches) {
        val['status'] = 'REJECTED';
        val['verification_status'] = 'REJECTED';
        val['rejected_at'] = DateTime.now().toIso8601String();
        if (reason != null && reason.isNotEmpty) val['remarks'] = reason;
        all[key] = val;
      }
    }
    _writeAllVerifications(all);
    await _broadcastToHttpBridge('/api/verifications/reject', {'id': partnerId, 'reason': reason});
  }
}
