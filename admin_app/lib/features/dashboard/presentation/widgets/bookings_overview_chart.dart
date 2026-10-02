import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BookingsOverviewChart extends StatefulWidget {
  final List<Map<String, dynamic>> bookings;

  const BookingsOverviewChart({super.key, required this.bookings});

  @override
  State<BookingsOverviewChart> createState() => _BookingsOverviewChartState();
}

class _BookingsOverviewChartState extends State<BookingsOverviewChart> {
  String _selectedFilter = 'Daily';

  String _monthName(int m) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[(m - 1).clamp(0, 11)];
  }

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
                'Bookings Overview',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
              const Spacer(),
              _buildLegend('Total Bookings', const Color(0xFF2563EB)),
              const SizedBox(width: 12),
              _buildLegend('Completed', const Color(0xFF10B981)),
              const SizedBox(width: 12),
              _buildLegend('Cancelled', const Color(0xFFEF4444)),
              const SizedBox(width: 14),
              // Dropdown
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedFilter,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    items: ['Daily', 'Weekly', 'Monthly'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _selectedFilter = val ?? 'Daily'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Line Chart with 100% Real Live Database Spots
          () {
            final now = DateTime.now();
            final dayDates = List.generate(7, (i) {
              final d = now.subtract(Duration(days: 6 - i));
              return DateTime(d.year, d.month, d.day);
            });
            final dayLabels = dayDates.map((d) => '${d.day} ${_monthName(d.month)}').toList();

            final List<FlSpot> totalSpots = [];
            final List<FlSpot> completedSpots = [];
            final List<FlSpot> cancelledSpots = [];

            double maxVal = 5.0;

            for (int i = 0; i < 7; i++) {
              final targetDate = dayDates[i];
              int totalDay = 0;
              int completedDay = 0;
              int cancelledDay = 0;

              for (final b in widget.bookings) {
                final rawCreated = b['created_at'] ?? b['booking_date'];
                DateTime? bDate;
                if (rawCreated is String) {
                  bDate = DateTime.tryParse(rawCreated);
                } else if (rawCreated is DateTime) {
                  bDate = rawCreated;
                }

                if (bDate != null) {
                  if (bDate.year == targetDate.year &&
                      bDate.month == targetDate.month &&
                      bDate.day == targetDate.day) {
                    totalDay++;
                    final status = (b['status'] ?? '').toString().toUpperCase();
                    if (status == 'COMPLETED' || status == 'SERVICE_COMPLETED') {
                      completedDay++;
                    } else if (status == 'CANCELLED' || status == 'REJECTED') {
                      cancelledDay++;
                    }
                  }
                }
              }

              totalSpots.add(FlSpot(i.toDouble(), totalDay.toDouble()));
              completedSpots.add(FlSpot(i.toDouble(), completedDay.toDouble()));
              cancelledSpots.add(FlSpot(i.toDouble(), cancelledDay.toDouble()));

              if (totalDay > maxVal) maxVal = totalDay.toDouble();
            }

            final chartMaxY = (maxVal * 1.25).ceilToDouble().clamp(5.0, 100000.0);
            final yInterval = (chartMaxY / 5).ceilToDouble().clamp(1.0, 50000.0);

            return SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                    getDrawingHorizontalLine: (val) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yInterval,
                        reservedSize: 32,
                        getTitlesWidget: (val, meta) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: 1,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < dayLabels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                dayLabels[idx],
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: 6,
                  minY: 0,
                  maxY: chartMaxY,
                  lineBarsData: [
                    // 1. Total Bookings Series
                    LineChartBarData(
                      spots: totalSpots,
                      isCurved: true,
                      color: const Color(0xFF2563EB),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: true),
                    ),
                    // 2. Completed Series
                    LineChartBarData(
                      spots: completedSpots,
                      isCurved: true,
                      color: const Color(0xFF10B981),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: true),
                    ),
                    // 3. Cancelled Series
                    LineChartBarData(
                      spots: cancelledSpots,
                      isCurved: true,
                      color: const Color(0xFFEF4444),
                      barWidth: 2.5,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            );
          }(),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
        ),
      ],
    );
  }
}
