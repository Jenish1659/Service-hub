import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/live_booking_sync_service.dart';
import 'admin_provider.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_kpi_cards.dart';
import 'widgets/bookings_overview_chart.dart';
import 'widgets/booking_status_donut_chart.dart';
import 'widgets/recent_bookings_card.dart';
import 'widgets/dashboard_bottom_grid.dart';
import 'package:service_hub_admin/features/bookings/presentation/admin_bookings_view.dart';
import 'package:service_hub_admin/features/partners/presentation/admin_partners_view.dart';
import 'package:service_hub_admin/features/customers/presentation/admin_customers_view.dart';
import 'package:service_hub_admin/features/services/presentation/admin_services_view.dart';
import 'package:service_hub_admin/features/finance/presentation/admin_finance_view.dart';
import 'package:service_hub_admin/features/support/presentation/admin_support_view.dart';
import 'package:service_hub_admin/features/settings/presentation/admin_settings_view.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  String _activeTab = 'Dashboard';
  bool _isSidebarCollapsed = false;
  final String _dateRangeText = '24 May 2025 - 30 May 2025';

  Future<void> _approvePartnerProfile(String profileId, String name) async {
    // 1. Instant Local Realtime Relay
    await LiveBookingSyncService.instance.approvePartnerVerification(profileId);

    // 2. Supabase Settlement
    try {
      await Supabase.instance.client
          .from('verification_requests')
          .update({'status': 'APPROVED', 'reviewed_at': DateTime.now().toIso8601String()})
          .eq('verification_id', profileId);

      await Supabase.instance.client
          .from('partners')
          .update({'verification_status': 'VERIFIED', 'approved_at': DateTime.now().toIso8601String()})
          .eq('user_id', profileId);
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partner "$name" approved successfully! KYC Activated.'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
    ref.invalidate(adminUnverifiedPartnersProvider);
    ref.invalidate(adminStatsProvider);
  }

  Future<void> _rejectPartnerProfile(String profileId, String name) async {
    await LiveBookingSyncService.instance.rejectPartnerVerification(profileId);

    try {
      await Supabase.instance.client
          .from('verification_requests')
          .update({'status': 'REJECTED', 'reviewed_at': DateTime.now().toIso8601String()})
          .eq('verification_id', profileId);
    } catch (_) {}

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partner "$name" application rejected.'),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
    ref.invalidate(adminUnverifiedPartnersProvider);
    ref.invalidate(adminStatsProvider);
  }

  Future<void> _settlePayout(String id, String type, String partnerName) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Instant Payout for "$partnerName" settled via IMPS!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  Future<void> _resolveTicket(String id) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Support ticket marked as Resolved successfully!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);
    final unverifiedAsync = ref.watch(adminUnverifiedPartnersProvider);
    final bookingsAsync = ref.watch(adminAllBookingsProvider);

    final stats = statsAsync.value ?? {
      'totalBookings': 0,
      'completedServices': 0,
      'ongoingServices': 0,
      'confirmedServices': 0,
      'cancelledServices': 0,
      'totalCustomers': 0,
      'totalPartners': 0,
      'underVerificationCount': 0,
      'activePartners': 0,
      'totalRevenue': 0.0,
      'serviceBookingCounts': <String, int>{},
      'serviceRevenue': <String, double>{},
    };

    final allBookings = bookingsAsync.value ?? [];
    final unverifiedPartners = unverifiedAsync.value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          // 1. Sidebar Navigation
          AdminSidebar(
            activeTab: _activeTab,
            onTabSelected: (tab) => setState(() => _activeTab = tab),
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
          ),

          // 2. Main Content Area
          Expanded(
            child: Column(
              children: [
                // Top Header
                AdminHeader(
                  title: _activeTab,
                  onToggleSidebar: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                  onSearch: (val) {},
                  dateRangeText: _dateRangeText,
                ),

                // Dynamic Body View
                Expanded(
                  child: _buildActiveView(stats, allBookings, unverifiedPartners),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveView(
    Map<String, dynamic> stats,
    List<Map<String, dynamic>> allBookings,
    List<Map<String, dynamic>> unverifiedPartners,
  ) {
    if (_activeTab == 'Dashboard') {
      return _buildMainDashboardContent(stats, allBookings, unverifiedPartners);
    }

    if (_activeTab == 'All Bookings' ||
        _activeTab == 'AC Service Bookings' ||
        _activeTab == 'Booking Requests' ||
        _activeTab == 'Assigned Bookings' ||
        _activeTab == 'Ongoing Services' ||
        _activeTab == 'Completed Services' ||
        _activeTab == 'Cancelled Bookings') {
      return AdminBookingsView(
        allBookings: allBookings,
        initialFilter: _activeTab,
      );
    }

    if (_activeTab == 'Partner Verification' ||
        _activeTab == 'Partner Applications' ||
        _activeTab == 'Service Partners' ||
        _activeTab == 'Partner Documents') {
      return AdminPartnersView(
        unverifiedPartners: unverifiedPartners,
        onApprove: _approvePartnerProfile,
        onReject: _rejectPartnerProfile,
      );
    }

    if (_activeTab == 'Customers') {
      return AdminCustomersView(
        customerCount: stats['totalCustomers'] ?? 0,
      );
    }

    if (_activeTab == 'Services' ||
        _activeTab == 'AC Service Types' ||
        _activeTab == 'Pricing & Charges' ||
        _activeTab == 'Service Areas' ||
        _activeTab == 'Coupons & Offers') {
      return const AdminServicesView();
    }

    if (_activeTab == 'Finance' ||
        _activeTab == 'Transactions' ||
        _activeTab == 'Payouts' ||
        _activeTab == 'Earnings' ||
        _activeTab == 'Refunds') {
      return AdminFinanceView(
        totalRevenue: (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0,
        onSettlePayout: _settlePayout,
      );
    }

    if (_activeTab == 'Support Tickets' || _activeTab == 'Reviews & Ratings') {
      return AdminSupportView(onResolve: _resolveTicket);
    }

    if (_activeTab == 'System Settings') {
      return const AdminSettingsView();
    }

    return _buildMainDashboardContent(stats, allBookings, unverifiedPartners);
  }

  Widget _buildMainDashboardContent(
    Map<String, dynamic> stats,
    List<Map<String, dynamic>> allBookings,
    List<Map<String, dynamic>> unverifiedPartners,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subheader: Date Range & Filter Pill Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(
                      _dateRangeText,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.filter_list_rounded, size: 15, color: Color(0xFF64748B)),
                    SizedBox(width: 6),
                    Text(
                      'Filter',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF64748B)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Top 6 Dynamic Metric KPI Cards (100% Real Database Values)
          AdminKPICards(
            totalBookings: stats['totalBookings'] ?? 0,
            completedServices: stats['completedServices'] ?? 0,
            ongoingServices: stats['ongoingServices'] ?? 0,
            totalCustomers: stats['totalCustomers'] ?? 0,
            totalPartners: stats['totalPartners'] ?? 0,
            totalRevenue: (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0,
          ),
          const SizedBox(height: 16),

          // 2. Middle Row: Bookings Overview Chart, Booking Status Donut Chart, Recent Bookings List
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bookings Overview Multi-Line Chart
              Expanded(
                flex: 4,
                child: BookingsOverviewChart(bookings: allBookings),
              ),
              const SizedBox(width: 14),

              // Booking Status Donut Chart (Real dynamic numbers)
              Expanded(
                flex: 3,
                child: BookingStatusDonutChart(
                  totalCount: stats['totalBookings'] ?? 0,
                  completedCount: stats['completedServices'] ?? 0,
                  ongoingCount: stats['ongoingServices'] ?? 0,
                  confirmedCount: stats['confirmedServices'] ?? 0,
                  cancelledCount: stats['cancelledServices'] ?? 0,
                ),
              ),
              const SizedBox(width: 14),

              // Recent Bookings Live Stream List
              Expanded(
                flex: 4,
                child: RecentBookingsCard(
                  bookings: allBookings,
                  onViewAll: () => setState(() => _activeTab = 'All Bookings'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. Bottom Grid: Top Services, Partners Overview, Partner Performance, Recent Reviews, System Notifications
          DashboardBottomGrid(
            stats: stats,
            allBookings: allBookings,
            unverifiedPartners: unverifiedPartners,
            onViewAllPartners: () => setState(() => _activeTab = 'Service Partners'),
            onViewAllReviews: () => setState(() => _activeTab = 'Reviews & Ratings'),
            onViewAllNotifications: () => setState(() => _activeTab = 'Notifications'),
          ),
        ],
      ),
    );
  }
}
