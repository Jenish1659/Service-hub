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
import '../../products/presentation/admin_products_view.dart';
import '../../finance/presentation/admin_finance_view.dart';
import '../../support/presentation/admin_support_view.dart';
import '../../settings/presentation/admin_settings_view.dart';
import '../../ai_operations/presentation/admin_ai_operations_view.dart';
import '../../database_explorer/presentation/admin_database_explorer_view.dart';
import '../../../core/services/live_booking_sync_service.dart';
import '../../../core/utils/partner_role_resolver.dart';

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
    final client = Supabase.instance.client;
    final nowIso = DateTime.now().toIso8601String();

    final String id = (partnerMap?['id'] ?? profileId).toString();
    final String? verId = (partnerMap?['verification_id'] != null && partnerMap!['verification_id'].toString().isNotEmpty)
        ? partnerMap['verification_id'].toString()
        : (_isUuid(profileId) ? profileId : null);
    String? targetPartnerId = partnerMap?['partner_id']?.toString();
    String? targetAgentId = partnerMap?['delivery_agent_id']?.toString();
    String? targetUserId = partnerMap?['user_id']?.toString();

    // 1. Update verification_requests table: target verification_id and user_id
    if (verId != null && _isUuid(verId)) {
      try {
        await client
            .from('verification_requests')
            .update({'status': 'APPROVED', 'reviewed_at': nowIso})
            .eq('verification_id', verId);
      } catch (e) {
        debugPrint('[AdminDashboard] Verification request approval error: $e');
      }
    }
    if (targetUserId != null && _isUuid(targetUserId)) {
      try {
        await client
            .from('verification_requests')
            .update({'status': 'APPROVED', 'reviewed_at': nowIso})
            .eq('user_id', targetUserId);
      } catch (_) {}
    }

    // 2. Resolve specific targetPartnerId if not already present
    if ((targetPartnerId == null || targetPartnerId.isEmpty) && _isUuid(profileId)) {
      try {
        final p = await client.from('partners').select('partner_id').eq('partner_id', profileId).maybeSingle();
        if (p != null) targetPartnerId = p['partner_id']?.toString();
      } catch (_) {}
    }
    if ((targetPartnerId == null || targetPartnerId.isEmpty) && targetUserId != null && _isUuid(targetUserId)) {
      try {
        final p = await client.from('partners').select('partner_id').eq('user_id', targetUserId).maybeSingle();
        if (p != null) targetPartnerId = p['partner_id']?.toString();
      } catch (_) {}
    }

    // 3. Update partners table: STRICTLY target partner_id and user_id
    if (targetPartnerId != null && _isUuid(targetPartnerId)) {
      try {
        await client.from('partners').update({
          'verification_status': 'VERIFIED',
          'availability_status': 'ONLINE',
          'approved_at': nowIso,
        }).eq('partner_id', targetPartnerId);
      } catch (e) {
        debugPrint('[AdminDashboard] Partner update error: $e');
      }
    }
    if (targetUserId != null && _isUuid(targetUserId)) {
      try {
        await client.from('partners').update({
          'verification_status': 'VERIFIED',
          'availability_status': 'ONLINE',
          'approved_at': nowIso,
        }).eq('user_id', targetUserId);
      } catch (_) {}
    }

    // 4. Role-specific profile updates
    final String pRole = (partnerMap?['role_name'] ?? partnerMap?['role'] ?? '').toString().toLowerCase();
    final bool isShopkeeper = partnerMap != null ? PartnerRoleResolver.isShopkeeper(partnerMap) : pRole == 'shopkeeper';
    final bool isDelivery = partnerMap != null ? PartnerRoleResolver.isDeliveryAgent(partnerMap) : pRole == 'delivery_agent';
    final bool isServiceProvider = !isShopkeeper && !isDelivery;

    if (isDelivery) {
      try {
        if (targetAgentId != null && _isUuid(targetAgentId)) {
          await client.from('delivery_agent_profiles').update({'availability_status': 'ONLINE'}).eq('delivery_agent_id', targetAgentId);
        }
        if (targetPartnerId != null && _isUuid(targetPartnerId)) {
          await client.from('delivery_agent_profiles').update({'availability_status': 'ONLINE'}).eq('partner_id', targetPartnerId);
        }
      } catch (e) {
        debugPrint('[AdminDashboard] Delivery agent profile update error: $e');
      }
    }

    if (isServiceProvider && targetPartnerId != null && _isUuid(targetPartnerId)) {
      try {
        await client.from('service_provider_profiles').update({'rating': 5.0}).eq('partner_id', targetPartnerId);
      } catch (_) {}
    }

    // 5. Update user account status if UUID is valid
    if (targetUserId != null && _isUuid(targetUserId)) {
      try {
        await client.from('users').update({'account_status': 'ACTIVE'}).eq('user_id', targetUserId);
      } catch (_) {}
    }

    // 6. Broadcast across LiveBookingSyncService for specific IDs ONLY (never broad phone or user_id)
    if (verId != null && verId.isNotEmpty) {
      await LiveBookingSyncService.instance.approvePartnerVerification(verId);
    }
    if (targetPartnerId != null && targetPartnerId.isNotEmpty) {
      await LiveBookingSyncService.instance.approvePartnerVerification(targetPartnerId);
    }
    if (id.isNotEmpty && id != verId && id != targetPartnerId) {
      await LiveBookingSyncService.instance.approvePartnerVerification(id);
    }

    // 7. Mark resolved in memory strictly for this verification request
    if (verId != null && verId.isNotEmpty) markPartnerResolved(verId);
    if (id.isNotEmpty && id != targetPartnerId) markPartnerResolved(id);

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

  Future<void> _rejectPartnerProfile(String profileId, String name, [Map<String, dynamic>? partnerMap, String? reason]) async {
    final client = Supabase.instance.client;
    final nowIso = DateTime.now().toIso8601String();
    final reasonText = (reason != null && reason.trim().isNotEmpty)
        ? 'REJECTED: ${reason.trim()}'
        : 'REJECTED: Verification documents or information provided did not meet requirements.';

    final String id = (partnerMap?['id'] ?? profileId).toString();
    final String? verId = (partnerMap?['verification_id'] != null && partnerMap!['verification_id'].toString().isNotEmpty)
        ? partnerMap['verification_id'].toString()
        : (_isUuid(profileId) ? profileId : null);
    String? targetPartnerId = partnerMap?['partner_id']?.toString();
    String? targetUserId = partnerMap?['user_id']?.toString();

    // 1. Update verification_requests table: target verification_id and user_id
    if (verId != null && _isUuid(verId)) {
      try {
        await client.from('verification_requests').update({
          'status': 'REJECTED',
          'reviewed_at': nowIso,
          'remarks': reasonText,
        }).eq('verification_id', verId);
      } catch (e) {
        debugPrint('[AdminDashboard] Verification request reject error: $e');
      }
    }
    if (targetUserId != null && _isUuid(targetUserId)) {
      try {
        await client.from('verification_requests').update({
          'status': 'REJECTED',
          'reviewed_at': nowIso,
          'remarks': reasonText,
        }).eq('user_id', targetUserId);
      } catch (_) {}
    }

    // 2. Resolve specific targetPartnerId if not already present
    if ((targetPartnerId == null || targetPartnerId.isEmpty) && _isUuid(profileId)) {
      try {
        final p = await client.from('partners').select('partner_id').eq('partner_id', profileId).maybeSingle();
        if (p != null) targetPartnerId = p['partner_id']?.toString();
      } catch (_) {}
    }
    if ((targetPartnerId == null || targetPartnerId.isEmpty) && targetUserId != null && _isUuid(targetUserId)) {
      try {
        final p = await client.from('partners').select('partner_id').eq('user_id', targetUserId).maybeSingle();
        if (p != null) targetPartnerId = p['partner_id']?.toString();
      } catch (_) {}
    }

    // 3. Update partners table: STRICTLY target partner_id and user_id
    if (targetPartnerId != null && _isUuid(targetPartnerId)) {
      try {
        await client.from('partners').update({
          'verification_status': 'REJECTED',
          'availability_status': 'OFFLINE',
        }).eq('partner_id', targetPartnerId);
      } catch (e) {
        debugPrint('[AdminDashboard] Partner reject error: $e');
      }
    }
    if (targetUserId != null && _isUuid(targetUserId)) {
      try {
        await client.from('partners').update({
          'verification_status': 'REJECTED',
          'availability_status': 'OFFLINE',
        }).eq('user_id', targetUserId);
      } catch (_) {}
    }

    // 4. Role-specific profile updates
    final String pRole = (partnerMap?['role_name'] ?? partnerMap?['role'] ?? '').toString().toLowerCase();
    final bool isShopkeeper = partnerMap != null ? PartnerRoleResolver.isShopkeeper(partnerMap) : pRole == 'shopkeeper';
    final bool isDelivery = partnerMap != null ? PartnerRoleResolver.isDeliveryAgent(partnerMap) : pRole == 'delivery_agent';

    if (isDelivery && targetPartnerId != null && _isUuid(targetPartnerId)) {
      try {
        await client.from('delivery_agent_profiles').update({'availability_status': 'OFFLINE'}).eq('partner_id', targetPartnerId);
      } catch (e) {
        debugPrint('[AdminDashboard] Delivery agent reject error: $e');
      }
    }

    // 5. Broadcast across LiveBookingSyncService with rejection reason strictly for specific IDs
    if (verId != null && verId.isNotEmpty) {
      await LiveBookingSyncService.instance.rejectPartnerVerification(verId, reasonText);
    }
    if (targetPartnerId != null && targetPartnerId.isNotEmpty) {
      await LiveBookingSyncService.instance.rejectPartnerVerification(targetPartnerId, reasonText);
    }
    if (id.isNotEmpty && id != verId && id != targetPartnerId) {
      await LiveBookingSyncService.instance.rejectPartnerVerification(id, reasonText);
    }

    // 6. Mark resolved in memory strictly for this verification request
    if (verId != null && verId.isNotEmpty) markPartnerResolved(verId);
    if (id.isNotEmpty && id != targetPartnerId) markPartnerResolved(id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Partner "$name" verification rejected: $reasonText'),
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
    ref.invalidate(adminUnverifiedPartnersProvider);
    ref.invalidate(adminStatsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final statsAsync = ref.watch(adminStatsProvider);
    final bookingsAsync = ref.watch(adminAllBookingsProvider);
    final unverifiedPartnersAsync = ref.watch(adminUnverifiedPartnersProvider);

    final stats = statsAsync.value ?? {};
    final allBookings = bookingsAsync.value ?? [];
    final unverifiedPartners = unverifiedPartnersAsync.value ?? [];

    final unverifiedShopkeepers = unverifiedPartners.where(PartnerRoleResolver.isShopkeeper).toList();
    final unverifiedDeliveryAgents = unverifiedPartners.where(PartnerRoleResolver.isDeliveryAgent).toList();
    final unverifiedProviders = unverifiedPartners.where(PartnerRoleResolver.isServiceProvider).toList();

    final isCompact = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isCompact
          ? Drawer(
              child: AdminSidebar(
                activeTab: _activeTab,
                onTabSelected: (tab) {
                  setState(() => _activeTab = tab);
                  Navigator.of(context).pop();
                },
                isCollapsed: false,
                onToggleCollapse: () {},
                shopkeeperCount: unverifiedShopkeepers.length,
                deliveryCount: unverifiedDeliveryAgents.length,
                partnerCount: unverifiedProviders.length,
              ),
            )
          : null,
      body: Builder(
        builder: (scaffoldContext) {
          return Row(
            children: [
              if (!isCompact)
                AdminSidebar(
                  activeTab: _activeTab,
                  onTabSelected: (tab) => setState(() => _activeTab = tab),
                  isCollapsed: _isSidebarCollapsed,
                  onToggleCollapse: () => setState(() => _isSidebarCollapsed = !_isSidebarCollapsed),
                  shopkeeperCount: unverifiedShopkeepers.length,
                  deliveryCount: unverifiedDeliveryAgents.length,
                  partnerCount: unverifiedProviders.length,
                ),
              Expanded(
                child: Column(
                  children: [
                    AdminHeader(
                      title: _activeTab,
                      onToggleSidebar: () {
                        if (isCompact) {
                          Scaffold.of(scaffoldContext).openDrawer();
                        } else {
                          setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
                        }
                      },
                      onSearch: (val) {
                        if (val.trim().isNotEmpty) {
                          setState(() {
                            _activeTab = 'Partner Verification';
                          });
                        }
                      },
                      dateRangeText: _dateRangeText,
                      unverifiedCount: unverifiedPartners.length,
                      onRefresh: () {
                        ref.invalidate(adminStatsStreamProvider);
                        ref.invalidate(adminAllBookingsStreamProvider);
                        ref.invalidate(adminUnverifiedPartnersProvider);
                        ref.invalidate(adminStatsProvider);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Row(
                                children: [
                                  Icon(Icons.cloud_done_rounded, color: Colors.white, size: 18),
                                  SizedBox(width: 8),
                                  Text('Database synced and live dashboard reloaded!'),
                                ],
                              ),
                              backgroundColor: Color(0xFF10B981),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    Expanded(
                      child: _buildActiveView(stats, allBookings, unverifiedPartners),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
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
      return AdminBookingsView(allBookings: allBookings, title: 'All Bookings');
    }
    if (_activeTab == 'AC Service Bookings') {
      return AdminBookingsView(allBookings: allBookings, serviceCategory: 'ac_service', title: 'AC Service Bookings');
    }
    if (_activeTab == 'Care Taker Bookings') {
      return AdminBookingsView(allBookings: allBookings, serviceCategory: 'care_taker', title: 'Care Taker Bookings');
    }
    if (_activeTab == 'Laundry Bookings') {
      return AdminBookingsView(allBookings: allBookings, serviceCategory: 'laundry', title: 'Laundry Bookings');
    }
    if (_activeTab == 'Car Service Bookings') {
      return AdminBookingsView(allBookings: allBookings, serviceCategory: 'car_service', title: 'Car Service Bookings');
    }
    if (_activeTab == 'Plumbing Bookings') {
      return AdminBookingsView(allBookings: allBookings, serviceCategory: 'plumbing', title: 'Plumbing Bookings');
    }
    if (_activeTab == 'Cooking Bookings') {
      return AdminBookingsView(allBookings: allBookings, serviceCategory: 'cooking', title: 'Cooking Bookings');
    }
    if (_activeTab == 'Partner Verification' ||
        _activeTab == 'Service Provider Verification' ||
        _activeTab == 'Service Partners') {
      return AdminPartnersView(
        filterRole: 'service_provider',
        unverifiedPartners: unverifiedPartners,
        onApprove: _approvePartnerProfile,
        onReject: _rejectPartnerProfile,
      );
    }
    if (_activeTab == 'Shopkeeper Verification') {
      return AdminPartnersView(
        filterRole: 'shopkeeper',
        unverifiedPartners: unverifiedPartners,
        onApprove: _approvePartnerProfile,
        onReject: _rejectPartnerProfile,
      );
    }
    if (_activeTab == 'Delivery Agent Verification') {
      return AdminPartnersView(
        filterRole: 'delivery_agent',
        unverifiedPartners: unverifiedPartners,
        onApprove: _approvePartnerProfile,
        onReject: _rejectPartnerProfile,
      );
    }
    if (_activeTab == 'Database Explorer') {
      return const AdminDatabaseExplorerView();
    }
    if (_activeTab == 'Customers') {
      return AdminCustomersView(customerCount: stats['totalCustomers'] ?? 0);
    }
    if (_activeTab == 'Store Products & Catalog' || _activeTab == 'Store Products' || _activeTab == 'Products') {
      return const AdminProductsView();
    }
    if (_activeTab == 'Services' || _activeTab == 'All Services') {
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

  bool _isShopkeeper(Map<String, dynamic> p) => PartnerRoleResolver.isShopkeeper(p);

  bool _isDeliveryAgent(Map<String, dynamic> p) => PartnerRoleResolver.isDeliveryAgent(p);

  bool _isServiceProvider(Map<String, dynamic> p) => PartnerRoleResolver.isServiceProvider(p);

  Widget _buildMainDashboardContent(
    Map<String, dynamic> stats,
    List<Map<String, dynamic>> allBookings,
    List<Map<String, dynamic>> unverifiedPartners,
  ) {
    final unverifiedShopkeepers = unverifiedPartners.where(PartnerRoleResolver.isShopkeeper).toList();
    final unverifiedDeliveryAgents = unverifiedPartners.where(PartnerRoleResolver.isDeliveryAgent).toList();
    final unverifiedProviders = unverifiedPartners.where(PartnerRoleResolver.isServiceProvider).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Shopkeeper Store Approval Banner
          if (unverifiedShopkeepers.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBBF7D0)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF16A34A).withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 640;
                  final content = Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${unverifiedShopkeepers.length} Store & Shopkeeper Application(s) Waiting For Approval!',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF14532D)),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Store: ${unverifiedShopkeepers.first['business_name'] ?? unverifiedShopkeepers.first['name']} • Owner: ${unverifiedShopkeepers.first['full_name'] ?? unverifiedShopkeepers.first['name']}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF16A34A)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final button = ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.store_mall_directory_rounded, size: 16),
                    label: const Text('Review Store Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    onPressed: () => setState(() => _activeTab = 'Shopkeeper Verification'),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        content,
                        const SizedBox(height: 12),
                        button,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: content),
                      const SizedBox(width: 12),
                      button,
                    ],
                  );
                },
              ),
            ),
          ],

          // Delivery Agent Approval Banner
          if (unverifiedDeliveryAgents.isNotEmpty) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFED7AA)),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFEA580C).withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 640;
                  final content = Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEA580C),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${unverifiedDeliveryAgents.length} Delivery Agent & Rider Application(s) Waiting For Approval!',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF7C2D12)),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Rider: ${unverifiedDeliveryAgents.first['full_name'] ?? unverifiedDeliveryAgents.first['name']} • App ID: ${unverifiedDeliveryAgents.first['verification_id'] ?? unverifiedDeliveryAgents.first['id']} • Vehicle: ${unverifiedDeliveryAgents.first['vehicle_type'] ?? "Two Wheeler"}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFFEA580C)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final button = ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    icon: const Icon(Icons.two_wheeler_rounded, size: 16),
                    label: const Text('Review Rider Queue', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                    onPressed: () => setState(() => _activeTab = 'Delivery Agent Verification'),
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        content,
                        const SizedBox(height: 12),
                        button,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: content),
                      const SizedBox(width: 12),
                      button,
                    ],
                  );
                },
              ),
            ),
          ],

          // Service Provider Partner Approval Banner
          if (unverifiedProviders.isNotEmpty) ...[
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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 640;
                  final content = Row(
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
                              '${unverifiedProviders.length} Service Partner Application(s) Waiting For Admin Approval!',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF1E3A8A)),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Candidate: ${unverifiedProviders.first['full_name'] ?? unverifiedProviders.first['name']} • App ID: ${unverifiedProviders.first['verification_id'] ?? unverifiedProviders.first['id']}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF3B82F6)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  final button = ElevatedButton.icon(
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
                  );

                  if (isNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        content,
                        const SizedBox(height: 12),
                        button,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: content),
                      const SizedBox(width: 12),
                      button,
                    ],
                  );
                },
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

          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 720) {
                return Column(
                  children: [
                    BookingsOverviewChart(
                      bookings: allBookings,
                    ),
                    const SizedBox(height: 16),
                    BookingStatusDonutChart(
                      totalCount: stats['totalBookings'] ?? 0,
                      completedCount: stats['completedServices'] ?? 0,
                      ongoingCount: stats['ongoingServices'] ?? 0,
                      confirmedCount: stats['confirmedServices'] ?? 0,
                      cancelledCount: stats['cancelledServices'] ?? 0,
                    ),
                  ],
                );
              }

              return Row(
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
              );
            },
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
