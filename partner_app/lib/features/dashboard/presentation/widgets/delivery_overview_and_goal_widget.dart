import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// KPI Metric item data structure for delivery overview cards.
class DeliveryKpiItem {
  final String label;
  final String countText;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color cardBgColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const DeliveryKpiItem({
    required this.label,
    required this.countText,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.cardBgColor,
    required this.borderColor,
    this.onTap,
  });
}

/// A responsive KPI card widget matching the ServiceHub Delivery Partner overview design.
class DeliveryKpiCard extends StatelessWidget {
  final String label;
  final String countText;
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final Color cardBgColor;
  final Color borderColor;
  final VoidCallback? onTap;

  const DeliveryKpiCard({
    super.key,
    required this.label,
    required this.countText,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.cardBgColor,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        countText,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                          height: 1.1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                        height: 1.15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 1. DeliveryOverviewMetricsGrid:
/// - Title: "TODAY'S OVERVIEW" in bold grey caps
/// - 4 KPI cards:
///   * Deliveries Completed (green checkmark icon, count e.g. 0, label "Deliveries Completed")
///   * Pending Deliveries (amber timer icon, count e.g. 0, label "Pending Deliveries")
///   * Today's Earnings (blue rupee wallet icon, e.g. ₹0, label "Today's Earnings")
///   * On-Time Rate (purple gauge/speed icon, e.g. 100%, label "On-Time Rate")
/// - STRICT REQUIREMENT: ZERO DUMMY DATA. All default values start at 0 baseline (0 completed, 0 pending, ₹0 earnings).
/// - Must use responsive wrapping or flexible columns to ensure 0 pixel buffer overflow on 320px–360px screens.
class DeliveryOverviewMetricsGrid extends StatelessWidget {
  final int completedCount;
  final int pendingCount;
  final double earnings;
  final double onTimeRate;
  final String? dateText;
  final String title;
  final VoidCallback? onTapCompleted;
  final VoidCallback? onTapPending;
  final VoidCallback? onTapEarnings;
  final VoidCallback? onTapOnTimeRate;
  final bool? forceSingleRow;

  const DeliveryOverviewMetricsGrid({
    super.key,
    this.completedCount = 0,
    this.pendingCount = 0,
    this.earnings = 0.0,
    this.onTimeRate = 100.0,
    this.dateText,
    this.title = "TODAY'S OVERVIEW",
    this.onTapCompleted,
    this.onTapPending,
    this.onTapEarnings,
    this.onTapOnTimeRate,
    this.forceSingleRow,
  });

  @override
  Widget build(BuildContext context) {
    final displayDate = dateText ?? DateFormat('EEE, d MMM').format(DateTime.now());

    final card1 = DeliveryKpiCard(
      label: 'Deliveries Completed',
      countText: '$completedCount',
      icon: Icons.check_circle_rounded,
      iconColor: const Color(0xFF16A34A),
      iconBgColor: const Color(0xFFDCFCE7),
      cardBgColor: const Color(0xFFF0FDF4),
      borderColor: const Color(0xFFDCFCE7),
      onTap: onTapCompleted,
    );

    final card2 = DeliveryKpiCard(
      label: 'Pending Deliveries',
      countText: '$pendingCount',
      icon: Icons.schedule_rounded,
      iconColor: const Color(0xFFEA580C),
      iconBgColor: const Color(0xFFFFF7ED),
      cardBgColor: const Color(0xFFFFF7ED),
      borderColor: const Color(0xFFFED7AA),
      onTap: onTapPending,
    );

    final card3 = DeliveryKpiCard(
      label: "Today's Earnings",
      countText: '₹${earnings.toStringAsFixed(0)}',
      icon: Icons.account_balance_wallet_rounded,
      iconColor: const Color(0xFF2563EB),
      iconBgColor: const Color(0xFFDBEAFE),
      cardBgColor: const Color(0xFFEFF6FF),
      borderColor: const Color(0xFFDBEAFE),
      onTap: onTapEarnings,
    );

    final card4 = DeliveryKpiCard(
      label: 'On-Time Rate',
      countText: '${onTimeRate.toStringAsFixed(0)}%',
      icon: Icons.speed_rounded,
      iconColor: const Color(0xFF9333EA),
      iconBgColor: const Color(0xFFF3E8FF),
      cardBgColor: const Color(0xFFFAF5FF),
      borderColor: const Color(0xFFF3E8FF),
      onTap: onTapOnTimeRate,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                size: 14,
                color: Color(0xFFEA580C),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.8,
                ),
              ),
            ),
            Text(
              displayDate,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Responsive KPI Cards (guarantees zero overflow on 320px–360px)
        LayoutBuilder(
          builder: (context, constraints) {
            final useSingleRow = forceSingleRow ?? (constraints.maxWidth >= 420);
            if (useSingleRow) {
              return Row(
                children: [
                  Expanded(child: card1),
                  const SizedBox(width: 8),
                  Expanded(child: card2),
                  const SizedBox(width: 8),
                  Expanded(child: card3),
                  const SizedBox(width: 8),
                  Expanded(child: card4),
                ],
              );
            } else {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(child: card1),
                      const SizedBox(width: 8),
                      Expanded(child: card2),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: card3),
                      const SizedBox(width: 8),
                      Expanded(child: card4),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }
}

/// 2. DeliveryDailyGoalCard:
/// - Title: "TODAY'S GOAL"
/// - Goal description: "Complete 8 deliveries today to earn ₹200 bonus"
/// - Dynamic progress bar showing `completedCount / 8`
/// - Action arrow: "Keep Going! 💪 >"
class DeliveryDailyGoalCard extends StatelessWidget {
  final int completedCount;
  final int targetCount;
  final int bonusAmount;
  final String title;
  final String? description;
  final String actionText;
  final VoidCallback? onTap;
  final VoidCallback? onActionTap;

  const DeliveryDailyGoalCard({
    super.key,
    this.completedCount = 0,
    this.targetCount = 8,
    this.bonusAmount = 200,
    this.title = "TODAY'S GOAL",
    this.description,
    this.actionText = "Keep Going! 💪",
    this.onTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = targetCount > 0
        ? (completedCount / targetCount).clamp(0.0, 1.0)
        : 0.0;
    final effectiveDescription = description ??
        'Complete $targetCount deliveries today to earn ₹$bonusAmount bonus';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 540;

          if (isWide) {
            return Row(
              children: [
                _buildTargetIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        effectiveDescription,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildProgressBar(progress)),
                const SizedBox(width: 12),
                Text(
                  '$completedCount / $targetCount',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 12),
                _buildActionPill(),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    _buildTargetIcon(),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            effectiveDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      flex: 0,
                      child: _buildActionPill(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildProgressBar(progress)),
                    const SizedBox(width: 10),
                    Text(
                      '$completedCount / $targetCount',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildTargetIcon() {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        color: Color(0xFFFFF7ED),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.track_changes_rounded,
        color: Color(0xFFEA580C),
        size: 20,
      ),
    );
  }

  Widget _buildProgressBar(double progress) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 8,
        backgroundColor: const Color(0xFFFED7AA).withValues(alpha: 0.35),
        valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEA580C)),
      ),
    );
  }

  Widget _buildActionPill() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onActionTap ?? onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFED7AA)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                actionText,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFEA580C),
                ),
              ),
              const SizedBox(width: 2),
              const Icon(
                Icons.chevron_right_rounded,
                size: 15,
                color: Color(0xFFEA580C),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A combined widget rendering both [DeliveryOverviewMetricsGrid] and [DeliveryDailyGoalCard]
/// with clean layout spacing and consistent baseline state.
class DeliveryOverviewAndGoalWidget extends StatelessWidget {
  final int completedCount;
  final int pendingCount;
  final double earnings;
  final double onTimeRate;
  final int targetDeliveries;
  final int bonusAmount;
  final String? dateText;
  final VoidCallback? onGoalTap;
  final VoidCallback? onActionTap;
  final VoidCallback? onTapCompleted;
  final VoidCallback? onTapPending;
  final VoidCallback? onTapEarnings;
  final VoidCallback? onTapOnTimeRate;
  final bool? forceSingleRow;

  const DeliveryOverviewAndGoalWidget({
    super.key,
    this.completedCount = 0,
    this.pendingCount = 0,
    this.earnings = 0.0,
    this.onTimeRate = 100.0,
    this.targetDeliveries = 8,
    this.bonusAmount = 200,
    this.dateText,
    this.onGoalTap,
    this.onActionTap,
    this.onTapCompleted,
    this.onTapPending,
    this.onTapEarnings,
    this.onTapOnTimeRate,
    this.forceSingleRow,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DeliveryOverviewMetricsGrid(
          completedCount: completedCount,
          pendingCount: pendingCount,
          earnings: earnings,
          onTimeRate: onTimeRate,
          dateText: dateText,
          onTapCompleted: onTapCompleted,
          onTapPending: onTapPending,
          onTapEarnings: onTapEarnings,
          onTapOnTimeRate: onTapOnTimeRate,
          forceSingleRow: forceSingleRow,
        ),
        const SizedBox(height: 14),
        DeliveryDailyGoalCard(
          completedCount: completedCount,
          targetCount: targetDeliveries,
          bonusAmount: bonusAmount,
          onTap: onGoalTap,
          onActionTap: onActionTap,
        ),
      ],
    );
  }
}
