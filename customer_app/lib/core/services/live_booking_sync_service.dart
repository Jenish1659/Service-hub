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
  final Map<String, StreamController<Map<String, dynamic>>> _bookingStreamControllers = {};

  Stream<List<Map<String, dynamic>>> get incomingOffersStream => _offersStreamController.stream;

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
      _pollingTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
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

    all.forEach((id, val) {
      if (val is Map<String, dynamic>) {
        final status = (val['status'] ?? '').toString().toUpperCase();
        final sName = (val['service_name'] ?? '').toString().toLowerCase();
        if ((status == 'PENDING' || status == 'SEARCHING_PROVIDER') &&
            (sName.contains('ac') || sName.contains('air') || sName.isEmpty)) {
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
  }

  Map<String, dynamic>? getBooking(String bookingId) {
    final all = _readAllBookings();
    return all[bookingId] as Map<String, dynamic>?;
  }

  List<Map<String, dynamic>> getPendingACOffers() {
    final all = _readAllBookings();
    final pending = <Map<String, dynamic>>[];
    all.forEach((id, val) {
      if (val is Map<String, dynamic>) {
        final status = (val['status'] ?? '').toString().toUpperCase();
        final sName = (val['service_name'] ?? '').toString().toLowerCase();
        if ((status == 'PENDING' || status == 'SEARCHING_PROVIDER') &&
            (sName.contains('ac') || sName.contains('air') || sName.isEmpty)) {
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
    String entrancePin = '7429',
    String completionOtp = '5892',
  }) async {
    final bookingId = 'bk_${DateTime.now().millisecondsSinceEpoch}';
    final bookingData = {
      'id': bookingId,
      'booking_id': bookingId,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'service_name': serviceName,
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
      booking['status'] = 'CONFIRMED';
      booking['partner_id'] = partnerInfo['partner_id'] ?? '';
      booking['partner_name'] = partnerInfo['partner_name'] ?? 'Jenish AC Experts';
      booking['partner_phone'] = partnerInfo['partner_phone'] ?? '+91 98765 43210';
      booking['accepted_at'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _writeAllBookings(all);
    }

    try {
      await Supabase.instance.client
          .from('bookings')
          .update({'status': 'CONFIRMED'})
          .eq('id', bookingId);
    } catch (_) {}
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
      final pending = getPendingPartnerVerifications();
      if (!_verificationsStreamController.isClosed) {
        _verificationsStreamController.add(pending);
      }
    } catch (_) {}
  }

  Future<void> submitPartnerVerification(Map<String, dynamic> partnerData) async {
    final verId = partnerData['verification_id'] ?? partnerData['id'] ?? 'ver_${DateTime.now().millisecondsSinceEpoch}';
    final all = _readAllVerifications();
    all[verId] = {
      'id': verId,
      'verification_id': verId,
      'user_id': partnerData['id'] ?? partnerData['user_id'] ?? verId,
      'full_name': partnerData['name'] ?? partnerData['business_name'] ?? 'Partner Provider',
      'phone': partnerData['phone'] ?? partnerData['mobile'] ?? '+91 98765 43210',
      'business_name': partnerData['business_name'] ?? 'Jenish AC Care',
      'category': partnerData['category'] ?? 'AC Repair & Service',
      'experience_years': partnerData['experience_years'] ?? '5+',
      'status': 'PENDING',
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
        if (status == 'PENDING' || status == 'PENDING_APPROVAL') {
          pending.add(val);
        }
      }
    });
    return pending;
  }

  String getPartnerVerificationStatus(String partnerId) {
    final all = _readAllVerifications();
    for (final val in all.values) {
      if (val is Map<String, dynamic>) {
        if (val['user_id'] == partnerId || val['id'] == partnerId || val['verification_id'] == partnerId) {
          return (val['status'] ?? 'PENDING').toString().toUpperCase();
        }
      }
    }
    return 'APPROVED'; // Default approved for active test sessions
  }

  Future<void> approvePartnerVerification(String verificationId) async {
    final all = _readAllVerifications();
    if (all.containsKey(verificationId)) {
      all[verificationId]['status'] = 'APPROVED';
      all[verificationId]['approved_at'] = DateTime.now().toIso8601String();
      _writeAllVerifications(all);
    }

    try {
      await Supabase.instance.client
          .from('verification_requests')
          .update({'status': 'APPROVED', 'reviewed_at': DateTime.now().toIso8601String()})
          .eq('verification_id', verificationId);
    } catch (_) {}
  }

  Future<void> rejectPartnerVerification(String verificationId) async {
    final all = _readAllVerifications();
    if (all.containsKey(verificationId)) {
      all[verificationId]['status'] = 'REJECTED';
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
    _verificationsStreamController.close();
    for (var ctrl in _bookingStreamControllers.values) {
      ctrl.close();
    }
  }
}
