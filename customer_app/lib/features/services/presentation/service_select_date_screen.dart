import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../services/ac_availability_service.dart';
import '../services/multi_service_booking_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';
import 'service_select_time_screen.dart';

/// Universal Date Selection screen for all ServiceHub service categories.
/// Ensures 100% visual and functional consistency with the AC reference flow.
class ServiceSelectDateScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> issueDetails;

  const ServiceSelectDateScreen({
    super.key,
    required this.issueDetails,
  });

  @override
  ConsumerState<ServiceSelectDateScreen> createState() => _ServiceSelectDateScreenState();
}

class _ServiceSelectDateScreenState extends ConsumerState<ServiceSelectDateScreen> {
  late Map<String, dynamic> _activeIssueDetails;
  late DateTime _displayedMonth;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _displayedMonth = DateTime(now.year, now.month, 1);
    _selectedDate = DateTime(now.year, now.month, now.day);
    _activeIssueDetails = Map<String, dynamic>.from(widget.issueDetails);
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

    final catId = (updatedDraft['category_id'] ?? 'ac_service').toString();
    await MultiServiceBookingService.instance.saveDraft(catId, updatedDraft);

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
        builder: (context) => ServiceSelectTimeScreen(
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
    final serviceName = _activeIssueDetails['service_name'] ?? 'Service';

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
                    Text(
                      'Select Date for $serviceName',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose a convenient date for your service',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Calendar Month Container
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
                                  fontWeight: FontWeight.w700,
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
                          // Days of Week Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: const ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su']
                                .map((day) => Expanded(
                                      child: Center(
                                        child: Text(
                                          day,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF94A3B8),
                                          ),
                                        ),
                                      ),
                                    ))
                                .toList(),
                          ),
                          const Divider(height: 24, thickness: 1, color: Color(0xFFF1F5F9)),
                          // Calendar Day Grid
                          _buildCalendarGrid(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Selection preview card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event_available_rounded, color: Color(0xFF3B49DF), size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Selected Appointment Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  selectedFormatted,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E1B4B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Continue CTA
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
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B49DF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continue to Select Time',
                    style: TextStyle(
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

  Widget _buildCalendarGrid() {
    final year = _displayedMonth.year;
    final month = _displayedMonth.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final firstDayWeekday = DateTime(year, month, 1).weekday; // 1 = Monday, 7 = Sunday

    final List<Widget> dayWidgets = [];

    // Empty spaces for padding before day 1
    for (int i = 1; i < firstDayWeekday; i++) {
      dayWidgets.add(const SizedBox());
    }

    // Month days
    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final isAllowed = _isAllowedDate(date);
      final isSelected = _isSelectedDate(date);

      dayWidgets.add(
        GestureDetector(
          onTap: isAllowed
              ? () {
                  setState(() {
                    _selectedDate = date;
                  });
                }
              : null,
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? const Color(0xFF3B49DF)
                  : isAllowed
                      ? Colors.transparent
                      : const Color(0xFFF1F5F9),
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : isAllowed
                          ? const Color(0xFF0F172A)
                          : const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 7,
      children: dayWidgets,
    );
  }
}
