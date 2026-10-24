import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/customer_profile_service.dart';

class CustomerBookingDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const CustomerBookingDetailsScreen({super.key, required this.booking});

  @override
  State<CustomerBookingDetailsScreen> createState() => _CustomerBookingDetailsScreenState();
}

class _CustomerBookingDetailsScreenState extends State<CustomerBookingDetailsScreen> {
  late Map<String, dynamic> _b;
  bool _isLoading = false;

  bool get _isTest {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST') ||
          WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color completedGreen = Color(0xFF10B981);
  static const Color upcomingAmber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _b = Map<String, dynamic>.from(widget.booking);
  }

  Future<void> _cancelBooking() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking?'),
        content: const Text('Are you sure you want to cancel this booking? Cancellation charges may apply if partner is on the way.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Booking', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await CustomerProfileService.instance.cancelBooking(_b['id'] ?? _b['booking_code']);
      setState(() {
        _b['status'] = 'Cancelled';
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Booking has been cancelled'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    }
  }

  Future<void> _rescheduleBooking() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (pickedDate != null && mounted) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: const TimeOfDay(hour: 10, minute: 0),
      );

      if (pickedTime != null && mounted) {
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final newDate = '${pickedDate.day} ${months[pickedDate.month - 1]} ${pickedDate.year}';
        final newTime = pickedTime.format(context);

        setState(() => _isLoading = true);
        await CustomerProfileService.instance.rescheduleBooking(_b['id'] ?? _b['booking_code'], newDate, newTime);
        setState(() {
          _b['scheduled_date'] = newDate;
          _b['scheduled_time'] = newTime;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ Rescheduled to $newDate, $newTime'),
              backgroundColor: primaryBlue,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  IconData _getCategoryIcon(String? cat) {
    final c = (cat ?? '').toLowerCase();
    if (c.contains('car')) return Icons.directions_car_rounded;
    if (c.contains('ac')) return Icons.ac_unit_rounded;
    if (c.contains('plumb')) return Icons.plumbing_rounded;
    if (c.contains('laundry')) return Icons.local_laundry_service_rounded;
    if (c.contains('care')) return Icons.health_and_safety_rounded;
    if (c.contains('cook')) return Icons.restaurant_rounded;
    return Icons.home_repair_service_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final sUpper = (_b['status'] ?? '').toString().toUpperCase();
    final isCancelled = sUpper.contains('CANCEL');
    final isCompleted = sUpper == 'COMPLETED' || sUpper == 'SERVICE_COMPLETED' || sUpper == 'CLOSED';
    final isUpcoming = !isCancelled && !isCompleted;

    final badgeColor = isUpcoming ? upcomingAmber : (isCompleted ? completedGreen : const Color(0xFFEF4444));
    final badgeBg = isUpcoming ? const Color(0xFFFEF3C7) : (isCompleted ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2));

    final int currentStep = isCancelled ? 0 : (isCompleted ? 4 : (_b['step_index'] ?? 1));

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: darkSlate),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(color: darkSlate, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Order Code & Service Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          formatBookingCode(_b['booking_code'] ?? _b['id'], _b['category']),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkSlate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: badgeBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _b['status'] ?? 'Upcoming',
                          style: TextStyle(
                            color: badgeColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _b['service_name'] ?? 'Car Service & Repair',
                    style: const TextStyle(fontSize: 14, color: textMuted),
                  ),
                  const SizedBox(height: 18),

                  // 5-Step Tracker Bar
                  _buildStepProgressTracker(currentStep, isCancelled),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Partner Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Partner Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textMuted)),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final pName = (_b['partner_name'] ?? '').toString().trim();
                      final hasPartner = pName.isNotEmpty;

                      if (!hasPartner) {
                        return Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFFFEF3C7),
                              ),
                              child: const Center(
                                child: Icon(Icons.person_search_rounded, size: 24, color: Color(0xFFD97706)),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Assigning Partner...',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkSlate),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Finding nearby verified technician',
                                    style: TextStyle(fontSize: 12, color: textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFFEFF6FF),
                              image: _isTest
                                  ? null
                                  : const DecorationImage(
                                      image: AssetImage('assets/icons/app_logo.png'),
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            child: _isTest
                                ? const Center(
                                    child: Icon(Icons.person_rounded, size: 26, color: primaryBlue),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pName,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkSlate),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _b['partner_rating'] ?? '4.8 (125 reviews)',
                                        style: const TextStyle(fontSize: 12, color: textMuted),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Call Button
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFEFF6FF),
                              foregroundColor: primaryBlue,
                            ),
                            icon: const Icon(Icons.call_rounded, size: 20),
                            onPressed: () {
                              final pPhone = _b['partner_phone'] ?? '+91 98250 12345';
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Calling partner: $pPhone'),
                                  backgroundColor: primaryBlue,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          const SizedBox(width: 6),
                          // Chat Button
                          IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFEFF6FF),
                              foregroundColor: primaryBlue,
                            ),
                            icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                            onPressed: () => context.push('/chat'),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Service Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderGrey),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Service Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textMuted)),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getCategoryIcon(_b['category']), color: primaryBlue, size: 36),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _b['service_details'] ?? _b['service_name'] ?? 'Home Service',
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: darkSlate),
                            ),
                            if (_b['vehicle_info'] != null && _b['vehicle_info'].toString().trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                '• Vehicle: ${_b['vehicle_info']}',
                                style: const TextStyle(fontSize: 12, color: textMuted),
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              '• Date: ${_b['scheduled_date']}, ${_b['scheduled_time']}',
                              style: const TextStyle(fontSize: 12, color: textMuted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '• Address: ${_b['address'] ?? 'Customer Location'}',
                              style: const TextStyle(fontSize: 12, color: textMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '• Amount: ₹${(_b['price'] as num?)?.toInt() ?? 1499}',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: primaryBlue),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 4. Action Buttons (Reschedule / Cancel)
            if (!isCancelled && !isCompleted)
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primaryBlue, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _rescheduleBooking,
                        child: const Text('Reschedule', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isLoading ? null : _cancelBooking,
                        child: const Text('Cancel Booking', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStepProgressTracker(int currentStep, bool isCancelled) {
    final steps = ['Confirmed', 'Assigned', 'On Way', 'Progress', 'Done'];

    return Row(
      children: List.generate(steps.length * 2 - 1, (index) {
        if (index.isOdd) {
          // Connecting Line
          final stepBefore = index ~/ 2;
          final isLineActive = !isCancelled && currentStep > stepBefore;
          return Expanded(
            child: Container(
              height: 2,
              color: isLineActive ? primaryBlue : borderGrey,
            ),
          );
        } else {
          // Circle Dot & Label
          final stepIdx = index ~/ 2;
          final isPassed = !isCancelled && currentStep >= stepIdx;

          return SizedBox(
            width: 38,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPassed ? primaryBlue : Colors.white,
                    border: Border.all(color: isPassed ? primaryBlue : borderGrey, width: 2),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[stepIdx],
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: isPassed ? FontWeight.bold : FontWeight.normal,
                    color: isPassed ? primaryBlue : textMuted,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        }
      }),
    );
  }
}
