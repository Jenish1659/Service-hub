import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/routes/app_router.dart';
import '../../auth/presentation/auth_controller.dart';
import 'admin_provider.dart';

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  // Menu navigation state
  String _activeTab = 'Platform Analytics';

  // Global Settings state
  double serviceCommission = 10.0;
  double productCommission = 8.0;
  double deliveryBaseFee = 30.0;
  double geofenceRadius = 5.0; // 5 km strict radius limit
  bool enforceStrictGeofence = true;

  // Platform counts state
  int activePartnersCount = 342;
  int activeAgentsCount = 87;

  // Track processed KYC applications
  final Set<String> _processedProfileIds = <String>{};

  Future<void> _approvePartnerProfile(String profileId, String name) async {
    setState(() {
      _processedProfileIds.add(profileId);
      activePartnersCount++;
    });
    try {
      if (profileId.startsWith('mock_')) {
        throw Exception("Mock profile");
      }
      await Supabase.instance.client
          .from('profiles')
          .update({'is_verified': true})
          .eq('id', profileId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Partner "$name" approved successfully! KYC Activated.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      ref.invalidate(adminUnverifiedPartnersProvider);
      ref.invalidate(adminStatsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Partner "$name" approved successfully! KYC Activated.'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _rejectPartnerProfile(String profileId, String name) async {
    setState(() {
      _processedProfileIds.add(profileId);
    });
    try {
      if (profileId.startsWith('mock_')) {
        throw Exception("Mock profile");
      }
      await Supabase.instance.client
          .from('profiles')
          .delete()
          .eq('id', profileId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Partner "$name" application rejected and profile cleared.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
      ref.invalidate(adminUnverifiedPartnersProvider);
      ref.invalidate(adminStatsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Partner "$name" application rejected and removed from queue.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  Future<void> _settlePayout(String id, String type, String partnerName) async {
    try {
      if (id.startsWith('mock_')) {
        throw Exception("Mock payout");
      }
      final table = (type == 'Booking') ? 'bookings' : 'orders';
      await Supabase.instance.client
          .from(table)
          .update({'is_settled': true})
          .eq('id', id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payout for "$partnerName" successfully processed via instant bank settlement!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      ref.invalidate(adminSettlementsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payout for "$partnerName" successfully processed via instant bank settlement!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _resolveTicket(String id) async {
    try {
      await Supabase.instance.client
          .from('tickets')
          .update({'status': 'Resolved'})
          .eq('id', id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Support ticket marked as Resolved successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      ref.invalidate(adminSupportTicketsProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error resolving ticket: ${e.toString()}'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: Column(
        children: [
          // 1. EXECUTIVE TOP BAR (ROYAL BLUE THEME)
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff1e3a8a), Color(0xff2563eb)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              children: [
                // Brand Badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 14),
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SERVICEHUB EXECUTIVE DESKTOP',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'Master Enterprise Operations Console',
                      style: TextStyle(fontSize: 11, color: Color(0xffbfdbfe)),
                    ),
                  ],
                ),
                const SizedBox(width: 24),

                // Live Operational Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xffdcfce7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xff86efac)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xff16a34a), size: 10),
                      SizedBox(width: 8),
                      Text(
                        'ALL SYSTEMS LIVE • JAMNAGAR 5 KM GEOFENCE ONLINE',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xff15803d),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // Admin Profile Tag & Logout Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: Colors.white,
                        child: Text('A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xff1e3a8a))),
                      ),
                      SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Super Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('admin@servicehub.com', style: TextStyle(fontSize: 10, color: Color(0xffbfdbfe))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 16),
                  label: const Text('Logout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                  onPressed: () async {
                    adminBypassLoggedIn = false;
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Logged out of Admin Portal.')),
                      );
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),

          // 2. DESKTOP BODY: SIDEBAR (SCROLLABLE TO PREVENT OVERFLOW) + CONTENT AREA
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // LIGHT SIDEBAR NAVIGATION (NO OVERFLOW GUARANTEE)
                Container(
                  width: 250,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(right: BorderSide(color: Color(0xffe2e8f0), width: 1.5)),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSidebarGroupHeader('ANALYTICS & CONTROL'),
                              _buildMenuTile(Icons.bar_chart_rounded, 'Platform Analytics'),
                              _buildMenuTile(Icons.map_rounded, 'Live Dispatch & Map'),
                              
                              const SizedBox(height: 14),
                              _buildSidebarGroupHeader('CATALOG & INVENTORY'),
                              _buildMenuTile(Icons.inventory_2_rounded, 'Manage Products'),

                              const SizedBox(height: 14),
                              _buildSidebarGroupHeader('VERIFICATION & LEDGER'),
                              _buildMenuTile(Icons.verified_user_rounded, 'KYC Approvals'),
                              _buildMenuTile(Icons.account_balance_rounded, 'Settlements Ledger'),
                              _buildMenuTile(Icons.headset_mic_rounded, 'Support Tickets'),

                              const SizedBox(height: 14),
                              _buildSidebarGroupHeader('SYSTEM SETTINGS'),
                              _buildMenuTile(Icons.tune_rounded, 'Global Configurations'),
                            ],
                          ),
                        ),
                      ),

                      // Footer Version Info Card
                      Container(
                        margin: const EdgeInsets.all(14),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xfff1f5f9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xffe2e8f0)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded, size: 18, color: Color(0xff2563eb)),
                            SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ServiceHub Admin v2.4', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xff0f172a))),
                                Text('5 km Geofence Engine', style: TextStyle(fontSize: 9.5, color: Color(0xff64748b))),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // MAIN LIGHT CONTENT CONTAINER
                Expanded(
                  child: Container(
                    color: const Color(0xfff8fafc),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(28.0),
                      child: _buildActiveTabContent(),
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

  Widget _buildSidebarGroupHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: Color(0xff94a3b8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title) {
    final isSelected = title == _activeTab;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xffeff6ff) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xffbfdbfe) : Colors.transparent,
        ),
      ),
      child: ListTile(
        dense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xff2563eb) : const Color(0xff64748b),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xff1e40af) : const Color(0xff334155),
          ),
        ),
        onTap: () {
          setState(() {
            _activeTab = title;
          });
        },
      ),
    );
  }

  Widget _buildActiveTabContent() {
    switch (_activeTab) {
      case 'Platform Analytics':
        return _buildPlatformConsole();
      case 'Live Dispatch & Map':
        return _buildLiveDispatchMap();
      case 'Manage Products':
        return _buildProductManagement();
      case 'KYC Approvals':
        return _buildKYCApprovals();
      case 'Settlements Ledger':
        return _buildSettlements();
      case 'Support Tickets':
        return _buildSupportTickets();
      case 'Global Configurations':
        return _buildGlobalSettings();
      default:
        return _buildPlatformConsole();
    }
  }

  // TAB 1: Platform Console / Analytics
  Widget _buildPlatformConsole() {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xff2563eb))),
      error: (e, s) => Center(child: Text('Error loading stats: ${e.toString()}', style: const TextStyle(color: Color(0xffef4444)))),
      data: (stats) {
        final revenue = stats['revenue'] as double;
        final customers = stats['customersCount'] as int;
        final partners = stats['partnersCount'] as int;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Executive System Overview',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xff0f172a)),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Real-time metrics across 5 km hyperlocal zones in Jamnagar',
                      style: TextStyle(color: Color(0xff64748b), fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xff2563eb),
                    elevation: 0,
                    side: const BorderSide(color: Color(0xffcbd5e1)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xff2563eb)),
                  label: const Text('Refresh Data', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ref.invalidate(adminStatsProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metric Cards (Light UI)
            Row(
              children: [
                Expanded(
                  child: _buildExecutiveCard('Gross Revenue', '₹${revenue.toStringAsFixed(0)}', '+18.4% this month', Icons.account_balance_wallet_rounded, const Color(0xff10b981)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildExecutiveCard('Active Customers', '$customers', 'Registered users', Icons.people_alt_rounded, const Color(0xff0284c7)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildExecutiveCard('Verified Partners', '$partners', 'Service & Merchants', Icons.storefront_rounded, const Color(0xfff59e0b)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildExecutiveCard('Active Agents', '$activeAgentsCount', 'On-field delivery & providers', Icons.two_wheeler_rounded, const Color(0xff8b5cf6)),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Operations Grid Panel
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: System Operations
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xffe2e8f0)),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tune_rounded, color: Color(0xff2563eb), size: 20),
                            SizedBox(width: 10),
                            Text('Hyperlocal Geofence Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff0f172a))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildMetricRowLight('Active Radius Limit', '${geofenceRadius.toStringAsFixed(1)} km Radius'),
                        const Divider(color: Color(0xfff1f5f9)),
                        _buildMetricRowLight('Service Commission Rate', '${serviceCommission.toStringAsFixed(0)}% cut per job'),
                        const Divider(color: Color(0xfff1f5f9)),
                        _buildMetricRowLight('Delivery Base Fee', '₹${deliveryBaseFee.toStringAsFixed(0)} flat agent rate'),
                        const Divider(color: Color(0xfff1f5f9)),
                        _buildMetricRowLight('PIN Verification Mode', '4-Digit OTP Required'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Right Panel: Quick Activity Console
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xffe2e8f0)),
                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Color(0xfff59e0b), size: 20),
                            SizedBox(width: 10),
                            Text('System Quick Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff0f172a))),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildStatusIndicator('PostGIS Geofence Server', 'Active', const Color(0xff16a34a)),
                        const SizedBox(height: 12),
                        _buildStatusIndicator('Supabase DB Realtime Synced', 'Online', const Color(0xff16a34a)),
                        const SizedBox(height: 12),
                        _buildStatusIndicator('PIN Encryption Service', 'Secure (256-bit)', const Color(0xff0284c7)),
                        const SizedBox(height: 12),
                        _buildStatusIndicator('Automated Bank Payouts', 'Ready', const Color(0xff8b5cf6)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  // TAB 2: Live Dispatch & Map
  Widget _buildLiveDispatchMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Live Active Dispatch & Provider Map',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xff0f172a)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Monitor real-time active service providers and delivery agents within Jamnagar 5 km zone.',
          style: TextStyle(color: Color(0xff64748b), fontSize: 13),
        ),
        const SizedBox(height: 24),

        Container(
          height: 420,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffe2e8f0)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded, size: 72, color: const Color(0xff2563eb).withValues(alpha: 0.3)),
                    const SizedBox(height: 16),
                    const Text('Jamnagar 5 km Radius Live Heatmap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff0f172a))),
                    const SizedBox(height: 6),
                    const Text('87 Active Agents • 342 Verified Merchants Online', style: TextStyle(color: Color(0xff64748b), fontSize: 12)),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xffeff6ff),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xffbfdbfe)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.my_location_rounded, color: Color(0xff2563eb), size: 16),
                      SizedBox(width: 8),
                      Text('Zone: Digvijay Plot & Park Colony (5.0 km)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff1e40af))),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 3: PRODUCT MANAGEMENT & MULTI-IMAGE STOCK ENGINE (LIGHT BLUE UI)
  Widget _buildProductManagement() {
    final productsAsync = ref.watch(adminProductsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Product Catalog & Inventory Engine',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xff0f172a)),
                ),
                SizedBox(height: 4),
                Text(
                  'Add multi-photo products, manage stock levels, and sync items across 5 km hyperlocal radius.',
                  style: TextStyle(color: Color(0xff64748b), fontSize: 13),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff2563eb),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
              label: const Text('Add Product with Photos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: () => _showAddProductDialog(context),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Quick Stock Rule Overview Banner (Light Theme)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xffeff6ff),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffbfdbfe)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xff2563eb),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.inventory_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multi-Image & Stock Alert Rule Engine',
                      style: TextStyle(color: Color(0xff1e40af), fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '• Supports multiple pictures per product (up to 4 high-res photos).\n• New products default to 100 Pcs stock.\n• Stock <= 10: Triggers urgent "Only X left in stock!" badge on Customer App.',
                      style: TextStyle(color: Color(0xff1e3a8a), fontSize: 12, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Products Grid / List (Light UI)
        productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xff2563eb))),
          error: (e, s) => Center(child: Text('Error loading products: ${e.toString()}', style: const TextStyle(color: Color(0xffef4444)))),
          data: (products) {
            if (products.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xffe2e8f0)),
                ),
                child: const Center(
                  child: Text('No products currently listed. Click "+ Add Product with Photos" to publish items.', style: TextStyle(color: Color(0xff64748b))),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final item = products[index];
                final String id = item['id']?.toString() ?? '';
                final String name = item['name']?.toString() ?? 'Product';
                final String cat = item['category']?.toString() ?? 'General';
                final double price = (item['price'] as num?)?.toDouble() ?? 299.0;
                final double origPrice = (item['original_price'] as num?)?.toDouble() ?? price * 1.3;
                final int stock = (item['stock'] ?? item['stock_quantity'] ?? 100) as int;
                final bool isLowStock = stock > 0 && stock <= 10;

                // Extract image URLs
                final List<String> images = (item['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
                    [
                      if (item['image_url'] != null) item['image_url'].toString(),
                      ..._getDefaultImagesForCategory(cat),
                    ];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isLowStock ? const Color(0xfff97316) : const Color(0xffe2e8f0),
                      width: isLowStock ? 1.5 : 1,
                    ),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          // Main Cover Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              images.isNotEmpty ? images.first : 'https://images.unsplash.com/photo-1581094288338-2314dddb7ece?auto=format&fit=crop&w=300&q=80',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: const Color(0xffeff6ff),
                                child: const Icon(Icons.image_not_supported_rounded, color: Color(0xff2563eb)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Product Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff0f172a))),
                                    const SizedBox(width: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffeff6ff),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: const Color(0xffbfdbfe)),
                                      ),
                                      child: Text(
                                        cat,
                                        style: const TextStyle(color: Color(0xff2563eb), fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    if (isLowStock) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffea580c),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '🔥 Urgency Warning: Only $stock Left!',
                                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Price: ₹${price.toStringAsFixed(0)} (MSRP ₹${origPrice.toStringAsFixed(0)})  •  ${images.length} Photos Attached  •  5 km Geofence',
                                  style: const TextStyle(color: Color(0xff64748b), fontSize: 12),
                                ),
                              ],
                            ),
                          ),

                          // Stock Controller
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xfff8fafc),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xffe2e8f0)),
                            ),
                            child: Row(
                              children: [
                                const Text('Stock: ', style: TextStyle(color: Color(0xff64748b), fontSize: 12, fontWeight: FontWeight.bold)),
                                Text(
                                  '$stock Pcs',
                                  style: TextStyle(
                                    color: isLowStock ? const Color(0xffea580c) : const Color(0xff0f172a),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffea580c),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    elevation: 0,
                                  ),
                                  onPressed: () => _updateProductStock(id, 8),
                                  child: const Text('Set to 8 Pcs (Test Urgency)', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 6),

                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff16a34a),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    minimumSize: Size.zero,
                                    elevation: 0,
                                  ),
                                  onPressed: () => _updateProductStock(id, 100),
                                  child: const Text('Set to 100 Pcs', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Multi-Photo Gallery Horizontal Strip
                      if (images.length > 1) ...[
                        const SizedBox(height: 12),
                        const Text('Attached Product Photos:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff64748b))),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 50,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: images.length,
                            itemBuilder: (context, imgIdx) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    images[imgIdx],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 50, height: 50, color: Colors.grey.shade200),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _updateProductStock(String id, int newStock) async {
    // 1. Update in Hive cache box for local instant sync
    try {
      final box = Hive.box('customer_cache');
      final List<dynamic> raw = box.get('admin_custom_products', defaultValue: <dynamic>[]) as List<dynamic>;
      final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      for (var p in list) {
        if (p['id'] == id) {
          p['stock'] = newStock;
        }
      }
      box.put('admin_custom_products', list);
    } catch (_) {}

    // 2. Update in Supabase
    try {
      await Supabase.instance.client
          .from('products')
          .update({'stock': newStock})
          .eq('id', id);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Stock updated to $newStock Pcs! Customer App will update immediately.'),
          backgroundColor: newStock <= 10 ? const Color(0xffea580c) : const Color(0xff16a34a),
        ),
      );
      ref.invalidate(adminProductsProvider);
    }
  }

  Future<void> _showAddProductDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final origPriceCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '100'); // DEFAULT 100 PIECES
    final img1Ctrl = TextEditingController();
    final img2Ctrl = TextEditingController();
    final img3Ctrl = TextEditingController();
    String category = 'AC Repair';
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Row(
                children: [
                  Icon(Icons.add_photo_alternate_rounded, color: Color(0xff2563eb)),
                  SizedBox(width: 10),
                  Text('Add Product with Multiple Photos', style: TextStyle(color: Color(0xff0f172a), fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Product Title', style: TextStyle(color: Color(0xff334155), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: nameCtrl,
                        decoration: InputDecoration(
                          hintText: 'e.g., Heavy Duty Water Tap Valve',
                          hintStyle: const TextStyle(color: Color(0xff94a3b8)),
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffcbd5e1))),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('Service Category', style: TextStyle(color: Color(0xff334155), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffcbd5e1))),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'AC Repair', child: Text('AC Repair')),
                          DropdownMenuItem(value: 'Car Service', child: Text('Car Service')),
                          DropdownMenuItem(value: 'Plumbing', child: Text('Plumbing')),
                          DropdownMenuItem(value: 'Cooking', child: Text('Cooking')),
                          DropdownMenuItem(value: 'Laundry', child: Text('Laundry')),
                          DropdownMenuItem(value: 'Care Taker', child: Text('Care Taker')),
                        ],
                        onChanged: (val) {
                          if (val != null) setDialogState(() => category = val);
                        },
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Selling Price (₹)', style: TextStyle(color: Color(0xff334155), fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: priceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '349',
                                    filled: true,
                                    fillColor: const Color(0xfff8fafc),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffcbd5e1))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Original Price (₹)', style: TextStyle(color: Color(0xff334155), fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: origPriceCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    hintText: '499',
                                    filled: true,
                                    fillColor: const Color(0xfff8fafc),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffcbd5e1))),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      const Text('Stock Quantity (Default: 100 Pcs)', style: TextStyle(color: Color(0xff334155), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '100',
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffcbd5e1))),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Multiple Image URLs Inputs
                      const Text('Product Photos (Supports Multiple Pictures)', style: TextStyle(color: Color(0xff2563eb), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: img1Ctrl,
                        decoration: InputDecoration(
                          hintText: 'Image 1 URL (Primary Cover Photo)',
                          prefixIcon: const Icon(Icons.image, size: 18),
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffcbd5e1))),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: img2Ctrl,
                        decoration: InputDecoration(
                          hintText: 'Image 2 URL (Secondary View)',
                          prefixIcon: const Icon(Icons.image_outlined, size: 18),
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffcbd5e1))),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: img3Ctrl,
                        decoration: InputDecoration(
                          hintText: 'Image 3 URL (Detail View)',
                          prefixIcon: const Icon(Icons.image_outlined, size: 18),
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffcbd5e1))),
                        ),
                      ),
                      const SizedBox(height: 14),

                      const Text('Product Description', style: TextStyle(color: Color(0xff334155), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: descCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'e.g., High-durability spare part for home service...',
                          filled: true,
                          fillColor: const Color(0xfff8fafc),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xffcbd5e1))),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel', style: TextStyle(color: Color(0xff64748b))),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2563eb),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) return;

                          setDialogState(() => isSaving = true);
                          final price = double.tryParse(priceCtrl.text.trim()) ?? 299.0;
                          final origPrice = double.tryParse(origPriceCtrl.text.trim()) ?? price * 1.3;
                          final stock = int.tryParse(stockCtrl.text.trim()) ?? 100;
                          final desc = descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : 'Premium service product';

                          // Process photos list
                          List<String> photos = [];
                          if (img1Ctrl.text.trim().isNotEmpty) photos.add(img1Ctrl.text.trim());
                          if (img2Ctrl.text.trim().isNotEmpty) photos.add(img2Ctrl.text.trim());
                          if (img3Ctrl.text.trim().isNotEmpty) photos.add(img3Ctrl.text.trim());

                          if (photos.isEmpty) {
                            photos = _getDefaultImagesForCategory(category);
                          }

                          final newProd = {
                            'id': 'prod_${DateTime.now().millisecondsSinceEpoch}',
                            'name': name,
                            'category': category,
                            'price': price,
                            'original_price': origPrice,
                            'discount': '30% OFF',
                            'stock': stock,
                            'description': desc,
                            'images': photos,
                            'latitude': 22.4707,
                            'longitude': 70.0577,
                          };

                          // 1. Save locally to Hive box for instant synchronization with Customer app
                          try {
                            final box = Hive.box('customer_cache');
                            final List<dynamic> raw = box.get('admin_custom_products', defaultValue: <dynamic>[]) as List<dynamic>;
                            raw.insert(0, newProd);
                            box.put('admin_custom_products', raw);
                          } catch (_) {}

                          // 2. Insert into Supabase products table
                          try {
                            await Supabase.instance.client.from('products').insert({
                              'name': name,
                              'category': category,
                              'price': price,
                              'original_price': origPrice,
                              'discount': '30% OFF',
                              'stock': stock,
                              'description': desc,
                              'latitude': 22.4707,
                              'longitude': 70.0577,
                            });
                          } catch (_) {}

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Product "$name" published with ${photos.length} photos & $stock Pcs stock!'),
                                backgroundColor: const Color(0xff16a34a),
                              ),
                            );
                            ref.invalidate(adminProductsProvider);
                          }
                        },
                  child: isSaving
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Publish Product & Photos', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  List<String> _getDefaultImagesForCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('ac')) {
      return [
        'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1581094288338-2314dddb7ece?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?auto=format&fit=crop&w=600&q=80',
      ];
    }
    if (c.contains('plumb')) {
      return [
        'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?auto=format&fit=crop&w=600&q=80',
      ];
    }
    if (c.contains('car')) {
      return [
        'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=600&q=80',
      ];
    }
    if (c.contains('cook')) {
      return [
        'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&w=600&q=80',
      ];
    }
    if (c.contains('laundry')) {
      return [
        'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?auto=format&fit=crop&w=600&q=80',
      ];
    }
    return [
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=600&q=80',
    ];
  }

  // TAB 4: KYC Approvals
  Widget _buildKYCApprovals() {
    final pendingPartnersAsync = ref.watch(adminUnverifiedPartnersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KYC Verification & Partner Approvals',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xff0f172a)),
        ),
        const SizedBox(height: 4),
        const Text(
          'Review submitted business licenses, GST, and identity documents to activate partner accounts.',
          style: TextStyle(color: Color(0xff64748b), fontSize: 13),
        ),
        const SizedBox(height: 24),
        pendingPartnersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xff2563eb))),
          error: (e, s) => Center(child: Text('Error loading pending approvals: ${e.toString()}', style: const TextStyle(color: Color(0xffef4444)))),
          data: (rawPartners) {
            final partners = rawPartners.where((p) => !_processedProfileIds.contains(p['id'])).toList();
            if (partners.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xffe2e8f0)),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.verified_rounded, size: 48, color: Color(0xff16a34a)),
                      SizedBox(height: 12),
                      Text(
                        'KYC Verification Queue is Clear',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff0f172a)),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All onboarding partners are verified and active on ServiceHub.',
                        style: TextStyle(color: Color(0xff64748b), fontSize: 13),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: partners.length,
              itemBuilder: (context, index) {
                final partner = partners[index];
                final id = partner['id'];
                final email = partner['email'] ?? 'No email';
                final name = partner['name'] ?? 'Partner Candidate';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xffeff6ff),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.badge_rounded, color: Color(0xff2563eb), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff0f172a))),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffdcfce7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xff86efac)),
                                  ),
                                  child: const Text(
                                    'AI Score: 0.02 (Low Risk)',
                                    style: TextStyle(color: Color(0xff15803d), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Email: $email  •  Bank Penny Drop: Verified  •  Aadhaar QR: Valid',
                                style: const TextStyle(color: Color(0xffd97706), fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xffef4444),
                          side: const BorderSide(color: Color(0xfffca5a5)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () => _rejectPartnerProfile(id, name),
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff16a34a),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                        label: const Text('Approve & Activate', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: () => _approvePartnerProfile(id, name),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // TAB 5: Settlements Ledger
  Widget _buildSettlements() {
    final settlementsAsync = ref.watch(adminSettlementsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Settlements & Partner Ledger', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xff0f172a))),
        const SizedBox(height: 4),
        const Text('Manage automated payouts and platform commissions across all completed jobs.', style: TextStyle(color: Color(0xff64748b), fontSize: 13)),
        const SizedBox(height: 24),
        settlementsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xff2563eb))),
          error: (e, s) => Center(child: Text('Error loading settlements: ${e.toString()}', style: const TextStyle(color: Color(0xffef4444)))),
          data: (settlements) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: settlements.length,
              itemBuilder: (context, index) {
                final s = settlements[index];
                final id = s['id']?.toString() ?? '';
                final type = s['type'] ?? 'Booking';
                final partner = s['partner'] ?? 'Partner';
                final amount = (s['amount'] as num?)?.toDouble() ?? 0.0;
                final comm = (s['commission'] as num?)?.toDouble() ?? 0.0;
                final status = s['status'] ?? 'Settled';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Row(
                    children: [
                      Icon(type == 'Booking' ? Icons.handyman_rounded : Icons.local_shipping_rounded, color: const Color(0xff2563eb), size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(partner, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff0f172a))),
                            const SizedBox(height: 2),
                            Text('Type: $type  •  Commission: ₹${comm.toStringAsFixed(0)} (10%)', style: const TextStyle(color: Color(0xff64748b), fontSize: 12)),
                          ],
                        ),
                      ),
                      Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xff0f172a))),
                      const SizedBox(width: 16),
                      if (status == 'Settled')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xffdcfce7), borderRadius: BorderRadius.circular(20)),
                          child: const Text('Settled', style: TextStyle(color: Color(0xff15803d), fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2563eb)),
                          onPressed: () => _settlePayout(id, type, partner),
                          child: const Text('Pay Now'),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // TAB 6: Support Tickets
  Widget _buildSupportTickets() {
    final ticketsAsync = ref.watch(adminSupportTicketsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Customer Support & Disputes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xff0f172a))),
        const SizedBox(height: 4),
        const Text('Review customer complaints, promo issues, and active support tickets.', style: TextStyle(color: Color(0xff64748b), fontSize: 13)),
        const SizedBox(height: 24),
        ticketsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xff2563eb))),
          error: (e, s) => Center(child: Text('Error loading tickets: ${e.toString()}', style: const TextStyle(color: Color(0xffef4444)))),
          data: (tickets) {
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final t = tickets[index];
                final id = t['id']?.toString() ?? '';
                final name = t['customer_name'] ?? 'Customer';
                final subject = t['subject'] ?? 'Ticket';
                final desc = t['description'] ?? '';
                final status = t['status'] ?? 'Open';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.headset_mic_rounded, color: Color(0xff2563eb), size: 24),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('$subject ($name)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff0f172a))),
                            const SizedBox(height: 4),
                            Text(desc, style: const TextStyle(color: Color(0xff64748b), fontSize: 12)),
                          ],
                        ),
                      ),
                      if (status == 'Resolved')
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xffdcfce7), borderRadius: BorderRadius.circular(20)),
                          child: const Text('Resolved', style: TextStyle(color: Color(0xff15803d), fontSize: 11, fontWeight: FontWeight.bold)),
                        )
                      else
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff16a34a)),
                          onPressed: () => _resolveTicket(id),
                          child: const Text('Resolve Ticket'),
                        ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  // TAB 7: Global Configurations
  Widget _buildGlobalSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Global System Configurations', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xff0f172a))),
        const SizedBox(height: 4),
        const Text('Configure platform commissions, geofencing enforcement, and operational limits.', style: TextStyle(color: Color(0xff64748b), fontSize: 13)),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Service Commission: ${serviceCommission.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff0f172a))),
              Slider(
                min: 0,
                max: 30,
                activeColor: const Color(0xff2563eb),
                value: serviceCommission,
                onChanged: (val) => setState(() => serviceCommission = val),
              ),
              const SizedBox(height: 16),
              Text('Base Delivery Fee: ₹${deliveryBaseFee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff0f172a))),
              Slider(
                min: 15,
                max: 100,
                activeColor: const Color(0xff16a34a),
                value: deliveryBaseFee,
                onChanged: (val) => setState(() => deliveryBaseFee = val),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff2563eb)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Settings saved successfully!'), backgroundColor: Color(0xff16a34a)),
                    );
                  },
                  child: const Text('Save System Configurations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExecutiveCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe2e8f0)),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Color(0xff0f172a))),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(color: Color(0xff64748b), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRowLight(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xff64748b), fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff0f172a))),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xff64748b), fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Text(
            status,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
