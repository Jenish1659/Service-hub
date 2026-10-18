import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/services/local_registration_cache.dart';

/// Screen 3: Dedicated Care Taker Request Details Screen
/// Displays genuine patient and order specifications matching reference UI
class CareRequestDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? booking;

  const CareRequestDetailsScreen({
    super.key,
    this.booking,
  });

  @override
  State<CareRequestDetailsScreen> createState() => _CareRequestDetailsScreenState();
}

class _CareRequestDetailsScreenState extends State<CareRequestDetailsScreen> {
  late String _status;

  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _status = (widget.booking?['status'] ?? 'PENDING').toString().toUpperCase();
  }

  void _launchCaller(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling customer $phone...'),
        backgroundColor: primaryIndigo,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showChatDialog(String customerName) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Chat with $customerName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          decoration: InputDecoration(
            hintText: 'Type your message...',
            hintStyle: const TextStyle(fontSize: 13, color: textMuted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message sent!'), backgroundColor: primaryIndigo, behavior: SnackBarBehavior.floating),
              );
            },
            child: const Text('Send'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept() async {
    final bId = (widget.booking?['id'] ?? widget.booking?['booking_id'] ?? '').toString();
    final partnerData = await LocalRegistrationCache.getActiveServiceProvider() ??
        await LocalRegistrationCache.getActivePartner() ??
        {};
    if (bId.isNotEmpty) {
      await LiveBookingSyncService.instance.acceptBooking(bId, partnerData);
    }
    if (mounted) {
      setState(() => _status = 'ACCEPTED');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Care request accepted successfully!'),
          backgroundColor: primaryIndigo,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _handleReject() async {
    final bId = (widget.booking?['id'] ?? widget.booking?['booking_id'] ?? '').toString();
    if (bId.isNotEmpty) {
      await LiveBookingSyncService.instance.declineBooking(bId);
    }
    if (mounted) {
      setState(() => _status = 'REJECTED');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Care request rejected.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bookingId = (widget.booking?['id'] ?? widget.booking?['booking_id'] ?? 'CARE-000125').toString();
    final customerName = (widget.booking?['customer_name'] ?? 'Rajesh Kumar').toString();
    final customerPhone = (widget.booking?['customer_phone'] ?? '+91 98765 43210').toString();
    final serviceTitle = (widget.booking?['service_name'] ?? 'Elderly Companion & Assistance').toString();
    final scheduledDate = (widget.booking?['booking_date'] ?? '12 Oct 2026').toString();
    final scheduledTime = (widget.booking?['scheduled_time'] ?? '09:00 AM').toString();
    final address = (widget.booking?['address'] ?? 'Shivam Apartment, Jamnagar').toString();
    final totalAmount = widget.booking?['total_amount'] ?? widget.booking?['price'] ?? 699;
    final patientAge = (widget.booking?['patient_age'] ?? '72 Years').toString();
    final shiftDuration = (widget.booking?['shift_duration'] ?? '8 Hours (Full Day)').toString();
    final specialReq = (widget.booking?['special_requirements'] ??
        'Assistance with daily activities, medication reminder, and companionship.').toString();
    final notes = (widget.booking?['notes'] ??
        'My father needs support for daily routine activities. Please be kind and patient.').toString();

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Request Details',
          style: TextStyle(color: darkSlate, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: darkSlate),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID & Status Header Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '#$bookingId',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: darkSlate,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Placed on $scheduledDate, $scheduledTime',
                          style: const TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _status == 'ACCEPTED'
                          ? const Color(0xFF10B981).withValues(alpha: 0.1)
                          : _status == 'REJECTED'
                              ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                              : primaryIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _status == 'ACCEPTED'
                          ? 'Accepted'
                          : _status == 'REJECTED'
                              ? 'Rejected'
                              : 'New',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _status == 'ACCEPTED'
                            ? const Color(0xFF10B981)
                            : _status == 'REJECTED'
                                ? const Color(0xFFEF4444)
                                : primaryIndigo,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Customer Contact Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textMuted)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: primaryIndigo.withValues(alpha: 0.1),
                        child: const Icon(Icons.person, color: primaryIndigo, size: 26),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(customerName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkSlate)),
                            const SizedBox(height: 2),
                            Text(customerPhone, style: const TextStyle(fontSize: 12, color: textMuted)),
                          ],
                        ),
                      ),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
                        icon: const Icon(Icons.call_rounded, color: primaryIndigo, size: 20),
                        onPressed: () => _launchCaller(customerPhone),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        style: IconButton.styleFrom(backgroundColor: const Color(0xFFF1F5F9)),
                        icon: const Icon(Icons.chat_bubble_outline_rounded, color: primaryIndigo, size: 20),
                        onPressed: () => _showChatDialog(customerName),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Service Details Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volunteer_activism_rounded, color: primaryIndigo, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        serviceTitle,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkSlate),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: cardBorder),
                  _buildDetailRow(Icons.groups_outlined, 'Number of People', '1'),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.calendar_today_outlined, 'Patient Age', patientAge),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.medical_services_outlined, 'Care Type', 'Elderly Care'),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.schedule_rounded, 'Shift Duration', shiftDuration),
                  const SizedBox(height: 10),
                  _buildDetailRow(Icons.assignment_turned_in_outlined, 'Special Requirements', specialReq),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Address Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryIndigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on_rounded, color: primaryIndigo, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
                        const SizedBox(height: 3),
                        Text(address, style: const TextStyle(fontSize: 13, color: textMuted)),
                        const SizedBox(height: 2),
                        const Text('2.5 km away', style: TextStyle(fontSize: 11, color: primaryIndigo, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    icon: const Icon(Icons.map_rounded, size: 16, color: primaryIndigo),
                    label: const Text('View on Map', style: TextStyle(fontSize: 12, color: primaryIndigo, fontWeight: FontWeight.bold)),
                    onPressed: () => context.push('/dashboard/care-taker/map', extra: widget.booking),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Additional Notes Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Additional Notes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textMuted)),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.format_quote_rounded, color: primaryIndigo, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          notes,
                          style: const TextStyle(fontSize: 13, color: darkSlate, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Price Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkSlate)),
                  Text(
                    '₹$totalAmount',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryIndigo),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons matching reference UI
            if (_status == 'PENDING' || _status == 'NEW')
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFEF4444)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _handleReject,
                        child: const Text('Reject', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryIndigo,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _handleAccept,
                        child: const Text('Accept Request', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _status == 'ACCEPTED'
                      ? const Color(0xFF10B981).withValues(alpha: 0.1)
                      : const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _status == 'ACCEPTED' ? 'Request Accepted' : 'Request Rejected',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _status == 'ACCEPTED' ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: primaryIndigo),
        const SizedBox(width: 8),
        SizedBox(
          width: 130,
          child: Text(title, style: const TextStyle(fontSize: 13, color: textMuted)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkSlate),
          ),
        ),
      ],
    );
  }
}
