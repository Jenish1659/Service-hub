import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class BookingStatusDonutChart extends StatelessWidget {
  final int totalCount;
  final int completedCount;
  final int ongoingCount;
  final int confirmedCount;
  final int cancelledCount;

  const BookingStatusDonutChart({
    super.key,
    required this.totalCount,
    required this.completedCount,
    required this.ongoingCount,
    required this.confirmedCount,
    required this.cancelledCount,
  });

  @override
  Widget build(BuildContext context) {
    final cPct = totalCount > 0 ? ((completedCount / totalCount) * 100).toStringAsFixed(1) : '0.0';
    final oPct = totalCount > 0 ? ((ongoingCount / totalCount) * 100).toStringAsFixed(1) : '0.0';
    final confPct = totalCount > 0 ? ((confirmedCount / totalCount) * 100).toStringAsFixed(1) : '0.0';
    final canPct = totalCount > 0 ? ((cancelledCount / totalCount) * 100).toStringAsFixed(1) : '0.0';

    final List<PieChartSectionData> chartSections = [];
    if (totalCount == 0) {
      chartSections.add(
        PieChartSectionData(
          value: 1,
          color: const Color(0xFFE2E8F0),
          showTitle: false,
          radius: 18,
        ),
      );
    } else {
      if (completedCount > 0) {
        chartSections.add(PieChartSectionData(
          value: completedCount.toDouble(),
          color: const Color(0xFF10B981),
          showTitle: false,
          radius: 18,
        ));
      }
      if (ongoingCount > 0) {
        chartSections.add(PieChartSectionData(
          value: ongoingCount.toDouble(),
          color: const Color(0xFFF59E0B),
          showTitle: false,
          radius: 18,
        ));
      }
      if (confirmedCount > 0) {
        chartSections.add(PieChartSectionData(
          value: confirmedCount.toDouble(),
          color: const Color(0xFF0284C7),
          showTitle: false,
          radius: 18,
        ));
      }
      if (cancelledCount > 0) {
        chartSections.add(PieChartSectionData(
          value: cancelledCount.toDouble(),
          color: const Color(0xFFEF4444),
          showTitle: false,
          radius: 18,
        ));
      }
    }

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
          const Text(
            'Booking Status',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 14),

          // Donut & Legend
          Row(
            children: [
              // Donut Chart with Center Total
              SizedBox(
                width: 140,
                height: 140,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: totalCount > 0 ? 3 : 0,
                        centerSpaceRadius: 44,
                        sections: chartSections,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          totalCount.toString(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        const Text(
                          'Total',
                          style: TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 16),

              // Status Legend List
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Completed', completedCount, '$cPct%', const Color(0xFF10B981)),
                    const SizedBox(height: 8),
                    _buildLegendItem('Ongoing', ongoingCount, '$oPct%', const Color(0xFFF59E0B)),
                    const SizedBox(height: 8),
                    _buildLegendItem('Confirmed', confirmedCount, '$confPct%', const Color(0xFF0284C7)),
                    const SizedBox(height: 8),
                    _buildLegendItem('Cancelled', cancelledCount, '$canPct%', const Color(0xFFEF4444)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, int count, String pct, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
          ),
        ),
        Text(
          '$count ($pct)',
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }
}
