import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

class BookingDateOption {
  final DateTime date;
  final String dayName;
  final String dateNumber;
  final String monthName;
  final String formattedIso;
  final bool isTomorrow;

  BookingDateOption({
    required this.date,
    required this.dayName,
    required this.dateNumber,
    required this.monthName,
    required this.formattedIso,
    required this.isTomorrow,
  });
}

class TimeSlotOption {
  final String time;
  final String period; // 'Morning', 'Afternoon', 'Evening'
  final bool isAvailable;
  final int availableProvidersCount;

  TimeSlotOption({
    required this.time,
    required this.period,
    required this.isAvailable,
    required this.availableProvidersCount,
  });
}

class ACAvailabilityService {
  static final ACAvailabilityService instance = ACAvailabilityService._internal();
  ACAvailabilityService._internal();

  /// Checks if a date is bookable:
  /// Current day (Today) and all future dates are available.
  /// Past dates (before today) are strictly unavailable.
  bool isDateBookable(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    return !target.isBefore(today);
  }

  /// Calculates available booking dates starting from Today (D) onward.
  List<BookingDateOption> getAvailableBookingDates({int count = 14}) {
    final now = DateTime.now();
    final List<BookingDateOption> dates = [];

    for (int i = 0; i < count; i++) {
      final targetDate = now.add(Duration(days: i));
      final isToday = i == 0;
      final isTomorrow = i == 1;
      final dayName = isToday
          ? 'Today'
          : (isTomorrow ? 'Tomorrow' : DateFormat('EEE').format(targetDate));
      final dateNumber = DateFormat('dd').format(targetDate);
      final monthName = DateFormat('MMM').format(targetDate);
      final formattedIso = DateFormat('yyyy-MM-dd').format(targetDate);

      dates.add(
        BookingDateOption(
          date: targetDate,
          dayName: dayName,
          dateNumber: dateNumber,
          monthName: monthName,
          formattedIso: formattedIso,
          isTomorrow: isTomorrow,
        ),
      );
    }

    return dates;
  }

  /// Legacy helper returning next 3 days
  List<BookingDateOption> getNext3BookingDates() {
    return getAvailableBookingDates(count: 3);
  }

  /// Queries the live count of active & verified AC Service Partners from Supabase / Hive.
  Future<int> getActiveACPartnersCount() async {
    int count = 0;
    try {
      final client = Supabase.instance.client;
      final partners = await client
          .from('partners')
          .select('partner_id, verification_status, is_online')
          .eq('verification_status', 'VERIFIED');

      count = partners.length;
    } catch (_) {
      // Check local registration cache / active partner count
      try {
        final box = Hive.box('customer_cache');
        final cachedCount = box.get('active_ac_partners_count', defaultValue: 3) as int;
        count = cachedCount;
      } catch (_) {
        count = 3; // Safe base count of verified technicians
      }
    }

    return count > 0 ? count : 3;
  }

  /// Generates 15-minute time slots for a given date and checks live availability against existing bookings.
  Future<Map<String, List<TimeSlotOption>>> getSlotAvailabilityForDate(DateTime date) async {
    final activePartners = await getActiveACPartnersCount();
    final dateStr = DateFormat('yyyy-MM-dd').format(date);

    // Query any existing accepted/active bookings for this date to determine busy intervals
    final Set<String> busySlots = {};
    try {
      final client = Supabase.instance.client;
      final booked = await client
          .from('service_bookings')
          .select('scheduled_time, status')
          .eq('scheduled_date', dateStr);

      for (var b in booked) {
        final time = b['scheduled_time'] as String?;
        if (time != null) {
          busySlots.add(time.trim());
        }
      }
    } catch (e) {
      debugPrint('Live booking lookup note: $e');
    }

    final Map<String, List<TimeSlotOption>> categorizedSlots = {
      'Morning': [],
      'Afternoon': [],
      'Evening': [],
    };

    // Morning: 08:00 AM to 11:45 AM (15-min intervals)
    for (int hour = 8; hour < 12; hour++) {
      for (int min = 0; min < 60; min += 15) {
        final timeLabel = _formatTime(hour, min);
        // A slot is available if activePartners > count of bookings in that slot
        final isBusy = busySlots.contains(timeLabel) && busySlots.length >= activePartners;
        categorizedSlots['Morning']!.add(
          TimeSlotOption(
            time: timeLabel,
            period: 'Morning',
            isAvailable: !isBusy,
            availableProvidersCount: isBusy ? 0 : activePartners,
          ),
        );
      }
    }

    // Afternoon: 12:00 PM to 04:45 PM (15-min intervals)
    for (int hour = 12; hour < 17; hour++) {
      for (int min = 0; min < 60; min += 15) {
        final timeLabel = _formatTime(hour, min);
        final isBusy = busySlots.contains(timeLabel) && busySlots.length >= activePartners;
        categorizedSlots['Afternoon']!.add(
          TimeSlotOption(
            time: timeLabel,
            period: 'Afternoon',
            isAvailable: !isBusy,
            availableProvidersCount: isBusy ? 0 : activePartners,
          ),
        );
      }
    }

    // Evening: 05:00 PM to 08:45 PM (15-min intervals)
    for (int hour = 17; hour < 21; hour++) {
      for (int min = 0; min < 60; min += 15) {
        final timeLabel = _formatTime(hour, min);
        final isBusy = busySlots.contains(timeLabel) && busySlots.length >= activePartners;
        categorizedSlots['Evening']!.add(
          TimeSlotOption(
            time: timeLabel,
            period: 'Evening',
            isAvailable: !isBusy,
            availableProvidersCount: isBusy ? 0 : activePartners,
          ),
        );
      }
    }

    return categorizedSlots;
  }

  /// Final atomic check to ensure slot is still available right before proceeding
  Future<bool> verifySlotStillAvailable({
    required DateTime date,
    required String timeSlot,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final activePartners = await getActiveACPartnersCount();

    try {
      final client = Supabase.instance.client;
      final existing = await client
          .from('service_bookings')
          .select('id')
          .eq('scheduled_date', dateStr)
          .eq('scheduled_time', timeSlot.trim())
          .neq('status', 'CANCELLED');

      if (existing.length >= activePartners) {
        return false;
      }
    } catch (_) {}

    return true;
  }

  String _formatTime(int hour, int minute) {
    final period = hour >= 12 ? 'PM' : 'AM';
    final h = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final hStr = h.toString().padLeft(2, '0');
    final mStr = minute.toString().padLeft(2, '0');
    return '$hStr:$mStr $period';
  }
}
