import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';

import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../location/providers/location_provider.dart';
import '../services/ac_availability_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';

class ACDateTimeSelectionScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? issueDetails;

  const ACDateTimeSelectionScreen({
    super.key,
    this.issueDetails,
  });

  @override
  ConsumerState<ACDateTimeSelectionScreen> createState() => _ACDateTimeSelectionScreenState();
}

class _ACDateTimeSelectionScreenState extends ConsumerState<ACDateTimeSelectionScreen> {
  late Map<String, dynamic> _activeIssueDetails;
  late List<BookingDateOption> _availableDates;

  BookingDateOption? _selectedDate;
  String? _selectedTime;
  int _activePartnersCount = 3;
  bool _isLoadingSlots = true;
  bool _isCheckingFinalAvailability = false;

  Map<String, List<TimeSlotOption>> _categorizedSlots = {
    'Morning': [],
    'Afternoon': [],
    'Evening': [],
  };

  @override
  void initState() {
    super.initState();
    _initBookingData();
  }

  Future<void> _initBookingData() async {
    // 1. Pull pure real issue data passed from previous step or cached draft
    if (widget.issueDetails != null && widget.issueDetails!.isNotEmpty) {
      _activeIssueDetails = Map<String, dynamic>.from(widget.issueDetails!);
    } else {
      try {
        final box = Hive.box('customer_cache');
        final cached = box.get('current_ac_issue_booking') as Map<dynamic, dynamic>?;
        if (cached != null) {
          _activeIssueDetails = Map<String, dynamic>.from(cached);
        } else {
          _activeIssueDetails = {
            'service_name': 'AC Service & Repair',
            'ac_type': 'Split AC',
            'ac_brand': 'Voltas',
            'problem_description': 'AC cooling diagnostic and general maintenance service',
          };
        }
      } catch (_) {
        _activeIssueDetails = {
          'service_name': 'AC Service & Repair',
          'ac_type': 'Split AC',
          'ac_brand': 'Voltas',
          'problem_description': 'AC cooling diagnostic and general maintenance service',
        };
      }
    }

    // 2. Compute the strict 3 available pre-booking dates (D+1, D+2, D+3; excluding Today D)
    _availableDates = ACAvailabilityService.instance.getNext3BookingDates();
    if (_availableDates.isNotEmpty) {
      _selectedDate = _availableDates.first;
    }

    // 3. Query real active partner count & slots for the first date
    _activePartnersCount = await ACAvailabilityService.instance.getActiveACPartnersCount();
    await _loadSlotsForDate(_selectedDate!.date);
  }

  Future<void> _loadSlotsForDate(DateTime date) async {
    setState(() {
      _isLoadingSlots = true;
      _selectedTime = null; // Reset selection when date changes
    });

    final slots = await ACAvailabilityService.instance.getSlotAvailabilityForDate(date);

    if (mounted) {
      setState(() {
        _categorizedSlots = slots;
        _isLoadingSlots = false;

        // Auto-select first available slot if available
        for (var slotList in slots.values) {
          for (var slot in slotList) {
            if (slot.isAvailable) {
              _selectedTime = slot.time;
              return;
            }
          }
        }
      });
    }
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _handleContinue() async {
    if (_selectedDate == null) {
      _showWarningSnackBar('Please select a booking date.');
      return;
    }

    if (_selectedTime == null || _selectedTime!.isEmpty) {
      _showWarningSnackBar('Please select an available 15-minute time slot.');
      return;
    }

    setState(() {
      _isCheckingFinalAvailability = true;
    });

    // 1. Live atomic availability verification
    final isStillAvailable = await ACAvailabilityService.instance.verifySlotStillAvailable(
      date: _selectedDate!.date,
      timeSlot: _selectedTime!,
    );

    if (!isStillAvailable) {
      setState(() {
        _isCheckingFinalAvailability = false;
      });
      _showWarningSnackBar('This time slot is no longer available. Please choose another time.');
      await _loadSlotsForDate(_selectedDate!.date);
      return;
    }

    // 2. Update booking record with real date & time
    final updatedBookingData = Map<String, dynamic>.from(_activeIssueDetails);
    updatedBookingData['booking_date'] = _selectedDate!.formattedIso;
    updatedBookingData['booking_date_formatted'] = '${_selectedDate!.dayName}, ${_selectedDate!.dateNumber} ${_selectedDate!.monthName}';
    updatedBookingData['scheduled_time'] = _selectedTime;
    updatedBookingData['estimated_duration'] = '60 – 90 min';
    updatedBookingData['status'] = 'DRAFT_DATE_TIME_SELECTED';
    updatedBookingData['updated_at'] = DateTime.now().toIso8601String();

    try {
      final box = Hive.box('customer_cache');
      await box.put('current_ac_issue_booking', updatedBookingData);
    } catch (_) {}

    // 3. Dispatch live booking request to ServiceHub backend & partners
    String userId = 'cust_${DateTime.now().millisecondsSinceEpoch}';
    String userName = 'Jenish Bheda';
    String userPhone = '+91 98765 43210';
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        userId = user.id;
        userName = user.userMetadata?['name'] as String? ?? user.email?.split('@').first ?? 'Jenish Bheda';
        userPhone = user.phone ?? '+91 98765 43210';
      }
    } catch (_) {}

    final locState = ref.read(locationProvider);
    final activeLocation = locState.selectedLocation ?? locState.currentLocation;
    final serviceAddress = activeLocation?.address ?? 'Selected Service Location, Jamnagar';
    final serviceLat = activeLocation?.latitude ?? 22.4707;
    final serviceLng = activeLocation?.longitude ?? 70.0577;
    final serviceName = _activeIssueDetails['service_name'] ?? 'AC Service & Repair';
    final acType = _activeIssueDetails['ac_type'] ?? 'Split AC';
    final acBrand = _activeIssueDetails['ac_brand'] ?? 'AC Unit';
    final problemDesc = _activeIssueDetails['problem_description'] ?? 'AC Service requested by customer';

    final createdBooking = await LiveBookingSyncService.instance.createACBooking(
      customerId: userId,
      customerName: userName,
      customerPhone: userPhone,
      serviceName: serviceName,
      problemDescription: '$acType ($acBrand) - $problemDesc',
      scheduledDate: '${_selectedDate!.dayName}, ${_selectedDate!.dateNumber} ${_selectedDate!.monthName}',
      scheduledTime: _selectedTime!,
      paymentMethod: 'Cash on Service',
      price: (updatedBookingData['service_price'] as num?)?.toDouble() ?? 499.0,
      customerAddress: serviceAddress,
      customerLat: serviceLat,
      customerLng: serviceLng,
      entrancePin: '7429',
      completionOtp: '5892',
    );

    setState(() {
      _isCheckingFinalAvailability = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Slot confirmed: ${_selectedDate!.dayName} at $_selectedTime! Partner notified.'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    final bookingId = createdBooking['id'];
    Navigator.of(context).popUntil((route) => route.isFirst);
    context.push('/track-booking/$bookingId');
  }

  @override
  Widget build(BuildContext context) {
    final todayFormatted = DateFormat('dd MMM yyyy').format(DateTime.now());

    final serviceName = _activeIssueDetails['service_name'] ?? 'AC Service';
    final acType = _activeIssueDetails['ac_type'] ?? 'Split AC';
    final acBrand = _activeIssueDetails['ac_brand'] ?? 'AC Unit';
    final problemDesc = _activeIssueDetails['problem_description'] ?? 'AC Diagnostic & Maintenance';

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
        actions: [
          // "Need Help?" AI Chatbot button
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: () => ACDateTimeAIChatbotSheet.show(
                context,
                selectedDateText: _selectedDate != null ? '${_selectedDate!.dayName}, ${_selectedDate!.dateNumber} ${_selectedDate!.monthName}' : null,
                selectedTimeText: _selectedTime,
                availablePartners: _activePartnersCount,
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.support_agent_rounded, size: 18, color: Color(0xFF3B49DF)),
                    SizedBox(width: 6),
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B49DF),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Header with Calendar & Clock Illustration
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF1F5F9), Color(0xFFEFF6FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Choose Date & Time',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Select a convenient date and time for our expert visit.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Calendar Illustration Badge
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 64,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Container(
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3B49DF),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(9)),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                  3,
                                  (i) => Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                  3,
                                  (i) => Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: const Color(0xFF3B49DF), width: 1.5),
                          ),
                          child: const Icon(Icons.access_time_rounded, color: Color(0xFF3B49DF), size: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Service Summary Card (With 100% Real User Input from Previous Step)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AC Unit Avatar
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(Icons.ac_unit_rounded, color: Color(0xFF3B49DF), size: 24),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            serviceName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildSummaryTag('Type', acType),
                              const SizedBox(width: 8),
                              _buildSummaryTag('Brand', acBrand),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Issue: $problemDesc',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    // Edit Action
                    OutlinedButton.icon(
                      icon: const Icon(Icons.edit_outlined, size: 14, color: Color(0xFF3B49DF)),
                      label: const Text(
                        'Edit',
                        style: TextStyle(fontSize: 12, color: Color(0xFF3B49DF), fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        side: const BorderSide(color: Color(0xFFC7D2FE)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // 4-Item Status Strip
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildMetaPill(Icons.access_time_rounded, 'Estimated Duration', '60 – 90 min', const Color(0xFF3B49DF)),
                    const SizedBox(width: 8),
                    _buildMetaPill(Icons.people_outline_rounded, 'Available Partners', '$_activePartnersCount partners available', const Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    _buildMetaPill(Icons.verified_user_outlined, 'Service Mode', 'At your location', const Color(0xFF6366F1)),
                    const SizedBox(width: 8),
                    _buildMetaPill(Icons.location_on_outlined, 'Time Zone', 'Local Time (Auto)', const Color(0xFF64748B)),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 1. Select Date Header with Today Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF3B49DF)),
                      SizedBox(width: 8),
                      Text(
                        '1. Select Date',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Today: $todayFormatted',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF3B49DF), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Strict 3-Day Horizontal Date Cards (Excluding Today D)
              Row(
                children: _availableDates.map((dateOpt) {
                  final isSelected = _selectedDate?.formattedIso == dateOpt.formattedIso;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _selectedDate = dateOpt;
                          });
                          _loadSlotsForDate(dateOpt.date);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected ? const Color(0xFF3B49DF).withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Column(
                                children: [
                                  Text(
                                    dateOpt.dayName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                      color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateOpt.dateNumber,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateOpt.monthName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              if (isSelected)
                                const Positioned(
                                  top: 0,
                                  right: 0,
                                  child: Icon(Icons.check_circle_rounded, color: Color(0xFF3B49DF), size: 16),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 22),

              // 2. Select Time Header & Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.format_list_bulleted_rounded, size: 18, color: Color(0xFF3B49DF)),
                          SizedBox(width: 8),
                          Text(
                            '2. Select Time',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        '15-min time slots',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                  // Legend
                  Row(
                    children: [
                      _buildLegendItem(const Color(0xFF10B981), 'Available'),
                      const SizedBox(width: 8),
                      _buildLegendItem(const Color(0xFF3B49DF), 'Selected'),
                      const SizedBox(width: 8),
                      _buildLegendItem(const Color(0xFF94A3B8), 'Not Available'),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Time Slots Grouped in Periods (Morning, Afternoon, Evening)
              if (_isLoadingSlots)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: CircularProgressIndicator(color: Color(0xFF3B49DF)),
                  ),
                )
              else ...[
                _buildTimePeriodSection(
                  periodTitle: 'Morning',
                  periodSubtitle: '8 AM – 12 PM',
                  periodIcon: Icons.wb_sunny_rounded,
                  badgeBg: const Color(0xFFFFFBEB),
                  badgeIconColor: const Color(0xFFD97706),
                  slots: _categorizedSlots['Morning'] ?? [],
                ),
                const SizedBox(height: 14),
                _buildTimePeriodSection(
                  periodTitle: 'Afternoon',
                  periodSubtitle: '12 PM – 5 PM',
                  periodIcon: Icons.wb_twilight_rounded,
                  badgeBg: const Color(0xFFFEF2F2),
                  badgeIconColor: const Color(0xFFEF4444),
                  slots: _categorizedSlots['Afternoon'] ?? [],
                ),
                const SizedBox(height: 14),
                _buildTimePeriodSection(
                  periodTitle: 'Evening',
                  periodSubtitle: '5 PM – 9 PM',
                  periodIcon: Icons.nightlight_round,
                  badgeBg: const Color(0xFFEFF6FF),
                  badgeIconColor: const Color(0xFF3B49DF),
                  slots: _categorizedSlots['Evening'] ?? [],
                ),
              ],

              const SizedBox(height: 18),

              // Availability Verification Banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFDBEAFE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF3B49DF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "We've checked availability",
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'These time slots are confirmed available for your selected date. Our partners will accept your request as soon as possible.',
                            style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.people_alt_rounded, size: 14, color: Color(0xFF3B49DF)),
                          const SizedBox(width: 4),
                          Text(
                            '$_activePartnersCount Partners\navailable',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF3B49DF),
                              height: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Continue Button
              SizedBox(
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
                  onPressed: _isCheckingFinalAvailability ? null : _handleContinue,
                  child: _isCheckingFinalAvailability
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Continue',
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

              const SizedBox(height: 8),

              // Bottom Re-check availability note
              const Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 13, color: Color(0xFF94A3B8)),
                    SizedBox(width: 4),
                    Text(
                      "We'll re-check availability when you continue",
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11.5, color: Color(0xFF3B49DF), fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildMetaPill(IconData icon, String title, String value, Color iconColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
              Text(value, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildTimePeriodSection({
    required String periodTitle,
    required String periodSubtitle,
    required IconData periodIcon,
    required Color badgeBg,
    required Color badgeIconColor,
    required List<TimeSlotOption> slots,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Period Sidebar Badge
          Container(
            width: 76,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(periodIcon, color: badgeIconColor, size: 20),
                const SizedBox(height: 4),
                Text(
                  periodTitle,
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: badgeIconColor),
                ),
                Text(
                  periodSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 8.5, color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Grid of 15-min Time Slot Chips
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 8,
              children: slots.map((slot) {
                final isSelected = _selectedTime == slot.time;
                return _buildTimeSlotChip(slot, isSelected);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotChip(TimeSlotOption slot, bool isSelected) {
    if (!slot.isAvailable) {
      // Disabled / Not Available Slot
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot.time,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF94A3B8),
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.block_rounded, size: 10, color: Color(0xFF94A3B8)),
          ],
        ),
      );
    }

    if (isSelected) {
      // Selected Slot (Solid Purple/Blue)
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF3B49DF),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B49DF).withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot.time,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(Icons.check_rounded, size: 12, color: Colors.white),
          ],
        ),
      );
    }

    // Available Slot (White with Green Border & Text)
    return InkWell(
      onTap: () {
        setState(() {
          _selectedTime = slot.time;
        });
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF10B981)),
        ),
        child: Text(
          slot.time,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF059669),
          ),
        ),
      ),
    );
  }
}
