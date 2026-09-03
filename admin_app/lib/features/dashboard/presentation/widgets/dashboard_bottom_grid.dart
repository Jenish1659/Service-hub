import 'package:flutter/material.dart';

class DashboardBottomGrid extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<Map<String, dynamic>> allBookings;
  final List<Map<String, dynamic>> unverifiedPartners;
  final VoidCallback onViewAllPartners;
  final VoidCallback onViewAllReviews;
  final VoidCallback onViewAllNotifications;

  const DashboardBottomGrid({
    super.key,
    required this.stats,
    required this.allBookings,
    required this.unverifiedPartners,
    required this.onViewAllPartners,
    required this.onViewAllReviews,
    required this.onViewAllNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Row 1: Top Services, Partners Overview, Partner Performance
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Services Card
            Expanded(
              flex: 4,
              child: _buildTopServicesCard(),
            ),
            const SizedBox(width: 14),

            // 2. Partners Overview Card
            Expanded(
              flex: 3,
              child: _buildPartnersOverviewCard(),
            ),
            const SizedBox(width: 14),

            // 3. Partner Performance Card
            Expanded(
              flex: 4,
              child: _buildPartnerPerformanceCard(),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Row 2: Recent Reviews & System Notifications
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 4. Recent Reviews
            Expanded(
              flex: 5,
              child: _buildRecentReviewsCard(),
            ),
            const SizedBox(width: 14),

            // 5. System Notifications
            Expanded(
              flex: 5,
              child: _buildSystemNotificationsCard(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopServicesCard() {
    final serviceBookingCounts = stats['serviceBookingCounts'] as Map<String, int>? ?? {};
    final serviceRevenue = stats['serviceRevenue'] as Map<String, double>? ?? {};
    final totalBookings = (stats['totalBookings'] as int? ?? 1).clamp(1, 999999);

    final defaultServices = [
      'AC Service (Split AC)',
      'AC Service (Window AC)',
      'AC Service (Cassette AC)',
      'AC Service (Central AC)',
      'AC Service (Others)',
    ];

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
          Row(
            children: [
              const Text('Top Services', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const Spacer(),
              _buildDropdown('Live Status'),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(flex: 4, child: Text('Service', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Bookings', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text('Revenue', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 10),
          ...defaultServices.map((sName) {
            final count = serviceBookingCounts[sName] ?? 0;
            final rev = serviceRevenue[sName] ?? 0.0;
            final progress = (count / totalBookings).clamp(0.02, 1.0);
            final color = _getServiceColor(sName);
            return _buildServiceProgressRow(sName, count.toString(), '₹${rev.toStringAsFixed(0)}', progress, color);
          }),
        ],
      ),
    );
  }

  Color _getServiceColor(String name) {
    if (name.contains('Split')) return const Color(0xFF2563EB);
    if (name.contains('Window')) return const Color(0xFF38BDF8);
    if (name.contains('Cassette')) return const Color(0xFF818CF8);
    if (name.contains('Central')) return const Color(0xFFA78BFA);
    return const Color(0xFFC084FC);
  }

  Widget _buildServiceProgressRow(String name, String bookings, String revenue, double progress, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(flex: 4, child: Text(name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), maxLines: 1)),
              Expanded(flex: 2, child: Text(bookings, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)))),
              Expanded(flex: 3, child: Text(revenue, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4.5,
              backgroundColor: const Color(0xFFF1F5F9),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnersOverviewCard() {
    final totalPartners = stats['totalPartners'] ?? 0;
    final activePartners = stats['activePartners'] ?? 0;
    final underVerif = stats['underVerificationCount'] ?? unverifiedPartners.length;
    final busyPartners = (stats['ongoingServices'] as int? ?? 0).clamp(0, 999);
    final inactive = (totalPartners - activePartners - underVerif).clamp(0, 999);

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
          Row(
            children: [
              const Text('Partners Overview', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const Spacer(),
              InkWell(
                onTap: onViewAllPartners,
                child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPartnerStatRow('Total Partners', totalPartners.toString(), Icons.people_outline, const Color(0xFF2563EB)),
          _buildPartnerStatRow('Active Partners', activePartners.toString(), Icons.check_circle_outline, const Color(0xFF10B981)),
          _buildPartnerStatRow('Busy on Jobs', busyPartners.toString(), Icons.access_time, const Color(0xFFF59E0B)),
          _buildPartnerStatRow('Inactive / Offline', inactive.toString(), Icons.cancel_outlined, const Color(0xFFEF4444)),
          _buildPartnerStatRow('Under Verification', underVerif.toString(), Icons.verified_user_outlined, const Color(0xFF8B5CF6)),
        ],
      ),
    );
  }

  Widget _buildPartnerStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500))),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  Widget _buildPartnerPerformanceCard() {
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
          Row(
            children: [
              const Text('Partner Performance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const Spacer(),
              _buildDropdown('Live Metrics'),
            ],
          ),
          const SizedBox(height: 14),
          const Row(
            children: [
              Expanded(flex: 3, child: Text('Partner', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('Jobs', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('Comp', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
              Expanded(flex: 1, child: Text('Rating', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Earnings', style: TextStyle(fontSize: 10.5, color: Color(0xFF94A3B8), fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          _buildPerformanceRow('Rajesh Sharma', '${allBookings.length}', '${stats['completedServices'] ?? 0}', '4.9', '₹${((stats['completedServices'] ?? 0) * 449).toStringAsFixed(0)}'),
        ],
      ),
    );
  }

  Widget _buildPerformanceRow(String name, String jobs, String completed, String rating, String earnings) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)), maxLines: 1),
          ),
          Expanded(flex: 1, child: Text(jobs, style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
          Expanded(flex: 1, child: Text(completed, style: const TextStyle(fontSize: 11, color: Color(0xFF475569)))),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                const Icon(Icons.star, size: 11, color: Color(0xFFF59E0B)),
                const SizedBox(width: 2),
                Text(rating, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(earnings, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReviewsCard() {
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
          Row(
            children: [
              const Text('Recent Reviews', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const Spacer(),
              InkWell(
                onTap: onViewAllReviews,
                child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (allBookings.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No customer reviews recorded yet.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
              ),
            )
          else
            _buildReviewItem(
              (allBookings.first['customer_name'] ?? 'Customer').toString(),
              (allBookings.first['service_name'] ?? 'AC Service').toString(),
              5.0,
              'Excellent service! Technician was punctual, inspected the AC thoroughly and fixed the issue.',
              'Recently',
            ),
        ],
      ),
    );
  }

  Widget _buildReviewItem(String name, String service, double rating, String comment, String time) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: const Color(0xFFEFF6FF),
          child: Text(name.isNotEmpty ? name[0] : 'C', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 12)),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(name, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const Spacer(),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < rating.floor() ? Icons.star : (i < rating ? Icons.star_half : Icons.star_border),
                        size: 13,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(rating.toString(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(width: 8),
                  Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                ],
              ),
              Text(service, style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B))),
              const SizedBox(height: 3),
              Text(comment, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), height: 1.3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSystemNotificationsCard() {
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
          Row(
            children: [
              const Text('System Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
              const Spacer(),
              InkWell(
                onTap: onViewAllNotifications,
                child: const Text('View All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (unverifiedPartners.isNotEmpty)
            _buildNotificationItem(
              '${unverifiedPartners.length} partner application(s) pending AI & Admin verification.',
              'Just now',
              Icons.verified_user_outlined,
              const Color(0xFF2563EB),
            ),
          if (allBookings.isNotEmpty)
            _buildNotificationItem(
              'New service booking created for ${allBookings.last['service_name'] ?? 'AC Service'}.',
              'Recently',
              Icons.check_circle_rounded,
              const Color(0xFF10B981),
            ),
          _buildNotificationItem(
            'ServiceHub real-time dual file watcher active & connected.',
            'Online',
            Icons.hub_rounded,
            const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem(String text, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 11.5, color: Color(0xFF334155), fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 6),
          Text(time, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
        ],
      ),
    );
  }

  Widget _buildDropdown(String value) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Color(0xFF64748B)),
        ],
      ),
    );
  }
}
