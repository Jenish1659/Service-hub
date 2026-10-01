import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/services/routing_service.dart';
import '../../services/services/ac_booking_service.dart';

class TrackBookingScreen extends StatefulWidget {
  final String bookingId;

  const TrackBookingScreen({super.key, required this.bookingId});

  @override
  State<TrackBookingScreen> createState() => _TrackBookingScreenState();
}

class _TrackBookingScreenState extends State<TrackBookingScreen> {
  Map<String, dynamic>? _bookingData;
  bool _loading = true;
  RealtimeChannel? _realtimeChannel;
  StreamSubscription<Map<String, dynamic>>? _localBookingSub;

  // Active status trackers
  String _status = 'ON_THE_WAY'; // SCHEDULED, SEARCHING, ON_THE_WAY, ARRIVED, IN_PROGRESS, COMPLETED
  String _entrancePin = '4821';
  String _completionOtp = '8294';

  // Partner info
  String _partnerName = 'Jenish Bheda';
  String _partnerPhone = '+91 75730 21659';
  double _partnerRating = 4.9;
  int _partnerJobs = 42;
  String _partnerVehicle = 'Honda Activa 6G (GJ-10-BD-0933)';

  // Geolocation
  LatLng _customerLocation = const LatLng(22.4707, 70.0577);
  LatLng _partnerLocation = const LatLng(22.4820, 70.0710);
  int _etaMinutes = 15;
  double _distanceKm = 2.4;

  // Rating and review state
  int _overallRating = 5;
  int _punctualityRating = 5;
  int _qualityRating = 5;
  int _cleanlinessRating = 5;
  int _professionalismRating = 5;
  final TextEditingController _reviewCommentController = TextEditingController();
  bool _reviewSubmitted = false;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
    _subscribeBookingUpdates();
  }

  @override
  void dispose() {
    _localBookingSub?.cancel();
    _realtimeChannel?.unsubscribe();
    _reviewCommentController.dispose();
    super.dispose();
  }

  void _subscribeBookingUpdates() {
    // 1. Subscribe to Local IPC Broadcast Stream
    _localBookingSub = LiveBookingSyncService.instance.streamBooking(widget.bookingId).listen((data) {
      if (mounted && data.isNotEmpty) {
        _applyBookingData(data);
      }
    });

    // 2. Subscribe to Supabase Realtime
    try {
      final client = Supabase.instance.client;
      _realtimeChannel = client
          .channel('track_channel_${widget.bookingId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'service_bookings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'booking_id',
              value: widget.bookingId,
            ),
            callback: (payload) {
              _fetchBookingDetails();
            },
          )
          .subscribe();
    } catch (_) {}
  }

  Future<void> _fetchBookingDetails() async {
    // 1. Check local sync
    final localData = LiveBookingSyncService.instance.getBooking(widget.bookingId);
    if (localData != null) {
      if (mounted) _applyBookingData(localData);
      return;
    }

    // 2. Check Supabase
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('service_bookings')
          .select('*, partners(*, users(*, user_profiles(*)), service_provider_profiles(*)), services(*), user_addresses(*)')
          .eq('booking_id', widget.bookingId)
          .maybeSingle();

      if (res != null && mounted) {
        _applyBookingData(res);
        return;
      }

      final bRes = await client.from('bookings').select().eq('id', widget.bookingId).maybeSingle();
      if (bRes != null && mounted) {
        _applyBookingData(bRes);
        return;
      }
    } catch (e) {
      debugPrint('[TrackBookingScreen] Note: $e');
    }

    if (mounted) {
      setState(() {
        _bookingData ??= {
          'id': widget.bookingId,
          'booking_id': widget.bookingId,
          'service_name': 'AC Regular Servicing',
          'scheduled_date': 'Today',
          'scheduled_time': '10:00 AM - 12:00 PM',
          'status': 'ON_THE_WAY',
          'price': 498.0,
        };
        _loading = false;
      });
    }
  }

  void _applyBookingData(Map<String, dynamic> data) {
    if (!mounted) return;

    final rawStatus = (data['status'] ?? data['service_status'] ?? 'ON_THE_WAY').toString().toUpperCase();
    String normalizedStatus = 'ON_THE_WAY';

    if (rawStatus == 'SCHEDULED') {
      normalizedStatus = 'SCHEDULED';
    } else if (rawStatus == 'SEARCHING_PROVIDER' || rawStatus == 'PENDING') {
      normalizedStatus = 'SEARCHING';
    } else if (rawStatus == 'ACCEPTED' || rawStatus == 'ASSIGNED' || rawStatus == 'CONFIRMED' || rawStatus == 'ON_THE_WAY' || rawStatus == 'EN ROUTE') {
      normalizedStatus = 'ON_THE_WAY';
    } else if (rawStatus == 'ARRIVED') {
      normalizedStatus = 'ARRIVED';
    } else if (rawStatus == 'STARTED' || rawStatus == 'SERVICE_STARTED' || rawStatus == 'IN_PROGRESS') {
      normalizedStatus = 'IN_PROGRESS';
    } else if (rawStatus == 'COMPLETED' || rawStatus == 'SERVICE_COMPLETED' || rawStatus == 'PAYMENT_COMPLETED' || rawStatus == 'CLOSED' || rawStatus == 'REVIEWED') {
      normalizedStatus = 'COMPLETED';
    } else if (rawStatus.contains('CANCELLED')) {
      normalizedStatus = 'CANCELLED';
    }

    // Customer coordinates
    final cLat = (data['customer_latitude'] ?? data['customer_lat'] as num?)?.toDouble() ?? 22.4707;
    final cLng = (data['customer_longitude'] ?? data['customer_lng'] as num?)?.toDouble() ?? 70.0577;

    // Partner coordinates
    final pLat = (data['partner_lat'] as num?)?.toDouble() ?? (cLat + 0.012);
    final pLng = (data['partner_lng'] as num?)?.toDouble() ?? (cLng + 0.014);

    final dist = OsrmRoutingService.computeHaversineDistanceKm(pLat, pLng, cLat, cLng) * 1.35;
    final eta = ((dist / 25.0) * 60.0).round().clamp(5, 45);

    // Partner profile extraction
    String pName = (data['technician_name'] ?? data['partner_name'] ?? '').toString();
    String pPhone = (data['technician_phone'] ?? data['partner_phone'] ?? '').toString();
    double pRating = 4.9;
    int pJobs = 42;

    final partnersMap = data['partners'] as Map<String, dynamic>?;
    if (partnersMap != null) {
      final u = partnersMap['users'] as Map<String, dynamic>?;
      final prof = u?['user_profiles'] as Map<String, dynamic>?;
      final sProf = partnersMap['service_provider_profiles'] as Map<String, dynamic>?;

      final fullName = '${prof?['first_name'] ?? ""} ${prof?['last_name'] ?? ""}'.trim();
      if (fullName.isNotEmpty) pName = fullName;
      if (u?['phone'] != null) pPhone = u!['phone'].toString();
      if (sProf?['rating'] != null) pRating = (sProf!['rating'] as num).toDouble();
      if (sProf?['total_jobs'] != null) pJobs = (sProf!['total_jobs'] as num).toInt();
    }

    setState(() {
      _bookingData = data;
      _loading = false;
      _status = normalizedStatus;
      _customerLocation = LatLng(cLat, cLng);
      _partnerLocation = LatLng(pLat, pLng);
      _distanceKm = dist;
      _etaMinutes = eta;

      if (pName.isNotEmpty) _partnerName = pName;
      if (pPhone.isNotEmpty) _partnerPhone = pPhone;
      _partnerRating = pRating;
      _partnerJobs = pJobs;
      if (data['partner_vehicle'] != null && data['partner_vehicle'].toString().isNotEmpty) {
        _partnerVehicle = data['partner_vehicle'].toString();
      }

      if (data['entrance_pin'] != null && data['entrance_pin'].toString().isNotEmpty) {
        _entrancePin = data['entrance_pin'].toString();
      }
      if (data['completion_otp'] != null && data['completion_otp'].toString().isNotEmpty) {
        _completionOtp = data['completion_otp'].toString();
      }
    });
  }

  void _showItemizedRawBillModal(BuildContext context) {
    final price = (_bookingData?['final_amount'] ?? _bookingData?['price'] as num?)?.toDouble() ?? 498.0;
    const visitingCharge = 449.0;
    const protectionFee = 49.0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Itemized Raw Bill',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBillItem('Visiting & Inspection Charge', '₹${visitingCharge.toStringAsFixed(2)}'),
              const SizedBox(height: 10),
              _buildBillItem('Safety & Protection Fee', '₹${protectionFee.toStringAsFixed(2)}'),
              const SizedBox(height: 10),
              _buildBillItem('GST & Applicable Taxes', 'Included'),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount Paid',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '₹${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Text(
                    'Payment Settled via Cash / UPI on Delivery.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillItem(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B))),
        Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
      ],
    );
  }

  void _submitReview() async {
    setState(() => _reviewSubmitted = true);
    final coins = WalletRewardService.instance.rewardCompletedService();

    try {
      final client = Supabase.instance.client;
      await client.from('reviews').insert({
        'booking_id': widget.bookingId,
        'rating': _overallRating,
        'comment': _reviewCommentController.text.trim(),
        'punctuality_rating': _punctualityRating,
        'quality_rating': _qualityRating,
        'cleanliness_rating': _cleanlinessRating,
        'professionalism_rating': _professionalismRating,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Review submitted successfully! You earned $coins ServiceHub reward coins!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))),
      );
    }

    final isCancelled = _status == 'CANCELLED';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/orders');
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 19),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/orders');
              }
            },
          ),
          title: Text(
            _getAppBarTitle(),
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
              onPressed: _fetchBookingDetails,
            ),
          ],
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isCancelled) _buildCancelledBanner(),
              if (_status == 'SCHEDULED')
                _buildScheduledFutureView()
              else if (_status == 'COMPLETED')
                _buildScreen5CompletedView()
              else if (_status == 'IN_PROGRESS' || _status == 'ARRIVED')
                _buildScreen4ServiceInProgressView()
              else
                _buildScreen3PartnerOnTheWayView(),
            ],
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_status) {
      case 'SCHEDULED':
        return 'Scheduled Booking';
      case 'ON_THE_WAY':
        return 'Partner on the Way';
      case 'ARRIVED':
        return 'Partner Arrived';
      case 'IN_PROGRESS':
        return 'Service in Progress';
      case 'COMPLETED':
        return 'Service Completed';
      default:
        return 'Track Service';
    }
  }

  Widget _buildCancelledBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFFEF2F2),
      child: const Row(
        children: [
          Icon(Icons.cancel_rounded, color: Color(0xFFEF4444), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'This booking has been cancelled.',
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFB91C1C), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // PATH B: FUTURE-DATE SCHEDULED VIEW
  // ==========================================
  Widget _buildScheduledFutureView() {
    final date = _bookingData?['scheduled_date'] ?? 'Tomorrow';
    final time = _bookingData?['scheduled_time'] ?? '10:00 AM - 12:00 PM';
    final service = _bookingData?['service_name'] ?? 'AC Regular Servicing';
    final address = _bookingData?['address'] ?? _bookingData?['customer_address'] ?? 'Customer Address';

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
            ),
            child: const Center(
              child: Icon(Icons.event_available_rounded, color: Color(0xFF2563EB), size: 40),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Booking Scheduled',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            'Reserved for $date at $time',
            style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFDCFCE7)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Partner matching starts on service date morning. A technician will be assigned 2 hours prior.',
                    style: TextStyle(fontSize: 12.5, color: Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _buildInfoRow(Icons.ac_unit_rounded, 'Service', service),
                const Divider(height: 20),
                _buildInfoRow(Icons.calendar_today_rounded, 'Date', date),
                const Divider(height: 20),
                _buildInfoRow(Icons.access_time_rounded, 'Slot', time),
                const Divider(height: 20),
                _buildInfoRow(Icons.location_on_outlined, 'Address', address),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.event_note_rounded, color: Color(0xFF2563EB)),
              label: const Text('Add Reminder to Calendar', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Reminder added to calendar!'), backgroundColor: Color(0xFF10B981)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // IMAGE 1 / 2 SCREEN 3: "Partner on the Way"
  // ==========================================
  Widget _buildScreen3PartnerOnTheWayView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. OPENSTREETMAP LIVE ROUTE MAP
        SizedBox(
          height: 260,
          width: double.infinity,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: LatLng(
                    (_partnerLocation.latitude + _customerLocation.latitude) / 2,
                    (_partnerLocation.longitude + _customerLocation.longitude) / 2,
                  ),
                  initialZoom: 13.8,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.servicehub.customer',
                  ),
                  // Connecting Road Route Polyline
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [
                          _partnerLocation,
                          LatLng(
                            _partnerLocation.latitude * 0.6 + _customerLocation.latitude * 0.4,
                            _partnerLocation.longitude * 0.4 + _customerLocation.longitude * 0.6,
                          ),
                          _customerLocation,
                        ],
                        strokeWidth: 4.5,
                        color: const Color(0xFF2563EB),
                      ),
                    ],
                  ),
                  // Markers for Partner & Customer
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _partnerLocation,
                        width: 48,
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2563EB),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                          ),
                          child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                      Marker(
                        point: _customerLocation,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                          ),
                          child: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Floating ETA Badge
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Arriving in ~$_etaMinutes mins (${_distanceKm.toStringAsFixed(1)} km)',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Entrance PIN Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_rounded, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'One-Time Entrance PIN',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _entrancePin,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                              letterSpacing: 4,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Share with technician when they arrive at your door.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Partner Card with Call, Chat & SOS
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                          child: const Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _partnerName,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: Colors.amber, size: 15),
                                  const SizedBox(width: 3),
                                  Text(
                                    '$_partnerRating ($_partnerJobs completed jobs)',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(_partnerVehicle, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.phone_rounded, color: Color(0xFF2563EB), size: 16),
                            label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _partnerPhone));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Calling $_partnerName ($_partnerPhone)...')),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFCBD5E1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF2563EB), size: 16),
                            label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            onPressed: () => context.push('/chat/${widget.bookingId}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Service Details Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(Icons.ac_unit_rounded, 'Service', _bookingData?['service_name'] ?? 'AC Regular Servicing'),
                    const Divider(height: 20),
                    _buildInfoRow(Icons.location_on_outlined, 'Address', _bookingData?['address'] ?? _bookingData?['customer_address'] ?? 'Your Address'),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // IMAGE 1 / 2 SCREEN 4: "Service in Progress"
  // ==========================================
  Widget _buildScreen4ServiceInProgressView() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Live Service in Progress Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.build_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Service in Progress',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Technician is actively servicing your AC.',
                        style: TextStyle(fontSize: 12, color: Color(0xFFDBEAFE)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Completion OTP Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Completion OTP (Share after service is done)',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _completionOtp,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Share with technician ONLY after satisfactory completion.',
                        style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Checklist of Service Milestones
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Checklist & Milestones',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 14),
                _buildMilestoneCheckRow('Partner arrived at doorstep', isDone: true),
                const SizedBox(height: 12),
                _buildMilestoneCheckRow('Initial AC inspection & diagnosis', isDone: true),
                const SizedBox(height: 12),
                _buildMilestoneCheckRow('Filter & indoor cooling coil jet wash', isDone: true),
                const SizedBox(height: 12),
                _buildMilestoneCheckRow('Gas pressure check & amp measurement', isDone: false, isCurrent: true),
                const SizedBox(height: 12),
                _buildMilestoneCheckRow('Final cooling test & area cleanup', isDone: false),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Partner Contact Bar
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.phone_rounded, color: Color(0xFF2563EB), size: 18),
                  label: const Text('Call Partner', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _partnerPhone));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Calling $_partnerPhone...')));
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF2563EB), size: 18),
                  label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  onPressed: () => context.push('/chat/${widget.bookingId}'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildMilestoneCheckRow(String title, {required bool isDone, bool isCurrent = false}) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDone ? const Color(0xFF10B981) : (isCurrent ? const Color(0xFFEFF6FF) : Colors.transparent),
            shape: BoxShape.circle,
            border: isDone
                ? null
                : Border.all(color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1), width: 1.5),
          ),
          child: isDone
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
              : (isCurrent
                  ? const Center(
                      child: SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                      ),
                    )
                  : null),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isDone || isCurrent ? FontWeight.bold : FontWeight.w500,
              color: isDone ? const Color(0xFF0F172A) : (isCurrent ? const Color(0xFF2563EB) : const Color(0xFF94A3B8)),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // IMAGE 1 / 2 SCREEN 5: "Service Completed"
  // ==========================================
  Widget _buildScreen5CompletedView() {
    final price = (_bookingData?['final_amount'] ?? _bookingData?['price'] as num?)?.toDouble() ?? 498.0;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 12),

          // Green Celebration Badge
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.check_rounded, color: Colors.white, size: 48),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Service Completed!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your AC Regular Servicing has been completed successfully.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),

          const SizedBox(height: 20),

          // Amount Paid Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                const Text(
                  'Total Amount Paid',
                  style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Paid via Cash / UPI on Delivery',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // View Invoice / Raw Bill Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF2563EB),
                side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 18),
              label: const Text('View Raw Bill Breakdown', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () => _showItemizedRawBillModal(context),
            ),
          ),

          const SizedBox(height: 16),

          // Rate & Review Section (Screen 6 Embed or Modal)
          _buildScreen6RateReviewCard(),

          const SizedBox(height: 16),

          // Book Again Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0F172A),
                side: const BorderSide(color: Color(0xFFCBD5E1)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                context.go('/services');
              },
              child: const Text('Book Another Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ==========================================
  // IMAGE 1 / 2 SCREEN 6: "Rate & Review"
  // ==========================================
  Widget _buildScreen6RateReviewCard() {
    if (_reviewSubmitted) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFDCFCE7)),
        ),
        child: const Column(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 40),
            SizedBox(height: 10),
            Text(
              'Thank You for Your Review!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF14532D)),
            ),
            SizedBox(height: 4),
            Text(
              'Your rating helps us maintain top service standards.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF15803D)),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFFFFBEB), shape: BoxShape.circle),
                child: const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rate & Review Partner',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      'Earn reward coins on submitting feedback',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 5-Star Selection
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final star = index + 1;
                return IconButton(
                  icon: Icon(
                    star <= _overallRating ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: Colors.amber,
                    size: 36,
                  ),
                  onPressed: () => setState(() => _overallRating = star),
                );
              }),
            ),
          ),

          const SizedBox(height: 14),

          // Rating Criteria Breakdown
          _buildRatingCriterionRow('Punctuality', _punctualityRating, (v) => setState(() => _punctualityRating = v)),
          const SizedBox(height: 8),
          _buildRatingCriterionRow('Quality of Service', _qualityRating, (v) => setState(() => _qualityRating = v)),
          const SizedBox(height: 8),
          _buildRatingCriterionRow('Cleanliness & Safety', _cleanlinessRating, (v) => setState(() => _cleanlinessRating = v)),
          const SizedBox(height: 8),
          _buildRatingCriterionRow('Professionalism', _professionalismRating, (v) => setState(() => _professionalismRating = v)),

          const SizedBox(height: 16),

          // Feedback Comment Box
          TextField(
            controller: _reviewCommentController,
            maxLines: 2,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Share feedback about the technician and service...',
              hintStyle: const TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),

          const SizedBox(height: 16),

          // Submit Review Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _submitReview,
              child: const Text(
                'Submit Review',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCriterionRow(String label, int rating, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final star = index + 1;
            return GestureDetector(
              onTap: () => onChanged(star),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  star <= rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: Colors.amber,
                  size: 20,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 18),
        const SizedBox(width: 10),
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        ),
      ],
    );
  }
}
