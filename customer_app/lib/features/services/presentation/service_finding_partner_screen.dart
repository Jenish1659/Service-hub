import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/live_booking_sync_service.dart';
import '../../bookings/presentation/track_booking_screen.dart';
import '../services/multi_service_booking_service.dart';

/// Universal Finding Partner Radar Screen for all ServiceHub service categories.
/// Listens to Supabase Realtime & LiveBookingSyncService, displays real partner
/// assignment details, and transitions smoothly to live tracking.
class ServiceFindingPartnerScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final String serviceTitle;
  final String address;
  final String selectedDateFormatted;
  final String selectedTime;
  final ServiceCategoryConfig categoryConfig;
  final String customerPhone;

  const ServiceFindingPartnerScreen({
    super.key,
    required this.bookingId,
    required this.serviceTitle,
    required this.address,
    required this.selectedDateFormatted,
    required this.selectedTime,
    required this.categoryConfig,
    required this.customerPhone,
  });

  @override
  ConsumerState<ServiceFindingPartnerScreen> createState() => _ServiceFindingPartnerScreenState();
}

class _ServiceFindingPartnerScreenState extends ConsumerState<ServiceFindingPartnerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;
  StreamSubscription<List<Map<String, dynamic>>>? _liveBookingsSubscription;
  RealtimeChannel? _supabaseRealtimeChannel;
  Timer? _pollingTimer;

  bool _isAssigned = false;
  Map<String, dynamic>? _assignedPartner;
  Map<String, dynamic>? _confirmedBookingRecord;
  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _setupRealtimeListeners();
  }

  void _setupRealtimeListeners() {
    // 1. Listen to in-memory / local sync stream
    _liveBookingsSubscription = LiveBookingSyncService.instance.bookingsStream.listen((bookings) {
      for (final b in bookings) {
        final id = (b['booking_id'] ?? b['id'] ?? '').toString();
        if (id == widget.bookingId) {
          final s = (b['status'] ?? '').toString().toUpperCase();
          if (s == 'CONFIRMED' || s == 'ACCEPTED' || s == 'ASSIGNED') {
            _onPartnerAssigned(b);
            break;
          }
        }
      }
    });

    // 2. Subscribe to Supabase service_bookings table updates
    try {
      _supabaseRealtimeChannel = Supabase.instance.client
          .channel('finding_partner_${widget.bookingId}')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'service_bookings',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'booking_id',
              value: widget.bookingId,
            ),
            callback: (payload) {
              final newRec = payload.newRecord;
              final s = (newRec['status'] ?? '').toString().toUpperCase();
              if (s == 'ACCEPTED' || s == 'ASSIGNED' || s == 'CONFIRMED') {
                _fetchAndAssignPartnerDetails(newRec);
              }
            },
          )
          .subscribe();
    } catch (_) {}

    // 3. Periodic Poll (Backup check every 6 seconds)
    _pollingTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      if (_isAssigned) {
        _pollingTimer?.cancel();
        return;
      }
      try {
        final supabase = Supabase.instance.client;
        final res = await supabase
            .from('service_bookings')
            .select()
            .eq('booking_id', widget.bookingId)
            .maybeSingle();

        if (res != null) {
          final s = (res['status'] ?? '').toString().toUpperCase();
          final pId = (res['partner_id'] ?? '').toString();
          if (pId.isNotEmpty || s == 'ACCEPTED' || s == 'ASSIGNED' || s == 'CONFIRMED') {
            _pollingTimer?.cancel();
            _fetchAndAssignPartnerDetails(res);
          }
        }
      } catch (_) {}
    });
  }

  void _onPartnerAssigned(Map<String, dynamic> bookingRecord) {
    if (!mounted || _isAssigned) return;

    final pName = bookingRecord['partner_name'] ?? 'Verified Professional';
    final pPhone = bookingRecord['partner_phone'] ?? '';
    final pId = bookingRecord['partner_id'] ?? '';
    final pRating = bookingRecord['rating'] ?? bookingRecord['partner_rating'];

    setState(() {
      _isAssigned = true;
      _confirmedBookingRecord = bookingRecord;
      _assignedPartner = {
        'partner_id': pId,
        'name': pName,
        'phone': pPhone,
        'rating': pRating,
        'role': widget.categoryConfig.requiredRole == 'shopkeeper' ? 'Laundry Partner' : 'Service Specialist',
      };
    });
  }

  Future<void> _fetchAndAssignPartnerDetails(Map<String, dynamic> bookingRecord) async {
    if (_isAssigned) return;

    final pId = (bookingRecord['partner_id'] ?? '').toString();
    String partnerName = (bookingRecord['technician_name'] ?? bookingRecord['partner_name'] ?? 'Verified Professional').toString();
    String partnerPhone = (bookingRecord['technician_phone'] ?? bookingRecord['partner_phone'] ?? '').toString();
    dynamic partnerRating = bookingRecord['rating'] ?? bookingRecord['partner_rating'];

    if (pId.isNotEmpty) {
      try {
        final supabase = Supabase.instance.client;
        final pRes = await supabase
            .from('partners')
            .select('partner_id, rating, users(username, phone, user_profiles(first_name, last_name, profile_photo))')
            .eq('partner_id', pId)
            .maybeSingle();

        if (pRes != null) {
          if (pRes['rating'] != null) {
            partnerRating = pRes['rating'];
          }
          final u = pRes['users'] as Map<String, dynamic>?;
          final prof = u?['user_profiles'] as Map<String, dynamic>?;
          final resolvedName = '${prof?['first_name'] ?? ""} ${prof?['last_name'] ?? ""}'.trim();
          if (resolvedName.isNotEmpty) {
            partnerName = resolvedName;
          }
          partnerPhone = (u?['phone'] ?? partnerPhone).toString();
        }
      } catch (_) {}
    }

    if (!mounted) return;

    setState(() {
      _isAssigned = true;
      _confirmedBookingRecord = bookingRecord;
      _assignedPartner = {
        'partner_id': pId,
        'name': partnerName,
        'phone': partnerPhone,
        'rating': partnerRating,
        'role': widget.categoryConfig.requiredRole == 'shopkeeper' ? 'Laundry Partner' : 'Service Specialist',
      };
    });
  }

  Future<void> _handleCancelSearch() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cancel Partner Search?'),
        content: const Text('Are you sure you want to cancel? No charges will be deducted from your wallet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Searching'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Cancel Request', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldCancel == true) {
      setState(() => _isCancelling = true);
      try {
        await LiveBookingSyncService.instance.updateBookingStatus(widget.bookingId, 'CANCELLED_BY_CUSTOMER');
        final supabase = Supabase.instance.client;
        await supabase
            .from('service_bookings')
            .update({'status': 'CANCELLED_BY_CUSTOMER'})
            .eq('booking_id', widget.bookingId);
      } catch (_) {}

      if (mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    }
  }

  void _navigateToTracking() {
    final booking = _confirmedBookingRecord ?? {
      'id': widget.bookingId,
      'booking_id': widget.bookingId,
      'service_name': widget.serviceTitle,
      'customer_address': widget.address,
      'partner_name': _assignedPartner?['name'] ?? 'Verified Professional',
      'partner_phone': _assignedPartner?['phone'] ?? '',
      'status': 'ACCEPTED',
    };

    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TrackBookingScreen(
          bookingId: widget.bookingId,
          initialBookingData: booking,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _radarController.dispose();
    _liveBookingsSubscription?.cancel();
    _pollingTimer?.cancel();
    if (_supabaseRealtimeChannel != null) {
      Supabase.instance.client.removeChannel(_supabaseRealtimeChannel!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () {
            if (_isAssigned) {
              _navigateToTracking();
            } else {
              _handleCancelSearch();
            }
          },
        ),
        title: Text(
          _isAssigned ? 'Partner Assigned!' : 'Finding ${widget.categoryConfig.categoryName}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Animated Radar Beacon / Assigned Pin
              Center(
                child: SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!_isAssigned) ...[
                        AnimatedBuilder(
                          animation: _radarController,
                          builder: (context, child) {
                            return Container(
                              width: 220 * _radarController.value,
                              height: 220 * _radarController.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF3B49DF).withValues(alpha: 0.15 * (1.0 - _radarController.value)),
                              ),
                            );
                          },
                        ),
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFEEF2FF),
                            border: Border.all(color: const Color(0xFFC7D2FE), width: 2),
                          ),
                        ),
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFF3B49DF), Color(0xFF1E1B4B)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.radar_rounded, color: Colors.white, size: 36),
                        ),
                      ] else ...[
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFECFDF5),
                            border: Border.all(color: const Color(0xFF10B981), width: 3),
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 54),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Status Title & Subtitle
              Text(
                _isAssigned ? 'Partner Assigned!' : 'Finding the Best Partner',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isAssigned
                    ? 'Your service partner has accepted the request and is preparing to arrive.'
                    : 'Dispatching to verified ${widget.categoryConfig.categoryName} partners in Jamnagar...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B), height: 1.3),
              ),

              const SizedBox(height: 24),

              // Search Progress Steps or Assigned Partner Card
              if (!_isAssigned) ...[
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      _buildStepRow(Icons.location_searching_rounded, 'Searching nearby technicians in Jamnagar', true),
                      const SizedBox(height: 12),
                      _buildStepRow(Icons.event_available_rounded, 'Checking availability for ${widget.selectedTime}', true),
                      const SizedBox(height: 12),
                      _buildStepRow(Icons.verified_user_outlined, 'Matching verified ${widget.categoryConfig.categoryName}', true),
                      const SizedBox(height: 12),
                      _buildStepRow(Icons.assignment_turned_in_outlined, 'Finalizing assignment', false),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isCancelling ? null : _handleCancelSearch,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFDC2626),
                      side: const BorderSide(color: Color(0xFFFCA5A5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isCancelling
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Cancel Search', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                ),
              ] else ...[
                // Assigned Partner Card
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF10B981), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFFEEF2FF),
                            child: Text(
                              (_assignedPartner?['name'] ?? 'P')[0].toUpperCase(),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF3B49DF)),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _assignedPartner?['name'] ?? 'Partner',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _assignedPartner?['role'] ?? 'Specialist',
                                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          if (_assignedPartner?['rating'] != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 14, color: Color(0xFFD97706)),
                                  const SizedBox(width: 3),
                                  Text(
                                    _assignedPartner!['rating'].toString(),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const Divider(height: 24, color: Color(0xFFF1F5F9)),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 18, color: Color(0xFF64748B)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _navigateToTracking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Track Partner & View Details',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(IconData icon, String title, bool isCompleted) {
    return Row(
      children: [
        Icon(
          isCompleted ? Icons.check_circle_rounded : icon,
          size: 18,
          color: isCompleted ? const Color(0xFF059669) : const Color(0xFF94A3B8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isCompleted ? FontWeight.w600 : FontWeight.normal,
              color: isCompleted ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ],
    );
  }
}
