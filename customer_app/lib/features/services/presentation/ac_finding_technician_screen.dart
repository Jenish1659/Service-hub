import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/live_booking_sync_service.dart';

class ACFindingTechnicianScreen extends StatefulWidget {
  final String bookingId;
  final Map<String, dynamic> bookingData;
  final String serviceTitle;
  final String address;
  final String selectedDateFormatted;
  final String selectedTime;

  const ACFindingTechnicianScreen({
    super.key,
    required this.bookingId,
    this.bookingData = const {},
    this.serviceTitle = 'AC Service',
    this.address = '',
    this.selectedDateFormatted = 'Tomorrow',
    this.selectedTime = '02:00 PM',
  });

  @override
  State<ACFindingTechnicianScreen> createState() => _ACFindingTechnicianScreenState();
}

class _ACFindingTechnicianScreenState extends State<ACFindingTechnicianScreen> with TickerProviderStateMixin {
  int _currentStep = 0; // 0: Searching, 1: Checking availability, 2: Matching best partner, 3: Finalizing assignment, 4: Assigned
  bool _isAssigned = false;
  Map<String, dynamic>? _assignedPartner;
  bool _isCancelling = false;

  Timer? _stepTimer;
  Timer? _pollingTimer;
  StreamSubscription? _localBookingSub;
  RealtimeChannel? _supabaseRealtimeChannel;

  late AnimationController _radarController;
  late AnimationController _spinnerController;

  @override
  void initState() {
    super.initState();

    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _startSearchPhaseProgress();
    _subscribeToLivePartnerAcceptance();
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    _pollingTimer?.cancel();
    _localBookingSub?.cancel();
    if (_supabaseRealtimeChannel != null) {
      try {
        Supabase.instance.client.removeChannel(_supabaseRealtimeChannel!);
      } catch (_) {}
    }
    _radarController.dispose();
    _spinnerController.dispose();
    super.dispose();
  }

  /// Progresses visually through the searching phases (0 -> 1 -> 2 -> 3)
  /// Crucial rule: Stays at step 3 until a real partner acceptance arrives!
  void _startSearchPhaseProgress() {
    _stepTimer = Timer(const Duration(milliseconds: 1000), () {
      if (!mounted || _isAssigned) return;
      setState(() => _currentStep = 1);

      _stepTimer = Timer(const Duration(milliseconds: 1200), () {
        if (!mounted || _isAssigned) return;
        setState(() => _currentStep = 2);

        _stepTimer = Timer(const Duration(milliseconds: 1400), () {
          if (!mounted || _isAssigned) return;
          setState(() => _currentStep = 3); // Awaiting acceptance
        });
      });
    });
  }

  void _subscribeToLivePartnerAcceptance() {
    // 1. Subscribe to Local Realtime IPC Broadcast Stream
    _localBookingSub = LiveBookingSyncService.instance.bookingsStream.listen((list) {
      for (final b in list) {
        final id = (b['booking_id'] ?? b['id'] ?? '').toString();
        if (id == widget.bookingId) {
          final s = (b['status'] ?? '').toString().toUpperCase();
          if (s == 'CONFIRMED' || s == 'ACCEPTED' || s == 'ASSIGNED') {
            _onRealPartnerAccepted(b);
            break;
          }
        }
      }
    });

    // 2. Subscribe to Supabase service_bookings table updates
    try {
      _supabaseRealtimeChannel = Supabase.instance.client
          .channel('finding_tech_${widget.bookingId}')
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

    // 3. Periodic Poll (Every 2 seconds)
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (_isAssigned) {
        _pollingTimer?.cancel();
        return;
      }
      try {
        final supabase = Supabase.instance.client;
        final res = await supabase
            .from('service_bookings')
            .select('*, partners(*, users(*, user_profiles(*)), service_provider_profiles(*))')
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

  Future<void> _fetchAndAssignPartnerDetails(Map<String, dynamic> bookingRecord) async {
    if (_isAssigned) return;

    final pId = (bookingRecord['partner_id'] ?? '').toString();
    Map<String, dynamic> partnerInfo = {
      'partner_id': pId,
      'name': bookingRecord['technician_name'] ?? bookingRecord['partner_name'] ?? 'Jenish Bheda',
      'phone': bookingRecord['technician_phone'] ?? bookingRecord['partner_phone'] ?? '+91 75730 21659',
      'rating': 4.9,
      'total_jobs': 42,
      'experience_years': 5,
      'specialty': 'Certified AC Jet Cleaning, Gas Refill & Diagnostics',
      'vehicle_model': 'Honda Activa 6G',
      'vehicle_number': 'GJ-10-BD-0933',
      'bio': 'Certified AC technician with 5+ years experience in split and inverter AC servicing.',
    };

    if (pId.isNotEmpty) {
      try {
        final supabase = Supabase.instance.client;
        final pRes = await supabase
            .from('partners')
            .select('*, users(*, user_profiles(*)), service_provider_profiles(*)')
            .eq('partner_id', pId)
            .maybeSingle();

        if (pRes != null) {
          final u = pRes['users'] as Map<String, dynamic>? ?? {};
          final prof = u['user_profiles'] as Map<String, dynamic>? ?? {};
          final sProf = pRes['service_provider_profiles'] as Map<String, dynamic>? ?? {};

          final fullName = '${prof['first_name'] ?? ""} ${prof['last_name'] ?? ""}'.trim();
          partnerInfo['name'] = fullName.isNotEmpty ? fullName : (u['username'] ?? 'Certified Partner');
          partnerInfo['phone'] = u['phone'] ?? partnerInfo['phone'];
          partnerInfo['rating'] = (sProf['rating'] as num?)?.toDouble() ?? 4.9;
          partnerInfo['total_jobs'] = sProf['total_jobs'] ?? 42;
          partnerInfo['experience_years'] = sProf['experience_years'] ?? 5;
          partnerInfo['bio'] = sProf['about'] ?? 'Certified AC technician with 5+ years experience.';
        }
      } catch (_) {}
    }

    _onRealPartnerAccepted(partnerInfo);
  }

  void _onRealPartnerAccepted(Map<String, dynamic> partnerData) {
    if (_isAssigned || !mounted) return;

    _stepTimer?.cancel();
    _pollingTimer?.cancel();

    final pName = (partnerData['name'] ??
            partnerData['partner_name'] ??
            partnerData['technician_name'] ??
            'Jenish Bheda')
        .toString();

    final partnerMap = {
      'partner_id': partnerData['partner_id'] ?? partnerData['id'] ?? '',
      'name': pName,
      'partner_name': pName,
      'phone': partnerData['phone'] ?? partnerData['partner_phone'] ?? partnerData['technician_phone'] ?? '+91 75730 21659',
      'rating': (partnerData['rating'] as num?)?.toDouble() ?? 4.9,
      'total_jobs': partnerData['total_jobs'] ?? 42,
      'experience_years': partnerData['experience_years'] ?? 5,
      'specialty': partnerData['specialty'] ?? 'Certified AC Jet Cleaning, Gas Refill & Diagnostics',
      'vehicle_model': partnerData['vehicle_model'] ?? 'Honda Activa 6G',
      'vehicle_number': partnerData['vehicle_number'] ?? 'GJ-10-BD-0933',
      'bio': partnerData['bio'] ?? 'Certified AC technician with 5+ years experience in split and inverter AC servicing.',
    };

    setState(() {
      _assignedPartner = partnerMap;
      _isAssigned = true;
      _currentStep = 4;
    });

    _radarController.stop();
    _spinnerController.stop();
    HapticFeedback.heavyImpact();
  }

  Future<void> _handleCancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Search?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Are you sure you want to stop searching for an AC service technician?',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Searching', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancel Search', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isCancelling = true);

    try {
      final supabase = Supabase.instance.client;
      try {
        await supabase.rpc('cancel_customer_booking', params: {
          'p_booking_id': widget.bookingId,
          'p_reason': 'Cancelled by customer during partner search',
        });
      } catch (_) {
        await supabase
            .from('service_bookings')
            .update({'status': 'CANCELLED_BY_CUSTOMER', 'service_status': 'CANCELLED_BY_CUSTOMER'})
            .eq('booking_id', widget.bookingId);
      }

      await LiveBookingSyncService.instance.cancelBooking(widget.bookingId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Search cancelled. Your booking was closed.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.popUntil(context, (route) => route.isFirst);
    } catch (e) {
      if (mounted) {
        setState(() => _isCancelling = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error cancelling: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showLiveChatModal() {
    final techName = _assignedPartner?['name'] ?? 'Your Technician';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF2563EB),
                          child: Icon(Icons.engineering_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Chat with $techName',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Hello! I am assigned to your AC Service. I am on my way with genuine equipment. Feel free to message here.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF1E3A8A)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  hintText: 'Type your message for the technician...',
                  hintStyle: const TextStyle(fontSize: 13),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Color(0xFF2563EB)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Message sent to technician!'), duration: Duration(seconds: 1)),
                      );
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showNeedHelpModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(22),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Need Help with your AC Booking?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                'Our 24x7 support team is available to assist you with dispatch, timing, or technical questions.',
                style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.support_agent_rounded, color: Color(0xFF2563EB)),
                title: const Text('Call Customer Support (1800-SERVICE)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                onTap: () {
                  Clipboard.setData(const ClipboardData(text: '1800-737-8423'));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Support helpline copied to clipboard!')),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF2563EB)),
                title: const Text('FAQ & Rescheduling Policy', style: TextStyle(fontSize: 13.5)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTechnicianProfileModal() {
    final partner = _assignedPartner ?? {};
    final name = partner['name'] ?? 'Certified AC Specialist';
    final rating = partner['rating'] ?? 4.9;
    final jobs = partner['total_jobs'] ?? 42;
    final exp = partner['experience_years'] ?? 5;
    final vehicle = partner['vehicle_model'] ?? 'Honda Activa 6G';
    final regNo = partner['vehicle_number'] ?? 'GJ-10-BD-0933';
    final bio = partner['bio'] ?? 'Certified AC technician with 5+ years experience in split and inverter AC servicing.';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(22),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFBFDBFE), width: 2),
                    ),
                    child: const Center(
                      child: Icon(Icons.person_rounded, size: 36, color: Color(0xFF2563EB)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 18),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                            const SizedBox(width: 3),
                            Text(
                              '$rating ($jobs completed jobs)',
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              const Divider(),
              const SizedBox(height: 12),
              const Text(
                'About Technician',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                bio,
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildProfileStatCard('Experience', '$exp+ Years', Icons.military_tech_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildProfileStatCard('Vehicle', vehicle, Icons.two_wheeler_rounded, subtitle: regNo),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Close Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileStatCard(String title, String value, IconData icon, {String? subtitle}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2563EB), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8))),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
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
        title: const Text(
          'AC Service',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: _showNeedHelpModal,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.headset_mic_rounded, color: Color(0xFF2563EB), size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header section
              _buildHeaderSection(),
              const SizedBox(height: 16),

              // Assigned Partner Card (Image 1 Screen 2)
              if (_isAssigned && _assignedPartner != null) ...[
                _buildAssignedPartnerCard(),
                const SizedBox(height: 16),
              ],

              // Animated Pulsing Radar Beacon
              if (!_isAssigned) ...[
                Center(
                  child: SizedBox(
                    width: 130,
                    height: 130,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AnimatedBuilder(
                          animation: _radarController,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: _RadarWavesPainter(_radarController.value),
                              size: const Size(130, 130),
                            );
                          },
                        ),
                        Container(
                          width: 54,
                          height: 54,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Icon(Icons.search_rounded, color: Colors.white, size: 28),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 4 Progress Steps Card
              _buildStepperCard(),
              const SizedBox(height: 16),

              // Note: "Technicians usually accept within 2-3 minutes" & Estimated time card
              _buildEstimatedTimeCard(),
              const SizedBox(height: 16),

              // While You Wait Card
              _buildWhileYouWaitCard(),
              const SizedBox(height: 16),

              // 100% Verified Trust Badge Card
              _buildTrustBadgeCard(),
              const SizedBox(height: 20),

              // Action Buttons: View Technicians Details & Live Chat
              _buildSecondaryActionButtons(),
              const SizedBox(height: 12),

              // Primary CTA: View Live Tracking / Track Partner ➔
              _buildPrimaryTrackingButton(),
              const SizedBox(height: 12),

              // Cancel Search Button
              if (!_isAssigned) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFFECACA)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _isCancelling ? null : _handleCancelBooking,
                    child: _isCancelling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Color(0xFFEF4444), strokeWidth: 2),
                          )
                        : const Text(
                            'Cancel Search',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _isAssigned ? 'Technician Found!' : 'Finding a Technician',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _isAssigned ? 'Partner Assigned!' : 'Finding the Best Partner',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2563EB),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isAssigned
              ? '${_assignedPartner?['name'] ?? "Your verified expert"} has been assigned to your booking.'
              : 'We are finding the best technician near you...',
          style: const TextStyle(
            fontSize: 13.5,
            color: Color(0xFF64748B),
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedPartnerCard() {
    final partner = _assignedPartner ?? {};
    final name = (partner['name'] ?? partner['partner_name'] ?? 'Jenish Bheda').toString();
    final phone = (partner['phone'] ?? partner['partner_phone'] ?? '+91 75730 21659').toString();
    final rating = (partner['rating'] as num?)?.toDouble() ?? 4.9;
    final totalJobs = partner['total_jobs'] ?? 42;
    final vehicle = '${partner['vehicle_model'] ?? "Honda Activa 6G"} • ${partner['vehicle_number'] ?? "GJ-10-BD-0933"}';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBFDBFE), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF3B82F6), width: 2),
                    ),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 34),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star_rounded, color: Color(0xFFD97706), size: 14),
                              const SizedBox(width: 3),
                              Text(
                                '$rating',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'AC Specialist • $totalJobs+ jobs completed',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.two_wheeler_rounded, color: Color(0xFF94A3B8), size: 14),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            vehicle,
                            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.phone_rounded, color: Color(0xFF2563EB), size: 16),
                  label: const Text('Call', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: phone));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling $name ($phone)...')),
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
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF2563EB), size: 16),
                  label: const Text('Chat', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  onPressed: _showLiveChatModal,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  onPressed: _showTechnicianProfileModal,
                  child: const Text('View Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 13)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepperCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStepRow(
            stepIndex: 0,
            title: 'Searching nearby technicians',
            subtitle: 'Checking verified partners nearby...',
            icon: Icons.search_rounded,
          ),
          _buildStepRow(
            stepIndex: 1,
            title: 'Checking availability',
            subtitle: 'Reviewing ratings & performance...',
            icon: Icons.format_list_bulleted_rounded,
          ),
          _buildStepRow(
            stepIndex: 2,
            title: 'Matching best partner',
            subtitle: 'Notifying available technicians...',
            icon: Icons.person_outline_rounded,
          ),
          _buildStepRow(
            stepIndex: 3,
            title: 'Finalizing assignment',
            subtitle: 'Awaiting technician acceptance...',
            icon: Icons.check_rounded,
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required int stepIndex,
    required String title,
    required String subtitle,
    required IconData icon,
    bool isLast = false,
  }) {
    final bool isDone = _currentStep > stepIndex;
    final bool isActive = _currentStep == stepIndex;
    final bool isPending = _currentStep < stepIndex;

    Color iconBgColor;
    Color iconColor;
    if (isDone) {
      iconBgColor = const Color(0xFF10B981);
      iconColor = Colors.white;
    } else if (isActive) {
      iconBgColor = const Color(0xFF2563EB);
      iconColor = Colors.white;
    } else {
      iconBgColor = const Color(0xFFF1F5F9);
      iconColor = const Color(0xFF94A3B8);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  shape: BoxShape.circle,
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: const Color(0xFF2563EB).withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Icon(
                    isDone ? Icons.check_rounded : icon,
                    color: iconColor,
                    size: 16,
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: isActive
                  ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
                  : const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: isActive
                  ? BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    )
                  : null,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: isPending ? const Color(0xFF64748B) : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isPending ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 8),
                    RotationTransition(
                      turns: _spinnerController,
                      child: const Icon(Icons.settings_suggest_rounded, color: Color(0xFF2563EB), size: 18),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEstimatedTimeCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.access_time_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estimated time', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    SizedBox(height: 2),
                    Text(
                      '2 - 5 minutes',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Technicians usually accept within 2-3 minutes. We\'ll notify you as soon as a technician is assigned.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildWhileYouWaitCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF3C7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE68A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFD97706), size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'While you wait',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNumberedBullet(1, 'Keep your phone reachable for calls.'),
          const SizedBox(height: 6),
          _buildNumberedBullet(2, 'Ensure someone is available at the address.'),
          const SizedBox(height: 6),
          _buildNumberedBullet(3, 'Our technician will carry genuine tools and safety equipment.'),
          const SizedBox(height: 6),
          _buildNumberedBullet(4, 'You\'ll receive a notification once the technician is assigned.'),
        ],
      ),
    );
  }

  Widget _buildNumberedBullet(int num, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$num. ', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.3)),
        ),
      ],
    );
  }

  Widget _buildTrustBadgeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '100% Verified Technicians',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 2),
                Text(
                  'Trained professionals | Background checked | Genuine service',
                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (!_isAssigned || _assignedPartner == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Finding your technician... Details will appear once a partner accepts.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              final tech = _assignedPartner!;
              context.push(
                '/services/ac/technician-details',
                extra: {
                  'booking_id': widget.bookingId,
                  'partner_data': tech,
                  'service_title': widget.serviceTitle,
                  'address': widget.address,
                },
              );
            },
            icon: const Icon(Icons.people_alt_rounded, color: Color(0xFF2563EB), size: 18),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'View Technicians Details',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: _showLiveChatModal,
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF2563EB), size: 18),
            label: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Live Chat',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryTrackingButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 2,
        ),
        onPressed: () {
          context.push('/track-booking/${widget.bookingId}');
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_on_rounded, size: 20, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              _isAssigned ? 'Track Partner ➔' : 'View Live Tracking ➔',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class _RadarWavesPainter extends CustomPainter {
  final double animationValue;
  _RadarWavesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    for (int i = 0; i < 3; i++) {
      final value = (animationValue + i * 0.33) % 1.0;
      final radius = 28 + value * (maxRadius - 28);
      final alpha = ((1.0 - value) * 0.35).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = const Color(0xFF2563EB).withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarWavesPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
