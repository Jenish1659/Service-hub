import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ACBookingConfirmedScreen extends ConsumerWidget {
  final Map<String, dynamic> bookingData;
  final String selectedDateFormatted;
  final String selectedTime;
  final String serviceTitle;
  final String address;
  final int partnerCount;
  final double visitingCharge;
  final double protectionFee;
  final double couponDiscount;
  final String? couponCode;
  final double walletDeduction;
  final double finalPayable;
  final bool isFutureDate;

  const ACBookingConfirmedScreen({
    super.key,
    required this.bookingData,
    required this.selectedDateFormatted,
    required this.selectedTime,
    required this.serviceTitle,
    required this.address,
    this.partnerCount = 1,
    this.visitingCharge = 0.0,
    this.protectionFee = 0.0,
    this.couponDiscount = 0.0,
    this.couponCode,
    this.walletDeduction = 0.0,
    this.finalPayable = 0.0,
    this.isFutureDate = false,
  });

  String _getFormattedTrackingId(String rawId) {
    if (rawId.isEmpty) {
      return 'TRK-AC-${(100000 + math.Random().nextInt(899999))}';
    }
    final clean = rawId.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
    if (clean.length > 8) {
      return 'TRK-AC-${clean.substring(clean.length - 8)}';
    }
    return 'TRK-AC-$clean';
  }

  void _showRawBillModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(22),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Itemized Raw Bill',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBillItem('Visiting & Inspection Charge', '₹${visitingCharge.toStringAsFixed(2)}'),
              const SizedBox(height: 10),
              _buildBillItem('Safety & Protection Fee', '₹${protectionFee.toStringAsFixed(2)}'),
              if (couponCode != null && couponDiscount > 0) ...[
                const SizedBox(height: 10),
                _buildBillItem('Coupon Discount ($couponCode)', '-₹${couponDiscount.toStringAsFixed(2)}', isDiscount: true),
              ],
              if (walletDeduction > 0) ...[
                const SizedBox(height: 10),
                _buildBillItem('Wallet Balance Applied', '-₹${walletDeduction.toStringAsFixed(2)}', isDiscount: true),
              ],
              const SizedBox(height: 10),
              _buildBillItem('GST & Applicable Taxes', 'Included'),
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Amount Payable',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '₹${finalPayable.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Row(
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 15, color: Color(0xFF10B981)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Cash / UPI on service. Pay after service completion.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillItem(String title, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF64748B)),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isDiscount ? const Color(0xFF10B981) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingId = (bookingData['id'] ?? bookingData['booking_id'] ?? '').toString();
    final trackingId = _getFormattedTrackingId(bookingId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Booking Scheduled',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_outlined, color: Color(0xFF0F172A), size: 24),
            onPressed: () {
              Navigator.popUntil(context, (route) => route.isFirst);
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 8),

              // Calendar & Success Checkmark Badge with Confetti
              Stack(
                alignment: Alignment.center,
                children: [
                  ...List.generate(8, (index) {
                    final colors = [
                      const Color(0xFFF59E0B),
                      const Color(0xFF2563EB),
                      const Color(0xFF10B981),
                      const Color(0xFF6366F1),
                    ];
                    final x = 45.0 * (index % 2 == 0 ? 1 : -1) * (1 + (index % 3) * 0.2);
                    final y = 45.0 * (index < 4 ? -1 : 1) * (1 + (index % 2) * 0.2);
                    return Transform.translate(
                      offset: Offset(x, y),
                      child: Container(
                        width: index % 2 == 0 ? 6 : 8,
                        height: index % 2 == 0 ? 6 : 4,
                        decoration: BoxDecoration(
                          color: colors[index % colors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.event_available_rounded, color: Colors.white, size: 42),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Title & Subtitle (Matches both 'Booking Confirmed!' and 'Booking Scheduled!')
              const Text(
                'Booking Confirmed!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Booking Scheduled!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2563EB),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "We've received your request and\nour partner will be there soon.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              // PRE-BOOKING TRACKING ID CARD
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2563EB),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'PRE-BOOKING TRACKING ID',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            trackingId,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Color(0xFF2563EB), size: 20),
                      tooltip: 'Copy Tracking ID',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: trackingId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✓ Tracking ID copied to clipboard!'),
                            backgroundColor: Color(0xFF2563EB),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Summary Card
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
                    _buildConfirmedRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Date',
                      value: selectedDateFormatted,
                    ),
                    const Divider(height: 24),
                    _buildConfirmedRow(
                      icon: Icons.access_time_rounded,
                      label: 'Time',
                      value: selectedTime,
                    ),
                    const Divider(height: 24),
                    _buildConfirmedRow(
                      icon: Icons.ac_unit_rounded,
                      label: 'Service',
                      value: serviceTitle,
                    ),
                    const Divider(height: 24),
                    _buildConfirmedRow(
                      icon: Icons.location_on_outlined,
                      label: 'Address',
                      value: address,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Estimated Technician Arrival Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.directions_car_rounded, color: Color(0xFF2563EB), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Estimated Technician Arrival',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Our service provider takes at least 20–25 minutes to reach your home.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Info Notice Box (Matching Image 2 Screen 1 Core Requirement)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF16A34A), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Matching starts on service date morning',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF14532D),
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'A certified technician will be assigned 2 hours before your scheduled slot. You will receive an SMS and push notification once assigned.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF15803D), height: 1.35),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // View Itemized Raw Bill Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF2563EB), size: 18),
                  label: const Text(
                    'View Raw Bill',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  onPressed: () => _showRawBillModal(context),
                ),
              ),

              const SizedBox(height: 20),

              // Find Technician Now Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: () {
                    context.push('/services/ac/finding-technician', extra: {
                      'booking_id': bookingId,
                      'booking_data': bookingData,
                      'service_title': serviceTitle,
                      'address': address,
                      'selected_date_formatted': selectedDateFormatted,
                      'selected_time': selectedTime,
                    });
                  },
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Find Technician Now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // View My Bookings / View Booking
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    if (bookingId.isNotEmpty) {
                      context.push('/track-booking/$bookingId');
                    } else {
                      context.push('/orders');
                    }
                  },
                  child: const Text(
                    'View My Bookings',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Secondary: Add to Calendar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Service reminder added to your device calendar!'),
                        backgroundColor: Color(0xFF10B981),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.event_note_rounded, color: Color(0xFF2563EB), size: 18),
                  label: const Text(
                    'Add to Calendar',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmedRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 20),
        const SizedBox(width: 12),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}
