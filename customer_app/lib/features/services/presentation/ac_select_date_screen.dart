import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/ac_availability_service.dart';
import '../services/ac_booking_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';
import 'ac_select_time_screen.dart';

class ACSelectDateScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? issueDetails;

  const ACSelectDateScreen({
    super.key,
    this.issueDetails,
  });

  @override
  ConsumerState<ACSelectDateScreen> createState() => _ACSelectDateScreenState();
}

class _ACSelectDateScreenState extends ConsumerState<ACSelectDateScreen> {
  late Map<String, dynamic> _activeIssueDetails;
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);

    // Current day (Today) is available and default selected
    _selectedDate = DateTime(now.year, now.month, now.day);

    _initData();
  }

  Future<void> _initData() async {
    if (widget.issueDetails != null && widget.issueDetails!.isNotEmpty) {
      _activeIssueDetails = Map<String, dynamic>.from(widget.issueDetails!);
    } else {
      final draft = ACIssueBookingService.instance.loadDraft();
      _activeIssueDetails = draft ?? {};
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _previousMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _displayedMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 1);
    });
  }

  bool _isAllowedDate(DateTime date) {
    return ACAvailabilityService.instance.isDateBookable(date);
  }

  bool _isSelectedDate(DateTime date) {
    return _selectedDate.year == date.year &&
        _selectedDate.month == date.month &&
        _selectedDate.day == date.day;
  }

  void _handleNext() async {
    final dayName = DateFormat('EEE').format(_selectedDate);
    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final userFormattedDate = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);

    final updatedDraft = Map<String, dynamic>.from(_activeIssueDetails);
    updatedDraft['booking_date'] = formattedDate;
    updatedDraft['booking_date_formatted'] = userFormattedDate;
    updatedDraft['status'] = 'DRAFT_DATE_SELECTED';
    updatedDraft['updated_at'] = DateTime.now().toIso8601String();

    await ACIssueBookingService.instance.saveDraft(updatedDraft);

    final dateOption = BookingDateOption(
      date: _selectedDate,
      dayName: dayName,
      dateNumber: DateFormat('dd').format(_selectedDate),
      monthName: DateFormat('MMM').format(_selectedDate),
      formattedIso: formattedDate,
      isTomorrow: _selectedDate.day == DateTime.now().add(const Duration(days: 1)).day,
    );

    if (!mounted) return;

    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ACSelectTimeScreen(
          issueDetails: updatedDraft,
          selectedDate: dateOption,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedFormatted = DateFormat('EEE, dd MMM yyyy').format(_selectedDate);

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
                selectedDateText: selectedFormatted,
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
                    // Header Title & Subtitle (Matching Screen 2 Reference)
                    const Text(
                      'Select Date',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose a convenient date',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Calendar Month Container (Matching Reference Card)
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
                          // Month Selector Header (< May 2025 >)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left_rounded, color: Color(0xFF3B49DF)),
                                onPressed: _previousMonth,
                              ),
                              Text(
                                DateFormat('MMMM yyyy').format(_displayedMonth),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.chevron_right_rounded, color: Color(0xFF3B49DF)),
                                onPressed: _nextMonth,
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Days of Week Header (S M T W T F S)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                                .map(
                                  (d) => SizedBox(
                                    width: 36,
                                    child: Text(
                                      d,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),

                          const SizedBox(height: 12),

                          // Calendar Grid
                          _buildMonthGrid(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Selected Date Display Card (Matching Reference Screen 2)
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
                            child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF3B49DF), size: 18),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Selected Date',
                                style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                selectedFormatted,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
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
                  onPressed: _handleNext,
                  child: const Row(
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

  Widget _buildMonthGrid() {
    final firstDayOfMonth = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
    final daysInMonth = DateTime(_displayedMonth.year, _displayedMonth.month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // Sunday = 0

    final List<Widget> dayWidgets = [];

    // Empty spaces before first day of month
    for (int i = 0; i < startWeekday; i++) {
      dayWidgets.add(const SizedBox(width: 36, height: 36));
    }

    // Days 1..daysInMonth
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
      final isAllowed = _isAllowedDate(date);
      final isSelected = _isSelectedDate(date);

      dayWidgets.add(
        InkWell(
          onTap: isAllowed
              ? () {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF3B49DF) : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFF3B49DF).withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : (isAllowed ? FontWeight.w600 : FontWeight.normal),
                color: isSelected
                    ? Colors.white
                    : (isAllowed ? const Color(0xFF0F172A) : const Color(0xFFCBD5E1)),
              ),
            ),
          ),
        ),
      );
    }

    return Wrap(
      alignment: WrapAlignment.start,
      spacing: (MediaQuery.of(context).size.width - 40 - 36 - 7 * 36) / 7 > 0
          ? (MediaQuery.of(context).size.width - 76 - 7 * 36) / 6
          : 8,
      runSpacing: 10,
      children: dayWidgets,
    );
  }
}
