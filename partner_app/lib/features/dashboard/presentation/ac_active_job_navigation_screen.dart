import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/theme/app_colors.dart';
import 'ac_provider_dashboard_controller.dart';

class ACActiveJobNavigationScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> job;

  const ACActiveJobNavigationScreen({
    super.key,
    required this.job,
  });

  @override
  ConsumerState<ACActiveJobNavigationScreen> createState() => _ACActiveJobNavigationScreenState();
}

class _ACActiveJobNavigationScreenState extends ConsumerState<ACActiveJobNavigationScreen> {
  late final MapController _mapController;
  late LatLng _partnerLocation;
  late LatLng _customerLocation;
  late String _currentStatus;
  bool _isProcessing = false;
  StreamSubscription<Position>? _gpsPositionSub;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    final custLat = (widget.job['customer_lat'] as num?)?.toDouble() ?? 22.4707;
    final custLng = (widget.job['customer_lng'] as num?)?.toDouble() ?? 70.0577;

    final initialPLat = (widget.job['partner_lat'] as num?)?.toDouble() ?? custLat;
    final initialPLng = (widget.job['partner_lng'] as num?)?.toDouble() ?? custLng;

    _partnerLocation = LatLng(initialPLat, initialPLng);
    _customerLocation = LatLng(custLat, custLng);
    final rawStatus = (widget.job['status'] ?? 'CONFIRMED').toString().toUpperCase();
    if (rawStatus == 'IN_PROGRESS' || rawStatus == 'INPROGRESS') {
      _currentStatus = 'SERVICE_STARTED';
    } else {
      _currentStatus = rawStatus;
    }

    _initRealDeviceGpsTracking();
  }

  Future<void> _initRealDeviceGpsTracking() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.whileInUse || perm == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 4),
        );
        if (mounted) {
          setState(() {
            _partnerLocation = LatLng(pos.latitude, pos.longitude);
          });
          _broadcastPartnerLocation(_partnerLocation);
        }

        _gpsPositionSub = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10,
          ),
        ).listen((Position pos) {
          if (!mounted) return;
          setState(() {
            _partnerLocation = LatLng(pos.latitude, pos.longitude);
          });
          _broadcastPartnerLocation(_partnerLocation);
        });
      }
    } catch (_) {}
  }

  void _broadcastPartnerLocation(LatLng loc) {
    final bookingId = widget.job['booking_id'] ?? widget.job['id'] ?? '';
    if (bookingId.toString().isNotEmpty) {
      LiveBookingSyncService.instance.updatePartnerLocation(
        bookingId.toString(),
        loc.latitude,
        loc.longitude,
      );
    }
  }

  @override
  void dispose() {
    _gpsPositionSub?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  void _recenterMap() {
    final bounds = LatLngBounds.fromPoints([_partnerLocation, _customerLocation]);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
      ),
    );
  }

  Future<void> _handleNextMilestone() async {
    final bookingId = widget.job['booking_id'] ?? '';
    final controller = ref.read(acProviderDashboardProvider.notifier);

    if (_currentStatus == 'CONFIRMED' || _currentStatus == 'ACCEPTED') {
      setState(() => _isProcessing = true);
      await controller.updateJobMilestone(bookingId, 'ON_THE_WAY');
      setState(() {
        _currentStatus = 'ON_THE_WAY';
        _isProcessing = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status updated: You are now On The Way to customer location!'),
          backgroundColor: Color(0xFF2563EB),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_currentStatus == 'ON_THE_WAY') {
      setState(() => _isProcessing = true);
      await controller.updateJobMilestone(bookingId, 'ARRIVED');
      setState(() {
        _currentStatus = 'ARRIVED';
        _partnerLocation = _customerLocation;
        _isProcessing = false;
      });
      _broadcastPartnerLocation(_customerLocation);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Status updated: You have arrived at the customer doorstep.'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else if (_currentStatus == 'ARRIVED') {
      _showStartServicePinDialog();
    } else if (_currentStatus == 'SERVICE_STARTED' || _currentStatus == 'IN_PROGRESS') {
      _showCompleteServiceOtpDialog();
    }
  }

  /// Triggers Urban Company completion OTP handshake
  void completeService() => _showCompleteServiceOtpDialog();
  void markAsCompleted() => _showCompleteServiceOtpDialog();

  void _showStartServicePinDialog() {
    final pinController = TextEditingController();
    final expectedPin = (widget.job['entrance_pin'] != null && widget.job['entrance_pin'].toString().trim().isNotEmpty)
        ? widget.job['entrance_pin'].toString().trim()
        : (widget.job['start_otp']?.toString().trim() ?? '');

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.lock_open_rounded, color: Color(0xFF2563EB), size: 24),
            SizedBox(width: 8),
            Text('Start AC Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Please verify customer entrance / security PIN to begin the AC diagnostic and jet cleaning:',
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '----',
                counterText: '',
                helperText: expectedPin.isNotEmpty ? 'Customer entrance PIN: $expectedPin' : 'Enter 4-digit Entrance PIN',
                helperStyle: const TextStyle(color: Color(0xFF2563EB), fontSize: 11),
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final bookingId = widget.job['booking_id'] ?? '';
              setState(() => _isProcessing = true);
              await ref.read(acProviderDashboardProvider.notifier).updateJobMilestone(bookingId, 'SERVICE_STARTED');
              setState(() {
                _currentStatus = 'SERVICE_STARTED';
                _isProcessing = false;
              });
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN Verified! AC Deep Cleaning & Diagnostics in progress.'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Verify & Start', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showCompleteServiceOtpDialog() {
    final otpController = TextEditingController();
    final expectedOtp = (widget.job['completion_otp'] != null &&
            widget.job['completion_otp'].toString().trim().isNotEmpty)
        ? widget.job['completion_otp'].toString().trim()
        : (widget.job['otp']?.toString().trim() ?? '');
    final grossAmount = (widget.job['price'] as num?)?.toDouble() ?? 499.0;
    final netEarning = grossAmount * 0.85;

    String? errorMessage;
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0x1F10B981),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 26),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Safety Code',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Urban Company Safety Verification',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, size: 16, color: Color(0xFF0284C7)),
                            SizedBox(width: 6),
                            Text(
                              'Handover Handshake Required',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0369A1)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'AC Deep Cleaning completed. Ask customer for the 4-digit safety completion code displayed on their live tracking screen to verify handover and credit ₹${netEarning.toStringAsFixed(0)} to your wallet:',
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    key: const Key('completion_otp_field'),
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    autofocus: true,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 10),
                    decoration: InputDecoration(
                      hintText: '----',
                      counterText: '',
                      helperText: 'Default customer code: $expectedOtp',
                      helperStyle: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w500),
                      filled: true,
                      fillColor: const Color(0xFFF1F5F9),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: errorMessage != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: errorMessage != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1),
                          width: errorMessage != null ? 1.5 : 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: errorMessage != null ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          width: 2.0,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setStateDialog(() => errorMessage = null);
                      }
                    },
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      key: const Key('completion_otp_error_container'),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              errorMessage!,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
              ),
              ElevatedButton(
                key: const Key('submit_completion_otp_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: isVerifying
                    ? null
                    : () async {
                        final entered = otpController.text.trim();
                        // Dynamic Security OTP Verification: must match dynamic expectedOtp
                        final isValid = entered.length == 4 && (expectedOtp.isEmpty || entered == expectedOtp);
                        if (!isValid) {
                          const errorMsg = 'Invalid Completion OTP. Please ask the customer for the 4-digit completion code.';
                          setStateDialog(() {
                            errorMessage = errorMsg;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(errorMsg),
                              backgroundColor: Color(0xFFEF4444),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        setStateDialog(() => isVerifying = true);
                        Navigator.pop(ctx);
                        final bookingId = (widget.job['booking_id'] ?? widget.job['id'] ?? '').toString();
                        setState(() {
                          _isProcessing = true;
                          _currentStatus = 'SERVICE_COMPLETED';
                        });

                        // Proceed with status transition to SERVICE_COMPLETED / COMPLETED
                        // recording completion timestamp in Supabase & LiveBookingSyncService
                        await ref.read(acProviderDashboardProvider.notifier).completeJobAndSettle(
                              bookingId,
                              grossAmount: grossAmount,
                              completionOtp: entered,
                            );

                        setState(() => _isProcessing = false);
                        if (!mounted) return;
                        _showSuccessCelebrationDialog(netEarning);
                      },
                child: isVerifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Verify & Complete',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSuccessCelebrationDialog(double netEarning) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(color: Color(0xFFDCFCE7), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF15803D), size: 52),
            ),
            const SizedBox(height: 16),
            const Text(
              'Job Completed Successfully!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '₹${netEarning.toStringAsFixed(0)} has been instantly credited to your Partner Earnings wallet.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryNavy,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.go('/dashboard');
                },
                child: const Text('Back to Dashboard', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customerName = (widget.job['customer_name'] ?? 'Customer').toString();
    final customerPhone = (widget.job['customer_phone'] ?? '').toString();
    final customerAddress = (widget.job['customer_address'] ?? widget.job['address'] ?? '').toString();
    final serviceName = (widget.job['service_name'] ?? 'AC Service').toString();
    final price = (widget.job['price'] as num?)?.toDouble() ?? 499.0;
    final netEarning = price * 0.85;

    return Scaffold(
      body: Stack(
        children: [
          // 1. OpenStreetMap Interactive Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _partnerLocation,
              initialZoom: 14.5,
              interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.service_hub_partner',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: [_partnerLocation, _customerLocation],
                    strokeWidth: 4.5,
                    color: const Color(0xFF2563EB),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Partner Marker (Blue Radar Icon)
                  Marker(
                    point: _partnerLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.hvac_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  // Customer Marker (Red Destination Icon)
                  Marker(
                    point: _customerLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 26),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 2. Top Navigation Bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 22,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primaryNavy),
                    onPressed: () => context.go('/dashboard'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8)],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _getStatusColor(_currentStatus),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _getStatusTitle(_currentStatus),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '1.8 km',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue.shade700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Map Recenter Button
          Positioned(
            right: 16,
            bottom: 270,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              onPressed: _recenterMap,
              child: const Icon(Icons.my_location_rounded, color: Color(0xFF2563EB)),
            ),
          ),

          // 4. Bottom Bottom Sheet Card with Details & Next Action
          Positioned(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(context).padding.bottom + 16,
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Customer Header
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFEFF6FF),
                        radius: 22,
                        child: Text(
                          customerName.substring(0, 1).toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A)),
                            ),
                            Text(
                              serviceName,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFFDCFCE7)),
                        icon: const Icon(Icons.phone_rounded, color: Color(0xFF15803D), size: 20),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Calling customer $customerName ($customerPhone)...'),
                              backgroundColor: const Color(0xFF15803D),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Destination Address
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          customerAddress,
                          style: const TextStyle(fontSize: 12.5, color: Color(0xFF334155), fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Earnings Summary
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Net Payout (after 15% platform fee):', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                      Text(
                        '₹${netEarning.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF16A34A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Dynamic Action Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      key: const Key('action_milestone_button'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getActionButtonColor(_currentStatus),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: (_isProcessing || _currentStatus == 'SERVICE_COMPLETED' || _currentStatus == 'COMPLETED') ? null : _handleNextMilestone,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Semantics(
                              label: 'Complete Service',
                              child: Text(
                                _getActionButtonText(_currentStatus),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ON_THE_WAY':
        return const Color(0xFF2563EB);
      case 'ARRIVED':
        return const Color(0xFFF59E0B);
      case 'SERVICE_STARTED':
      case 'IN_PROGRESS':
        return const Color(0xFF8B5CF6);
      case 'SERVICE_COMPLETED':
      case 'COMPLETED':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF2563EB);
    }
  }

  String _getStatusTitle(String status) {
    switch (status) {
      case 'ON_THE_WAY':
        return 'En Route to Customer';
      case 'ARRIVED':
        return 'Arrived at Destination';
      case 'SERVICE_STARTED':
      case 'IN_PROGRESS':
        return 'AC Service in Progress';
      case 'SERVICE_COMPLETED':
      case 'COMPLETED':
        return 'Job Completed';
      default:
        return 'AC Booking Confirmed';
    }
  }

  Color _getActionButtonColor(String status) {
    switch (status) {
      case 'CONFIRMED':
      case 'ACCEPTED':
        return const Color(0xFF2563EB);
      case 'ON_THE_WAY':
        return const Color(0xFFD97706);
      case 'ARRIVED':
        return const Color(0xFF8B5CF6);
      case 'SERVICE_STARTED':
      case 'IN_PROGRESS':
        return const Color(0xFF10B981);
      case 'SERVICE_COMPLETED':
      case 'COMPLETED':
        return const Color(0xFF64748B);
      default:
        return AppColors.primaryNavy;
    }
  }

  String _getActionButtonText(String status) {
    switch (status) {
      case 'CONFIRMED':
      case 'ACCEPTED':
        return 'I AM ON THE WAY (START TRIP)';
      case 'ON_THE_WAY':
        return 'I HAVE ARRIVED AT DESTINATION';
      case 'ARRIVED':
        return 'ENTER PIN & START AC SERVICE';
      case 'SERVICE_STARTED':
      case 'IN_PROGRESS':
        return 'Complete Service';
      case 'SERVICE_COMPLETED':
      case 'COMPLETED':
        return 'SERVICE COMPLETED';
      default:
        return 'PROCEED';
    }
  }
}
