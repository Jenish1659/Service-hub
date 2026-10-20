import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../data/customer_profile_service.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import 'customer_booking_details_screen.dart';

class CustomerMyBookingsScreen extends StatefulWidget {
  const CustomerMyBookingsScreen({super.key});

  @override
  State<CustomerMyBookingsScreen> createState() => _CustomerMyBookingsScreenState();
}

class _CustomerMyBookingsScreenState extends State<CustomerMyBookingsScreen> {
  int _selectedFilter = 0; // 0: All, 1: Upcoming, 2: Completed
  late List<Map<String, dynamic>> _bookings;

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color completedGreen = Color(0xFF10B981);
  static const Color upcomingAmber = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _loadBookings();
    try {
      if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
        LiveBookingSyncService.instance.syncWithSupabaseNow().then((_) {
          if (mounted) _loadBookings();
        });
      }
    } catch (_) {}
  }

  void _loadBookings() {
    setState(() {
      _bookings = CustomerProfileService.instance.getBookings();
    });
  }

  List<Map<String, dynamic>> get _filteredBookings {
    if (_selectedFilter == 1) {
      return _bookings.where((b) {
        final s = (b['status'] ?? '').toString().toUpperCase();
        return s == 'UPCOMING' || s == 'ASSIGNED' || s == 'CONFIRMED' || s == 'ON THE WAY' || s == 'ON_THE_WAY' || s == 'IN PROGRESS' || s == 'IN_PROGRESS' || s.contains('SEARCH');
      }).toList();
    }
    if (_selectedFilter == 2) {
      return _bookings.where((b) {
        final s = (b['status'] ?? '').toString().toUpperCase();
        return s == 'COMPLETED' || s == 'SERVICE_COMPLETED' || s == 'CLOSED';
      }).toList();
    }
    return _bookings;
  }

  int get _upcomingCount => _bookings.where((b) {
        final s = (b['status'] ?? '').toString().toUpperCase();
        return s == 'UPCOMING' || s == 'ASSIGNED' || s == 'CONFIRMED' || s == 'ON THE WAY' || s == 'ON_THE_WAY' || s == 'IN PROGRESS' || s == 'IN_PROGRESS' || s.contains('SEARCH');
      }).length;

  int get _completedCount => _bookings.where((b) {
        final s = (b['status'] ?? '').toString().toUpperCase();
        return s == 'COMPLETED' || s == 'SERVICE_COMPLETED' || s == 'CLOSED';
      }).length;

  @override
  Widget build(BuildContext context) {
    final list = _filteredBookings;

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
          'My Bookings',
          style: TextStyle(color: darkSlate, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Chips Row
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  _buildFilterChip(0, 'All (${_bookings.length})'),
                  const SizedBox(width: 8),
                  _buildFilterChip(1, 'Upcoming ($_upcomingCount)'),
                  const SizedBox(width: 8),
                  _buildFilterChip(2, 'Completed ($_completedCount)'),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: borderGrey),

          // Bookings List
          Expanded(
            child: list.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.calendar_today_rounded, color: primaryBlue, size: 30),
                        ),
                        const SizedBox(height: 16),
                        const Text('No Bookings Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkSlate)),
                        const SizedBox(height: 4),
                        const Text('You do not have any bookings in this section', style: TextStyle(color: textMuted, fontSize: 13)),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final b = list[index];
                      final statusUpper = (b['status'] ?? '').toString().toUpperCase();
                      final isCompleted = statusUpper == 'COMPLETED' || statusUpper == 'SERVICE_COMPLETED' || statusUpper == 'CLOSED';
                      final isCancelled = statusUpper.contains('CANCEL');

                      final badgeColor = isCompleted ? completedGreen : (isCancelled ? const Color(0xFFEF4444) : upcomingAmber);
                      final badgeBg = isCompleted ? const Color(0xFFECFDF5) : (isCancelled ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7));

                      // Thumbnail
                      final cat = (b['category'] ?? '').toString().toLowerCase();
                      IconData catIcon = Icons.home_repair_service_rounded;
                      Color catColor = primaryBlue;

                      if (cat.contains('car')) {
                        catIcon = Icons.directions_car_rounded;
                        catColor = const Color(0xFFD97706);
                      } else if (cat.contains('ac')) {
                        catIcon = Icons.ac_unit_rounded;
                        catColor = primaryBlue;
                      } else if (cat.contains('plumb')) {
                        catIcon = Icons.plumbing_rounded;
                        catColor = const Color(0xFF9333EA);
                      } else if (cat.contains('laundry')) {
                        catIcon = Icons.local_laundry_service_rounded;
                        catColor = const Color(0xFF0D9488);
                      } else if (cat.contains('care')) {
                        catIcon = Icons.volunteer_activism_rounded;
                        catColor = const Color(0xFFEA580C);
                      }

                      return GestureDetector(
                        onTap: () async {
                          final updated = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CustomerBookingDetailsScreen(booking: b),
                            ),
                          );
                          if (updated == true) _loadBookings();
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderGrey),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Order code & Status row
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      formatBookingCode(b['booking_code'] ?? b['id'], b['category']),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: darkSlate,
                                      ),
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
                                      b['status'] ?? 'Upcoming',
                                      style: TextStyle(
                                        color: badgeColor,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),

                              // Thumbnail & Info Row
                              Row(
                                children: [
                                  Container(
                                    width: 52,
                                    height: 52,
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(catIcon, color: catColor, size: 28),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          b['service_name'] ?? 'Car Service & Repair',
                                          style: const TextStyle(
                                            fontSize: 14.5,
                                            fontWeight: FontWeight.bold,
                                            color: darkSlate,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '${b['scheduled_date']} • ${b['scheduled_time']}',
                                          style: const TextStyle(fontSize: 12, color: textMuted),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          b['address'] ?? 'Green Park, Jamnagar',
                                          style: const TextStyle(fontSize: 12, color: textMuted),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '₹${(b['price'] as num?)?.toInt() ?? 499}',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: darkSlate,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryBlue : borderGrey,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : darkSlate,
          ),
        ),
      ),
    );
  }
}
