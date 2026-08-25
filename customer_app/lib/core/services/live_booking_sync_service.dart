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

  void dispose() {
    _pollingTimer?.cancel();
    _offersStreamController.close();
    for (var ctrl in _bookingStreamControllers.values) {
      ctrl.close();
    }
  }
}
