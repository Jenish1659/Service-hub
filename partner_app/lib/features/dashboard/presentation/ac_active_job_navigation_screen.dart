import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Timer? _gpsMovementTimer;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Default Coordinates (Jamnagar/Rajkot, Gujarat)
    final custLat = (widget.job['customer_lat'] as num?)?.toDouble() ?? 22.4707;
    final custLng = (widget.job['customer_lng'] as num?)?.toDouble() ?? 70.0577;

    // Partner is located ~1.8 km nearby initially
    _partnerLocation = LatLng(custLat - 0.012, custLng - 0.009);
    _customerLocation = LatLng(custLat, custLng);
    _currentStatus = widget.job['status'] ?? 'CONFIRMED';

    // Broadcast initial position
    final bookingId = widget.job['booking_id'] ?? widget.job['id'] ?? '';
    if (bookingId.toString().isNotEmpty) {
      LiveBookingSyncService.instance.updatePartnerLocation(
        bookingId.toString(),
        _partnerLocation.latitude,
        _partnerLocation.longitude,
      );
    }

    _startGpsSimulationTimer();
  }

  void _startGpsSimulationTimer() {
    _gpsMovementTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      if (_currentStatus == 'ON_THE_WAY' || _currentStatus == 'CONFIRMED' || _currentStatus == 'ACCEPTED') {
        final dLat = (_customerLocation.latitude - _partnerLocation.latitude) * 0.15;
        final dLng = (_customerLocation.longitude - _partnerLocation.longitude) * 0.15;

        setState(() {
          _partnerLocation = LatLng(_partnerLocation.latitude + dLat, _partnerLocation.longitude + dLng);
        });

        final bookingId = widget.job['booking_id'] ?? widget.job['id'] ?? '';
        if (bookingId.toString().isNotEmpty) {
          LiveBookingSyncService.instance.updatePartnerLocation(
            bookingId.toString(),
            _partnerLocation.latitude,
            _partnerLocation.longitude,
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _gpsMovementTimer?.cancel();
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
        _partnerLocation = LatLng(_customerLocation.latitude - 0.0005, _customerLocation.longitude - 0.0005);
        _isProcessing = false;
      });
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
    } else if (_currentStatus == 'SERVICE_STARTED') {
      _showCompleteServiceOtpDialog();
    }
  }

  void _showStartServicePinDialog() {
    final pinController = TextEditingController();
    final expectedPin = widget.job['entrance_pin']?.toString() ?? '7429';

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
                helperText: 'Default demo PIN: $expectedPin',
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
    final expectedOtp = widget.job['completion_otp']?.toString() ?? '5892';
    final grossAmount = (widget.job['price'] as num?)?.toDouble() ?? 499.0;
    final netEarning = grossAmount * 0.85;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text('Complete & Settle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AC Deep Cleaning completed. Ask customer for their 4-digit completion OTP to close job and credit ₹${netEarning.toStringAsFixed(0)} to your wallet:',
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 8),
              decoration: InputDecoration(
                hintText: '----',
                counterText: '',
                helperText: 'Default demo OTP: $expectedOtp',
                helperStyle: const TextStyle(color: Color(0xFF10B981), fontSize: 11),
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
              backgroundColor: const Color(0xFF10B981),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final bookingId = widget.job['booking_id'] ?? '';
              setState(() => _isProcessing = true);
              await ref.read(acProviderDashboardProvider.notifier).completeJobAndSettle(
                    bookingId,
                    grossAmount: grossAmount,
                    completionOtp: otpController.text.trim(),
                  );
              if (!mounted) return;
              _showSuccessCelebrationDialog(netEarning);
            },
            child: const Text('Complete & Collect', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _getActionButtonColor(_currentStatus),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _isProcessing ? null : _handleNextMilestone,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _getActionButtonText(_currentStatus),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
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
        return const Color(0xFF8B5CF6);
      case 'SERVICE_COMPLETED':
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
        return 'AC Service in Progress';
      case 'SERVICE_COMPLETED':
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
        return const Color(0xFF10B981);
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
        return 'COMPLETE AC SERVICE & SETTLE (OTP)';
      default:
        return 'PROCEED';
    }
  }
}
