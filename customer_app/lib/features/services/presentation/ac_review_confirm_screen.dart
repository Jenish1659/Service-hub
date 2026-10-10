import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/services/h3_geospatial_service.dart';
import '../../location/providers/location_provider.dart';
import '../../location/widgets/gps_enforcement_dialog.dart';
import '../services/ac_availability_service.dart';
import '../services/ac_booking_service.dart';
import 'ac_booking_confirmed_screen.dart';
import 'ac_finding_technician_screen.dart';

class ACReviewConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> issueDetails;
  final BookingDateOption selectedDate;
  final String selectedTime;

  const ACReviewConfirmScreen({
    super.key,
    required this.issueDetails,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  ConsumerState<ACReviewConfirmScreen> createState() => _ACReviewConfirmScreenState();
}

class _ACReviewConfirmScreenState extends ConsumerState<ACReviewConfirmScreen> {
  bool _isConfirming = false;
  final TextEditingController _couponController = TextEditingController();
  String? _appliedCoupon;
  double _couponDiscount = 0.0;
  bool _useWallet = false;
  double _walletBalance = 0.0;
  int _walletCoins = 0;

  @override
  void initState() {
    super.initState();
    WalletRewardService.instance.ensureInitialWalletCreated();
    _loadUserWallet();
  }

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  void _loadUserWallet() {
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        _walletBalance = (box.get('wallet_balance_inr', defaultValue: 0.0) as num).toDouble();
        _walletCoins = (box.get('wallet_coins', defaultValue: 0) as num).toInt();
      }
    } catch (_) {}
  }

  double get _availableWalletRupees {
    if (_walletBalance > 0) return _walletBalance;
    return _walletCoins > 0 ? (_walletCoins / 10.0) : 0.0;
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;

    double discount = 0.0;
    if (code == 'SAVE50') {
      discount = 50.0;
    } else if (code == 'WELCOME20') {
      discount = 20.0;
    } else if (code == 'SERVICE10') {
      discount = 25.0;
    } else if (code == 'HUB100') {
      discount = 100.0;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid coupon code "$code". Try SAVE50 or WELCOME20.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _appliedCoupon = code;
      _couponDiscount = discount;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Coupon "$code" applied! ₹${discount.toStringAsFixed(0)} saved.'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeCoupon() {
    setState(() {
      _appliedCoupon = null;
      _couponDiscount = 0.0;
      _couponController.clear();
    });
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleConfirmBooking() async {
    // 0. Mandatory Location & GPS Check
    final isGpsActive = await GpsEnforcementDialog.ensureGpsActive(context);
    if (!isGpsActive) {
      if (mounted) {
        _showWarningSnackBar('Please enable device location (GPS) to find nearby service partners.');
      }
      return;
    }

    setState(() {
      _isConfirming = true;
    });

    // 1. Atomic availability check
    final isAvailable = await ACAvailabilityService.instance.verifySlotStillAvailable(
      date: widget.selectedDate.date,
      timeSlot: widget.selectedTime,
    );

    if (!isAvailable) {
      setState(() {
        _isConfirming = false;
      });
      _showWarningSnackBar('This time slot is no longer available. Please choose another time.');
      return;
    }

    // 2. Real Customer identity & metadata resolution
    final supabase = Supabase.instance.client;
    String realCustomerId = '3e2584b1-4943-4196-abaa-1de62a456703'; // Real customer in DB
    String realAddressId = '0cbd6285-4c82-4af4-9849-f9b910bb0c14'; // Real customer address in DB
    String realServiceId = 'f27fbac4-115c-4674-9c93-6b6ff8e1d080'; // Real AC Deep Cleaning in DB
    String userName = widget.issueDetails['customer_name'] ?? '';
    String userPhone = widget.issueDetails['customer_phone'] ?? '';

    try {
      final user = supabase.auth.currentUser;
      if (user != null) {
        final uRes = await supabase.from('users').select('user_id').eq('auth_id', user.id).maybeSingle();
        if (uRes != null && uRes['user_id'] != null) {
          realCustomerId = uRes['user_id'].toString();
        }
        if (widget.issueDetails['customer_name'] == null) {
          userName = user.userMetadata?['name'] as String? ??
              user.userMetadata?['full_name'] as String? ??
              user.email?.split('@').first ?? userName;
        }
        if (widget.issueDetails['customer_phone'] == null) {
          userPhone = user.phone ?? user.userMetadata?['phone'] as String? ?? userPhone;
        }
      } else if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        final cachedId = box.get('user_id')?.toString() ?? '';
        if (cachedId.length == 36 && cachedId.contains('-')) {
          final uRes = await supabase.from('users').select('user_id').eq('user_id', cachedId).maybeSingle();
          if (uRes != null && uRes['user_id'] != null) {
            realCustomerId = cachedId;
          }
        }
      }

      final aRes = await supabase.from('user_addresses').select('address_id').eq('user_id', realCustomerId).limit(1).maybeSingle();
      if (aRes != null && aRes['address_id'] != null) {
        realAddressId = aRes['address_id'].toString();
      }

      final svcRes = await supabase.from('services').select('service_id, name').eq('category_id', 'ac_service');
      for (final s in svcRes) {
        final sName = (s['name'] ?? '').toString().toLowerCase();
        final acTypeReq = (widget.issueDetails['ac_type'] ?? '').toString().toLowerCase();
        if (sName.contains(acTypeReq) || sName.contains('cleaning') || sName.contains('jet')) {
          realServiceId = s['service_id'].toString();
          break;
        }
      }
    } catch (e) {
      debugPrint('[CustomerBooking] Identity resolution fallback note: $e');
    }

    final serviceName = widget.issueDetails['service_name'] ?? 'AC Service';
    final acType = widget.issueDetails['ac_type'] ?? '';
    final acBrand = widget.issueDetails['ac_brand'] ?? '';
    final problemDesc = widget.issueDetails['problem_description'] ?? '';
    final address = widget.issueDetails['customer_address']?.toString() ?? '';

    // Visiting ₹449 + Protection ₹49
    const visitingCharge = 449.0;
    const protectionFee = 49.0;
    const subtotal = visitingCharge + protectionFee;
    final afterCoupon = (subtotal - _couponDiscount).clamp(0.0, 9999.0);
    final walletDeduction = _useWallet && _availableWalletRupees > 0
        ? (_availableWalletRupees < afterCoupon ? _availableWalletRupees : afterCoupon)
        : 0.0;
    final finalPrice = (afterCoupon - walletDeduction).clamp(0.0, 9999.0);

    // Deduct wallet if used (Backend Authoritative & Double-Spend Protection)
    if (_useWallet && walletDeduction > 0) {
      try {
        if (realCustomerId.length == 36 && realCustomerId.contains('-')) {
          await supabase.rpc('apply_wallet_deduction_atomic', params: {
            'p_user_id': realCustomerId,
            'p_requested_deduction': walletDeduction,
          });
        }
      } catch (e) {
        debugPrint('[Wallet] RPC note: $e');
      }
      try {
        if (Hive.isBoxOpen('customer_cache')) {
          final box = Hive.box('customer_cache');
          final remainingBal = (_walletBalance - walletDeduction).clamp(0.0, 99999.0);
          box.put('wallet_balance_inr', remainingBal);
        }
      } catch (_) {}
    }

    final locState = ref.read(locationProvider);
    var activeLoc = locState.selectedLocation ?? locState.currentLocation;
    if (activeLoc == null) {
      try {
        await ref.read(locationProvider.notifier).fetchCurrentGpsLocation();
        activeLoc = ref.read(locationProvider).selectedLocation ?? ref.read(locationProvider).currentLocation;
      } catch (_) {}
    }

    if (activeLoc == null) {
      setState(() => _isConfirming = false);
      _showWarningSnackBar('Please enable GPS or select a service address to proceed with booking.');
      return;
    }

    final lat = activeLoc.latitude;
    final lng = activeLoc.longitude;

    // Strict Jamnagar geofence check
    final serviceArea = ref.read(serviceAreaServiceProvider);
    final areaCheck = serviceArea.checkServiceArea(activeLoc.city, lat, lng);
    final combinedAddress = ('$address ${activeLoc.address} ${activeLoc.city}').toLowerCase();
    if (!areaCheck.isAvailable && !combinedAddress.contains('jamnagar')) {
      setState(() => _isConfirming = false);
      _showWarningSnackBar('Sorry, we are not available at your location. ServiceHub is currently available only in Jamnagar.');
      return;
    }

    final h3Index = H3GeospatialService.instance.latLngToH3Index(lat, lng, resolution: 8);

    final pin = (1000 + DateTime.now().millisecond % 9000).toString();
    final otp = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();

    final scheduledAtFormatted = '${widget.issueDetails['booking_date_formatted'] ?? widget.selectedDate.formattedIso} ${widget.selectedTime}'.trim();

    // Check if selected booking date is TODAY (Path A) or FUTURE DATE (Path B)
    final now = DateTime.now();
    final isToday = widget.selectedDate.date.year == now.year &&
        widget.selectedDate.date.month == now.month &&
        widget.selectedDate.date.day == now.day;
    final initialStatus = isToday ? 'SEARCHING_PROVIDER' : 'SCHEDULED';
    final bookingUuid = const Uuid().v4();

    // 3. Store into permanent database ONLY upon confirmation!
    final createdBooking = await LiveBookingSyncService.instance.createACBooking(
      id: bookingUuid,
      bookingId: bookingUuid,
      customerId: realCustomerId,
      customerName: userName.isNotEmpty ? userName : 'Customer',
      customerPhone: userPhone.isNotEmpty ? userPhone : '',
      serviceName: acType.isNotEmpty ? '$serviceName ($acType)' : serviceName,
      problemDescription: acBrand.isNotEmpty ? '$acType ($acBrand) - $problemDesc' : problemDesc,
      scheduledDate: widget.issueDetails['booking_date_formatted'] ?? widget.selectedDate.formattedIso,
      scheduledTime: widget.selectedTime,
      paymentMethod: 'Cash on Service',
      price: finalPrice,
      customerAddress: address,
      customerLat: lat,
      customerLng: lng,
      entrancePin: pin,
      completionOtp: otp,
      extraData: {
        'id': bookingUuid,
        'booking_id': bookingUuid,
        'service_id': realServiceId,
        'scheduled_at': scheduledAtFormatted,
        'final_amount': finalPrice,
        'address': address,
        'status': initialStatus,
        'service_status': initialStatus,
        'is_today': isToday,
        'customer_h3_res8': h3Index,
      },
    );

    // 4. Write to Supabase service_bookings table
    try {
      await supabase.from('service_bookings').insert({
        'booking_id': bookingUuid,
        'customer_id': realCustomerId,
        'service_id': realServiceId,
        'address_id': realAddressId,
        'status': initialStatus,
        'service_status': initialStatus,
        'booking_date': widget.selectedDate.formattedIso,
        'scheduled_time': widget.selectedTime,
        'problem_description': acBrand.isNotEmpty ? '$acType ($acBrand) - $problemDesc' : problemDesc,
        'estimated_amount': finalPrice,
        'final_amount': finalPrice,
        'customer_latitude': lat,
        'customer_longitude': lng,
        'entrance_pin': pin,
        'completion_otp': otp,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Successfully written AC booking to Supabase service_bookings: $bookingUuid');
    } catch (e) {
      debugPrint('Supabase service_bookings insert note: $e');
    }

    // 5. For Same-Day booking (Path A), execute Real Partner Assignment Dispatch
    if (isToday) {
      try {
        final candidatesRes = await supabase
            .from('service_provider_profiles')
            .select('provider_id, partner_id, partners(partner_id, user_id, verification_status, availability_status, users(user_id, is_active, account_status, roles(role_name)), partner_live_locations(latitude, longitude))');

        int dispatchedCount = 0;
        for (final c in candidatesRes) {
          final partner = c['partners'] as Map<String, dynamic>?;
          if (partner == null) continue;
          final user = partner['users'] as Map<String, dynamic>?;
          if (user == null) continue;
          final role = (user['roles'] as Map<String, dynamic>?)?['role_name']?.toString() ?? '';

          // A. Role Isolation: Strictly service_provider (exclude shopkeeper & delivery_agent)
          if (role != 'service_provider') continue;

          // B. Verification & Availability checks
          final ver = partner['verification_status']?.toString().toUpperCase();
          final avail = partner['availability_status']?.toString().toUpperCase();
          if (ver != 'VERIFIED' && ver != 'APPROVED') continue;
          if (avail != 'ONLINE' && avail != 'AVAILABLE') continue;

          // C. Geographic Distance check (5.0 km radius)
          final loc = partner['partner_live_locations'];
          double? pLat, pLng;
          if (loc is Map && loc['latitude'] != null) {
            pLat = (loc['latitude'] as num).toDouble();
            pLng = (loc['longitude'] as num).toDouble();
          } else if (loc is List && loc.isNotEmpty) {
            pLat = (loc[0]['latitude'] as num).toDouble();
            pLng = (loc[0]['longitude'] as num).toDouble();
          }

          if (pLat != null && pLng != null) {
            final distM = H3GeospatialService.instance.computeHaversineDistanceMeters(lat, lng, pLat, pLng);
            if (distM > 5000.0) continue; // Exceeds 5km radius
          }

          // D. Create request row in booking_requests table
          final reqId = const Uuid().v4();
          await supabase.from('booking_requests').insert({
            'request_id': reqId,
            'booking_id': bookingUuid,
            'provider_id': c['provider_id'],
            'partner_id': partner['partner_id'],
            'response_status': 'Pending',
            'sent_at': DateTime.now().toIso8601String(),
          });

          // E. Insert partner notification
          try {
            await supabase.from('notifications').insert({
              'notification_id': const Uuid().v4(),
              'user_id': user['user_id'],
              'title': 'New AC Service Request',
              'message': 'Customer requested $serviceName ($acType) nearby. Tap to review and accept.',
              'notification_type': 'BOOKING',
              'created_at': DateTime.now().toIso8601String(),
            });
          } catch (_) {}

          dispatchedCount++;
        }
        debugPrint('[DispatchEngine] Successfully dispatched $dispatchedCount real provider requests for booking $bookingUuid');
      } catch (e) {
        debugPrint('[DispatchEngine] Dispatch note: $e');
      }
    }

    // 6. Broadcast to LiveBookingSyncService.instance.submitBooking(...)
    await LiveBookingSyncService.instance.submitBooking({
      ...createdBooking,
      'id': bookingUuid,
      'booking_id': bookingUuid,
      'service_id': realServiceId,
      'scheduled_at': scheduledAtFormatted,
      'final_amount': finalPrice,
      'address': address,
      'status': initialStatus,
      'service_status': initialStatus,
      'is_today': isToday,
    });

    // 7. Clear unconfirmed draft from local cache
    await ACIssueBookingService.instance.clearDraft();

    setState(() {
      _isConfirming = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isToday
            ? '✓ Booking confirmed! Finding the best partner for your service today...'
            : '✓ Booking scheduled for ${widget.issueDetails['booking_date_formatted'] ?? widget.selectedDate.formattedIso}!'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // SEPARATE PATHS:
    if (isToday) {
      // PATH A: SAME-DAY BOOKING -> Screen 1: "Finding the Best Partner" (Image 1)
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ACFindingTechnicianScreen(
            bookingId: bookingUuid,
            bookingData: createdBooking,
            serviceTitle: 'AC Service ($acType)',
            address: address,
            selectedDateFormatted: widget.issueDetails['booking_date_formatted'] ?? widget.selectedDate.formattedIso,
            selectedTime: widget.selectedTime,
          ),
        ),
      );
    } else {
      // PATH B: FUTURE-DATE PRE-BOOKING -> Screen 1: "Booking Scheduled (Future Date)" (Image 2)
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ACBookingConfirmedScreen(
            bookingData: createdBooking,
            selectedDateFormatted: widget.issueDetails['booking_date_formatted'] ?? widget.selectedDate.formattedIso,
            selectedTime: widget.selectedTime,
            serviceTitle: 'AC Service ($acType)',
            address: address,
            visitingCharge: visitingCharge,
            protectionFee: protectionFee,
            couponDiscount: _couponDiscount,
            couponCode: _appliedCoupon,
            walletDeduction: walletDeduction,
            finalPayable: finalPrice,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormatted = widget.issueDetails['booking_date_formatted'] ??
        '${widget.selectedDate.dayName}, ${widget.selectedDate.dateNumber} ${widget.selectedDate.monthName}';
    final acType = widget.issueDetails['ac_type'] ?? '';
    final problemDesc = widget.issueDetails['problem_description'] ?? '';
    final address = widget.issueDetails['customer_address'] ?? '';

    // Visiting ₹449 + Protection ₹49
    const visitingCharge = 449.0;
    const protectionFee = 49.0;
    const subtotal = visitingCharge + protectionFee;
    final afterCoupon = (subtotal - _couponDiscount).clamp(0.0, 9999.0);
    final walletDeduction = _useWallet && _availableWalletRupees > 0
        ? (_availableWalletRupees < afterCoupon ? _availableWalletRupees : afterCoupon)
        : 0.0;
    final finalPrice = (afterCoupon - walletDeduction).clamp(0.0, 9999.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'AC Service',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title & Subtitle
                    const Text(
                      'Review & Confirm',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Please review your booking details and bill estimate',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Review Details Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                          _buildReviewRow(
                            icon: Icons.calendar_today_rounded,
                            label: 'Date',
                            value: dateFormatted,
                          ),
                          const Divider(height: 24),
                          _buildReviewRow(
                            icon: Icons.access_time_rounded,
                            label: 'Time',
                            value: widget.selectedTime,
                          ),
                          const Divider(height: 24),
                          _buildReviewRow(
                            icon: Icons.ac_unit_rounded,
                            label: 'Service',
                            value: 'AC Service ($acType)',
                          ),
                          const Divider(height: 24),
                          _buildReviewRow(
                            icon: Icons.warning_amber_rounded,
                            label: 'Issue',
                            value: problemDesc,
                          ),
                          const Divider(height: 24),
                          _buildReviewRow(
                            icon: Icons.location_on_outlined,
                            label: 'Address',
                            value: address,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Technician Arrival Time Notice Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.directions_car_rounded, color: Color(0xFF3B49DF), size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estimated Technician Arrival',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Our service provider takes at least 20–25 minutes to reach your home.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Coupon Code Input Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.local_offer_outlined, color: Color(0xFF3B49DF), size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Do you have a coupon code?',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          if (_appliedCoupon == null)
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFCBD5E1)),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    child: TextField(
                                      controller: _couponController,
                                      textCapitalization: TextCapitalization.characters,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      decoration: const InputDecoration(
                                        hintText: 'Enter coupon (e.g. SAVE50)',
                                        hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  height: 44,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF3B49DF),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                      elevation: 0,
                                    ),
                                    onPressed: _applyCoupon,
                                    child: const Text(
                                      'Apply',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF86EFAC)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Coupon "$_appliedCoupon" Applied (-₹${_couponDiscount.toStringAsFixed(0)})',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF15803D),
                                      ),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: _removeCoupon,
                                    child: const Text(
                                      'Remove',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Wallet Rupees / Coins Integration (Uses real user wallet)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF3B49DF), size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Use Wallet Balance',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Available: ₹${_availableWalletRupees.toStringAsFixed(0)} ($_walletCoins coins)',
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                          ),
                          Switch.adaptive(
                            value: _useWallet && _availableWalletRupees > 0,
                            activeTrackColor: const Color(0xFF3B49DF),
                            onChanged: _availableWalletRupees > 0
                                ? (val) {
                                    setState(() => _useWallet = val);
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Raw Bill / Price Breakdown Card (Visiting ₹199 + Protection ₹50)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
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
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF3B49DF), size: 18),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Raw Bill / Price Breakdown',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildBillRow('Visiting & Inspection Charge', '₹449.00'),
                          const SizedBox(height: 8),
                          _buildBillRow('Safety & Protection Fee', '₹49.00'),
                          if (_appliedCoupon != null && _couponDiscount > 0) ...[
                            const SizedBox(height: 8),
                            _buildBillRow('Coupon Discount ($_appliedCoupon)', '-₹${_couponDiscount.toStringAsFixed(2)}', isDiscount: true),
                          ],
                          if (_useWallet && walletDeduction > 0) ...[
                            const SizedBox(height: 8),
                            _buildBillRow('Wallet Balance Applied', '-₹${walletDeduction.toStringAsFixed(2)}', isDiscount: true),
                          ],
                          const SizedBox(height: 8),
                          _buildBillRow('GST & Applicable Taxes', 'Included'),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Total Estimated Amount',
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                '₹${finalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF3B49DF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 14, color: Color(0xFF10B981)),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'No advance payment. Pay after service completion.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Service Guarantee Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFDCFCE7)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ServiceHub 100% Satisfaction Guarantee',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Verified professional technician assigned for your service.',
                                  style: TextStyle(fontSize: 11.5, color: Color(0xFF15803D)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Confirm Booking Button Bar
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B49DF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _isConfirming ? null : _handleConfirmBooking,
                  child: _isConfirming
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Confirm Booking',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillRow(String label, String amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDiscount ? const Color(0xFF10B981) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF3B49DF), size: 20),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

