import 'package:flutter/material.dart';
import 'booking_details_modal.dart';

class RecentBookingsCard extends StatelessWidget {
  final List<Map<String, dynamic>> bookings;
  final VoidCallback onViewAll;

  const RecentBookingsCard({
    super.key,
    required this.bookings,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const Text(
                'Recent Bookings',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              InkWell(
                onTap: onViewAll,
                child: const Text(
                  'View All',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Booking Rows
          if (bookings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(
                child: Text('No recent bookings yet.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bookings.length > 5 ? 5 : bookings.length,
              separatorBuilder: (_, __) => const Divider(color: Color(0xFFF1F5F9), height: 16),
              itemBuilder: (ctx, idx) {
                final b = bookings[idx];
                final rawId = b['id'] ?? b['booking_id'];
                final id = rawId != null
                    ? (rawId.toString().length > 8 ? rawId.toString().substring(0, 8) : rawId.toString())
                    : '${idx + 1}';
                final customerName = (b['customer_name'] ??
                        b['name'] ??
                        (b['customer_id'] != null
                            ? 'Customer #${b['customer_id'].toString().substring(0, b['customer_id'].toString().length.clamp(0, 6))}'
                            : 'Customer'))
                    .toString();
                final service = (b['service_name'] ?? b['category_name'] ?? b['problem_description'] ?? 'AC Service').toString();
                final status = (b['status'] ?? 'PENDING').toString().toUpperCase();

                String calcTimeAgo(dynamic raw) {
                  if (raw == null) return 'Recently';
                  DateTime? dt;
                  if (raw is DateTime) dt = raw;
                  if (raw is String) dt = DateTime.tryParse(raw);
                  if (dt == null) return 'Recently';
                  final diff = DateTime.now().difference(dt);
                  if (diff.inSeconds < 60) return 'Just now';
                  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
                  if (diff.inHours < 24) return '${diff.inHours}h ago';
                  return '${diff.inDays}d ago';
                }

                final timeAgo = b['time_ago']?.toString() ?? calcTimeAgo(b['created_at']);

                return InkWell(
                  onTap: () => BookingDetailsModal.show(context, b),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: const Color(0xFFEFF6FF),
                          child: Text(
                            customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    '#$id',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      customerName,
                                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                service,
                                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildStatusBadge(status),
                        const SizedBox(width: 10),
                        Text(
                          timeAgo,
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'CONFIRMED':
      case 'ACCEPTED':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF10B981);
        break;
      case 'ONGOING':
      case 'SERVICE_STARTED':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFF59E0B);
        break;
      case 'ASSIGNED':
      case 'SEARCHING_PROVIDER':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF0284C7);
        break;
      case 'COMPLETED':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        break;
      case 'CANCELLED':
      case 'REJECTED':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFEF4444);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status.capitalizeFirst(),
        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    final lower = toLowerCase();
    return lower[0].toUpperCase() + lower.substring(1);
  }
}
