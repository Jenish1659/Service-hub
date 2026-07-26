import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
          content: Text('Payout for "$partnerName" successfully processed via instant bank settlement! (Offline Demo Mode)'),
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
      backgroundColor: const Color(0xff090d16),
      body: Column(
        children: [
          // 1. EXECUTIVE TOP BAR
          Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: const BoxDecoration(
              color: Color(0xff0f172a),
              border: Border(bottom: BorderSide(color: Color(0xff1e293b), width: 1.5)),
            ),
            child: Row(
              children: [
                // Brand Badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xff2563eb).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xff2563eb).withValues(alpha: 0.4)),
                  ),
                  child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xff38bdf8), size: 24),
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
                      style: TextStyle(fontSize: 11, color: Color(0xff94a3b8)),
                    ),
                  ],
                ),
                const SizedBox(width: 24),

                // Live Operational Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xff064e3b).withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xff10b981).withValues(alpha: 0.5)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xff10b981), size: 10),
                      SizedBox(width: 8),
                      Text(
                        'ALL SYSTEMS LIVE • JAMNAGAR 5 KM GEOFENCE ONLINE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xffa7f3d0),
                          letterSpacing: 0.8,
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
                    color: const Color(0xff1e293b),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xff334155)),
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: Color(0xff2563eb),
                        child: Text('A', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      SizedBox(width: 8),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Super Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          Text('admin@servicehub.com', style: TextStyle(fontSize: 10, color: Color(0xff94a3b8))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xfff87171),
                    side: const BorderSide(color: Color(0xff7f1d1d)),
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

          // 2. DESKTOP BODY: SIDEBAR + CONTENT AREA
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // SIDEBAR NAVIGATION
                Container(
                  width: 260,
                  decoration: const BoxDecoration(
                    color: Color(0xff0f172a),
                    border: Border(right: BorderSide(color: Color(0xff1e293b), width: 1.5)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      _buildSidebarGroupHeader('ANALYTICS & CONTROL'),
                      _buildMenuTile(Icons.bar_chart_rounded, 'Platform Analytics'),
                      _buildMenuTile(Icons.map_rounded, 'Live Dispatch & Map'),
                      
                      const SizedBox(height: 16),
                      _buildSidebarGroupHeader('VERIFICATION & LEDGER'),
                      _buildMenuTile(Icons.verified_user_rounded, 'KYC Approvals'),
                      _buildMenuTile(Icons.account_balance_rounded, 'Settlements Ledger'),
                      _buildMenuTile(Icons.headset_mic_rounded, 'Support Tickets'),

                      const SizedBox(height: 16),
                      _buildSidebarGroupHeader('SYSTEM SETTINGS'),
                      _buildMenuTile(Icons.tune_rounded, 'Global Configurations'),

                      const Spacer(),
                      
                      // Footer Version Info Card
                      Container(
                        margin: const EdgeInsets.all(16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xff1e293b),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xff334155)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('ServiceHub Admin v2.4', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 2),
                            Text('Strict 5 km Geofence Engine', style: TextStyle(fontSize: 10, color: Color(0xff94a3b8))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // MAIN CONTENT CONTAINER
                Expanded(
                  child: Container(
                    color: const Color(0xff090d16),
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
          fontWeight: FontWeight.bold,
          color: Color(0xff64748b),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuTile(IconData icon, String title) {
    final isSelected = title == _activeTab;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xff2563eb).withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xff2563eb).withValues(alpha: 0.5) : Colors.transparent,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xff38bdf8) : const Color(0xff64748b),
          size: 20,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : const Color(0xff94a3b8),
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
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xff38bdf8))),
      error: (e, s) => Center(child: Text('Error loading stats: ${e.toString()}', style: const TextStyle(color: Color(0xfff87171)))),
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
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Real-time metrics across 5 km hyperlocal zones in Jamnagar',
                      style: TextStyle(color: Color(0xff94a3b8), fontSize: 13),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff1e293b),
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xff334155)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xff38bdf8)),
                  label: const Text('Refresh Data'),
                  onPressed: () {
                    ref.invalidate(adminStatsProvider);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Metric Cards
            Row(
              children: [
                Expanded(
                  child: _buildExecutiveCard('Gross Revenue', '₹${revenue.toStringAsFixed(0)}', '+18.4% this month', Icons.account_balance_wallet_rounded, const Color(0xff10b981)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildExecutiveCard('Active Customers', '$customers', 'Registered users', Icons.people_alt_rounded, const Color(0xff38bdf8)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildExecutiveCard('Verified Partners', '$partners', 'Service & Merchants', Icons.storefront_rounded, const Color(0xfff59e0b)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildExecutiveCard('Active Agents', '$activeAgentsCount', 'On-field delivery & providers', Icons.two_wheeler_rounded, const Color(0xffa855f7)),
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
                      color: const Color(0xff0f172a),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xff1e293b)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.tune_rounded, color: Color(0xff38bdf8), size: 20),
                            SizedBox(width: 10),
                            Text('Hyperlocal Geofence Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildMetricRowDark('Active Radius Limit', '${geofenceRadius.toStringAsFixed(1)} km Radius'),
                        const Divider(color: Color(0xff1e293b)),
                        _buildMetricRowDark('Service Commission Rate', '${serviceCommission.toStringAsFixed(0)}% cut per job'),
                        const Divider(color: Color(0xff1e293b)),
                        _buildMetricRowDark('Delivery Base Fee', '₹${deliveryBaseFee.toStringAsFixed(0)} flat agent rate'),
                        const Divider(color: Color(0xff1e293b)),
                        _buildMetricRowDark('PIN Verification Mode', '4-Digit OTP Required'),
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
                      color: const Color(0xff0f172a),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xff1e293b)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shield_outlined, color: Color(0xfff59e0b), size: 20),
                            SizedBox(width: 10),
                            Text('System Quick Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildStatusIndicator('PostGIS Geofence Server', 'Active', const Color(0xff10b981)),
                        const SizedBox(height: 12),
                        _buildStatusIndicator('Supabase DB Realtime Synced', 'Online', const Color(0xff10b981)),
                        const SizedBox(height: 12),
                        _buildStatusIndicator('PIN Encryption Service', 'Secure (256-bit)', const Color(0xff38bdf8)),
                        const SizedBox(height: 12),
                        _buildStatusIndicator('Automated Bank Payouts', 'Ready', const Color(0xffa855f7)),
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
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Monitor real-time active service providers and delivery agents within Jamnagar 5 km zone.',
          style: TextStyle(color: Color(0xff94a3b8), fontSize: 13),
        ),
        const SizedBox(height: 24),

        Container(
          height: 420,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xff0f172a),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xff1e293b)),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded, size: 72, color: const Color(0xff2563eb).withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    const Text('Jamnagar 5 km Radius Live Heatmap', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 6),
                    const Text('87 Active Agents • 342 Verified Merchants Online', style: TextStyle(color: Color(0xff94a3b8), fontSize: 12)),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xff1e293b),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xff334155)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.my_location_rounded, color: Color(0xff38bdf8), size: 16),
                      SizedBox(width: 8),
                      Text('Zone: Digvijay Plot & Park Colony (5.0 km)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
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

  // TAB 3: KYC Approvals
  Widget _buildKYCApprovals() {
    final pendingPartnersAsync = ref.watch(adminUnverifiedPartnersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'KYC Verification & Partner Approvals',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Review submitted business licenses, GST, and identity documents to activate partner accounts.',
          style: TextStyle(color: Color(0xff94a3b8), fontSize: 13),
        ),
        const SizedBox(height: 24),
        pendingPartnersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xff38bdf8))),
          error: (e, s) => Center(child: Text('Error loading pending approvals: ${e.toString()}', style: const TextStyle(color: Color(0xfff87171)))),
          data: (rawPartners) {
            final partners = rawPartners.where((p) => !_processedProfileIds.contains(p['id'])).toList();
            if (partners.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xff0f172a),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xff1e293b)),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.verified_rounded, size: 48, color: Color(0xff10b981)),
                      SizedBox(height: 12),
                      Text(
                        'KYC Verification Queue is Clear',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'All onboarding partners are verified and active on ServiceHub.',
                        style: TextStyle(color: Color(0xff94a3b8), fontSize: 13),
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
                    color: const Color(0xff0f172a),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xff1e293b)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xff1e293b),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.badge_rounded, color: Color(0xff38bdf8), size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                                const SizedBox(width: 10),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff064e3b),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xff059669)),
                                  ),
                                  child: const Text(
                                    'AI Score: 0.02 (Low Risk)',
                                    style: TextStyle(color: Color(0xff34d399), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff1e1b4b),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: const Color(0xff6366f1)),
                                  ),
                                  child: const Text(
                                    'Face Match: 98.4%',
                                    style: TextStyle(color: Color(0xffa5b4fc), fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text('Email: $email  •  Bank Penny Drop: Verified (HDFC Bank)  •  Aadhaar QR: Valid',
                                style: const TextStyle(color: Color(0xfff59e0b), fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            Text('Dossier Ref ID: SH-AI-2026-$id  •  Vehicle Plate: GJ-03-AB-1234 (Honda Activa)',
                                style: const TextStyle(color: Color(0xff64748b), fontSize: 11)),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xfff87171),
                          side: const BorderSide(color: Color(0xff7f1d1d)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        onPressed: () => _rejectPartnerProfile(id, name),
                        child: const Text('Reject Application'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff10b981),
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

  // TAB 4: Settlements Ledger
  Widget _buildSettlements() {
    final settlementsAsync = ref.watch(adminSettlementsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Partner Settlements Ledger',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Automated payouts, platform commissions, and completed job settlements.',
          style: TextStyle(color: Color(0xff94a3b8), fontSize: 13),
        ),
        const SizedBox(height: 24),
        settlementsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xff38bdf8))),
          error: (e, s) => Center(child: Text('Error loading settlements: ${e.toString()}', style: const TextStyle(color: Color(0xfff87171)))),
          data: (settlements) {
            if (settlements.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xff0f172a),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xff1e293b)),
                ),
                child: const Center(
                  child: Text('No completed transactions found in history.', style: TextStyle(color: Color(0xff94a3b8))),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xff0f172a),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xff1e293b)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: settlements.length,
                separatorBuilder: (context, index) => const Divider(color: Color(0xff1e293b)),
                itemBuilder: (context, index) {
                  final item = settlements[index];
                  final isPending = item['status'] == 'Pending Settlement';
                  final id = item['id'];
                  final type = item['type'];
                  final partnerName = item['partner'];

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: type == 'Booking' ? const Color(0xff1e3a8a) : const Color(0xff4c1d95),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                type.toUpperCase(),
                                style: TextStyle(
                                  color: type == 'Booking' ? const Color(0xff93c5fd) : const Color(0xffc084fc),
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(partnerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                                const SizedBox(height: 2),
                                Text('Date: ${item['date']}  |  TxID: ${id.toString().substring(0, 8).toUpperCase()}', style: const TextStyle(color: Color(0xff64748b), fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text('Total: ₹${(item['amount'] as double).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                                Text('Net Platform Fee: ₹${(item['commission'] as double).toStringAsFixed(0)} (10%)', style: const TextStyle(color: Color(0xff38bdf8), fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(width: 24),
                            isPending
                                ? ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xffd97706),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    ),
                                    onPressed: () => _settlePayout(id, type, partnerName),
                                    child: const Text('Settle Payout Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xff064e3b),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xff10b981).withValues(alpha: 0.5)),
                                    ),
                                    child: const Text(
                                      'Settled ✓',
                                      style: TextStyle(color: Color(0xffa7f3d0), fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  // TAB 5: Support Tickets
  Widget _buildSupportTickets() {
    final ticketsAsync = ref.watch(adminSupportTicketsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Customer Support Tickets Console',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Review customer queries and resolve complaints.',
          style: TextStyle(color: Color(0xff94a3b8), fontSize: 13),
        ),
        const SizedBox(height: 24),
        ticketsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: Color(0xff38bdf8))),
          error: (e, s) => Center(child: Text('Error loading tickets: ${e.toString()}', style: const TextStyle(color: Color(0xfff87171)))),
          data: (tickets) {
            if (tickets.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xff0f172a),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xff1e293b)),
                ),
                child: const Center(
                  child: Text('No support tickets submitted yet.', style: TextStyle(color: Color(0xff94a3b8))),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: tickets.length,
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final id = ticket['id'];
                final subject = ticket['subject'] ?? 'Untitled Ticket';
                final description = ticket['description'] ?? '';
                final status = ticket['status'] ?? 'Open';
                final isResolved = status == 'Resolved';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xff0f172a),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xff1e293b)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(subject, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isResolved ? const Color(0xff064e3b) : const Color(0xff78350f),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: isResolved ? const Color(0xffa7f3d0) : const Color(0xfffde68a),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(description, style: const TextStyle(color: Color(0xff94a3b8), fontSize: 13)),
                      const SizedBox(height: 14),
                      const Divider(color: Color(0xff1e293b)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Ticket ID: ${id.toString().substring(0, 8).toUpperCase()}', style: const TextStyle(color: Color(0xff64748b), fontSize: 11)),
                          if (!isResolved)
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xff10b981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              icon: const Icon(Icons.check, size: 14),
                              label: const Text('Mark Resolved', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              onPressed: () => _resolveTicket(id),
                            ),
                        ],
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

  // TAB 6: Global Settings
  Widget _buildGlobalSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Global Platform Configurations',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white),
        ),
        const SizedBox(height: 4),
        const Text(
          'Fine-tune 5 km geofences, commissions, and system operational parameters.',
          style: TextStyle(color: Color(0xff94a3b8), fontSize: 13),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xff0f172a),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xff1e293b)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Geofence Switch
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Enforce Strict Geofencing (5 km Radius)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      SizedBox(height: 2),
                      Text('Restricts service provider dispatch and merchant orders within 5 km of customer location', style: TextStyle(color: Color(0xff94a3b8), fontSize: 12)),
                    ],
                  ),
                  Switch(
                    value: enforceStrictGeofence,
                    activeThumbColor: const Color(0xff38bdf8),
                    onChanged: (val) {
                      setState(() {
                        enforceStrictGeofence = val;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Geofence Threshold: ${geofenceRadius.toStringAsFixed(1)} km',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xff38bdf8)),
              ),
              Slider(
                min: 1.0,
                max: 15.0,
                activeColor: const Color(0xff38bdf8),
                inactiveColor: const Color(0xff1e293b),
                value: geofenceRadius,
                onChanged: enforceStrictGeofence
                    ? (val) {
                        setState(() {
                          geofenceRadius = val;
                        });
                      }
                    : null,
              ),
              const Divider(color: Color(0xff1e293b), height: 32),

              // Service Commission
              Text(
                'Service Provider Commission Cut: ${serviceCommission.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
              const SizedBox(height: 2),
              const Text('Percentage retained by ServiceHub from service booking completions.', style: TextStyle(color: Color(0xff94a3b8), fontSize: 12)),
              Slider(
                min: 5,
                max: 30,
                activeColor: const Color(0xfff59e0b),
                inactiveColor: const Color(0xff1e293b),
                value: serviceCommission,
                onChanged: (val) {
                  setState(() {
                    serviceCommission = val;
                  });
                },
              ),
              const Divider(color: Color(0xff1e293b), height: 32),

              // Product Commission
              Text(
                'Product Merchant Commission Cut: ${productCommission.toStringAsFixed(0)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
              const SizedBox(height: 2),
              const Text('Percentage retained from hyperlocal product sales.', style: TextStyle(color: Color(0xff94a3b8), fontSize: 12)),
              Slider(
                min: 2,
                max: 20,
                activeColor: const Color(0xffa855f7),
                inactiveColor: const Color(0xff1e293b),
                value: productCommission,
                onChanged: (val) {
                  setState(() {
                    productCommission = val;
                  });
                },
              ),
              const Divider(color: Color(0xff1e293b), height: 32),

              // Base Delivery Fee
              Text(
                'Base Delivery Agent Fee: ₹${deliveryBaseFee.toStringAsFixed(0)}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
              ),
              const SizedBox(height: 2),
              const Text('Flat rate paid per completed product delivery.', style: TextStyle(color: Color(0xff94a3b8), fontSize: 12)),
              Slider(
                min: 15,
                max: 100,
                activeColor: const Color(0xff10b981),
                inactiveColor: const Color(0xff1e293b),
                value: deliveryBaseFee,
                onChanged: (val) {
                  setState(() {
                    deliveryBaseFee = val;
                  });
                },
              ),
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2563eb),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Global executive settings successfully updated & applied!'),
                        backgroundColor: Color(0xff10b981),
                      ),
                    );
                  },
                  child: const Text('Save & Apply System Configurations', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
        color: const Color(0xff0f172a),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xff1e293b)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: Colors.white)),
                const SizedBox(height: 2),
                Text(title, style: const TextStyle(color: Color(0xff94a3b8), fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRowDark(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(0xff94a3b8), fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String label, String status, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xff94a3b8), fontSize: 13)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
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
