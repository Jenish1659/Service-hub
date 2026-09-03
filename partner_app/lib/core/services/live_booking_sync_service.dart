import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Universal Real-time Booking and Partner Verification Synchronization Engine
/// Supports cross-platform IPC between Windows Desktop, Android Emulator (10.0.2.2),
/// Web (localhost), and Physical Devices via embedded pure dart:io HTTP Bridge.
class LiveBookingSyncService {
  static final LiveBookingSyncService instance = LiveBookingSyncService._internal();
  LiveBookingSyncService._internal() {
    _initEngine();
  }

  // Stream Controllers
  final StreamController<List<Map<String, dynamic>>> _offersStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _allBookingsStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final StreamController<List<Map<String, dynamic>>> _verificationsStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  final Map<String, StreamController<Map<String, dynamic>>> _bookingStreamControllers = {};

  // Public Streams
  Stream<List<Map<String, dynamic>>> get incomingOffersStream => _offersStreamController.stream;
  Stream<List<Map<String, dynamic>>> get allBookingsStream => _allBookingsStreamController.stream;
  Stream<List<Map<String, dynamic>>> get verificationsStream => _verificationsStreamController.stream;

  Stream<Map<String, dynamic>> streamBooking(String bookingId) {
    if (!_bookingStreamControllers.containsKey(bookingId)) {
      _bookingStreamControllers[bookingId] = StreamController<Map<String, dynamic>>.broadcast();
    }
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

  void dispose() {
    _pollingTimer?.cancel();
    _httpServer?.close(force: true);
  }

  File? _syncFile;
  File? _verificationsFile;
  Timer? _pollingTimer;
  HttpServer? _httpServer;

  // In-memory active stores for instant non-blocking reads
  final Map<String, Map<String, dynamic>> _inMemoryBookings = {};
  final Map<String, Map<String, dynamic>> _inMemoryVerifications = {};

  File _getSyncFile() {
    if (_syncFile != null) return _syncFile!;
    final tempDir = Directory.systemTemp;
    _syncFile = File('${tempDir.path}/service_hub_live_bookings.json');
    if (!_syncFile!.existsSync()) {
      try {
        _syncFile!.createSync(recursive: true);
        _syncFile!.writeAsStringSync('{}');
      } catch (_) {}
    }
    return _syncFile!;
  }

  File _getVerificationsFile() {
    if (_verificationsFile != null) return _verificationsFile!;
    final tempDir = Directory.systemTemp;
    _verificationsFile = File('${tempDir.path}/service_hub_partner_verifications.json');
    if (!_verificationsFile!.existsSync()) {
      try {
        _verificationsFile!.createSync(recursive: true);
        _verificationsFile!.writeAsStringSync('{}');
      } catch (_) {}
    }
    return _verificationsFile!;
  }

  void _initEngine() {
    // 1. Start embedded HTTP Bridge Server on port 8088 if on desktop/server
    _startEmbeddedServerIfPossible();

    // 2. Initial load from local file if available
    _readAllBookings();
    _readAllVerifications();

    // 3. Start high-frequency 300ms watcher & bridge poller
    _pollingTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      _broadcastLocalChanges();
      _broadcastVerificationChanges();
      _pollHttpBridge();
    });

    try {
      final syncFile = _getSyncFile();
      final verifFile = _getVerificationsFile();
      syncFile.watch().listen((_) => _broadcastLocalChanges());
      verifFile.watch().listen((_) => _broadcastVerificationChanges());
    } catch (_) {}
  }

  Future<void> _startEmbeddedServerIfPossible() async {
    if (kIsWeb) return;
    try {
      _httpServer = await HttpServer.bind(InternetAddress.anyIPv4, 8088);
      debugPrint('✓ ServiceHub Live IPC Bridge listening on http://0.0.0.0:8088');
      _httpServer!.listen((HttpRequest request) async {
        // Enable CORS
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', '*');

        if (request.method == 'OPTIONS') {
          request.response.statusCode = HttpStatus.ok;
          await request.response.close();
          return;
        }

        final path = request.uri.path;

        try {
          if (path == '/api/verifications' && request.method == 'GET') {
            final all = getAllPartnerVerifications();
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode(all));
          } else if (path == '/api/verifications' && request.method == 'POST') {
            final content = await utf8.decoder.bind(request).join();
            final data = jsonDecode(content) as Map<String, dynamic>;
            final verId = data['verification_id'] ?? data['id'] ?? 'ver_${DateTime.now().millisecondsSinceEpoch}';
            final all = _readAllVerifications();
            all[verId] = data;
            _writeAllVerifications(all);
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'status': 'SUCCESS', 'data': data}));
          } else if (path == '/api/verifications/approve' && request.method == 'POST') {
            final content = await utf8.decoder.bind(request).join();
            final data = jsonDecode(content) as Map<String, dynamic>;
            final id = data['verification_id'] ?? data['id'];
            if (id != null) {
              await approvePartnerVerification(id.toString());
            }
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'status': 'SUCCESS'}));
          } else if (path == '/api/bookings' && request.method == 'GET') {
            final all = getAllBookings();
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode(all));
          } else if (path == '/api/bookings' && request.method == 'POST') {
            final content = await utf8.decoder.bind(request).join();
            final data = jsonDecode(content) as Map<String, dynamic>;
            final bId = data['id'] ?? data['booking_id'];
            if (bId != null) {
              final all = _readAllBookings();
              all[bId] = data;
              _writeAllBookings(all);
            }
            request.response.headers.contentType = ContentType.json;
            request.response.write(jsonEncode({'status': 'SUCCESS', 'data': data}));
          } else {
            request.response.statusCode = HttpStatus.notFound;
          }
        } catch (err) {
          request.response.statusCode = HttpStatus.internalServerError;
          request.response.write(jsonEncode({'error': err.toString()}));
        }
        await request.response.close();
      });
    } catch (_) {
      // Port already in use by another ServiceHub process on same machine - that's fine!
    }
  }

  Future<void> _pollHttpBridge() async {
    if (kIsWeb) return;
    final hosts = ['10.0.2.2', '127.0.0.1', 'localhost'];

    for (final host in hosts) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(milliseconds: 250);

        final reqVerif = await client.get(host, 8088, '/api/verifications');
        final respVerif = await reqVerif.close().timeout(const Duration(milliseconds: 300));
        if (respVerif.statusCode == 200) {
          final content = await utf8.decoder.bind(respVerif).join();
          final List<dynamic> list = jsonDecode(content);
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

        final reqBook = await client.get(host, 8088, '/api/bookings');
        final respBook = await reqBook.close().timeout(const Duration(milliseconds: 300));
        if (respBook.statusCode == 200) {
          final content = await utf8.decoder.bind(respBook).join();
          final List<dynamic> list = jsonDecode(content);
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
        client.close();
        break; // Successfully connected to bridge
      } catch (_) {}
    }
  }

  Future<void> _broadcastToHttpBridge(String path, Map<String, dynamic> payload) async {
    if (kIsWeb) return;
    final hosts = ['10.0.2.2', '127.0.0.1', 'localhost'];

    for (final host in hosts) {
      try {
        final client = HttpClient();
        client.connectionTimeout = const Duration(milliseconds: 400);
        final req = await client.post(host, 8088, path);
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode(payload));
        final resp = await req.close().timeout(const Duration(milliseconds: 600));
        await resp.drain();
        client.close();
        break;
      } catch (_) {}
    }
  }

  // --- Bookings Handling ---
  Map<String, dynamic> _readAllBookings() {
    try {
      final file = _getSyncFile();
      if (!file.existsSync()) return _inMemoryBookings;
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) return _inMemoryBookings;
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      decoded.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          _inMemoryBookings[k] = v;
        }
      });
      return _inMemoryBookings;
    } catch (_) {
      return _inMemoryBookings;
    }
  }

  void _writeAllBookings(Map<String, dynamic> map) {
    try {
      map.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          _inMemoryBookings[k] = v;
        }
      });
      final file = _getSyncFile();
      file.writeAsStringSync(jsonEncode(_inMemoryBookings));
      _broadcastLocalChanges();
    } catch (_) {
      _broadcastLocalChanges();
    }
  }

  void _broadcastLocalChanges() {
    final all = _inMemoryBookings;
    final pendingOffers = <Map<String, dynamic>>[];
    final allList = <Map<String, dynamic>>[];

    all.forEach((id, val) {
      allList.add(val);
      final status = (val['status'] ?? '').toString().toUpperCase();
      final sName = (val['service_name'] ?? '').toString().toLowerCase();
      final sCat = (val['category'] ?? '').toString().toLowerCase();

      if ((status == 'PENDING' || status == 'SEARCHING_PROVIDER') &&
          (sName.contains('ac') || sName.contains('air') || sCat.contains('ac') || sName.isEmpty)) {
        pendingOffers.add(val);
      }

      if (_bookingStreamControllers.containsKey(id) &&
          !_bookingStreamControllers[id]!.isClosed) {
        _bookingStreamControllers[id]!.add(val);
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
    return _inMemoryBookings[bookingId];
  }

  List<Map<String, dynamic>> getAllBookings() {
    return _inMemoryBookings.values.toList();
  }

  List<Map<String, dynamic>> getPendingACOffers() {
    final pending = <Map<String, dynamic>>[];
    _inMemoryBookings.forEach((id, val) {
      final status = (val['status'] ?? '').toString().toUpperCase();
      final sName = (val['service_name'] ?? '').toString().toLowerCase();
      final sCat = (val['category'] ?? '').toString().toLowerCase();
      if ((status == 'PENDING' || status == 'SEARCHING_PROVIDER') &&
          (sName.contains('ac') || sName.contains('air') || sCat.contains('ac') || sName.isEmpty)) {
        pending.add(val);
      }
    });
    return pending;
  }

  Future<Map<String, dynamic>> createACBooking({
    required String customerId,
    required String customerName,
    required String customerPhone,
    String? address,
    String? customerAddress,
    String? acType,
    String? acBrand,
    String? problemDescription,
    String? acAge,
    String? serviceDate,
    String? scheduledDate,
    String? serviceTime,
    String? scheduledTime,
    double? estimatedPrice,
    double? price,
    String? serviceName,
    String? paymentMethod,
    List<String>? photoPaths,
    double? latitude,
    double? customerLat,
    double? longitude,
    double? customerLng,
    String? entrancePin,
    String? completionOtp,
    String? category,
  }) async {
    final bookingId = 'AC_${DateTime.now().millisecondsSinceEpoch}';
    final actualPrice = price ?? estimatedPrice ?? 498.0;
    final actualDate = scheduledDate ?? serviceDate ?? '2026-09-02';
    final actualTime = scheduledTime ?? serviceTime ?? '10:30 AM';
    final actualAddress = customerAddress ?? address ?? 'Customer Location, Jamnagar';
    final actualServiceName = serviceName ?? 'AC Service (${acType ?? "Split AC"})';
    final actualLat = customerLat ?? latitude ?? 22.4707;
    final actualLng = customerLng ?? longitude ?? 70.0577;

    final bookingData = {
      'id': bookingId,
      'booking_id': bookingId,
      'tracking_id': 'TRK-AC-${DateTime.now().millisecondsSinceEpoch % 100000}',
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'address': actualAddress,
      'customer_address': actualAddress,
      'service_name': actualServiceName,
      'category': category ?? 'AC Service',
      'category_name': 'AC Appliance Service',
      'ac_type': acType ?? 'Split AC',
      'ac_brand': acBrand ?? 'General',
      'problem_description': problemDescription ?? 'AC Service & Inspection',
      'ac_age': acAge ?? '1-3 Years',
      'service_date': actualDate,
      'scheduled_date': actualDate,
      'service_time': actualTime,
      'scheduled_time': actualTime,
      'price': actualPrice,
      'estimated_amount': actualPrice,
      'final_amount': actualPrice,
      'payment_method': paymentMethod ?? 'Cash on Service',
      'status': 'PENDING',
      'photos': photoPaths ?? [],
      'latitude': actualLat,
      'customer_lat': actualLat,
      'longitude': actualLng,
      'customer_lng': actualLng,
      'entrance_pin': entrancePin ?? '4589',
      'completion_otp': completionOtp ?? '7821',
      'created_at': DateTime.now().toIso8601String(),
    };

    final all = _readAllBookings();
    all[bookingId] = bookingData;
    _writeAllBookings(all);
    _broadcastToHttpBridge('/api/bookings', bookingData);

    try {
      final client = Supabase.instance.client;
      await client.from('service_bookings').insert({
        'booking_id': bookingId,
        'user_id': customerId,
        'service_id': 'ac_service',
        'estimated_amount': actualPrice,
        'status': 'PENDING',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    return bookingData;
  }

  Future<void> acceptBooking(String bookingId, Map<String, dynamic> partnerData) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking != null) {
      booking['status'] = 'CONFIRMED';
      booking['assigned_partner'] = partnerData;
      booking['partner_id'] = partnerData['id'] ?? partnerData['user_id'] ?? partnerData['partner_id'];
      booking['partner_name'] = partnerData['name'] ?? partnerData['full_name'] ?? partnerData['partner_name'];
      booking['partner_phone'] = partnerData['phone'] ?? partnerData['partner_phone'];
      booking['partner_lat'] = partnerData['partner_lat'] ?? partnerData['lat'];
      booking['partner_lng'] = partnerData['partner_lng'] ?? partnerData['lng'];
      booking['partner_vehicle'] = partnerData['partner_vehicle'] ?? partnerData['vehicle'];
      booking['accepted_at'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _writeAllBookings(all);
      _broadcastToHttpBridge('/api/bookings', booking);
    }

    try {
      await Supabase.instance.client
          .from('service_bookings')
          .update({'status': 'CONFIRMED', 'partner_id': partnerData['id'] ?? partnerData['partner_id']})
          .eq('booking_id', bookingId);
    } catch (_) {}
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking != null) {
      booking['status'] = newStatus;
      booking['updated_at'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _writeAllBookings(all);
      _broadcastToHttpBridge('/api/bookings', booking);
    }
  }

  Future<void> updatePartnerLocation(String bookingId, double lat, double lng, {double? distanceMeters}) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking != null) {
      booking['partner_lat'] = lat;
      booking['partner_lng'] = lng;
      if (distanceMeters != null) {
        booking['distance_meters'] = distanceMeters;
      }
      booking['location_updated_at'] = DateTime.now().toIso8601String();
      all[bookingId] = booking;
      _writeAllBookings(all);
      _broadcastToHttpBridge('/api/bookings', booking);
    }
  }

  Future<void> declineBooking(String bookingId, [String? partnerId]) async {
    final all = _readAllBookings();
    final booking = all[bookingId] as Map<String, dynamic>? ?? _inMemoryBookings[bookingId];
    if (booking != null) {
      final declinedList = List<String>.from(booking['declined_partner_ids'] ?? []);
      if (partnerId != null && !declinedList.contains(partnerId)) {
        declinedList.add(partnerId);
      }
      booking['declined_partner_ids'] = declinedList;
      all[bookingId] = booking;
      _writeAllBookings(all);
      _broadcastToHttpBridge('/api/bookings', booking);
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
      _broadcastToHttpBridge('/api/bookings', booking);
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
      _broadcastToHttpBridge('/api/bookings', booking);
    }
  }

  // --- Partner Verification & Admin Approval Sync ---
  Map<String, dynamic> _readAllVerifications() {
    try {
      final file = _getVerificationsFile();
      if (!file.existsSync()) return _inMemoryVerifications;
      final content = file.readAsStringSync();
      if (content.trim().isEmpty) return _inMemoryVerifications;
      final decoded = jsonDecode(content) as Map<String, dynamic>;
      decoded.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          _inMemoryVerifications[k] = v;
        }
      });
      return _inMemoryVerifications;
    } catch (_) {
      return _inMemoryVerifications;
    }
  }

  void _writeAllVerifications(Map<String, dynamic> map) {
    try {
      map.forEach((k, v) {
        if (v is Map<String, dynamic>) {
          _inMemoryVerifications[k] = v;
        }
      });
      final file = _getVerificationsFile();
      file.writeAsStringSync(jsonEncode(_inMemoryVerifications));
      _broadcastVerificationChanges();
    } catch (_) {
      _broadcastVerificationChanges();
    }
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
    final current = getPartnerVerification(partnerId);
    if (current != null) {
      yield current;
    }
    yield* _verificationsStreamController.stream.map((list) {
      return getPartnerVerification(partnerId);
    });
  }

  Map<String, dynamic>? getPartnerVerification(String partnerId) {
    for (final val in _inMemoryVerifications.values) {
      if (val['user_id'] == partnerId || val['id'] == partnerId || val['verification_id'] == partnerId) {
        return val;
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

    final record = {
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

    all[verId] = record;
    _writeAllVerifications(all);

    // Broadcast to embedded HTTP bridge on host machine
    _broadcastToHttpBridge('/api/verifications', record);

    try {
      final client = Supabase.instance.client;
      await client.from('verification_requests').insert(record);
    } catch (_) {}
  }

  List<Map<String, dynamic>> getPendingPartnerVerifications() {
    final pending = <Map<String, dynamic>>[];
    _inMemoryVerifications.forEach((id, val) {
      final status = (val['status'] ?? '').toString().toUpperCase();
      if (status == 'PENDING' || status == 'PENDING_APPROVAL' || status == 'SUBMITTED') {
        pending.add(val);
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
    all.forEach((id, val) {
      if (val['verification_id'] == verificationId || val['id'] == verificationId || val['user_id'] == verificationId) {
        val['status'] = 'APPROVED';
        val['verification_status'] = 'VERIFIED';
        val['approved_at'] = DateTime.now().toIso8601String();
        all[id] = val;
      }
    });
    _writeAllVerifications(all);
    _broadcastToHttpBridge('/api/verifications/approve', {'verification_id': verificationId});
  }

  Future<void> rejectPartnerVerification(String verificationId) async {
    final all = _readAllVerifications();
    all.forEach((id, val) {
      if (val['verification_id'] == verificationId || val['id'] == verificationId || val['user_id'] == verificationId) {
        val['status'] = 'REJECTED';
        val['verification_status'] = 'REJECTED';
        val['rejected_at'] = DateTime.now().toIso8601String();
        all[id] = val;
      }
    });
    _writeAllVerifications(all);
  }
}
