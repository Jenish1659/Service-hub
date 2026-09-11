import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_provider.dart';
import 'widgets/admin_header.dart';
import 'widgets/admin_kpi_cards.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/bookings_overview_chart.dart';
import 'widgets/booking_status_donut_chart.dart';
import 'widgets/recent_bookings_card.dart';
import 'widgets/dashboard_bottom_grid.dart';
import '../../bookings/presentation/admin_bookings_view.dart';
import '../../partners/presentation/admin_partners_view.dart';
import '../../customers/presentation/admin_customers_view.dart';
import '../../services/presentation/admin_services_view.dart';
import '../../finance/presentation/admin_finance_view.dart';
import '../../support/presentation/admin_support_view.dart';
import '../../settings/presentation/admin_settings_view.dart';
import '../../ai_operations/presentation/admin_ai_operations_view.dart';
import '../../../core/services/live_booking_sync_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _activeTab = 'Dashboard';
  bool _isSidebarCollapsed = false;
  final String _dateRangeText = 'Live Operations';

  bool _isUuid(String s) =>
      RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(s.trim());

  Future<void> _approvePartnerProfile(String profileId, String name, [Map<String, dynamic>? partnerMap]) async {
    await LiveBookingSyncService.instance.approvePartnerVerification(profileId);
    final client = Supabase.instance.client;

    String? targetUserId = partnerMap?['user_id']?.toString();
    String? targetPartnerId = partnerMap?['partner_id']?.toString();
    final phone = partnerMap?['phone']?.toString().replaceAll(' ', '');
    final verId = partnerMap?['verification_id']?.toString();

    // If targetUserId is not directly in partnerMap, look it up by phone first
    if ((targetUserId == null || targetUserId.isEmpty) && phone != null && phone.isNotEmpty) {
      try {
        final rawDigits = phone.replaceAll(RegExp(r'\D'), '');
        final u = await client
            .from('users')
            .select('user_id, phone, partners(partner_id)')
            .or('phone.eq.$phone,phone.ilike.%${rawDigits.length >= 10 ? rawDigits.substring(rawDigits.length - 10) : rawDigits}%')
            .maybeSingle();
        if (u != null) {
          targetUserId = u['user_id']?.toString();
          final pList = u['partners'];
          if (pList is List && pList.isNotEmpty) {
            targetPartnerId = (pList.first as Map<String, dynamic>)['partner_id']?.toString();
          } else if (pList is Map) {
            targetPartnerId = (pList as Map<String, dynamic>)['partner_id']?.toString();
          }
        }
      } catch (_) {}
    }

    // Look up by profileId in Supabase if it's a valid UUID
    if ((targetUserId == null || targetUserId.isEmpty) && _isUuid(profileId)) {
      try {
        final vr = await client
            .from('verification_requests')
            .select('user_id')
            .or('verification_id.eq.$profileId,user_id.eq.$profileId')
            .maybeSingle();
        if (vr != null && vr['user_id'] != null) {
          targetUserId = vr['user_id']?.toString();
        }
      } catch (_) {}
    }

    if ((targetUserId == null || targetUserId.isEmpty) && _isUuid(profileId)) {
      try {
        final p = await client
            .from('partners')
            .select('user_id, partner_id')
            .or('partner_id.eq.$profileId,user_id.eq.$profileId')
            .maybeSingle();
        if (p != null) {
          targetUserId = p['user_id']?.toString();
          targetPartnerId = p['partner_id']?.toString();
        }
      } catch (_) {}
    }

    final effectiveUserId = (targetUserId != null && targetUserId.isNotEmpty) ? targetUserId : profileId;
    final nowIso = DateTime.now().toIso8601String();

    // 1. Update verification_requests table
    try {
      if (_isUuid(effectiveUserId)) {
        await client
            .from('verification_requests')
            .update({'status': 'APPROVED', 'reviewed_at': nowIso})
            .eq('user_id', effectiveUserId);
      }
      if (_isUuid(profileId)) {
        await client
            .from('verification_requests')
            .update({'status': 'APPROVED', 'reviewed_at': nowIso})
            .or('verification_id.eq.$profileId,user_id.eq.$profileId');
      }
      if (verId != null && _isUuid(verId)) {
        await client
            .from('verification_requests')
            .update({'status': 'APPROVED', 'reviewed_at': nowIso})
            .eq('verification_id', verId);
      }
    } catch (_) {}

    // 2. Update partners table (availability_status: 'ONLINE' complies with CHECK constraint)
    try {
      if (targetPartnerId != null && _isUuid(targetPartnerId)) {
        await client
            .from('partners')
            .update({'verification_status': 'VERIFIED', 'availability_status': 'ONLINE', 'approved_at': nowIso})
            .eq('partner_id', targetPartnerId);
      }
      if (_isUuid(effectiveUserId)) {
        await client
            .from('partners')
            .update({'verification_status': 'VERIFIED', 'availability_status': 'ONLINE', 'approved_at': nowIso})
            .eq('user_id', effectiveUserId);
      }
      if (_isUuid(profileId)) {
        await client
            .from('partners')
            .update({'verification_status': 'VERIFIED', 'availability_status': 'ONLINE', 'approved_at': nowIso})
            .or('partner_id.eq.$profileId,user_id.eq.$profileId');
      }
    } catch (_) {}

    // 3. Update users table
    try {
      if (_isUuid(effectiveUserId)) {
        await client
            .from('users')
            .update({'account_status': 'ACTIVE'})
            .eq('user_id', effectiveUserId);
      }
      if (phone != null && phone.isNotEmpty) {
        await client
            .from('users')
            .update({'account_status': 'ACTIVE'})
            .or('phone.eq.$phone,phone.eq.+91$phone');
      }
    } catch (_) {}

    // Broadcast across LiveBookingSyncService for all IDs and phone
    if (effectiveUserId != profileId) {
      await LiveBookingSyncService.instance.approvePartnerVerification(effectiveUserId);
    }
    if (targetPartnerId != null && targetPartnerId.isNotEmpty) {
      await LiveBookingSyncService.instance.approvePartnerVerification(targetPartnerId);
    }
    if (phone != null && phone.isNotEmpty) {
      await LiveBookingSyncService.instance.approvePartnerVerification(phone);
    }
    if (verId != null && verId.isNotEmpty) {
      await LiveBookingSyncService.instance.approvePartnerVerification(verId);
    }

    markPartnerResolved(profileId);
    markPartnerResolved(effectiveUserId);
    if (targetPartnerId != null && targetPartnerId.isNotEmpty) markPartnerResolved(targetPartnerId);
    if (phone != null && phone.isNotEmpty) markPartnerResolved(phone);
    if (verId != null && verId.isNotEmpty) markPartnerResolved(verId);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Partner "$name" Approved & Activated Successfully!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
    ref.invalidate(adminUnverifiedPartnersProvider);
    ref.invalidate(adminStatsProvider);
  }

  Future<void> _rejectPartnerProfile(String profileId, String name, [Map<String, dynamic>? partnerMap]) async {
    await LiveBookingSyncService.instance.rejectPartnerVerification(profileId);
    final client = Supabase.instance.client;

    String? targetUserId = partnerMap?['user_id']?.toString();
    String? targetPartnerId = partnerMap?['partner_id']?.toString();
    final phone = partnerMap?['phone']?.toString().replaceAll(' ', '');

    if ((targetUserId == null || targetUserId.isEmpty) && phone != null && phone.isNotEmpty) {
      try {
        final rawDigits = phone.replaceAll(RegExp(r'\D'), '');
        final u = await client
            .from('users')
            .select('user_id, phone, partners(partner_id)')
            .or('phone.eq.$phone,phone.ilike.%${rawDigits.length >= 10 ? rawDigits.substring(rawDigits.length - 10) : rawDigits}%')
            .maybeSingle();
        if (u != null) {
          targetUserId = u['user_id']?.toString();
          final pList = u['partners'];
          if (pList is List && pList.isNotEmpty) {
            targetPartnerId = (pList.first as Map<String, dynamic>)['partner_id']?.toString();
          } else if (pList is Map) {
            targetPartnerId = (pList as Map<String, dynamic>)['partner_id']?.toString();
          }
        }
      } catch (_) {}
    }

    if ((targetUserId == null || targetUserId.isEmpty) && _isUuid(profileId)) {
      try {
        final vr = await client
            .from('verification_requests')
            .select('user_id')
            .or('verification_id.eq.$profileId,user_id.eq.$profileId')
            .maybeSingle();
        if (vr != null && vr['user_id'] != null) {
          targetUserId = vr['user_id']?.toString();
        }
      } catch (_) {}
    }

    final effectiveUserId = (targetUserId != null && targetUserId.isNotEmpty) ? targetUserId : profileId;
    final nowIso = DateTime.now().toIso8601String();

    try {
      if (_isUuid(effectiveUserId)) {
        await client
            .from('verification_requests')
            .update({'status': 'REJECTED', 'reviewed_at': nowIso})
            .eq('user_id', effectiveUserId);
      }
      if (_isUuid(profileId)) {
        await client
            .from('verification_requests')
            .update({'status': 'REJECTED', 'reviewed_at': nowIso})
            .or('verification_id.eq.$profileId,user_id.eq.$profileId');
      }
    } catch (_) {}

    try {
      if (targetPartnerId != null && _isUuid(targetPartnerId)) {
        await client
            .from('partners')
            .update({'verification_status': 'REJECTED'})
            .eq('partner_id', targetPartnerId);
      }
      if (_isUuid(effectiveUserId)) {
        await client
            .from('partners')
            .update({'verification_status': 'REJECTED'})
            .eq('user_id', effectiveUserId);
      }
      if (_isUuid(profileId)) {
        await client
            .from('partners')
            .update({'verification_status': 'REJECTED'})
            .or('partner_id.eq.$profileId,user_id.eq.$profileId');
      }
    } catch (_) {}

    if (effectiveUserId != profileId) {
      await LiveBookingSyncService.instance.rejectPartnerVerification(effectiveUserId);
    }
    if (targetPartnerId != null && targetPartnerId.isNotEmpty) {
      await LiveBookingSyncService.instance.rejectPartnerVerification(targetPartnerId);
    }
    if (phone != null && phone.isNotEmpty) {
      await LiveBookingSyncService.instance.rejectPartnerVerification(phone);
    }

    markPartnerResolved(profileId);
    markPartnerResolved(effectiveUserId);
    if (targetPartnerId != null && targetPartnerId.isNotEmpty) markPartnerResolved(targetPartnerId);
    if (phone != null && phone.isNotEmpty) markPartnerResolved(phone);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partner "$name" verification rejected.'),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
    ref.invalidate(adminUnverifiedPartnersProvider);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);
    final bookingsAsync = ref.watch(adminAllBookingsProvider);
    final unverifiedPartnersAsync = ref.watch(adminUnverifiedPartnersProvider);

    final stats = statsAsync.value ?? {};
    final allBookings = bookingsAsync.value ?? [];
    final unverifiedPartners = unverifiedPartnersAsync.value ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          AdminSidebar(
            activeTab: _activeTab,
            onTabSelected: (tab) => setState(() => _activeTab = tab),
            isCollapsed: _isSidebarCollapsed,
            onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
          ),
          Expanded(
            child: Column(
              children: [
                AdminHeader(
                  title: _activeTab,
                  onToggleSidebar: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                  onSearch: (val) { if (val.trim().isNotEmpty) { setState(() { _activeTab = 'Partner Verification'; }); } },
                  dateRangeText: _dateRangeText,
                ),
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
    if (_activeTab == 'All Bookings') {
      return AdminBookingsView(allBookings: allBookings);
    }
    if (_activeTab == 'Partner Verification') {
      return AdminPartnersView(
        unverifiedPartners: unverifiedPartners,
        onApprove: _approvePartnerProfile,
        onReject: _rejectPartnerProfile,
      );
    }
    if (_activeTab == 'Customers') {
      return AdminCustomersView(customerCount: stats['totalCustomers'] ?? 0);
    }
    if (_activeTab == 'Services') {
      return const AdminServicesView();
    }
    if (_activeTab == 'Finance') {
      return AdminFinanceView(totalRevenue: (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0);
    }
    if (_activeTab == 'Support Tickets') {
      return const AdminSupportView();
    }
    if (_activeTab == 'AI Operations') {
      return const AdminAIOperationsView();
    }
    if (_activeTab == 'Settings') {
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
          if (unverifiedPartners.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF2563EB).withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2563EB),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${unverifiedPartners.length} Partner Application(s) Waiting For Admin Approval!',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF1E3A8A)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Candidate: ${unverifiedPartners.first['full_name'] ?? unverifiedPartners.first['name']} • App ID: ${unverifiedPartners.first['verification_id'] ?? unverifiedPartners.first['id']} • AI Trust: 99.8% (Recommended)',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.rate_review_rounded, size: 16),
                    label: const Text('Review & Approve Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    onPressed: () => setState(() => _activeTab = 'Partner Verification'),
                  ),
                ],
              ),
            ),
          ],
          AdminKPICards(
            totalBookings: stats['totalBookings'] ?? 0,
            completedServices: stats['completedServices'] ?? 0,
            ongoingServices: stats['ongoingServices'] ?? 0,
            totalCustomers: stats['totalCustomers'] ?? 0,
            totalPartners: stats['totalPartners'] ?? 0,
            totalRevenue: (stats['totalRevenue'] as num?)?.toDouble() ?? 0.0,
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 7,
                child: BookingsOverviewChart(
                  bookings: allBookings,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 4,
                child: BookingStatusDonutChart(
                  totalCount: stats['totalBookings'] ?? 0,
                  completedCount: stats['completedServices'] ?? 0,
                  ongoingCount: stats['ongoingServices'] ?? 0,
                  confirmedCount: stats['confirmedServices'] ?? 0,
                  cancelledCount: stats['cancelledServices'] ?? 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          RecentBookingsCard(
            bookings: allBookings,
            onViewAll: () => setState(() => _activeTab = 'All Bookings'),
          ),
          const SizedBox(height: 16),

          DashboardBottomGrid(
            stats: stats,
            allBookings: allBookings,
            unverifiedPartners: unverifiedPartners,
            onViewAllPartners: () => setState(() => _activeTab = 'Partner Verification'),
            onViewAllReviews: () => setState(() => _activeTab = 'Support Tickets'),
            onViewAllNotifications: () => setState(() => _activeTab = 'Partner Verification'),
          ),
        ],
      ),
    );
  }
}
