import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ac_availability_service.dart';
import '../services/ac_booking_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';
import 'ac_service_details_screen.dart';

class ACSelectTimeScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> issueDetails;
  final BookingDateOption selectedDate;

  const ACSelectTimeScreen({
    super.key,
    required this.issueDetails,
    required this.selectedDate,
  });

  @override
  ConsumerState<ACSelectTimeScreen> createState() => _ACSelectTimeScreenState();
}

class _ACSelectTimeScreenState extends ConsumerState<ACSelectTimeScreen> {
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
      // Auto-fetch current time + 20 minutes buffer, rounded up to next 5 minutes
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

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAllPartnersBusyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.event_busy_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Time Slot Unavailable',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: const Text(
          "We're sorry! All our service partners are currently occupied at this time. Could you please select another time slot at least 1 hour later? Thank you for your understanding!",
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.45),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B49DF),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                // Auto adjust +1 hour and open Hour selection
                int h = _selectedHour + 1;
                if (h > 12) {
                  h = 1;
                  _isPm = !_isPm;
                }
                _selectedHour = h;
                _isSelectingHours = true;
              });
            },
            child: const Text(
              'Choose Another Time',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    if (!_hasSelectedTime) {
      _showWarningSnackBar('Please select a service time *');
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

    // Live Database check against partner availability
    final isSlotAvailable = await ACAvailabilityService.instance.verifySlotStillAvailable(
      date: widget.selectedDate.date,
      timeSlot: _formattedTime,
    );

    if (mounted) {
      setState(() => _isCheckingAvailability = false);
    }

    if (!isSlotAvailable) {
      if (mounted) {
        _showAllPartnersBusyDialog();
      }
      return;
    }

    final updatedDraft = Map<String, dynamic>.from(widget.issueDetails);
    updatedDraft['scheduled_time'] = _formattedTime;
    updatedDraft['status'] = 'DRAFT_TIME_SELECTED';
    updatedDraft['updated_at'] = DateTime.now().toIso8601String();

    await ACIssueBookingService.instance.saveDraft(updatedDraft);

    if (!mounted) return;

    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ACServiceDetailsScreen(
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
    final period = _isPm ? 'PM' : 'AM';

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
                selectedDateText:
                    '${widget.selectedDate.dayName}, ${widget.selectedDate.dateNumber} ${widget.selectedDate.monthName}',
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
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Header Title & Subtitle
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Time *',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Choose your preferred time',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Interactive Digital Time Badge & AM/PM Toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Hours & Minutes Interactive Digits
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Hours Box
                              InkWell(
                                onTap: () {
                                  setState(() => _isSelectingHours = true);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _isSelectingHours
                                        ? const Color(0xFF3B49DF)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _hasSelectedTime ? hStr : '--',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: _isSelectingHours ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Text(
                                  ':',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF3B49DF),
                                  ),
                                ),
                              ),
                              // Minutes Box
                              InkWell(
                                onTap: () {
                                  setState(() => _isSelectingHours = false);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: !_isSelectingHours
                                        ? const Color(0xFF3B49DF)
                                        : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _hasSelectedTime ? mStr : '--',
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: !_isSelectingHours ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // AM / PM Segmented Pill Toggle
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildAmPmButton('AM', (_hasSelectedTime && !_isPm), () {
                                  setState(() {
                                    _isPm = false;
                                    _hasSelectedTime = true;
                                  });
                                }),
                                _buildAmPmButton('PM', (_hasSelectedTime && _isPm), () {
                                  setState(() {
                                    _isPm = true;
                                    _hasSelectedTime = true;
                                  });
                                }),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Clock Mode Indicator Tab (Hours / Minutes Switcher)
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeTab('1. Select Hour', _isSelectingHours, () {
                            setState(() => _isSelectingHours = true);
                          }),
                          _buildModeTab('2. Select Minute', !_isSelectingHours, () {
                            setState(() => _isSelectingHours = false);
                          }),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Two-Step Interactive Analog Clock Dial
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Clock Hand
                          CustomPaint(
                            size: const Size(250, 250),
                            painter: DynamicClockHandPainter(
                              isSelectingHours: _isSelectingHours,
                              selectedHour: _selectedHour,
                              selectedMinute: _selectedMinute,
                            ),
                          ),

                          // Dial Numbers (Hours 1..12 OR Minutes 00..55)
                          if (_isSelectingHours)
                            ...List.generate(12, (index) {
                              final hour = index + 1;
                              final angle = (hour * 30 - 90) * (math.pi / 180);
                              const radius = 95.0;
                              final x = radius * math.cos(angle);
                              final y = radius * math.sin(angle);

                              final isSelected = _hasSelectedTime && _selectedHour == hour;

                              return Transform.translate(
                                offset: Offset(x, y),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedHour = hour;
                                      _hasSelectedTime = true;
                                      // After selecting hour, automatically show the minutes clock!
                                      _isSelectingHours = false;
                                    });
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF3B49DF) : Colors.transparent,
                                      shape: BoxShape.circle,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF3B49DF).withValues(alpha: 0.4),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      '$hour',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            })
                          else
                            ...List.generate(12, (index) {
                              final minute = index * 5; // 0, 5, 10, ... 55
                              final angle = (minute * 6 - 90) * (math.pi / 180);
                              const radius = 95.0;
                              final x = radius * math.cos(angle);
                              final y = radius * math.sin(angle);

                              final isSelected = _hasSelectedTime && _selectedMinute == minute;
                              final minStr = minute.toString().padLeft(2, '0');

                              return Transform.translate(
                                offset: Offset(x, y),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedMinute = minute;
                                      _hasSelectedTime = true;
                                    });
                                  },
                                  child: Container(
                                    width: 32,
                                    height: 32,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF3B49DF) : Colors.transparent,
                                      shape: BoxShape.circle,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF3B49DF).withValues(alpha: 0.4),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Text(
                                      minStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                        color: isSelected ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),

                          // Center Pivot
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B49DF),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Selected Time Display Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFEFF6FF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.access_time_rounded, color: Color(0xFF3B49DF), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected Time *',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _hasSelectedTime ? '$hStr:$mStr $period' : 'Please select a time *',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _hasSelectedTime ? const Color(0xFF0F172A) : const Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            _isSelectingHours ? 'Setting Hour' : 'Setting Minutes',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF3B49DF),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Next Button Bar
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
                  onPressed: _isCheckingAvailability ? null : _handleNext,
                  child: _isCheckingAvailability
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Next',
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

  Widget _buildAmPmButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF3B49DF) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildModeTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

class DynamicClockHandPainter extends CustomPainter {
  final bool isSelectingHours;
  final int selectedHour;
  final int selectedMinute;

  DynamicClockHandPainter({
    required this.isSelectingHours,
    required this.selectedHour,
    required this.selectedMinute,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle = isSelectingHours
        ? (selectedHour * 30 - 90) * (math.pi / 180)
        : (selectedMinute * 6 - 90) * (math.pi / 180);
    final handLength = isSelectingHours ? 80.0 : 95.0;

    final handEnd = Offset(
      center.dx + handLength * math.cos(angle),
      center.dy + handLength * math.sin(angle),
    );

    final handPaint = Paint()
      ..color = const Color(0xFF3B49DF)
      ..strokeWidth = isSelectingHours ? 3.0 : 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(center, handEnd, handPaint);
  }

  @override
  bool shouldRepaint(covariant DynamicClockHandPainter oldDelegate) {
    return oldDelegate.isSelectingHours != isSelectingHours ||
        oldDelegate.selectedHour != selectedHour ||
        oldDelegate.selectedMinute != selectedMinute;
  }
}
