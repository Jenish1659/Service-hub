import 'package:flutter/material.dart';

class EarningsChartWidget extends StatelessWidget {
  final List<double> dailyEarnings;

  const EarningsChartWidget({
    super.key,
    required this.dailyEarnings,
  });

  @override
  Widget build(BuildContext context) {
    // Generate 30 days of data, defaulting to 0 or incoming values
    final data = List<double>.generate(30, (i) => i < dailyEarnings.length ? dailyEarnings[i] : 0.0);
    final maxVal = data.fold<double>(100.0, (prev, e) => e > prev ? e : prev);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Earnings Overview',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Your earnings for the selected period',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'This Month',
                      style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Chart Graphic
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Y-Axis Labels
                const SizedBox(
                  width: 32,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('\u20B93K', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                      Text('\u20B92K', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                      Text('\u20B91K', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                      Text('0', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                    ],
                  ),
                ),
                const SizedBox(width: 6),

                // Bars Container
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final barWidth = (constraints.maxWidth / 30) - 2.5;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(30, (index) {
                          final val = data[index];
                          final heightFactor = val == 0 ? 0.04 : (val / maxVal).clamp(0.04, 1.0);
                          final isHighlight = index == 11 && val > 0;

                          return Container(
                            width: barWidth > 3 ? barWidth : 3,
                            height: constraints.maxHeight * heightFactor,
                            decoration: BoxDecoration(
                              color: isHighlight
                                  ? const Color(0xFF1D4ED8)
                                  : val > 0
                                      ? const Color(0xFF60A5FA)
                                      : const Color(0xFFE2E8F0),
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // X-Axis Date Markers
          const Padding(
            padding: EdgeInsets.only(left: 38),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('1 Sep', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('10 Sep', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('20 Sep', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                    ),
                  ),
                ),
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('30 Sep', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
