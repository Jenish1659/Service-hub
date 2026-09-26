import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/live_booking_sync_service.dart';
import '../../../services/services/ac_availability_service.dart';
import '../../../services/services/ac_booking_service.dart';
import '../../../services/presentation/ac_booking_confirmed_screen.dart';
import '../../../location/providers/location_provider.dart';

/// Centralized AC Service Booking Flow Screen and Submission Lifecycle Handler
class ACBookingFlowScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? initialIssueDetails;

  const ACBookingFlowScreen({
    super.key,
    this.initialIssueDetails,
  });

  /// Centralized static booking submission method that writes to Supabase `bookings` table
  /// AND broadcasts to `LiveBookingSyncService.instance.submitBooking(...)`.
  ///
  /// Guarantees that the booking payload contains all necessary fields:
  /// - id
  /// - booking_id
  /// - service_id: 'ac_service'
  /// - service_name
  /// - status: 'PENDING' or 'CONFIRMED'
  /// - customer_name
  /// - address
  /// - final_amount
  /// - scheduled_at
  /// - created_at
  static Future<Map<String, dynamic>> submitACBooking({
    required String customerName,
    required String address,
    required double finalAmount,
    required String scheduledAt,
    String? id,
    String? bookingId,
    String serviceId = 'ac_service',
    String serviceName = 'AC Service (Split AC)',
    String status = 'PENDING',
    String? customerPhone,
    String? customerId,
    String? problemDescription,
    String? scheduledDate,
    String? scheduledTime,
    String? acBrand,
    String? acType,
    double? customerLat,
    double? customerLng,
    String? entrancePin,
    String? completionOtp,
    String paymentMethod = 'Cash on Service',
    Map<String, dynamic>? extraData,
  }) async {
    final bId = id ?? bookingId ?? 'AC_${DateTime.now().millisecondsSinceEpoch}';
    final nowIso = DateTime.now().toIso8601String();
    final pin = entrancePin ?? (1000 + DateTime.now().millisecond % 9000).toString();
    final otp = completionOtp ?? (1000 + (DateTime.now().microsecondsSinceEpoch % 9000)).toString();

    final Map<String, dynamic> payload = {
      'id': bId,
      'booking_id': bId,
      'service_id': serviceId,
      'service_name': serviceName,
      'status': status.toUpperCase(),
      'service_status': status.toUpperCase(),
      'customer_id': customerId ?? 'cust_live_user',
      'customer_name': customerName,
      'customer_phone': customerPhone ?? '',
      'address': address,
      'customer_address': address,
      'final_amount': finalAmount,
      'price': finalAmount,
      'estimated_amount': finalAmount,
      'scheduled_at': scheduledAt,
      'scheduled_date': scheduledDate ?? scheduledAt.split(' ').first,
      'scheduled_time': scheduledTime ?? (scheduledAt.contains(' ') ? scheduledAt.split(' ').sublist(1).join(' ') : '10:00 AM'),
      'scheduled_time_slot': scheduledTime ?? (scheduledAt.contains(' ') ? scheduledAt.split(' ').sublist(1).join(' ') : '10:00 AM'),
      'problem_description': problemDescription ?? 'AC Service & Jet Cleaning',
      'category': 'AC Service',
      'category_name': 'AC Service Specialist',
      'ac_brand': acBrand ?? '',
      'ac_type': acType ?? 'Split AC',
      'customer_lat': customerLat ?? 22.4707,
      'customer_lng': customerLng ?? 70.0577,
      'entrance_pin': pin,
      'completion_otp': otp,
      'payment_method': paymentMethod,
      'tracking_id': 'TRK-AC-${DateTime.now().millisecondsSinceEpoch}',
      'created_at': nowIso,
    };

    if (extraData != null) {
      payload.addAll(extraData);
    }

    // 1. Write to Supabase bookings table
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('bookings').insert(payload);
      debugPrint('Successfully wrote booking to Supabase bookings table: $bId');
    } catch (e) {
      debugPrint('Supabase bookings insert note (offline/simulated): $e');
    }

    // Also attempt write to service_bookings table if available
    try {
      final supabase = Supabase.instance.client;
      await supabase.from('service_bookings').insert({
        'booking_id': bId,
        'status': payload['status'],
        'final_amount': finalAmount,
        'scheduled_time': scheduledAt,
        'problem_description': payload['problem_description'],
        'entrance_pin': pin,
        'completion_otp': otp,
      });
    } catch (_) {}

    // 2. Broadcast to LiveBookingSyncService.instance.submitBooking(...)
    await LiveBookingSyncService.instance.submitBooking(payload);

    return payload;
  }

  @override
  ConsumerState<ACBookingFlowScreen> createState() => _ACBookingFlowScreenState();
}

class _ACBookingFlowScreenState extends ConsumerState<ACBookingFlowScreen> {
  int _currentStep = 0;
  bool _isSubmitting = false;

  // Step 1: Issue Details
  String _acType = 'Split AC';
  String _acBrand = 'Daikin';
  final TextEditingController _problemController = TextEditingController(text: 'AC Not Cooling properly, needs deep jet wash service');

  // Step 2: Date & Time
  late BookingDateOption _selectedDate;
  String _selectedTime = '10:00 AM';

  // Step 3: Customer Details
  final TextEditingController _nameController = TextEditingController(text: 'Customer');
  final TextEditingController _phoneController = TextEditingController(text: '+91 98765 43210');
  final TextEditingController _addressController = TextEditingController(text: '12, Shanti Nagar, Ahmedabad, Gujarat 380001');

  // Pricing
  final double _visitingCharge = 449.0;
  final double _protectionFee = 49.0;
  final double _couponDiscount = 0.0;
  String? _couponCode;

  @override
  void initState() {
    super.initState();
    final dates = ACAvailabilityService.instance.getNext3BookingDates();
    _selectedDate = dates.isNotEmpty ? dates.first : BookingDateOption(
      date: DateTime.now().add(const Duration(days: 1)),
      dayName: 'Tomorrow',
      dateNumber: '${DateTime.now().add(const Duration(days: 1)).day}',
      monthName: 'Current',
      formattedIso: DateTime.now().add(const Duration(days: 1)).toIso8601String().split('T').first,
      isTomorrow: true,
    );

    if (widget.initialIssueDetails != null) {
      final d = widget.initialIssueDetails!;
      if (d['ac_type'] != null) _acType = d['ac_type'].toString();
      if (d['ac_brand'] != null) _acBrand = d['ac_brand'].toString();
      if (d['problem_description'] != null) _problemController.text = d['problem_description'].toString();
      if (d['customer_name'] != null) _nameController.text = d['customer_name'].toString();
      if (d['customer_phone'] != null) _phoneController.text = d['customer_phone'].toString();
      if (d['customer_address'] != null) _addressController.text = d['customer_address'].toString();
    }

    _loadUserInfo();
  }

  void _loadUserInfo() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final metaName = user.userMetadata?['name'] as String? ?? user.userMetadata?['full_name'] as String?;
        if (metaName != null && metaName.isNotEmpty) _nameController.text = metaName;
        final metaPhone = user.phone ?? user.userMetadata?['phone'] as String?;
        if (metaPhone != null && metaPhone.isNotEmpty) _phoneController.text = metaPhone;
      }
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        final savedName = box.get('user_name') as String?;
        if (savedName != null && savedName.isNotEmpty) _nameController.text = savedName;
        final savedPhone = box.get('user_phone') as String?;
        if (savedPhone != null && savedPhone.isNotEmpty) _phoneController.text = savedPhone;
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _problemController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  double get _finalPayable {
    final subtotal = _visitingCharge + _protectionFee;
    return (subtotal - _couponDiscount).clamp(0.0, 99999.0);
  }

  Future<void> _submitBookingFlow() async {
    setState(() => _isSubmitting = true);

    final locState = ref.read(locationProvider);
    final activeLoc = locState.selectedLocation ?? locState.currentLocation;
    final lat = activeLoc?.latitude ?? 22.4707;
    final lng = activeLoc?.longitude ?? 70.0577;

    final customerName = _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : 'Customer';
    final customerAddress = _addressController.text.trim().isNotEmpty
        ? _addressController.text.trim()
        : '12, Shanti Nagar, Ahmedabad, Gujarat';
    final scheduledAt = '${_selectedDate.formattedIso} $_selectedTime';

    final createdBooking = await ACBookingFlowScreen.submitACBooking(
      customerName: customerName,
      customerPhone: _phoneController.text.trim(),
      address: customerAddress,
      finalAmount: _finalPayable,
      scheduledAt: scheduledAt,
      scheduledDate: _selectedDate.formattedIso,
      scheduledTime: _selectedTime,
      acBrand: _acBrand,
      acType: _acType,
      problemDescription: '$_acType ($_acBrand) - ${_problemController.text.trim()}',
      serviceName: 'AC Service ($_acType)',
      status: 'PENDING',
      customerLat: lat,
      customerLng: lng,
    );

    await ACIssueBookingService.instance.clearDraft();

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pushReplacement(
      MaterialPageRoute(
        builder: (context) => ACBookingConfirmedScreen(
          bookingData: createdBooking,
          selectedDateFormatted: '${_selectedDate.dayName}, ${_selectedDate.dateNumber} ${_selectedDate.monthName}',
          selectedTime: _selectedTime,
          serviceTitle: 'AC Service ($_acType)',
          address: customerAddress,
          visitingCharge: _visitingCharge,
          protectionFee: _protectionFee,
          couponDiscount: _couponDiscount,
          couponCode: _couponCode,
          finalPayable: _finalPayable,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('AC Service Booking Flow', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress Indicator
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  _buildStepDot(0, 'Issue'),
                  _buildStepDivider(0),
                  _buildStepDot(1, 'Schedule'),
                  _buildStepDivider(1),
                  _buildStepDot(2, 'Address'),
                  _buildStepDivider(2),
                  _buildStepDot(3, 'Confirm'),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),

            // Active Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCurrentStepContent(),
              ),
            ),

            // Bottom Navigation Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => setState(() => _currentStep--),
                        child: const Text('Back', style: TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () {
                              if (_currentStep < 3) {
                                setState(() => _currentStep++);
                              } else {
                                _submitBookingFlow();
                              }
                            },
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(
                              _currentStep == 3 ? 'Confirm & Book (₹${_finalPayable.toStringAsFixed(0)})' : 'Continue',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

  Widget _buildStepDot(int step, String label) {
    final isActive = _currentStep == step;
    final isDone = _currentStep > step;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isDone ? const Color(0xFF10B981) : (isActive ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : Text('${step + 1}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isActive ? Colors.white : const Color(0xFF64748B))),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            color: isActive ? const Color(0xFF2563EB) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildStepDivider(int step) {
    final isDone = _currentStep > step;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 14, left: 4, right: 4),
        color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
      ),
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildIssueStep();
      case 1:
        return _buildScheduleStep();
      case 2:
        return _buildAddressStep();
      case 3:
      default:
        return _buildReviewStep();
    }
  }

  Widget _buildIssueStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('AC Type & Issue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        const Text('Select your appliance type and explain the issue you are facing.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 20),

        const Text('AC Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        Row(
          children: ['Split AC', 'Window AC', 'Cassette AC'].map((type) {
            final isSel = _acType == type;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(type),
                selected: isSel,
                selectedColor: const Color(0xFF2563EB),
                labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF334155), fontWeight: FontWeight.bold),
                onSelected: (val) => setState(() => _acType = type),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        const Text('AC Brand', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: ['Daikin', 'Voltas', 'LG', 'Samsung', 'Hitachi', 'Blue Star'].map((brand) {
            final isSel = _acBrand == brand;
            return ChoiceChip(
              label: Text(brand),
              selected: isSel,
              selectedColor: const Color(0xFF2563EB),
              labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF334155), fontWeight: FontWeight.bold),
              onSelected: (val) => setState(() => _acBrand = brand),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        const Text('Describe Problem', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        TextField(
          controller: _problemController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'e.g. Low cooling, strange noise, water leakage...',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleStep() {
    final dates = ACAvailabilityService.instance.getNext3BookingDates();
    final times = ['10:00 AM', '12:00 PM', '02:00 PM', '04:00 PM', '06:00 PM'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Date & Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        const Text('Choose a preferred slot for technician arrival.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 20),

        const Text('Available Dates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        Row(
          children: dates.map((d) {
            final isSel = _selectedDate.formattedIso == d.formattedIso;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedDate = d),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSel ? const Color(0xFF2563EB) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSel ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Text(d.dayName, style: TextStyle(fontSize: 11, color: isSel ? Colors.white70 : const Color(0xFF64748B))),
                      const SizedBox(height: 4),
                      Text(d.dateNumber, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSel ? Colors.white : const Color(0xFF0F172A))),
                      const SizedBox(height: 2),
                      Text(d.monthName, style: TextStyle(fontSize: 11, color: isSel ? Colors.white70 : const Color(0xFF64748B))),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),

        const Text('Preferred Time Slot', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: times.map((t) {
            final isSel = _selectedTime == t;
            return ChoiceChip(
              label: Text(t),
              selected: isSel,
              selectedColor: const Color(0xFF2563EB),
              labelStyle: TextStyle(color: isSel ? Colors.white : const Color(0xFF334155), fontWeight: FontWeight.bold),
              onSelected: (val) => setState(() => _selectedTime = t),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAddressStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Contact & Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        const Text('Where should our certified AC technician visit?', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 20),

        const Text('Full Name', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            hintText: 'Your Name',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 16),

        const Text('Phone Number', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: '+91 98765 43210',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
        const SizedBox(height: 16),

        const Text('Service Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
        const SizedBox(height: 8),
        TextField(
          controller: _addressController,
          maxLines: 2,
          decoration: InputDecoration(
            hintText: 'Street, Apartment / House No, Landmark, City',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Booking Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
        const SizedBox(height: 6),
        const Text('Verify your details and price estimate before confirming.', style: TextStyle(fontSize: 13, color: Color(0xFF64748B))),
        const SizedBox(height: 16),

        // Summary Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('AC Service ($_acType)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF0F172A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                    child: Text(_acBrand, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Text('${_selectedDate.dayName}, ${_selectedDate.dateNumber} ${_selectedDate.monthName} • $_selectedTime', style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569))),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _addressController.text.trim().isNotEmpty ? _addressController.text.trim() : 'Ahmedabad, Gujarat',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bill Breakdown Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Raw Bill / Price Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              _buildBillRow('Visiting & Inspection Charge', '₹${_visitingCharge.toStringAsFixed(0)}'),
              const SizedBox(height: 8),
              _buildBillRow('Safety & Protection Fee', '₹${_protectionFee.toStringAsFixed(0)}'),
              if (_couponDiscount > 0) ...[
                const SizedBox(height: 8),
                _buildBillRow('Coupon Discount', '-₹${_couponDiscount.toStringAsFixed(0)}', isGreen: true),
              ],
              const Divider(height: 20, color: Color(0xFFE2E8F0)),
              _buildBillRow('Final Amount Payable', '₹${_finalPayable.toStringAsFixed(0)}', isBold: true),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBillRow(String label, String value, {bool isGreen = false, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF475569),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 15 : 13,
            fontWeight: FontWeight.bold,
            color: isGreen ? const Color(0xFF10B981) : (isBold ? const Color(0xFF2563EB) : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
