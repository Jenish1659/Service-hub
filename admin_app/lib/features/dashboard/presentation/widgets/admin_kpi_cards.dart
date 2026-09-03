import 'package:flutter/material.dart';

class AdminKPICards extends StatelessWidget {
  final int totalBookings;
  final int completedServices;
  final int ongoingServices;
  final int totalCustomers;
  final int totalPartners;
  final double totalRevenue;

  const AdminKPICards({
    super.key,
    required this.totalBookings,
    required this.completedServices,
    required this.ongoingServices,
    required this.totalCustomers,
    required this.totalPartners,
    required this.totalRevenue,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - (5 * 14)) / 6;
        final isCompact = constraints.maxWidth < 1100;

        if (isCompact) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCard(
                  width: 180,
                  title: "Total Bookings",
                  value: totalBookings.toString(),
                  growth: totalBookings > 0 ? "Live Database" : "0 Active",
                  period: "realtime",
                  icon: Icons.calendar_today_rounded,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF2563EB),
                  sparklineColor: const Color(0xFF818CF8),
                ),
                const SizedBox(width: 12),
                _buildCard(
                  width: 180,
                  title: "Completed Services",
                  value: completedServices.toString(),
                  growth: completedServices > 0 ? "$completedServices done" : "0 Done",
                  period: "all-time",
                  icon: Icons.check_circle_outline_rounded,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF10B981),
                  sparklineColor: const Color(0xFF34D399),
                ),
                const SizedBox(width: 12),
                _buildCard(
                  width: 180,
                  title: "Ongoing Services",
                  value: ongoingServices.toString(),
                  growth: ongoingServices > 0 ? "In Progress" : "None active",
                  period: "realtime",
                  icon: Icons.access_time_rounded,
                  iconBg: const Color(0xFFFFFBEB),
                  iconColor: const Color(0xFFF59E0B),
                  sparklineColor: const Color(0xFFFBBF24),
                ),
                const SizedBox(width: 12),
                _buildCard(
                  width: 180,
                  title: "Total Customers",
                  value: totalCustomers.toString(),
                  growth: totalCustomers > 0 ? "Verified" : "0 Users",
                  period: "registered",
                  icon: Icons.people_outline_rounded,
                  iconBg: const Color(0xFFEFF6FF),
                  iconColor: const Color(0xFF0284C7),
                  sparklineColor: const Color(0xFF38BDF8),
                ),
                const SizedBox(width: 12),
                _buildCard(
                  width: 180,
                  title: "Total Partners",
                  value: totalPartners.toString(),
                  growth: totalPartners > 0 ? "KYC Verified" : "0 Partners",
                  period: "registered",
                  icon: Icons.handshake_outlined,
                  iconBg: const Color(0xFFFAF5FF),
                  iconColor: const Color(0xFF9333EA),
                  sparklineColor: const Color(0xFFC084FC),
                ),
                const SizedBox(width: 12),
                _buildCard(
                  width: 200,
                  title: "Total Revenue",
                  value: "₹${_formatCurrency(totalRevenue)}",
                  growth: totalRevenue > 0 ? "Gross Volume" : "₹0.00",
                  period: "settled",
                  icon: Icons.account_balance_wallet_outlined,
                  iconBg: const Color(0xFFECFDF5),
                  iconColor: const Color(0xFF059669),
                  sparklineColor: const Color(0xFF10B981),
                ),
              ],
            ),
          );
        }

        return Row(
          children: [
            Expanded(
              child: _buildCard(
                width: cardWidth,
                title: "Total Bookings",
                value: totalBookings.toString(),
                growth: totalBookings > 0 ? "Live Database" : "0 Active",
                period: "realtime",
                icon: Icons.calendar_today_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                sparklineColor: const Color(0xFF818CF8),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildCard(
                width: cardWidth,
                title: "Completed Services",
                value: completedServices.toString(),
                growth: completedServices > 0 ? "$completedServices done" : "0 Done",
                period: "all-time",
                icon: Icons.check_circle_outline_rounded,
                iconBg: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF10B981),
                sparklineColor: const Color(0xFF34D399),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildCard(
                width: cardWidth,
                title: "Ongoing Services",
                value: ongoingServices.toString(),
                growth: ongoingServices > 0 ? "In Progress" : "None active",
                period: "realtime",
                icon: Icons.access_time_rounded,
                iconBg: const Color(0xFFFFFBEB),
                iconColor: const Color(0xFFF59E0B),
                sparklineColor: const Color(0xFFFBBF24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildCard(
                width: cardWidth,
                title: "Total Customers",
                value: totalCustomers.toString(),
                growth: totalCustomers > 0 ? "Verified" : "0 Users",
                period: "registered",
                icon: Icons.people_outline_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF0284C7),
                sparklineColor: const Color(0xFF38BDF8),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildCard(
                width: cardWidth,
                title: "Total Partners",
                value: totalPartners.toString(),
                growth: totalPartners > 0 ? "KYC Verified" : "0 Partners",
                period: "registered",
                icon: Icons.handshake_outlined,
                iconBg: const Color(0xFFFAF5FF),
                iconColor: const Color(0xFF9333EA),
                sparklineColor: const Color(0xFFC084FC),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildCard(
                width: cardWidth,
                title: "Total Revenue",
                value: "₹${_formatCurrency(totalRevenue)}",
                growth: totalRevenue > 0 ? "Gross Volume" : "₹0.00",
                period: "settled",
                icon: Icons.account_balance_wallet_outlined,
                iconBg: const Color(0xFFECFDF5),
                iconColor: const Color(0xFF059669),
                sparklineColor: const Color(0xFF10B981),
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000) {
      final inLakhs = amount / 100000;
      return "${inLakhs.toStringAsFixed(2)}L";
    }
    if (amount >= 1000) {
      final inK = amount / 1000;
      return "${inK.toStringAsFixed(1)}K";
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildCard({
    required double width,
    required String title,
    required String value,
    required String growth,
    required String period,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color sparklineColor,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Row: Title + Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Middle: Big Value
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 10),

          // Bottom Row: Growth Badge + Dynamic Wave Sparkline
          Row(
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    growth,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF059669),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                period,
                style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
              ),
              const Spacer(),
              // Wave Sparkline
              SizedBox(
                width: 32,
                height: 14,
                child: CustomPaint(
                  painter: _SparklinePainter(color: sparklineColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final Color color;
  _SparklinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.75);
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.9,
      size.width * 0.35,
      size.height * 0.15,
      size.width * 0.65,
      size.height * 0.4,
    );
    path.cubicTo(
      size.width * 0.8,
      size.height * 0.55,
      size.width * 0.9,
      size.height * 0.1,
      size.width,
      size.height * 0.2,
    );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
