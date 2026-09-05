import 'dart:async';
import 'dart:convert';
import 'dart:io' show Directory, File, Platform;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

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
      return s == 'PENDING' || s == 'BROADCASTED' || s == 'CONFIRMED';
    }).toList();
  });

  Timer? _pollingTimer;

  final Map<String, Map<String, dynamic>> _inMemoryBookings = {};
  final Map<String, Map<String, dynamic>> _inMemoryVerifications = {};

  List<dynamic> _getVerificationFiles() {
    if (kIsWeb) return [];
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

    _pollingTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      reloadAllFromDisk();
      _pollHttpBridge();
    });
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
    final List<String> hosts = kIsWeb
        ? ['127.0.0.1', 'localhost']
        : ['10.0.2.2', '127.0.0.1', 'localhost'];

    for (final host in hosts) {
      try {
        final uriVerif = Uri.parse('http://$host:8088/api/verifications');
        final respVerif = await http.get(uriVerif).timeout(const Duration(milliseconds: 300));
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
        final respBook = await http.get(uriBook).timeout(const Duration(milliseconds: 300));
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
    final List<String> hosts = kIsWeb
        ? ['127.0.0.1', 'localhost']
        : ['10.0.2.2', '127.0.0.1', 'localhost'];

    for (final host in hosts) {
      try {
        final uri = Uri.parse('http://$host:8088$path');
        await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        ).timeout(const Duration(milliseconds: 300));
        break;
      } catch (_) {}
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
    return _inMemoryBookings.values.toList();
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
    final bId = 'AC_${DateTime.now().millisecondsSinceEpoch}';
    final effectivePrice = price ?? estimatedPrice ?? 499.0;
    final effectiveDate = scheduledDate ?? serviceDate ?? 'Today';
    final effectiveTime = scheduledTime ?? serviceTime ?? 'Immediate';
    final Map<String, dynamic> record = <String, dynamic>{
      'id': bId,
      'booking_id': bId,
      'customer_id': customerId ?? 'cust_live_user',
      'customer_name': customerName ?? 'Verified Customer',
      'customer_phone': customerPhone ?? '+91 98980 11223',
      'service_id': 'ac_master_service',
      'service_name': serviceName ?? 'AC Service (Split AC)',
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
      'payment_method': paymentMethod ?? 'Cash after Service',
      'customer_address': customerAddress ?? address ?? 'Patel Colony, Jamnagar',
      'address': customerAddress ?? address ?? 'Patel Colony, Jamnagar',
      'customer_lat': customerLat ?? 22.4707,
      'customer_lng': customerLng ?? 70.0577,
      'entrance_pin': entrancePin ?? '1234',
      'completion_otp': completionOtp ?? '5678',
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
    final Map<String, dynamic> record = <String, dynamic>{
      'id': bId,
      'booking_id': bId,
      'customer_id': bookingData['customer_id'] ?? 'cust_live_user',
      'customer_name': bookingData['customer_name'] ?? 'Verified Customer',
      'customer_phone': bookingData['customer_phone'] ?? '+91 98980 11223',
      'service_id': bookingData['service_id'] ?? 'ac_master_service',
      'service_name': bookingData['service_name'] ?? 'AC Service (Split AC)',
      'status': (bookingData['status'] ?? 'PENDING').toString().toUpperCase(),
      'service_status': (bookingData['status'] ?? 'PENDING').toString().toUpperCase(),
      'estimated_amount': bookingData['estimated_amount'] ?? 499.0,
      'final_amount': bookingData['final_amount'] ?? 499.0,
      'price': bookingData['price'] ?? 499.0,
      'scheduled_date': bookingData['scheduled_date'] ?? 'Today',
      'scheduled_time_slot': bookingData['scheduled_time_slot'] ?? 'Immediate',
      'address': bookingData['address'] ?? 'Patel Colony, Jamnagar, Gujarat',
      'created_at': DateTime.now().toIso8601String(),
    };

    all[bId] = record;
    _writeAllBookings(all);
    await _broadcastToHttpBridge('/api/bookings', record);
  }

  List<Map<String, dynamic>> getPendingACOffers({String? categoryId, String? serviceCategoryId}) {
    reloadAllFromDisk();
    return getAllBookings().where((b) {
      final status = (b['status'] ?? '').toString().toUpperCase();
      return status == 'PENDING' || status == 'CONFIRMED' || status == 'BROADCASTED';
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
      booking['partner_name'] = partnerName ?? 'Rajesh Sharma';
      booking['partner_phone'] = partnerPhone ?? '+91 98765 43210';
      booking['status'] = 'ASSIGNED';
      booking['service_status'] = 'ASSIGNED';
      all[bookingId] = booking;
      _writeAllBookings(all);
      await _broadcastToHttpBridge('/api/bookings', booking);
    }
  }

  Future<void> acceptBooking(String bookingId, dynamic partnerDataOrId, [String? partnerName, String? partnerPhone]) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking != null) {
      if (partnerDataOrId is Map<String, dynamic>) {
        booking['partner_id'] = partnerDataOrId['partner_id'] ?? 'ptr_live';
        booking['partner_name'] = partnerDataOrId['partner_name'] ?? 'Jenish AC Experts';
        booking['partner_phone'] = partnerDataOrId['partner_phone'] ?? '+91 98765 43210';
      } else {
        booking['partner_id'] = partnerDataOrId.toString();
        booking['partner_name'] = partnerName ?? 'Rajesh Sharma';
        booking['partner_phone'] = partnerPhone ?? '+91 98765 43210';
      }
      booking['status'] = 'CONFIRMED';
      booking['service_status'] = 'CONFIRMED';
      booking['accepted_at'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _writeAllBookings(all);
      await _broadcastToHttpBridge('/api/bookings', booking);
    }
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
    while (true) {
      reloadAllFromDisk();
      final current = getPartnerVerification(partnerId);
      yield current;
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }

  Map<String, dynamic>? getPartnerVerification(String partnerId) {
    final clean = partnerId.toLowerCase().replaceAll('shb-', '').replaceAll('partner_', '').replaceAll('ver_', '').replaceAll('+', '').replaceAll(' ', '').trim();
    for (final val in _inMemoryVerifications.values) {
      final vId = (val['id'] ?? '').toString().toLowerCase();
      final vVerId = (val['verification_id'] ?? '').toString().toLowerCase();
      final vUserId = (val['user_id'] ?? '').toString().toLowerCase();
      final vPhone = (val['phone'] ?? '').toString().replaceAll('+', '').replaceAll(' ', '');
      if (vId == partnerId.toLowerCase() || vVerId == partnerId.toLowerCase() || vUserId == partnerId.toLowerCase()) {
        return val;
      }
      if (clean.isNotEmpty && (vId.contains(clean) || vVerId.contains(clean) || vPhone.contains(clean))) {
        return val;
      }
    }
    return null;
  }

  Future<void> submitPartnerVerification(Map<String, dynamic> partnerData) async {
    final verId = (partnerData['verification_id'] ?? partnerData['id'] ?? 'ver_${DateTime.now().millisecondsSinceEpoch}').toString();
    final all = _readAllVerifications();

    final aiReport = partnerData['ai_report'] as Map<String, dynamic>? ?? {
      'ai_risk_score': 0.02,
      'trust_score': 99.8,
      'risk_level': 'LOW_RISK',
      'recommendation': 'RECOMMENDED_FOR_APPROVAL',
      'aadhaar_validation': {'is_valid': true, 'is_verhoeff_valid': true, 'qr_signed': true, 'formatted': 'XXXX-XXXX-4589'},
      'ocr_inspection': {'is_authentic': true, 'confidence': 0.994, 'tampering_detected': false, 'integrity_level': 'HIGH_FIDELITY'},
      'face_biometrics': {'liveness_verified': true, 'match_score': 99.4, 'status': 'MATCH_VERIFIED'},
      'penny_drop': {'is_verified': true, 'bank_name': 'HDFC Bank', 'ifsc': 'HDFC0000123', 'status': 'Verified'},
    };

    final Map<String, dynamic> record = <String, dynamic>{
      'id': verId,
      'verification_id': verId,
      'user_id': (partnerData['id'] ?? partnerData['user_id'] ?? verId).toString(),
      'name': (partnerData['name'] ?? partnerData['full_name'] ?? partnerData['business_name'] ?? 'Partner Candidate').toString(),
      'full_name': (partnerData['full_name'] ?? partnerData['name'] ?? partnerData['business_name'] ?? 'Partner Candidate').toString(),
      'phone': (partnerData['phone'] ?? partnerData['mobile'] ?? '+91 98765 43210').toString(),
      'email': (partnerData['email'] ?? 'partner@servicehub.com').toString(),
      'business_name': (partnerData['business_name'] ?? partnerData['name'] ?? 'Service Center').toString(),
      'category': (partnerData['category'] ?? 'ac_service').toString(),
      'category_name': (partnerData['category_name'] ?? 'AC Service Specialist').toString(),
      'experience_years': (partnerData['experience_years'] ?? '4 Years').toString(),
      'city': (partnerData['city'] ?? 'Jamnagar').toString(),
      'state': (partnerData['state'] ?? 'Gujarat').toString(),
      'status': (partnerData['verification_status'] ?? partnerData['status'] ?? 'PENDING').toString().toUpperCase(),
      'verification_status': (partnerData['verification_status'] ?? partnerData['status'] ?? 'PENDING').toString().toUpperCase(),
      'ai_risk_score': (partnerData['ai_risk_score'] as num?)?.toDouble() ?? 0.02,
      'trust_score': (partnerData['trust_score'] as num?)?.toDouble() ?? 99.8,
      'ai_report': aiReport,
      'submitted_at': (partnerData['submitted_at'] ?? DateTime.now().toIso8601String()).toString(),
    };

    all[verId] = record;
    _writeAllVerifications(all);
    await _broadcastToHttpBridge('/api/verifications', record);

    try {
      final client = Supabase.instance.client;
      await client.from('verification_requests').insert(record);
    } catch (_) {}
  }

  List<Map<String, dynamic>> getPendingPartnerVerifications() {
    _readAllVerifications();
    final pending = <Map<String, dynamic>>[];
    _inMemoryVerifications.forEach((id, val) {
      final status = (val['status'] ?? val['verification_status'] ?? '').toString().toUpperCase();
      if (status == 'PENDING' || status == 'PENDING_APPROVAL' || status == 'SUBMITTED' || status == 'UNDER_REVIEW') {
        pending.add(val);
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
    final all = _readAllVerifications();
    for (final key in all.keys.toList()) {
      final val = all[key];
      if (key == partnerId || val['user_id'] == partnerId || val['verification_id'] == partnerId || val['id'] == partnerId) {
        val['status'] = 'APPROVED';
        val['verification_status'] = 'VERIFIED';
        val['approved_at'] = DateTime.now().toIso8601String();
        all[key] = val;
      }
    }
    _writeAllVerifications(all);
    await _broadcastToHttpBridge('/api/verifications/approve', {'id': partnerId});
  }

  Future<void> rejectPartnerVerification(String partnerId) async {
    final all = _readAllVerifications();
    for (final key in all.keys.toList()) {
      final val = all[key];
      if (key == partnerId || val['user_id'] == partnerId || val['verification_id'] == partnerId || val['id'] == partnerId) {
        val['status'] = 'REJECTED';
        val['verification_status'] = 'REJECTED';
        all[key] = val;
      }
    }
    _writeAllVerifications(all);
    await _broadcastToHttpBridge('/api/verifications/reject', {'id': partnerId});
  }
}
