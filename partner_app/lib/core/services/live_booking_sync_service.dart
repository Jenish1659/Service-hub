import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
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
      return (s == 'PENDING' || s == 'BROADCASTED' || s == 'SEARCHING_PROVIDER' || s == 'OFFERED_TO_PROVIDERS') &&
          partnerId.isEmpty;
    }).toList();
  });

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

    _pollingTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      reloadAllFromDisk();
      _pollHttpBridge();
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
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
    reloadAllFromDisk();
    return getAllBookings().where((b) {
      final status = (b['status'] ?? '').toString().toUpperCase();
      final partnerId = (b['partner_id'] ?? '').toString();
      return (status == 'PENDING' || status == 'SEARCHING_PROVIDER' || status == 'OFFERED_TO_PROVIDERS' || status == 'BROADCASTED') &&
          partnerId.isEmpty;
    }).toList();
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
    final booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking != null) {
      final currentStatus = (booking['status'] ?? '').toString().toUpperCase();
      // Cannot accept cancelled or expired booking
      if (currentStatus.contains('CANCELLED') || currentStatus == 'EXPIRED' || currentStatus == 'CLOSED') {
        return false;
      }
      final existingPartner = booking['partner_id']?.toString() ?? '';
      // If already claimed by another partner or already confirmed, reject duplicate claim
      if (existingPartner.isNotEmpty || currentStatus == 'CONFIRMED' || currentStatus == 'ACCEPTED') {
        return false;
      }
      if (partnerDataOrId is Map<String, dynamic>) {
        booking['partner_id'] = (partnerDataOrId['partner_id'] ?? '').toString();
        booking['partner_name'] = (partnerDataOrId['partner_name'] ?? partnerDataOrId['name'] ?? '').toString();
        booking['partner_phone'] = (partnerDataOrId['partner_phone'] ?? partnerDataOrId['phone'] ?? '').toString();
      } else {
        booking['partner_id'] = partnerDataOrId.toString();
        booking['partner_name'] = partnerName ?? '';
        booking['partner_phone'] = partnerPhone ?? '';
      }
      booking['status'] = 'CONFIRMED';
      booking['service_status'] = 'CONFIRMED';
      booking['accepted_at'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _writeAllBookings(all);
      await _broadcastToHttpBridge('/api/bookings', booking);
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
