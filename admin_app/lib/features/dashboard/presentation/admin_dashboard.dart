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
    final String id = (partnerMap?['id'] ?? profileId).toString();
    await LiveBookingSyncService.instance.approvePartnerVerification(id);
    if (profileId.isNotEmpty && profileId != id) {
      await LiveBookingSyncService.instance.approvePartnerVerification(profileId);
    }
    final client = Supabase.instance.client;

    String? targetUserId = partnerMap?['user_id']?.toString();
    String? targetPartnerId = partnerMap?['partner_id']?.toString();
    String? targetAgentId = partnerMap?['delivery_agent_id']?.toString();
    final phone = partnerMap?['phone']?.toString().replaceAll(' ', '');
    final verId = partnerMap?['verification_id']?.toString();

    // If targetUserId is not directly in partnerMap, look it up by phone first
    if ((targetUserId == null || targetUserId.isEmpty) && phone != null && phone.isNotEmpty) {
      try {
        final rawDigits = phone.replaceAll(RegExp(r'\D'), '');
        final isPhone = rawDigits.length >= 10;
        final clean10 = isPhone ? rawDigits.substring(rawDigits.length - 10) : '';
        final filterParts = <String>['phone.eq.$phone'];
        if (isPhone) {
          filterParts.add('phone.eq.$rawDigits');
          filterParts.add('phone.eq.+91$clean10');
          filterParts.add('phone.ilike.*$clean10*');
        }
        final u = await client
            .from('users')
            .select('user_id, phone, partners(partner_id)')
            .or(filterParts.join(','))
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

    if ((targetPartnerId == null || targetPartnerId.isEmpty) && _isUuid(profileId)) {
      try {
        final dap = await client
            .from('delivery_agent_profiles')
            .select('partner_id, delivery_agent_id')
            .or('delivery_agent_id.eq.$profileId,partner_id.eq.$profileId')
            .maybeSingle();
        if (dap != null) {
          targetPartnerId = dap['partner_id']?.toString();
          targetAgentId ??= dap['delivery_agent_id']?.toString();
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
      if (id.isNotEmpty && id != profileId && _isUuid(id)) {
        await client
            .from('verification_requests')
            .update({'status': 'APPROVED', 'reviewed_at': nowIso})
            .or('verification_id.eq.$id,user_id.eq.$id');
      }
      if (verId != null && _isUuid(verId)) {
        await client
            .from('verification_requests')
            .update({'status': 'APPROVED', 'reviewed_at': nowIso})
            .eq('verification_id', verId);
      }
    } catch (_) {}

    // 2. Update partners table (verification_status: 'VERIFIED', availability_status: 'ONLINE', approved_at: nowIso)
    try {
      final partnerUpdate = {
        'verification_status': 'VERIFIED',
        'availability_status': 'ONLINE',
        'approved_at': nowIso,
      };
      if (targetPartnerId != null && _isUuid(targetPartnerId)) {
        await client
            .from('partners')
            .update(partnerUpdate)
            .eq('partner_id', targetPartnerId);
      }
      if (_isUuid(effectiveUserId)) {
        await client
            .from('partners')
            .update(partnerUpdate)
            .eq('user_id', effectiveUserId);
      }
      if (_isUuid(profileId)) {
        await client
            .from('partners')
            .update(partnerUpdate)
            .or('partner_id.eq.$profileId,user_id.eq.$profileId');
      }
      if (id.isNotEmpty && id != profileId && _isUuid(id)) {
        await client
            .from('partners')
            .update(partnerUpdate)
            .or('partner_id.eq.$id,user_id.eq.$id');
      }
    } catch (e) {
      debugPrint('[AdminDashboard] Partner update error: $e');
    }

    final String pRole = (partnerMap?['role_name'] ?? partnerMap?['role'] ?? '').toString().toLowerCase();
    final bool isShopkeeper = pRole == 'shopkeeper' || (partnerMap != null && _isShopkeeper(partnerMap));
    final bool isDelivery = !isShopkeeper && (pRole == 'delivery_agent' || (partnerMap != null && _isDeliveryAgent(partnerMap)));
    final bool isServiceProvider = !isShopkeeper && !isDelivery;

    // 2b. Update delivery_agent_profiles table (availability_status: 'ONLINE') only if delivery
    if (isDelivery) {
      try {
        final dapUpdate = {
          'availability_status': 'ONLINE',
        };
        if (targetAgentId != null && _isUuid(targetAgentId)) {
          await client
              .from('delivery_agent_profiles')
              .update(dapUpdate)
              .eq('delivery_agent_id', targetAgentId);
        }
        if (targetPartnerId != null && _isUuid(targetPartnerId)) {
          await client
              .from('delivery_agent_profiles')
              .update(dapUpdate)
              .eq('partner_id', targetPartnerId);
        }
        if (_isUuid(effectiveUserId)) {
          await client
              .from('delivery_agent_profiles')
              .update(dapUpdate)
              .or('partner_id.eq.$effectiveUserId,delivery_agent_id.eq.$effectiveUserId');
        }
        if (_isUuid(profileId)) {
          await client
              .from('delivery_agent_profiles')
              .update(dapUpdate)
              .or('partner_id.eq.$profileId,delivery_agent_id.eq.$profileId');
        }
        if (id.isNotEmpty && id != profileId && _isUuid(id)) {
          await client
              .from('delivery_agent_profiles')
              .update(dapUpdate)
              .or('partner_id.eq.$id,delivery_agent_id.eq.$id');
        }
      } catch (e) {
        debugPrint('[AdminDashboard] Delivery agent profile update error: $e');
      }
    }

    // 2d. Update providers table only if service provider
    if (isServiceProvider) {
      try {
        final provData = {
          'verification_status': 'VERIFIED',
          'is_active': true,
        };
        if (_isUuid(effectiveUserId)) {
          await client.from('providers').update(provData).eq('id', effectiveUserId);
        }
        if (_isUuid(profileId)) {
          await client.from('providers').update(provData).eq('id', profileId);
        }
        if (targetPartnerId != null && _isUuid(targetPartnerId)) {
          await client.from('service_provider_profiles').update({'rating': 5.0}).eq('partner_id', targetPartnerId);
        }
        if (_isUuid(effectiveUserId)) {
          await client.from('service_provider_profiles').update({'rating': 5.0}).or('partner_id.eq.$effectiveUserId,provider_id.eq.$effectiveUserId');
        }
      } catch (_) {}
    }

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
    await LiveBookingSyncService.instance.approvePartnerVerification(id);
    if (effectiveUserId != profileId && effectiveUserId != id) {
      await LiveBookingSyncService.instance.approvePartnerVerification(effectiveUserId);
    }
    if (targetPartnerId != null && targetPartnerId.isNotEmpty) {
      await LiveBookingSyncService.instance.approvePartnerVerification(targetPartnerId);
    }
    if (targetAgentId != null && targetAgentId.isNotEmpty) {
      await LiveBookingSyncService.instance.approvePartnerVerification(targetAgentId);
    }
    final targetShopId = partnerMap?['shop_id']?.toString();
    if (targetShopId != null && targetShopId.isNotEmpty) {
      await LiveBookingSyncService.instance.approvePartnerVerification(targetShopId);
    }
    if (phone != null && phone.isNotEmpty) {
      await LiveBookingSyncService.instance.approvePartnerVerification(phone);
    }
    if (verId != null && verId.isNotEmpty) {
      await LiveBookingSyncService.instance.approvePartnerVerification(verId);
    }

    markPartnerResolved(id);
    markPartnerResolved(profileId);
    markPartnerResolved(effectiveUserId);
    if (targetPartnerId != null && targetPartnerId.isNotEmpty) markPartnerResolved(targetPartnerId);
    if (targetAgentId != null && targetAgentId.isNotEmpty) markPartnerResolved(targetAgentId);
    if (targetShopId != null && targetShopId.isNotEmpty) markPartnerResolved(targetShopId);
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

  Future<void> _rejectPartnerProfile(String profileId, String name, [Map<String, dynamic>? partnerMap, String? reason]) async {
    final client = Supabase.instance.client;

    String? targetUserId = partnerMap?['user_id']?.toString();
    String? targetPartnerId = partnerMap?['partner_id']?.toString();
    final phone = partnerMap?['phone']?.toString().replaceAll(' ', '');
    final verId = partnerMap?['verification_id']?.toString();

    if ((targetUserId == null || targetUserId.isEmpty) && phone != null && phone.isNotEmpty) {
      try {
        final rawDigits = phone.replaceAll(RegExp(r'\D'), '');
        final isPhone = rawDigits.length >= 10;
        final clean10 = isPhone ? rawDigits.substring(rawDigits.length - 10) : '';
        final filterParts = <String>['phone.eq.$phone'];
        if (isPhone) {
          filterParts.add('phone.eq.$rawDigits');
          filterParts.add('phone.eq.+91$clean10');
          filterParts.add('phone.ilike.*$clean10*');
        }
        final u = await client
            .from('users')
            .select('user_id, phone, partners(partner_id)')
            .or(filterParts.join(','))
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
    final reasonText = (reason != null && reason.trim().isNotEmpty)
        ? 'REJECTED: ${reason.trim()}'
        : 'REJECTED: Verification documents or information provided did not meet requirements.';

    // 1. Update verification_requests table
    try {
      final vrReject = {
        'status': 'REJECTED',
        'reviewed_at': nowIso,
        'remarks': reasonText,
      };
      if (_isUuid(effectiveUserId)) {
        await client
            .from('verification_requests')
            .update(vrReject)
            .eq('user_id', effectiveUserId);
      }
      if (_isUuid(profileId)) {
        await client
            .from('verification_requests')
            .update(vrReject)
            .or('verification_id.eq.$profileId,user_id.eq.$profileId');
      }
      if (verId != null && _isUuid(verId)) {
        await client
            .from('verification_requests')
            .update(vrReject)
            .eq('verification_id', verId);
      }
    } catch (e) {
      debugPrint('[AdminDashboard] Verification request reject error: $e');
    }

    // 2. Update partners table
    try {
      final pReject = {
        'verification_status': 'REJECTED',
        'availability_status': 'OFFLINE',
      };
      if (targetPartnerId != null && _isUuid(targetPartnerId)) {
        await client
            .from('partners')
            .update(pReject)
            .eq('partner_id', targetPartnerId);
      }
      if (_isUuid(effectiveUserId)) {
        await client
            .from('partners')
            .update(pReject)
            .eq('user_id', effectiveUserId);
      }
      if (_isUuid(profileId)) {
        await client
            .from('partners')
            .update(pReject)
            .or('partner_id.eq.$profileId,user_id.eq.$profileId');
      }
    } catch (e) {
      debugPrint('[AdminDashboard] Partner reject error: $e');
    }

    final String rRole = (partnerMap?['role_name'] ?? partnerMap?['role'] ?? '').toString().toLowerCase();
    final bool isShopkeeperReject = rRole == 'shopkeeper' || (partnerMap != null && _isShopkeeper(partnerMap));
    final bool isDeliveryReject = !isShopkeeperReject && (rRole == 'delivery_agent' || (partnerMap != null && _isDeliveryAgent(partnerMap)));

    // 3. Update delivery_agent_profiles table only if delivery
    if (isDeliveryReject) {
      try {
        final dapReject = {
          'availability_status': 'OFFLINE',
        };
        if (targetPartnerId != null && _isUuid(targetPartnerId)) {
          await client
              .from('delivery_agent_profiles')
              .update(dapReject)
              .eq('partner_id', targetPartnerId);
        }
        if (_isUuid(effectiveUserId)) {
          await client
              .from('delivery_agent_profiles')
              .update(dapReject)
              .or('partner_id.eq.$effectiveUserId,delivery_agent_id.eq.$effectiveUserId');
        }
        if (_isUuid(profileId)) {
          await client
              .from('delivery_agent_profiles')
              .update(dapReject)
              .or('partner_id.eq.$profileId,delivery_agent_id.eq.$profileId');
        }
      } catch (e) {
        debugPrint('[AdminDashboard] Delivery agent reject error: $e');
      }
    }

    // 4. Update users table: suspend account
    try {
      if (_isUuid(effectiveUserId)) {
        await client
            .from('users')
            .update({'account_status': 'SUSPENDED'})
            .eq('user_id', effectiveUserId);
      }
    } catch (_) {}

    // 5. Broadcast across LiveBookingSyncService with rejection reason
    final String id = (partnerMap?['id'] ?? profileId).toString();
    await LiveBookingSyncService.instance.rejectPartnerVerification(id, reason);
    if (effectiveUserId != profileId && effectiveUserId != id) {
      await LiveBookingSyncService.instance.rejectPartnerVerification(effectiveUserId, reason);
    }
    if (targetPartnerId != null && targetPartnerId.isNotEmpty) {
      await LiveBookingSyncService.instance.rejectPartnerVerification(targetPartnerId, reason);
    }
    if (phone != null && phone.isNotEmpty) {
      await LiveBookingSyncService.instance.rejectPartnerVerification(phone, reason);
    }
    if (verId != null && verId.isNotEmpty) {
      await LiveBookingSyncService.instance.rejectPartnerVerification(verId, reason);
    }

    markPartnerResolved(id);
    markPartnerResolved(profileId);
    markPartnerResolved(effectiveUserId);
    if (targetPartnerId != null && targetPartnerId.isNotEmpty) markPartnerResolved(targetPartnerId);
    if (phone != null && phone.isNotEmpty) markPartnerResolved(phone);
    if (verId != null && verId.isNotEmpty) markPartnerResolved(verId);

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

    final unverifiedShopkeepers = unverifiedPartners.where((p) => _isShopkeeper(p) && !_isDeliveryAgent(p)).toList();
    final unverifiedDeliveryAgents = unverifiedPartners.where(_isDeliveryAgent).toList();
    final unverifiedProviders = unverifiedPartners.where((p) => !_isShopkeeper(p) && !_isDeliveryAgent(p)).toList();

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
      return AdminBookingsView(allBookings: allBookings);
    }
    if (_activeTab == 'Partner Verification') {
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

  bool _isShopkeeper(Map<String, dynamic> p) {
    final role = (p['role_name'] ?? p['role'] ?? '').toString().toLowerCase();
    if (role == 'shopkeeper') return true;
    if (role == 'delivery_agent' || role == 'service_provider') return false;
    final docType = (p['document_type'] ?? '').toString().toUpperCase();
    if (docType == 'PROVIDER_ONBOARDING' || docType == 'DELIVERY_ONBOARDING' || role.contains('technician') || role.contains('expert')) {
      return false;
    }
    final cat = (p['category'] ?? p['category_name'] ?? '').toString().toLowerCase();
    final bName = (p['business_name'] ?? p['shop_name'] ?? '').toString().toLowerCase();
    return role.contains('shop') ||
        role.contains('store') ||
        cat.contains('shop') ||
        cat.contains('store') ||
        cat.contains('parts') ||
        cat.contains('grocery') ||
        cat.contains('pharmacy') ||
        cat.contains('retail') ||
        cat.contains('hardware') ||
        cat.contains('ac_parts') ||
        cat.contains('laundry_supplies') ||
        cat.contains('car_parts') ||
        bName.contains('store') ||
        bName.contains('electronics') ||
        bName.contains('parts') ||
        docType.contains('SHOP') ||
        (p['shop_id'] != null && p['shop_id'].toString().trim().isNotEmpty) ||
        (p['shop_name'] != null && p['shop_name'].toString().trim().isNotEmpty);
  }

  bool _isDeliveryAgent(Map<String, dynamic> p) {
    final role = (p['role_name'] ?? p['role'] ?? '').toString().toLowerCase();
    if (role == 'delivery_agent') return true;
    if (role == 'shopkeeper' || role == 'service_provider') return false;
    final docType = (p['document_type'] ?? '').toString().toUpperCase();
    final verType = (p['verification_type'] ?? '').toString().toUpperCase();
    if (docType == 'PROVIDER_ONBOARDING' || docType.contains('SHOP') || verType == 'SHOP_LICENSE') {
      return false;
    }
    final cat = (p['category'] ?? p['category_name'] ?? '').toString().toLowerCase();
    final bName = (p['business_name'] ?? '').toString().toLowerCase();
    return cat.contains('delivery') ||
        cat.contains('rider') ||
        role.contains('delivery') ||
        role.contains('rider') ||
        bName.contains('delivery') ||
        bName.contains('rider') ||
        docType.contains('DELIVERY') ||
        verType == 'DRIVING_LICENSE' ||
        (p['delivery_agent_id'] != null && p['delivery_agent_id'].toString().trim().isNotEmpty) ||
        (p['vehicle_type'] != null && p['vehicle_type'].toString().trim().isNotEmpty) ||
        (p['vehicle_number'] != null && p['vehicle_number'].toString().trim().isNotEmpty) ||
        (p['vehicle_reg_number'] != null && p['vehicle_reg_number'].toString().trim().isNotEmpty) ||
        (p['driving_license_number'] != null && p['driving_license_number'].toString().trim().isNotEmpty);
  }

  Widget _buildMainDashboardContent(
    Map<String, dynamic> stats,
    List<Map<String, dynamic>> allBookings,
    List<Map<String, dynamic>> unverifiedPartners,
  ) {
    final unverifiedShopkeepers = unverifiedPartners.where((p) => _isShopkeeper(p) && !_isDeliveryAgent(p)).toList();
    final unverifiedDeliveryAgents = unverifiedPartners.where(_isDeliveryAgent).toList();
    final unverifiedProviders = unverifiedPartners.where((p) => !_isShopkeeper(p) && !_isDeliveryAgent(p)).toList();

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
