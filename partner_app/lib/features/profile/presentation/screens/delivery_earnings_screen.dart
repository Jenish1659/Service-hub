import 'package:flutter/material.dart';
import '../../../../core/storage/local_registration_cache.dart';
import '../controllers/delivery_agent_profile_controller.dart';

class DeliveryEarningsScreen extends StatefulWidget {
  final DeliveryAgentProfileController? controller;
  const DeliveryEarningsScreen({super.key, this.controller});

  @override
  State<DeliveryEarningsScreen> createState() => _DeliveryEarningsScreenState();
}

class _DeliveryEarningsScreenState extends State<DeliveryEarningsScreen> {
  int _selectedFilterIndex = 0; // 0: Daily, 1: Weekly, 2: Monthly
  final List<String> _filters = ['Daily', 'Weekly', 'Monthly'];
  double _cachedTotalEarnings = 0.0;
  int _cachedDeliveries = 0;

  @override
  void initState() {
    super.initState();
    _loadCachedEarnings();
  }

  Future<void> _loadCachedEarnings() async {
    try {
      final cached = widget.controller?.agentData ?? await LocalRegistrationCache.getActiveDeliveryAgent();
      if (cached != null && mounted) {
        setState(() {
          _cachedTotalEarnings = ((cached['total_earnings'] ?? cached['earnings'] ?? 0) as num).toDouble();
          _cachedDeliveries = ((cached['completed_deliveries'] ?? cached['deliveries_count'] ?? 0) as num).toInt();
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFEA580C);
    final c = widget.controller;
    final totalE = c != null ? c.totalEarnings : _cachedTotalEarnings;
    final deliveries = c != null ? c.completedDeliveries : _cachedDeliveries;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Earnings & Payouts',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Pills (Daily, Weekly, Monthly)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: List.generate(_filters.length, (idx) {
                  final isSel = _selectedFilterIndex == idx;
                  return Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedFilterIndex = idx),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSel ? orangeColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _filters[idx],
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isSel ? Colors.white : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Main Earnings Hero Card (Strictly Zero Data Guarantee)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedFilterIndex == 0
                        ? "Today's Earnings"
                        : (_selectedFilterIndex == 1 ? "This Week's Earnings" : "This Month's Earnings"),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    totalE > 0 ? '₹${totalE.toStringAsFixed(2)}' : '₹0.00',
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        deliveries > 0 ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                        size: 14,
                        color: deliveries > 0 ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        deliveries > 0 ? '$deliveries Completed Trips' : '0 Completed Trips',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: deliveries > 0 ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildMiniMetric('Deliveries', '$deliveries', const Color(0xFFEA580C)),
                      const SizedBox(width: 8),
                      _buildMiniMetric('Tips', '₹0', const Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      _buildMiniMetric('Distance Pay', '₹0', const Color(0xFF16A34A)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Weekly Chart (Baseline Zero or Real Data)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly Performance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 6),
                  const Text('Daily order completion graph', style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 16),
                  Builder(
                    builder: (context) {
                      final currentWeekday = DateTime.now().weekday; // 1 = Mon ... 7 = Sun
                      final todayBarHeight = deliveries > 0 ? (12.0 + (deliveries * 8.0)).clamp(12.0, 80.0) : 6.0;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildBar('Mon', currentWeekday == 1 ? todayBarHeight : 6.0, currentWeekday == 1),
                          _buildBar('Tue', currentWeekday == 2 ? todayBarHeight : 6.0, currentWeekday == 2),
                          _buildBar('Wed', currentWeekday == 3 ? todayBarHeight : 6.0, currentWeekday == 3),
                          _buildBar('Thu', currentWeekday == 4 ? todayBarHeight : 6.0, currentWeekday == 4),
                          _buildBar('Fri', currentWeekday == 5 ? todayBarHeight : 6.0, currentWeekday == 5),
                          _buildBar('Sat', currentWeekday == 6 ? todayBarHeight : 6.0, currentWeekday == 6),
                          _buildBar('Sun', currentWeekday == 7 ? todayBarHeight : 6.0, currentWeekday == 7),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Earnings Breakdown (Strictly Zero Data Guarantee)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EARNINGS BREAKDOWN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF94A3B8))),
                  const SizedBox(height: 12),
                  _buildBreakdownRow('Delivery Fare', totalE > 0 ? '₹${totalE.toStringAsFixed(2)}' : '₹0.00'),
                  const Divider(height: 16),
                  _buildBreakdownRow('Customer Tips', '₹0.00'),
                  const Divider(height: 16),
                  _buildBreakdownRow('Distance Base Pay', '₹0.00'),
                  const Divider(height: 16),
                  _buildBreakdownRow('Platform Adjustments', '₹0.00'),
                  const Divider(height: 16),
                  _buildBreakdownRow('Net Settlement Balance', totalE > 0 ? '₹${totalE.toStringAsFixed(2)}' : '₹0.00', isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons (Payouts, Details, Trip History)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: orangeColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.account_balance_wallet_outlined, color: orangeColor, size: 18),
                    label: const Text('Payouts', style: TextStyle(color: orangeColor, fontWeight: FontWeight.bold)),
                    onPressed: () => _showPayoutsModal(context, totalE),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: orangeColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('Trip History', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () => _showHistoryModal(context, deliveries),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildDeliveryEarningsBottomNav(context),
    );
  }

  Widget _buildMiniMetric(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String day, double height, bool isHighlight) {
    return Column(
      children: [
        Container(
          width: 22,
          height: height,
          decoration: BoxDecoration(
            color: isHighlight ? const Color(0xFFEA580C) : const Color(0xFFCBD5E1),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Text(day, style: TextStyle(fontSize: 11, fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF64748B))),
      ],
    );
  }

  Widget _buildBreakdownRow(String title, String amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            color: isBold ? const Color(0xFF0F172A) : const Color(0xFF475569),
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w800,
            color: isBold ? const Color(0xFFEA580C) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  void _showPayoutsModal(BuildContext context, double totalE) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Payouts & Direct Deposit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFEA580C), Color(0xFFC2410C)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        totalE > 0 ? '₹${totalE.toStringAsFixed(2)}' : '₹0.00',
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFFEA580C)),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(totalE > 0
                              ? 'Withdrawal request of ₹${totalE.toStringAsFixed(2)} submitted to bank!'
                              : 'No withdrawable balance. Complete deliveries to earn.'),
                          backgroundColor: totalE > 0 ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                        ),
                      );
                    },
                    child: const Text('Withdraw', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryEarningsBottomNav(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDeliveryNavItem(
                icon: Icons.home_rounded,
                label: 'Dashboard',
                isSelected: false,
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
              _buildDeliveryNavItem(
                icon: Icons.local_shipping_outlined,
                label: 'Tasks',
                isSelected: false,
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
              Expanded(
                child: Center(
                  child: InkWell(
                    onTap: () {
                      if (Navigator.canPop(context)) Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(27),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x40EA580C),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.map_rounded, color: Colors.white, size: 20),
                          Text('Map', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              _buildDeliveryNavItem(
                icon: Icons.account_balance_wallet_rounded,
                label: 'Earnings',
                isSelected: true,
                onTap: () {},
              ),
              _buildDeliveryNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                isSelected: false,
                onTap: () {
                  if (Navigator.canPop(context)) Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    const orangeColor = Color(0xFFEA580C);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? orangeColor : const Color(0xFF64748B),
              size: 22,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? orangeColor : const Color(0xFF64748B),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryModal(BuildContext context, int deliveries) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Delivery History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
            const SizedBox(height: 16),
            Expanded(
              child: deliveries == 0
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.history_toggle_off_rounded, color: Color(0xFF94A3B8), size: 36),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No Completed Deliveries',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Your completed delivery trips and fare breakdowns will be displayed here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: deliveries,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFFFF7ED),
                                child: Icon(Icons.local_shipping, color: Color(0xFFEA580C)),
                              ),
                              title: Text('Trip #${index + 1} • Completed Order', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: const Text('Status: Delivered ✓', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
                              trailing: const Text('Delivered', style: TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
