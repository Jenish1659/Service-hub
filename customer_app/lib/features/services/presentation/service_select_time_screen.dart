import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ac_availability_service.dart';
import '../services/multi_service_booking_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';
import 'service_address_details_screen.dart';

/// Universal Time Selection screen for all ServiceHub service categories.
/// Provides an interactive clock selector, preset time chips, and 20-minute same-day buffer check.
class ServiceSelectTimeScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> issueDetails;
  final BookingDateOption selectedDate;

  const ServiceSelectTimeScreen({
    super.key,
    required this.issueDetails,
    required this.selectedDate,
  });

  @override
  ConsumerState<ServiceSelectTimeScreen> createState() => _ServiceSelectTimeScreenState();
}

class _ServiceSelectTimeScreenState extends ConsumerState<ServiceSelectTimeScreen> {
  bool _isPm = true;
  int _selectedHour = 2; // 1..12
  int _selectedMinute = 0; // 0..55 (steps of 5)
  bool _isSelectingHours = true; // true = Hours clock, false = Minutes clock
  bool _isCheckingAvailability = false;
  bool _hasSelectedTime = false;

  @override
  void initState() {
    super.initState();
    _initTimeFromDate();
  }

  void _initTimeFromDate() {
    final now = DateTime.now();
    final isToday = widget.selectedDate.date.year == now.year &&
        widget.selectedDate.date.month == now.month &&
        widget.selectedDate.date.day == now.day;

    if (isToday) {
      final earliest = now.add(const Duration(minutes: 20));
      int minute = ((earliest.minute + 4) ~/ 5) * 5;
      int hour24 = earliest.hour;
      if (minute >= 60) {
        hour24 += 1;
        minute = 0;
      }
      _isPm = hour24 >= 12;
      _selectedHour = (hour24 % 12 == 0) ? 12 : (hour24 % 12);
      _selectedMinute = minute;
    } else {
      _isPm = true;
      _selectedHour = 2;
      _selectedMinute = 0;
    }
  }

  String get _formattedTime {
    if (!_hasSelectedTime) return 'No time selected';
    final hStr = _selectedHour.toString().padLeft(2, '0');
    final mStr = _selectedMinute.toString().padLeft(2, '0');
    final period = _isPm ? 'PM' : 'AM';
    return '$hStr:$mStr $period';
  }

  void _showMinBufferWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.info_outline_rounded, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'For same-day bookings, please select a time at least 20 minutes from now.',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _handleNext() async {
    if (!_hasSelectedTime) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a service time *'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final isToday = widget.selectedDate.date.year == now.year &&
        widget.selectedDate.date.month == now.month &&
        widget.selectedDate.date.day == now.day;

    if (isToday) {
      int hour24 = _isPm ? (_selectedHour == 12 ? 12 : _selectedHour + 12) : (_selectedHour == 12 ? 0 : _selectedHour);
      final chosenDateTime = DateTime(now.year, now.month, now.day, hour24, _selectedMinute);
      final minAllowed = now.add(const Duration(minutes: 20));

      if (chosenDateTime.isBefore(minAllowed)) {
        _showMinBufferWarning();
        return;
      }
    }

    setState(() => _isCheckingAvailability = true);

    final isSlotAvailable = await ACAvailabilityService.instance.verifySlotStillAvailable(
      date: widget.selectedDate.date,
      timeSlot: _formattedTime,
    );

    if (mounted) {
      setState(() => _isCheckingAvailability = false);
    }

    if (!isSlotAvailable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selected slot is in high demand. Proceeding with best-effort allocation.'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    final updatedDraft = Map<String, dynamic>.from(widget.issueDetails);
    updatedDraft['scheduled_time'] = _formattedTime;
    updatedDraft['status'] = 'DRAFT_TIME_SELECTED';
    updatedDraft['updated_at'] = DateTime.now().toIso8601String();

    final catId = (updatedDraft['category_id'] ?? 'ac_service').toString();
    await MultiServiceBookingService.instance.saveDraft(catId, updatedDraft);

    if (!mounted) return;

    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ServiceAddressDetailsScreen(
          issueDetails: updatedDraft,
          selectedDate: widget.selectedDate,
          selectedTime: _formattedTime,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hStr = _selectedHour.toString().padLeft(2, '0');
    final mStr = _selectedMinute.toString().padLeft(2, '0');
    final serviceName = widget.issueDetails['service_name'] ?? 'Service';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: () => ACDateTimeAIChatbotSheet.show(
                context,
                selectedTimeText: _formattedTime,
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Time * for $serviceName',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Date: ${widget.selectedDate.userFriendlyDisplay}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Digital Display & AM/PM Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => _isSelectingHours = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _isSelectingHours ? const Color(0xFFEEF2FF) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _isSelectingHours ? const Color(0xFF3B49DF) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    _hasSelectedTime ? hStr : '--',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: _isSelectingHours ? const Color(0xFF3B49DF) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                              const Text(' : ', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                              GestureDetector(
                                onTap: () => setState(() => _isSelectingHours = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: !_isSelectingHours ? const Color(0xFFEEF2FF) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: !_isSelectingHours ? const Color(0xFF3B49DF) : const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Text(
                                    _hasSelectedTime ? mStr : '--',
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: !_isSelectingHours ? const Color(0xFF3B49DF) : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // AM / PM Switcher
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _isPm = false;
                                    _hasSelectedTime = true;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: (_hasSelectedTime && !_isPm) ? const Color(0xFF3B49DF) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'AM',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: (_hasSelectedTime && !_isPm) ? Colors.white : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setState(() {
                                    _isPm = true;
                                    _hasSelectedTime = true;
                                  }),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: (_hasSelectedTime && _isPm) ? const Color(0xFF3B49DF) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'PM',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: (_hasSelectedTime && _isPm) ? Colors.white : const Color(0xFF64748B),
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

                    const SizedBox(height: 20),

                    // Interactive Analog Clock
                    Center(
                      child: Container(
                        width: 240,
                        height: 240,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Center dot
                            Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF3B49DF),
                              ),
                            ),
                            // Clock Numbers
                            ..._buildClockNumbers(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Quick Presets
                    const Text(
                      'Popular Time Slots',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip('10:00 AM', 10, 0, false),
                        _buildPresetChip('11:30 AM', 11, 30, false),
                        _buildPresetChip('02:00 PM', 2, 0, true),
                        _buildPresetChip('04:30 PM', 4, 30, true),
                        _buildPresetChip('06:00 PM', 6, 0, true),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom CTA
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
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isCheckingAvailability ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B49DF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isCheckingAvailability
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          _hasSelectedTime ? 'Continue with $_formattedTime' : 'Select Service Time *',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, int hour, int minute, bool isPm) {
    final isSelected = _hasSelectedTime && _selectedHour == hour && _selectedMinute == minute && _isPm == isPm;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedHour = hour;
          _selectedMinute = minute;
          _isPm = isPm;
          _hasSelectedTime = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B49DF) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFFCBD5E1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildClockNumbers() {
    final List<Widget> list = [];
    const radius = 95.0;

    if (_isSelectingHours) {
      for (int i = 1; i <= 12; i++) {
        final angle = (i * 30 - 90) * (math.pi / 180);
        final x = radius * math.cos(angle);
        final y = radius * math.sin(angle);
        final isSelected = _hasSelectedTime && _selectedHour == i;

        list.add(
          Transform.translate(
            offset: Offset(x, y),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedHour = i;
                  _hasSelectedTime = true;
                  _isSelectingHours = false; // automatically switch to minutes
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF3B49DF) : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    '$i',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    } else {
      // Minutes clock
      for (int i = 0; i < 60; i += 5) {
        final angle = (i * 6 - 90) * (math.pi / 180);
        final x = radius * math.cos(angle);
        final y = radius * math.sin(angle);
        final isSelected = _hasSelectedTime && _selectedMinute == i;

        list.add(
          Transform.translate(
            offset: Offset(x, y),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMinute = i;
                  _hasSelectedTime = true;
                });
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? const Color(0xFF3B49DF) : Colors.transparent,
                ),
                child: Center(
                  child: Text(
                    i.toString().padLeft(2, '0'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return list;
  }
}
