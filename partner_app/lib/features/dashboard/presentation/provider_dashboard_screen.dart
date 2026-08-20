import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/storage/local_registration_cache.dart';
import 'ac_provider_dashboard_controller.dart';

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  ConsumerState<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends ConsumerState<ProviderDashboardScreen> {
  int _currentBottomNavIndex = 0;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }

  String _formatCurrency(double value) {
    final format = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    return format.format(value);
  }

  void _showTimeframePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select Timeframe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('This Month'),
                  trailing: ref.watch(acProviderDashboardProvider).timeframe == 'This Month'
                      ? const Icon(Icons.check, color: Color(0xFF2563EB))
                      : null,
                  onTap: () {
                    ref.read(acProviderDashboardProvider.notifier).setTimeframe('This Month');
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('This Week'),
                  trailing: ref.watch(acProviderDashboardProvider).timeframe == 'This Week'
                      ? const Icon(Icons.check, color: Color(0xFF2563EB))
                      : null,
                  onTap: () {
                    ref.read(acProviderDashboardProvider.notifier).setTimeframe('This Week');
                    Navigator.pop(ctx);
                  },
                ),
                ListTile(
                  title: const Text('All Time'),
                  trailing: ref.watch(acProviderDashboardProvider).timeframe == 'All Time'
                      ? const Icon(Icons.check, color: Color(0xFF2563EB))
                      : null,
                  onTap: () {
                    ref.read(acProviderDashboardProvider.notifier).setTimeframe('All Time');
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showLiveOffersModal(BuildContext context, ACProviderDashboardState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '⚡ Live AC Service Requests',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${state.incomingOffers.length} NEW',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (state.incomingOffers.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.radar_rounded, color: Color(0xFF94A3B8), size: 48),
                        SizedBox(height: 12),
                        Text(
                          'No pending service requests',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF475569)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Keep your status Online to receive instant alerts when customers book AC services.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: state.incomingOffers.length,
                    itemBuilder: (c, idx) {
                      final offer = state.incomingOffers[idx];
                      final serviceName = offer['service_name'] ?? 'AC Jet Cleaning';
                      final price = (offer['price'] as num?)?.toDouble() ?? 599.0;
                      final customerAddress = offer['customer_address'] ?? 'Digvijay Plot, Jamnagar';

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFF2563EB), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2563EB).withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDBEAFE),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    serviceName,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                                  ),
                                ),
                                Text(
                                  '₹${price.toStringAsFixed(0)}',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.location_on_outlined, size: 15, color: Color(0xFF64748B)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    customerAddress,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      ref.read(acProviderDashboardProvider.notifier).declineOffer(offer);
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('DECLINE', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF2563EB),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      ref.read(acProviderDashboardProvider.notifier).acceptOffer(offer);
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('✓ AC Service Job Accepted! Added to Active Jobs.'),
                                          backgroundColor: Color(0xFF10B981),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    child: const Text('ACCEPT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(acProviderDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildCustomHeader(context, dashboardState),
      drawer: _buildAppDrawer(context, dashboardState),
      body: dashboardState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(acProviderDashboardProvider.notifier).initDashboard(),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. ONLINE STATUS TOGGLE CARD
                        _buildOnlineStatusCard(dashboardState),
                        const SizedBox(height: 18),

                        // 2. LIVE REQUESTS BANNER (If pending offers exist)
                        if (dashboardState.incomingOffers.isNotEmpty) ...[
                          _buildLiveOffersBanner(dashboardState),
                          const SizedBox(height: 18),
                        ],

                        // 3. INCOME SUMMARY SECTION (4 CARDS)
                        _buildIncomeSummarySection(dashboardState),
                        const SizedBox(height: 22),

                        // 4. TODAY'S WORK OVERVIEW SECTION (2 CARDS WITH WATERMARKS)
                        _buildWorkOverviewSection(dashboardState),
                        const SizedBox(height: 22),

                        // 5. BUSINESS OVERVIEW SECTION (4 CARDS WITH TIMEFRAME SELECTOR)
                        _buildBusinessOverviewSection(dashboardState),
                        const SizedBox(height: 22),

                        // 6. COMPLETED JOBS – TODAY SECTION
                        _buildCompletedJobsSection(dashboardState),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _buildElevatedBottomNav(context, dashboardState),
    );
  }

  // --- 1. Custom App Bar matching exact image ---
  PreferredSizeWidget _buildCustomHeader(BuildContext context, ACProviderDashboardState state) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 26),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '${_getGreeting()}, ${state.providerName}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 4),
              const Text('👋', style: TextStyle(fontSize: 15)),
            ],
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  state.businessName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.verified_rounded,
                color: Color(0xFF0052CC),
                size: 15,
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Notification bell with red badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF0F172A), size: 24),
              onPressed: () {
                if (state.incomingOffers.isNotEmpty) {
                  _showLiveOffersModal(context, state);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No new alerts. Your AC Service Hub is active.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
            if (state.unreadNotificationsCount > 0 || state.incomingOffers.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text(
                      '${state.incomingOffers.isNotEmpty ? state.incomingOffers.length : state.unreadNotificationsCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),

        // Profile Avatar
        Padding(
          padding: const EdgeInsets.only(right: 14, left: 2),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF0052CC),
              border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
            ),
            child: const Center(
              child: Icon(Icons.person, color: Colors.white, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  // --- 2. Online Status Card ---
  Widget _buildOnlineStatusCard(ACProviderDashboardState state) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: state.isOnline ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                  boxShadow: state.isOnline
                      ? [
                          BoxShadow(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.isOnline ? 'You are Online' : 'You are Offline',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.isOnline ? 'Customers can book services' : 'You will not receive new bookings',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: state.isOnline,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF0052CC),
            onChanged: (val) {
              ref.read(acProviderDashboardProvider.notifier).toggleOnlineStatus(val);
            },
          ),
        ],
      ),
    );
  }

  // --- Live Offers Banner ---
  Widget _buildLiveOffersBanner(ACProviderDashboardState state) {
    return InkWell(
      onTap: () => _showLiveOffersModal(context, state),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF3B82F6), width: 1.2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF2563EB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${state.incomingOffers.length} New Live AC Booking Request${state.incomingOffers.length > 1 ? "s" : ""} Available!',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
                  ),
                  const Text('Tap to review and accept nearby jobs', style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6))),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF2563EB)),
          ],
        ),
      ),
    );
  }

  // --- 3. Income Summary Section (4 Cards) ---
  Widget _buildIncomeSummarySection(ACProviderDashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Income Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Detailed Earnings Report is up to date.')),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0052CC),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, color: Color(0xFF0052CC), size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // 4 Horizontal / Grid Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isSmall = constraints.maxWidth < 600;

            if (isSmall) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildIncomeCard(
                      icon: Icons.account_balance_wallet_rounded,
                      iconBg: const Color(0xFFDBEAFE),
                      iconColor: const Color(0xFF2563EB),
                      title: "Today's Income",
                      amount: _formatCurrency(state.todayIncome),
                      badgeText: state.todayIncomeTrend,
                      isPositive: true,
                      width: 140,
                    ),
                    const SizedBox(width: 10),
                    _buildIncomeCard(
                      icon: Icons.calendar_month_rounded,
                      iconBg: const Color(0xFFDCFCE7),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Monthly Income',
                      amount: _formatCurrency(state.monthlyIncome),
                      badgeText: state.monthlyIncomeTrend,
                      isPositive: true,
                      width: 140,
                    ),
                    const SizedBox(width: 10),
                    _buildIncomeCard(
                      icon: Icons.layers_rounded,
                      iconBg: const Color(0xFFF3E8FF),
                      iconColor: const Color(0xFF9333EA),
                      title: 'Total Income',
                      amount: _formatCurrency(state.totalIncome),
                      badgeText: 'All Time',
                      isSubtext: true,
                      width: 140,
                    ),
                    const SizedBox(width: 10),
                    _buildIncomeCard(
                      icon: Icons.insert_chart_rounded,
                      iconBg: const Color(0xFFFFEDD5),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Avg. Income / Month',
                      amount: _formatCurrency(state.avgIncomePerMonth),
                      badgeText: 'All Time',
                      isSubtext: true,
                      width: 150,
                    ),
                  ],
                ),
              );
            }

            return Row(
              children: [
                Expanded(
                  child: _buildIncomeCard(
                    icon: Icons.account_balance_wallet_rounded,
                    iconBg: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF2563EB),
                    title: "Today's Income",
                    amount: _formatCurrency(state.todayIncome),
                    badgeText: state.todayIncomeTrend,
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildIncomeCard(
                    icon: Icons.calendar_month_rounded,
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF16A34A),
                    title: 'Monthly Income',
                    amount: _formatCurrency(state.monthlyIncome),
                    badgeText: state.monthlyIncomeTrend,
                    isPositive: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildIncomeCard(
                    icon: Icons.layers_rounded,
                    iconBg: const Color(0xFFF3E8FF),
                    iconColor: const Color(0xFF9333EA),
                    title: 'Total Income',
                    amount: _formatCurrency(state.totalIncome),
                    badgeText: 'All Time',
                    isSubtext: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildIncomeCard(
                    icon: Icons.insert_chart_rounded,
                    iconBg: const Color(0xFFFFEDD5),
                    iconColor: const Color(0xFFEA580C),
                    title: 'Avg. Income / Month',
                    amount: _formatCurrency(state.avgIncomePerMonth),
                    badgeText: 'All Time',
                    isSubtext: true,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildIncomeCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String amount,
    required String badgeText,
    bool isPositive = false,
    bool isSubtext = false,
    double? width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          if (isSubtext)
            Text(
              badgeText,
              style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            )
          else
            Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  size: 11,
                  color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 2),
                Flexible(
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // --- 4. Today's Work Overview Section (2 Cards) ---
  Widget _buildWorkOverviewSection(ACProviderDashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Today's Work Overview",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Viewing complete job history.')),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'View All',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0052CC),
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, color: Color(0xFF0052CC), size: 16),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 1: Completed / Accepted Jobs
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Stack(
                  children: [
                    // Watermark Clipboard Icon
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: Icon(
                        Icons.assignment_outlined,
                        size: 70,
                        color: const Color(0xFF16A34A).withValues(alpha: 0.08),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 18),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Completed / Accepted Jobs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${state.completedAcceptedJobsToday}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.arrow_upward_rounded, color: Color(0xFF16A34A), size: 12),
                            const SizedBox(width: 2),
                            Text(
                              state.completedJobsTrend,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Card 2: Declined Jobs
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFFEE2E2)),
                ),
                child: Stack(
                  children: [
                    // Watermark Cancelled Clipboard Icon
                    Positioned(
                      right: -6,
                      bottom: -6,
                      child: Icon(
                        Icons.assignment_late_outlined,
                        size: 70,
                        color: const Color(0xFFDC2626).withValues(alpha: 0.08),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 18),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Declined Jobs',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${state.declinedJobsToday}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.arrow_downward_rounded, color: Color(0xFFDC2626), size: 12),
                            const SizedBox(width: 2),
                            Text(
                              state.declinedJobsTrend,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- 5. Business Overview Section (4 Cards) ---
  Widget _buildBusinessOverviewSection(ACProviderDashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Business Overview',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () => _showTimeframePicker(context),
              child: Row(
                children: [
                  Text(
                    state.timeframe,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0052CC),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF0052CC), size: 18),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Card 1: Total Jobs Completed
            Expanded(
              child: _buildBusinessCard(
                icon: Icons.business_center_rounded,
                iconBg: const Color(0xFFEFF6FF),
                iconColor: const Color(0xFF2563EB),
                title: 'Total Jobs Completed',
                value: '${state.totalJobsCompleted}',
                trendText: state.totalJobsTrend,
                isPositive: true,
              ),
            ),
            const SizedBox(width: 8),

            // Card 2: Total Customers
            Expanded(
              child: _buildBusinessCard(
                icon: Icons.people_alt_rounded,
                iconBg: const Color(0xFFF0FDF4),
                iconColor: const Color(0xFF16A34A),
                title: 'Total Customers',
                value: '${state.totalCustomers}',
                trendText: state.totalCustomersTrend,
                isPositive: true,
              ),
            ),
            const SizedBox(width: 8),

            // Card 3: Customer Rating
            Expanded(
              child: _buildBusinessCard(
                icon: Icons.star_rounded,
                iconBg: const Color(0xFFFAF5FF),
                iconColor: const Color(0xFF9333EA),
                title: 'Customer Rating',
                value: state.customerRating.toStringAsFixed(1),
                trendText: state.ratingTrend,
                isPositive: true,
              ),
            ),
            const SizedBox(width: 8),

            // Card 4: Repeat Customers
            Expanded(
              child: _buildBusinessCard(
                icon: Icons.sync_rounded,
                iconBg: const Color(0xFFFFF7ED),
                iconColor: const Color(0xFFEA580C),
                title: 'Repeat Customers',
                value: '${state.repeatCustomers}',
                trendText: state.repeatCustomersTrend,
                isPositive: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBusinessCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String trendText,
    bool isPositive = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 9.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                size: 10,
                color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
              ),
              const SizedBox(width: 2),
              Flexible(
                child: Text(
                  trendText,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 6. Completed Jobs – Today Section ---
  Widget _buildCompletedJobsSection(ACProviderDashboardState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Completed Jobs – Today',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
            InkWell(
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Showing all completed tasks for today.')),
                );
              },
              child: const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0052CC),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (state.todayCompletedJobs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hvac_rounded, color: Color(0xFF0052CC), size: 36),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No jobs completed today yet',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Stay online to receive live AC installation, deep cleaning & repair requests from nearby customers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
                ),
              ],
            ),
          )
        else
          Column(
            children: state.todayCompletedJobs.map((job) => _buildCompletedJobCard(job)).toList(),
          ),
      ],
    );
  }

  Widget _buildCompletedJobCard(Map<String, dynamic> job) {
    final customerName = job['customer_name'] ?? 'Customer';
    final customerPhone = job['customer_phone'] ?? '+91 98765 43210';
    final customerArea = job['customer_area'] ?? job['customer_address'] ?? 'Gondal Road, Rajkot';
    final serviceName = job['service_name'] ?? 'AC Deep Cleaning';
    final completedAt = job['completed_at'] ?? '10:45 AM';
    final price = (job['price'] as num?)?.toDouble() ?? 650.0;
    final rating = (job['rating'] as num?)?.toDouble() ?? 5.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Customer Avatar
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.person, color: Color(0xFF2563EB), size: 20),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Customer Details
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customerName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.phone, size: 10, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        customerPhone,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 10, color: Color(0xFF64748B)),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        customerArea,
                        style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // 3. Service Column
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Service', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                const SizedBox(height: 1),
                Text(
                  serviceName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text('Completed At\n$completedAt', style: const TextStyle(fontSize: 9.5, color: Color(0xFF64748B))),
              ],
            ),
          ),

          // 4. Amount & Paid Badge
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Amount', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
                const SizedBox(height: 1),
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                const Row(
                  children: [
                    Text('Payment', style: TextStyle(fontSize: 8.5, color: Color(0xFF94A3B8))),
                  ],
                ),
                const Row(
                  children: [
                    Text('Paid ', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 10),
                  ],
                ),
              ],
            ),
          ),

          // 5. Rating & Call Actions
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Rating', style: TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8))),
              const SizedBox(height: 1),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  // Call Action Button
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Calling customer $customerName ($customerPhone)...'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.phone, color: Color(0xFF2563EB), size: 12),
                          SizedBox(width: 3),
                          Text('Call', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.more_vert, color: Color(0xFF94A3B8), size: 16),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- 7. Elevated Center Bottom Navigation Bar ---
  Widget _buildElevatedBottomNav(BuildContext context, ACProviderDashboardState state) {
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
              // 1. Dashboard Tab
              _buildBottomNavItem(
                icon: Icons.home_rounded,
                label: 'Dashboard',
                isSelected: _currentBottomNavIndex == 0,
                onTap: () => setState(() => _currentBottomNavIndex = 0),
              ),

              // 2. Jobs Tab
              _buildBottomNavItem(
                icon: Icons.business_center_outlined,
                label: 'Jobs',
                isSelected: _currentBottomNavIndex == 1,
                onTap: () {
                  setState(() => _currentBottomNavIndex = 1);
                  _showLiveOffersModal(context, state);
                },
              ),

              // 3. Elevated Centered Map FAB Button
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Map View: Live GPS Service Coverage Active.')),
                  );
                },
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x402563EB),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_rounded, color: Colors.white, size: 22),
                      Text('Map', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              // 4. Earnings Tab
              _buildBottomNavItem(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Earnings',
                isSelected: _currentBottomNavIndex == 3,
                onTap: () {
                  setState(() => _currentBottomNavIndex = 3);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Total AC Service Income: ${_formatCurrency(state.totalIncome)}'),
                    ),
                  );
                },
              ),

              // 5. Profile Tab
              _buildBottomNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                isSelected: _currentBottomNavIndex == 4,
                onTap: () {
                  setState(() => _currentBottomNavIndex = 4);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Logged in as ${state.providerName} (${state.businessName})'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? const Color(0xFF0052CC) : const Color(0xFF64748B),
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF0052CC) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // --- App Drawer ---
  Widget _buildAppDrawer(BuildContext context, ACProviderDashboardState state) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              color: const Color(0xFF0052CC),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Icon(Icons.hvac_rounded, color: Color(0xFF0052CC), size: 28),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        state.providerName,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.verified, color: Colors.white, size: 16),
                    ],
                  ),
                  Text(
                    state.businessName,
                    style: const TextStyle(fontSize: 13, color: Colors.white70),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text('AC Service Technician', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_outlined, color: Color(0xFF0052CC)),
              title: const Text('AC Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.flash_on_rounded, color: Color(0xFF0052CC)),
              title: const Text('Live Booking Requests'),
              trailing: state.incomingOffers.isNotEmpty
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                      child: Text('${state.incomingOffers.length}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                _showLiveOffersModal(context, state);
              },
            ),
            ListTile(
              leading: const Icon(Icons.refresh_rounded, color: Color(0xFF0052CC)),
              title: const Text('Refresh Live Metrics'),
              onTap: () {
                Navigator.pop(context);
                ref.read(acProviderDashboardProvider.notifier).initDashboard();
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFDC2626)),
              title: const Text('Sign Out', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold)),
              onTap: () async {
                Navigator.pop(context);
                await LocalRegistrationCache.logout();
                if (context.mounted) {
                  context.go('/role-selection');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
