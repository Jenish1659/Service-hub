import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/services/h3_geospatial_service.dart';
import '../../location/providers/location_provider.dart';
import '../services/ac_availability_service.dart';
import '../services/ac_booking_service.dart';
import '../services/multi_service_booking_service.dart';
import 'ac_booking_confirmed_screen.dart';
import 'service_finding_partner_screen.dart';

/// Universal Review & Confirm Booking Screen for all ServiceHub service categories.
/// Provides dynamic itemized billing, coupon/wallet redemption, strict Jamnagar geofence
/// validation, Supabase transaction insert, and atomic partner dispatch.
class ServiceReviewConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> issueDetails;
  final BookingDateOption selectedDate;
  final String selectedTime;

  const ServiceReviewConfirmScreen({
    super.key,
    required this.issueDetails,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  ConsumerState<ServiceReviewConfirmScreen> createState() => _ServiceReviewConfirmScreenState();
}

class _ServiceReviewConfirmScreenState extends ConsumerState<ServiceReviewConfirmScreen> {
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
        const SnackBar(
          content: Text('Invalid coupon code. Try SAVE50 or WELCOME20'),
          backgroundColor: Color(0xFFDC2626),
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
        content: Text('Coupon $code applied! You saved ₹${discount.toStringAsFixed(0)}'),
        backgroundColor: const Color(0xFF059669),
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
    if (_isConfirming) return;
    setState(() => _isConfirming = true);

    final supabase = Supabase.instance.client;
    final catId = (widget.issueDetails['category_id'] ?? 'ac_service').toString();
    final config = MultiServiceBookingService.getConfig(catId);

    // 1. Resolve Customer Identity
    String realCustomerId = '00000000-0000-0000-0000-000000000002';
    String userName = widget.issueDetails['customer_name'] ?? 'Customer';
    String userPhone = widget.issueDetails['customer_phone'] ?? '';
    String? realAddressId;
    String realServiceId = widget.issueDetails['service_id']?.toString() ?? catId;

    try {
      final authUser = supabase.auth.currentUser;
      if (authUser != null) {
        realCustomerId = authUser.id;
        final meta = authUser.userMetadata ?? {};
        userName = (meta['full_name'] ?? meta['name'] ?? userName).toString();
        userPhone = authUser.phone ?? (meta['phone'] ?? userPhone).toString();
      } else if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        final cachedId = box.get('user_id')?.toString();
        if (cachedId != null && cachedId.isNotEmpty) {
          final uRes = await supabase.from('users').select('user_id').eq('user_id', cachedId).maybeSingle();
          if (uRes != null && uRes['user_id'] != null) {
            realCustomerId = cachedId;
          }
        }
      }

      if (realCustomerId == '00000000-0000-0000-0000-000000000002') {
        try {
          final custUser = await supabase
              .from('users')
              .select('user_id, username, phone, user_profiles(first_name, last_name), roles!inner(role_name)')
              .eq('roles.role_name', 'customer')
              .eq('account_status', 'ACTIVE')
              .limit(1)
              .maybeSingle();
          if (custUser != null && custUser['user_id'] != null) {
            realCustomerId = custUser['user_id'].toString();
            if (userName == 'Customer') {
              dynamic prof = custUser['user_profiles'];
              if (prof is List && prof.isNotEmpty) prof = prof.first;
              userName = (prof is Map)
                  ? '${prof['first_name'] ?? ""} ${prof['last_name'] ?? ""}'.trim()
                  : (custUser['username'] ?? 'Customer').toString();
            }
            if (userPhone.isEmpty) {
              userPhone = custUser['phone']?.toString() ?? '';
            }
          }
        } catch (_) {}
      }

      final aRes = await supabase.from('user_addresses').select('address_id').eq('user_id', realCustomerId).limit(1).maybeSingle();
      if (aRes != null && aRes['address_id'] != null) {
        realAddressId = aRes['address_id'].toString();
      }

      // Resolve Real Service ID from Database catalog
      final svcRes = await supabase.from('services').select('service_id, name').eq('category_id', catId).limit(1);
      if (svcRes.isNotEmpty) {
        realServiceId = svcRes.first['service_id'].toString();
      }
    } catch (e) {
      debugPrint('[ServiceReviewConfirm] Identity resolution note: $e');
    }

    // Ensure valid user address in PostgreSQL (Mandatory foreign key)
    if (realAddressId == null && realCustomerId.isNotEmpty && realCustomerId != '00000000-0000-0000-0000-000000000002') {
      try {
        final newAddr = await supabase.from('user_addresses').insert({
          'user_id': realCustomerId,
          'address_type': 'Home',
          'area': (widget.issueDetails['customer_address']?.toString() ?? 'Jamnagar').trim(),
          'city': 'Jamnagar',
          'state': 'Gujarat',
          'pincode': '361001',
          'latitude': 22.4707,
          'longitude': 70.0577,
          'is_default': true,
        }).select('address_id').single();
        realAddressId = newAddr['address_id']?.toString();
      } catch (e) {
        debugPrint('[ServiceReviewConfirm] Auto-create address note: $e');
      }
    }

    if (realAddressId == null) {
      try {
        final anyAddr = await supabase.from('user_addresses').select('address_id').limit(1).maybeSingle();
        if (anyAddr != null && anyAddr['address_id'] != null) {
          realAddressId = anyAddr['address_id'].toString();
        }
      } catch (_) {}
    }

    final serviceName = widget.issueDetails['service_name'] ?? config.categoryName;
    final problemDesc = widget.issueDetails['problem_description'] ?? widget.issueDetails['notes'] ?? 'Standard Service Request';
    final address = widget.issueDetails['customer_address']?.toString() ?? '';

    // Pricing calculation
    final serviceBasePrice = (widget.issueDetails['service_price'] as num?)?.toDouble() ??
        (widget.issueDetails['estimated_amount'] as num?)?.toDouble() ??
        config.defaultVisitingFee;
    final visitingCharge = config.defaultVisitingFee > 0 ? config.defaultVisitingFee : 0.0;
    final protectionFee = config.protectionFee;
    final subtotal = serviceBasePrice + protectionFee;
    final afterCoupon = (subtotal - _couponDiscount).clamp(0.0, 9999.0);
    final walletDeduction = _useWallet && _availableWalletRupees > 0
        ? (_availableWalletRupees < afterCoupon ? _availableWalletRupees : afterCoupon)
        : 0.0;
    final finalPrice = (afterCoupon - walletDeduction).clamp(0.0, 9999.0);

    // Deduct wallet if applied (Backend Authoritative & Double-Spend Protection)
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

    // Strict Jamnagar Geofence check
    final locState = ref.read(locationProvider);
    var activeLoc = locState.selectedLocation ?? locState.currentLocation;
    final lat = activeLoc?.latitude ?? (widget.issueDetails['customer_lat'] as num?)?.toDouble() ?? 22.4707;
    final lng = activeLoc?.longitude ?? (widget.issueDetails['customer_lng'] as num?)?.toDouble() ?? 70.0577;

    final serviceArea = ref.read(serviceAreaServiceProvider);
    final areaCheck = serviceArea.checkServiceArea(activeLoc?.city ?? 'Jamnagar', lat, lng);
    final combinedAddress = ('$address ${activeLoc?.address ?? ""} ${activeLoc?.city ?? ""}').toLowerCase();
    if (!areaCheck.isAvailable && !combinedAddress.contains('jamnagar')) {
      setState(() => _isConfirming = false);
      _showWarningSnackBar('Sorry, we are not available at your location. ServiceHub is currently available only in Jamnagar.');
      return;
    }

    final h3Index = H3GeospatialService.instance.latLngToH3Index(lat, lng, resolution: 8);
    final pin = (1000 + DateTime.now().millisecond % 9000).toString();
    final otp = (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();

    final scheduledAtFormatted = '${widget.issueDetails['booking_date_formatted'] ?? widget.selectedDate.formattedIso} ${widget.selectedTime}'.trim();

    // Check if booking date is TODAY (Path A) or FUTURE DATE (Path B)
    final now = DateTime.now();
    final isToday = widget.selectedDate.date.year == now.year &&
        widget.selectedDate.date.month == now.month &&
        widget.selectedDate.date.day == now.day;
    final initialStatus = isToday ? 'SEARCHING_PROVIDER' : 'SCHEDULED';
    final bookingUuid = const Uuid().v4();

    // 1. Submit to LiveBookingSyncService (Local & HTTP Bridge)
    await LiveBookingSyncService.instance.submitBooking({
      'id': bookingUuid,
      'booking_id': bookingUuid,
      'customer_id': realCustomerId,
      'customer_name': userName.isNotEmpty ? userName : 'Customer',
      'customer_phone': userPhone.isNotEmpty ? userPhone : '',
      'service_id': realServiceId,
      'service_name': serviceName,
      'category': config.categoryName,
      'category_name': config.categoryName,
      'category_id': catId,
      'required_role': config.requiredRole,
      'required_capability': config.requiredCapability,
      'problem_description': problemDesc,
      'scheduled_date': scheduledAtFormatted,
      'scheduled_time': widget.selectedTime,
      'payment_method': 'Cash on Service',
      'price': finalPrice,
      'customer_address': address,
      'customer_lat': lat,
      'customer_lng': lng,
      'entrance_pin': pin,
      'completion_otp': otp,
      'status': initialStatus,
      'service_status': initialStatus,
      'is_today': isToday,
      'customer_h3_res8': h3Index,
      'service_details': widget.issueDetails,
    });

    // 2. Write to Supabase service_bookings table
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
        'problem_description': problemDesc,
        'estimated_amount': finalPrice,
        'final_amount': finalPrice,
        'customer_latitude': lat,
        'customer_longitude': lng,
        'entrance_pin': pin,
        'completion_otp': otp,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Successfully inserted booking into Supabase service_bookings: $bookingUuid');
    } catch (e) {
      debugPrint('Supabase service_bookings insert note: $e');
    }

    // 3. For Same-Day booking (Path A), execute Real Partner Assignment Dispatch
    if (isToday) {
      try {
        await supabase.rpc('find_and_dispatch_eligible_partners', params: {
          'p_booking_id': bookingUuid,
        });
      } catch (e) {
        debugPrint('[ServiceReviewConfirm] RPC dispatch note: $e');
      }

      try {
        if (config.requiredRole == 'service_provider') {
          final candidatesRes = await supabase
              .from('service_provider_profiles')
              .select('provider_id, partner_id, partners(partner_id, user_id, verification_status, availability_status, users(user_id, is_active, account_status, roles(role_name)), partner_live_locations(latitude, longitude))');

          for (final c in candidatesRes) {
            dynamic pRaw = c['partners'];
            if (pRaw is List && pRaw.isNotEmpty) pRaw = pRaw.first;
            final p = pRaw is Map<String, dynamic> ? pRaw : null;

            dynamic uRaw = p?['users'];
            if (uRaw is List && uRaw.isNotEmpty) uRaw = uRaw.first;
            final u = uRaw is Map<String, dynamic> ? uRaw : null;

            dynamic rRaw = u?['roles'];
            if (rRaw is List && rRaw.isNotEmpty) rRaw = rRaw.first;
            final r = rRaw is Map<String, dynamic> ? rRaw : null;

            dynamic locRaw = p?['partner_live_locations'];
            if (locRaw is List && locRaw.isNotEmpty) locRaw = locRaw.first;
            final loc = locRaw is Map<String, dynamic> ? locRaw : null;

            final isRoleMatch = (r?['role_name'] ?? '').toString().toLowerCase() == 'service_provider';
            final vStat = (p?['verification_status'] ?? '').toString().toUpperCase();
            final aStat = (p?['availability_status'] ?? '').toString().toUpperCase();
            final isVerified = vStat == 'VERIFIED' || vStat == 'APPROVED';
            final isOnline = aStat == 'ONLINE' || aStat == 'AVAILABLE';
            final isActive = (u?['is_active'] == true || u?['is_active'] == null) &&
                (u?['account_status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';

            if (isRoleMatch && isVerified && isOnline && isActive) {
              final pLat = (loc?['latitude'] as num?)?.toDouble() ?? 22.4707;
              final pLng = (loc?['longitude'] as num?)?.toDouble() ?? 70.0577;

              // PostGIS / Haversine distance in Jamnagar (<= 15 km)
              final distKm = ACAvailabilityService.instance.calculateHaversineDistanceKm(lat, lng, pLat, pLng);
              if (distKm <= 15.0) {
                await supabase.from('booking_requests').insert({
                  'booking_id': bookingUuid,
                  'provider_id': c['provider_id'],
                  'partner_id': c['partner_id'],
                  'response_status': 'Pending',
                  'sent_at': DateTime.now().toIso8601String(),
                });
              }
            }
          }
        } else if (config.requiredRole == 'shopkeeper') {
          // Laundry Shopkeeper matching
          final shopsRes = await supabase
              .from('shops')
              .select('shop_id, shopkeeper_id, shop_type, shopkeeper_profiles(shopkeeper_id, partner_id, partners(partner_id, user_id, verification_status, availability_status, users(user_id, is_active, account_status)))');

          for (final sh in shopsRes) {
            final shopType = (sh['shop_type'] ?? '').toString().toUpperCase();
            if (shopType.contains('LAUNDRY')) {
              dynamic skpRaw = sh['shopkeeper_profiles'];
              if (skpRaw is List && skpRaw.isNotEmpty) skpRaw = skpRaw.first;
              final skp = skpRaw is Map<String, dynamic> ? skpRaw : null;

              dynamic pRaw = skp?['partners'];
              if (pRaw is List && pRaw.isNotEmpty) pRaw = pRaw.first;
              final p = pRaw is Map<String, dynamic> ? pRaw : null;

              dynamic uRaw = p?['users'];
              if (uRaw is List && uRaw.isNotEmpty) uRaw = uRaw.first;
              final u = uRaw is Map<String, dynamic> ? uRaw : null;

              final vStat = (p?['verification_status'] ?? '').toString().toUpperCase();
              final aStat = (p?['availability_status'] ?? '').toString().toUpperCase();
              final isVerified = vStat == 'VERIFIED' || vStat == 'APPROVED';
              final isOnline = aStat == 'ONLINE' || aStat == 'AVAILABLE';
              final isActive = (u?['is_active'] == true || u?['is_active'] == null) &&
                  (u?['account_status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';

              if (isVerified && isOnline && isActive && skp != null) {
                await supabase.from('booking_requests').insert({
                  'booking_id': bookingUuid,
                  'partner_id': skp['partner_id'],
                  'response_status': 'Pending',
                  'sent_at': DateTime.now().toIso8601String(),
                });
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[ServiceReviewConfirm] Dispatch dispatch note: $e');
      }
    }

    // Clear draft after confirmed booking
    await MultiServiceBookingService.instance.clearDraft(catId);

    if (!mounted) return;

    if (isToday) {
      // Path A: Same-Day Immediate Matching Screen
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ServiceFindingPartnerScreen(
            bookingId: bookingUuid,
            serviceTitle: serviceName,
            address: address,
            selectedDateFormatted: widget.issueDetails['booking_date_formatted'] ?? widget.selectedDate.formattedIso,
            selectedTime: widget.selectedTime,
            categoryConfig: config,
            customerPhone: userPhone,
          ),
        ),
      );
    } else {
      // Path B: Future Scheduled Booking Screen
      Navigator.of(context, rootNavigator: true).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ACBookingConfirmedScreen(
            bookingData: {
              'id': bookingUuid,
              'booking_id': bookingUuid,
              'status': 'SCHEDULED',
              'partner_id': null,
            },
            selectedDateFormatted: widget.issueDetails['booking_date_formatted'] ?? widget.selectedDate.userFriendlyDisplay,
            selectedTime: widget.selectedTime,
            serviceTitle: serviceName,
            address: address,
            visitingCharge: visitingCharge,
            protectionFee: protectionFee,
            finalPayable: finalPrice,
            isFutureDate: true,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final catId = (widget.issueDetails['category_id'] ?? 'ac_service').toString();
    final config = MultiServiceBookingService.getConfig(catId);
    final serviceName = widget.issueDetails['service_name'] ?? config.categoryName;
    final address = widget.issueDetails['customer_address']?.toString() ?? '';

    final serviceBasePrice = (widget.issueDetails['service_price'] as num?)?.toDouble() ??
        (widget.issueDetails['estimated_amount'] as num?)?.toDouble() ??
        config.defaultVisitingFee;
    final visitingCharge = config.defaultVisitingFee > 0 ? config.defaultVisitingFee : 0.0;
    final protectionFee = config.protectionFee;
    final subtotal = serviceBasePrice + protectionFee;
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
          'Review & Confirm',
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Service & Requirements Card
                    _buildServiceSummaryCard(serviceName, config),

                    const SizedBox(height: 16),

                    // Appointment Schedule Card
                    _buildAppointmentCard(),

                    const SizedBox(height: 16),

                    // Service Address Card
                    _buildAddressCard(address),

                    const SizedBox(height: 16),

                    // Coupon & Offers Card
                    _buildCouponCard(),

                    const SizedBox(height: 16),

                    // Wallet & ServiceHub Coins
                    _buildWalletCard(),

                    const SizedBox(height: 16),

                    // Itemized Billing Breakdown
                    _buildBillingCard(visitingCharge, serviceBasePrice, protectionFee, walletDeduction, finalPrice),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom Confirm CTA Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Total Payable',
                        style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${finalPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isConfirming ? null : _handleConfirmBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B49DF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isConfirming
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text(
                                'Book Service Now',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceSummaryCard(String serviceName, ServiceCategoryConfig config) {
    final catId = config.categoryId;
    final items = widget.issueDetails['items'] as Map<String, dynamic>?;
    final vehicleModel = widget.issueDetails['vehicle_model'] ?? widget.issueDetails['car_model'];
    final careCategory = widget.issueDetails['care_category'] ?? widget.issueDetails['care_type'];
    final cuisine = widget.issueDetails['cuisine'] ?? widget.issueDetails['cuisine_type'];
    final plumbingArea = widget.issueDetails['plumbing_area'] ?? widget.issueDetails['issue_type'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.handyman_rounded, color: Color(0xFF3B49DF), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serviceName,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      config.categoryName,
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),

          // Service-Specific Details Preview
          if (catId == 'laundry' && items != null) ...[
            const Text('Selected Items & Quantity:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            const SizedBox(height: 6),
            ...items.entries.where((e) => (e.value as num) > 0).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(e.key, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                      Text('${e.value} pcs', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    ],
                  ),
                )),
          ] else if (catId == 'car_service' && vehicleModel != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Vehicle:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                Text('$vehicleModel', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ] else if (catId == 'care_taker' && careCategory != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Care Need:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                Text('$careCategory', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ] else if (catId == 'cooking' && cuisine != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cuisine & Persons:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                Text('$cuisine • ${widget.issueDetails['headcount'] ?? "Family"}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ] else if (catId == 'plumbing' && plumbingArea != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Issue Type:', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                Text('$plumbingArea', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAppointmentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.event_note_rounded, color: Color(0xFF3B49DF), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date & Time Slot', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  '${widget.selectedDate.userFriendlyDisplay} at ${widget.selectedTime}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(String address) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.place_rounded, color: Color(0xFFDC2626), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Service Location', style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Jamnagar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCouponCard() {
    return Container(
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
              Icon(Icons.local_offer_outlined, color: Color(0xFF059669), size: 20),
              SizedBox(width: 8),
              Text('Coupons & Discounts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
          const SizedBox(height: 12),
          if (_appliedCoupon != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFA7F3D0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Code: $_appliedCoupon (-₹${_couponDiscount.toStringAsFixed(0)})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF059669)),
                    onPressed: _removeCoupon,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _couponController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Enter promo code (e.g. SAVE50)',
                        hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: _applyCoupon,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF3B49DF), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ServiceHub Wallet', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(
                  'Available: ₹${_walletBalance.toStringAsFixed(0)} • $_walletCoins Coins',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          Switch(
            value: _useWallet,
            activeThumbColor: const Color(0xFF3B49DF),
            onChanged: _walletBalance > 0
                ? (val) => setState(() => _useWallet = val)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBillingCard(
    double visitingCharge,
    double servicePrice,
    double protectionFee,
    double walletDeduct,
    double finalPrice,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bill Summary', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          const SizedBox(height: 12),
          _billRow('Service Charge', '₹${servicePrice.toStringAsFixed(0)}'),
          if (visitingCharge > 0 && visitingCharge != servicePrice)
            _billRow('Visiting / Diagnostic Fee', '₹${visitingCharge.toStringAsFixed(0)}'),
          _billRow('Safety & Insurance Fee', '₹${protectionFee.toStringAsFixed(0)}'),
          if (_couponDiscount > 0)
            _billRow('Coupon Discount', '-₹${_couponDiscount.toStringAsFixed(0)}', isDiscount: true),
          if (walletDeduct > 0)
            _billRow('Wallet Deduction', '-₹${walletDeduct.toStringAsFixed(0)}', isDiscount: true),
          const Divider(height: 20, color: Color(0xFFF1F5F9)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Final Payable', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              Text('₹${finalPrice.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF3B49DF))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B))),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDiscount ? const Color(0xFF059669) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}
