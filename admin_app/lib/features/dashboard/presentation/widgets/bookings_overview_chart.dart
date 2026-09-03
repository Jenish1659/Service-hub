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

          // Line Chart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (val) => const FlLine(color: Color(0xFFF1F5F9), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 50,
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
                        const days = ['24 May', '25 May', '26 May', '27 May', '28 May', '29 May', '30 May'];
                        final idx = val.toInt();
                        if (idx >= 0 && idx < days.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(days[idx], style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w600)),
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
                maxY: 250,
                lineBarsData: [
                  // 1. Total Bookings Series
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 180),
                      FlSpot(1, 160),
                      FlSpot(2, 175),
                      FlSpot(3, 210),
                      FlSpot(4, 208),
                      FlSpot(5, 190),
                      FlSpot(6, 230),
                    ],
                    isCurved: true,
                    color: const Color(0xFF2563EB),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                  ),
                  // 2. Completed Series
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 140),
                      FlSpot(1, 120),
                      FlSpot(2, 130),
                      FlSpot(3, 160),
                      FlSpot(4, 155),
                      FlSpot(5, 135),
                      FlSpot(6, 170),
                    ],
                    isCurved: true,
                    color: const Color(0xFF10B981),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                  ),
                  // 3. Cancelled Series
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 45),
                      FlSpot(1, 50),
                      FlSpot(2, 60),
                      FlSpot(3, 55),
                      FlSpot(4, 65),
                      FlSpot(5, 58),
                      FlSpot(6, 68),
                    ],
                    isCurved: true,
                    color: const Color(0xFFEF4444),
                    barWidth: 2.5,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
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
