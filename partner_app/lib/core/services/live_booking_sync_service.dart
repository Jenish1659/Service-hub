import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class LiveBookingSyncService {
  static final LiveBookingSyncService instance = LiveBookingSyncService._internal();
  LiveBookingSyncService._internal() {
    _initFileWatcher();
  }

  final StreamController<List<Map<String, dynamic>>> _offersStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _allBookingsStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final Map<String, StreamController<Map<String, dynamic>>> _bookingStreamControllers = {};

  Stream<List<Map<String, dynamic>>> get incomingOffersStream => _offersStreamController.stream;
  Stream<List<Map<String, dynamic>>> get allBookingsStream => _allBookingsStreamController.stream;

  Stream<Map<String, dynamic>> streamBooking(String bookingId) {
    if (!_bookingStreamControllers.containsKey(bookingId)) {
      _bookingStreamControllers[bookingId] = StreamController<Map<String, dynamic>>.broadcast();
    }
    // Emit current state immediately
    final current = getBooking(bookingId);
    if (current != null) {
      Timer.run(() {
        if (!_bookingStreamControllers[bookingId]!.isClosed) {
          _bookingStreamControllers[bookingId]!.add(current);
        }
      });
    }
    return _bookingStreamControllers[bookingId]!.stream;
  }

  File? _syncFile;
  Timer? _pollingTimer;

  File _getSyncFile() {
    if (_syncFile != null) return _syncFile!;
    final tempDir = Directory.systemTemp;
    _syncFile = File('${tempDir.path}/service_hub_live_bookings.json');
    if (!_syncFile!.existsSync()) {
      _syncFile!.createSync(recursive: true);
      _syncFile!.writeAsStringSync('{}');
    }
    return _syncFile!;
  }

  void _initFileWatcher() {
    try {
      final file = _getSyncFile();
      _pollingTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        _broadcastLocalChanges();
      });
      file.watch().listen((_) {
        _broadcastLocalChanges();
      });
    } catch (_) {}
  }

  Map<String, dynamic> _readAllBookings() {
    try {
      final file = _getSyncFile();
      if (!file.existsSync()) return {};
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) return {};
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _writeAllBookings(Map<String, dynamic> map) {
    try {
      final file = _getSyncFile();
      file.writeAsStringSync(jsonEncode(map));
      _broadcastLocalChanges();
    } catch (_) {}
  }

  void _broadcastLocalChanges() {
    final all = _readAllBookings();
    final pendingOffers = <Map<String, dynamic>>[];
    final allList = <Map<String, dynamic>>[];

    all.forEach((id, val) {
      if (val is Map<String, dynamic>) {
        allList.add(val);
        final status = (val['status'] ?? '').toString().toUpperCase();
        final sName = (val['service_name'] ?? '').toString().toLowerCase();
        final sCat = (val['category'] ?? '').toString().toLowerCase();

        // Strictly target AC Service Providers
        if ((status == 'PENDING' || status == 'SEARCHING_PROVIDER') &&
            (sName.contains('ac') || sName.contains('air') || sCat.contains('ac') || sName.isEmpty)) {
          pendingOffers.add(val);
        }

        if (_bookingStreamControllers.containsKey(id) &&
            !_bookingStreamControllers[id]!.isClosed) {
          _bookingStreamControllers[id]!.add(val);
        }
      }
    });

    if (!_offersStreamController.isClosed) {
      _offersStreamController.add(pendingOffers);
    }
    if (!_allBookingsStreamController.isClosed) {
      _allBookingsStreamController.add(allList);
    }
  }

  Map<String, dynamic>? getBooking(String bookingId) {
    final all = _readAllBookings();
    return all[bookingId] as Map<String, dynamic>?;
  }

  List<Map<String, dynamic>> getAllBookings() {
    final all = _readAllBookings();
    final list = <Map<String, dynamic>>[];
    all.forEach((id, val) {
      if (val is Map<String, dynamic>) {
        list.add(val);
      }
    });
    return list;
  }

  List<Map<String, dynamic>> getPendingACOffers() {
    final all = _readAllBookings();
    final pending = <Map<String, dynamic>>[];
    all.forEach((id, val) {
      if (val is Map<String, dynamic>) {
        final status = (val['status'] ?? '').toString().toUpperCase();
        final sName = (val['service_name'] ?? '').toString().toLowerCase();
        final sCat = (val['category'] ?? '').toString().toLowerCase();
        if ((status == 'PENDING' || status == 'SEARCHING_PROVIDER') &&
            (sName.contains('ac') || sName.contains('air') || sCat.contains('ac') || sName.isEmpty)) {
          pending.add(val);
        }
      }
    });
    return pending;
  }

  Future<Map<String, dynamic>> createACBooking({
    required String customerId,
    required String customerName,
    required String customerPhone,
    required String serviceName,
    required String problemDescription,
    required String scheduledDate,
    required String scheduledTime,
    required String paymentMethod,
    required double price,
    required String customerAddress,
    required double customerLat,
    required double customerLng,
    String category = 'AC Service',
    String entrancePin = '7429',
    String completionOtp = '5892',
  }) async {
    final bookingId = 'bk_${DateTime.now().millisecondsSinceEpoch}';
    final trackingId = 'TRK-AC-${bookingId.substring(bookingId.length - 8).toUpperCase()}';

    final bookingData = {
      'id': bookingId,
      'booking_id': bookingId,
      'tracking_id': trackingId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'service_name': serviceName,
      'category': category,
      'problem_description': problemDescription,
      'scheduled_date': scheduledDate,
      'scheduled_time': scheduledTime,
      'payment_method': paymentMethod,
      'price': price,
      'status': 'PENDING',
      'entrance_pin': entrancePin,
      'completion_otp': completionOtp,
      'customer_address': customerAddress,
      'customer_lat': customerLat,
      'customer_lng': customerLng,
      'partner_id': null,
      'partner_name': null,
      'partner_phone': null,
      'partner_lat': null,
      'partner_lng': null,
      'partner_rating': 4.9,
      'partner_vehicle': 'Honda Activa (GJ-10-AC-4589)',
      'created_at': DateTime.now().toIso8601String(),
    };

    // 1. Write to Shared Live Sync File
    final all = _readAllBookings();
    all[bookingId] = bookingData;
    _writeAllBookings(all);

    // 2. Also try writing to Supabase
    try {
      final client = Supabase.instance.client;
      await client.from('bookings').insert(bookingData);
    } catch (_) {}

    return bookingData;
  }

  Future<void> acceptBooking(String bookingId, Map<String, dynamic> partnerInfo) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>?;
    if (booking != null) {
      final pLat = (partnerInfo['partner_lat'] as num?)?.toDouble() ?? 22.4707;
      final pLng = (partnerInfo['partner_lng'] as num?)?.toDouble() ?? 70.0577;

      booking['status'] = 'CONFIRMED';
      booking['partner_id'] = partnerInfo['partner_id'] ?? partnerInfo['id'] ?? 'prt_ac_9821';
      booking['partner_name'] = partnerInfo['partner_name'] ?? partnerInfo['name'] ?? partnerInfo['business_name'] ?? 'Rajesh Sharma (AC Specialist)';
      booking['partner_phone'] = partnerInfo['partner_phone'] ?? partnerInfo['phone'] ?? '+91 98765 43210';
      booking['partner_rating'] = partnerInfo['partner_rating'] ?? 4.9;
      booking['partner_vehicle'] = partnerInfo['partner_vehicle'] ?? 'Honda Activa (GJ-10-AC-4589)';
      booking['partner_lat'] = pLat;
      booking['partner_lng'] = pLng;
      booking['accepted_at'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _writeAllBookings(all);
    }

    try {
      await Supabase.instance.client
          .from('bookings')
          .update({
            'status': 'CONFIRMED',
            'partner_id': partnerInfo['partner_id'] ?? partnerInfo['id'],
            'partner_name': partnerInfo['partner_name'] ?? partnerInfo['name'],
            'accepted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bookingId);
    } catch (_) {}
  }

  Future<void> updatePartnerLocation(String bookingId, double lat, double lng, {double? distanceMeters}) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>?;
    if (booking != null) {
      booking['partner_lat'] = lat;
      booking['partner_lng'] = lng;
      if (distanceMeters != null) {
        booking['distance_meters'] = distanceMeters;
      }
      booking['last_location_update'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _writeAllBookings(all);
    }
  }

  Future<void> declineBooking(String bookingId) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>?;
    if (booking != null) {
      booking['status'] = 'REJECTED';
      all[bookingId] = booking;
      _writeAllBookings(all);
    }
  }

  Future<void> updateMilestone(String bookingId, String newStatus) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>?;
    if (booking != null) {
      booking['status'] = newStatus;
      all[bookingId] = booking;
      _writeAllBookings(all);
    }

    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': newStatus})
          .eq('id', bookingId);
    } catch (_) {}
  }

  Future<void> completeBooking(String bookingId, double grossAmount) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>?;
    if (booking != null) {
      booking['status'] = 'SERVICE_COMPLETED';
      booking['final_amount'] = grossAmount;
      booking['completed_at'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _writeAllBookings(all);
    }

    try {
      await Supabase.instance.client
          .from('bookings')
          .update({
            'status': 'Completed',
            'price': grossAmount,
          })
          .eq('id', bookingId);
    } catch (_) {}
  }

  // --- Partner Verification & Admin Approval Sync ---
  final StreamController<List<Map<String, dynamic>>> _verificationsStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  Stream<List<Map<String, dynamic>>> get verificationsStream => _verificationsStreamController.stream;

  File? _verificationsFile;

  File _getVerificationsFile() {
    if (_verificationsFile != null) return _verificationsFile!;
    final tempDir = Directory.systemTemp;
    _verificationsFile = File('${tempDir.path}/service_hub_partner_verifications.json');
    if (!_verificationsFile!.existsSync()) {
      _verificationsFile!.createSync(recursive: true);
      _verificationsFile!.writeAsStringSync('{}');
    }
    return _verificationsFile!;
  }

  Map<String, dynamic> _readAllVerifications() {
    try {
      final file = _getVerificationsFile();
      if (!file.existsSync()) return {};
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) return {};
      return jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  void _writeAllVerifications(Map<String, dynamic> map) {
    try {
      final file = _getVerificationsFile();
      file.writeAsStringSync(jsonEncode(map));
      final allList = getAllPartnerVerifications();
      if (!_verificationsStreamController.isClosed) {
        _verificationsStreamController.add(allList);
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> getAllPartnerVerifications() {
    final all = _readAllVerifications();
    final list = <Map<String, dynamic>>[];
    all.forEach((id, val) {
      if (val is Map<String, dynamic>) {
        list.add(val);
      }
    });
    return list;
  }

  Stream<Map<String, dynamic>?> streamPartnerVerification(String partnerId) async* {
    final current = getPartnerVerification(partnerId);
    if (current != null) {
      yield current;
    }
    yield* _verificationsStreamController.stream.map((list) {
      return getPartnerVerification(partnerId);
    });
  }

  Map<String, dynamic>? getPartnerVerification(String partnerId) {
    final all = _readAllVerifications();
    for (final val in all.values) {
      if (val is Map<String, dynamic>) {
        if (val['user_id'] == partnerId || val['id'] == partnerId || val['verification_id'] == partnerId) {
          return val;
        }
      }
    }
    return null;
  }

  Future<void> submitPartnerVerification(Map<String, dynamic> partnerData) async {
    final verId = partnerData['verification_id'] ?? partnerData['id'] ?? 'ver_${DateTime.now().millisecondsSinceEpoch}';
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

    all[verId] = {
      'id': verId,
      'verification_id': verId,
      'user_id': partnerData['id'] ?? partnerData['user_id'] ?? verId,
      'full_name': partnerData['name'] ?? partnerData['full_name'] ?? partnerData['business_name'] ?? 'Rajesh Sharma',
      'phone': partnerData['phone'] ?? partnerData['mobile'] ?? '+91 98765 43210',
      'email': partnerData['email'] ?? 'partner@servicehub.com',
      'business_name': partnerData['business_name'] ?? partnerData['name'] ?? 'Rajesh AC Service Center',
      'category': partnerData['category'] ?? 'ac_service',
      'category_name': partnerData['category_name'] ?? 'AC Service Specialist',
      'experience_years': partnerData['experience_years'] ?? '4 Years',
      'city': partnerData['city'] ?? 'Jamnagar',
      'state': partnerData['state'] ?? 'Gujarat',
      'status': partnerData['verification_status'] ?? 'PENDING',
      'ai_risk_score': partnerData['ai_risk_score'] ?? 0.02,
      'trust_score': partnerData['trust_score'] ?? 99.8,
      'ai_report': aiReport,
      'submitted_at': DateTime.now().toIso8601String(),
    };
    _writeAllVerifications(all);

    try {
      final client = Supabase.instance.client;
      await client.from('verification_requests').insert(all[verId]!);
    } catch (_) {}
  }

  List<Map<String, dynamic>> getPendingPartnerVerifications() {
    final all = _readAllVerifications();
    final pending = <Map<String, dynamic>>[];
    all.forEach((id, val) {
      if (val is Map<String, dynamic>) {
        final status = (val['status'] ?? '').toString().toUpperCase();
        if (status == 'PENDING' || status == 'PENDING_APPROVAL' || status == 'SUBMITTED') {
          pending.add(val);
        }
      }
    });
    return pending;
  }

  String getPartnerVerificationStatus(String partnerId) {
    final record = getPartnerVerification(partnerId);
    if (record != null) {
      return (record['status'] ?? 'PENDING').toString().toUpperCase();
    }
    return 'PENDING';
  }

  Future<void> approvePartnerVerification(String verificationId) async {
    final all = _readAllVerifications();
    String? targetKey;
    for (final entry in all.entries) {
      final val = entry.value;
      if (val is Map<String, dynamic>) {
        if (entry.key == verificationId || val['id'] == verificationId || val['user_id'] == verificationId || val['verification_id'] == verificationId) {
          targetKey = entry.key;
          break;
        }
      }
    }

    if (targetKey != null) {
      all[targetKey]['status'] = 'APPROVED';
      all[targetKey]['verification_status'] = 'VERIFIED';
      all[targetKey]['approved_at'] = DateTime.now().toIso8601String();
      _writeAllVerifications(all);
    }

    try {
      await Supabase.instance.client
          .from('verification_requests')
          .update({'status': 'APPROVED', 'reviewed_at': DateTime.now().toIso8601String()})
          .eq('verification_id', verificationId);
    } catch (_) {}
  }

  Future<void> rejectPartnerVerification(String verificationId, {String reason = 'Document verification failed'}) async {
    final all = _readAllVerifications();
    String? targetKey;
    for (final entry in all.entries) {
      final val = entry.value;
      if (val is Map<String, dynamic>) {
        if (entry.key == verificationId || val['id'] == verificationId || val['user_id'] == verificationId || val['verification_id'] == verificationId) {
          targetKey = entry.key;
          break;
        }
      }
    }

    if (targetKey != null) {
      all[targetKey]['status'] = 'REJECTED';
      all[targetKey]['verification_status'] = 'REJECTED';
      all[targetKey]['rejection_reason'] = reason;
      all[targetKey]['rejected_at'] = DateTime.now().toIso8601String();
      _writeAllVerifications(all);
    }

    try {
      await Supabase.instance.client
          .from('verification_requests')
          .update({'status': 'REJECTED', 'reviewed_at': DateTime.now().toIso8601String()})
          .eq('verification_id', verificationId);
    } catch (_) {}
  }

  void dispose() {
    _pollingTimer?.cancel();
    _offersStreamController.close();
    _allBookingsStreamController.close();
    _verificationsStreamController.close();
    for (var ctrl in _bookingStreamControllers.values) {
      ctrl.close();
    }
  }
}
