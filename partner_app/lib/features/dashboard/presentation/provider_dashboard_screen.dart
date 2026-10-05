import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/storage/local_registration_cache.dart';
import '../../../core/services/live_booking_sync_service.dart';
import 'ac_provider_dashboard_controller.dart';

class ProviderDashboardScreen extends ConsumerStatefulWidget {
  const ProviderDashboardScreen({super.key});

  @override
  ConsumerState<ProviderDashboardScreen> createState() => _ProviderDashboardScreenState();
}

class _ProviderDashboardScreenState extends ConsumerState<ProviderDashboardScreen> with WidgetsBindingObserver {
  int _currentBottomNavIndex = 0;
  bool _hasNotificationPermission = true;
  bool _hasDisplayOverAppsPermission = true;
  bool _isOverlayShowing = false;
  String? _lastShownOfferId;
  String _partnerCity = 'Gujarat';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _verifyPartnerApprovalStatus();
  }

  Future<void> _verifyPartnerApprovalStatus() async {
    final active = await LocalRegistrationCache.getActiveServiceProvider() ??
        await LocalRegistrationCache.getActivePartner();
    if (active == null) {
      if (mounted) GoRouter.maybeOf(context)?.go('/login/service-provider');
      return;
    }

    final role = (active['role_name'] ?? active['role'] ?? '').toString().toLowerCase();
    if (role.isNotEmpty && role != 'service_provider' && !role.contains('provider') && !role.contains('expert') && !role.contains('technician')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Access restricted: Logged in account is registered as $role, not Service Provider.'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (role.contains('shop') || role.contains('store')) {
          GoRouter.maybeOf(context)?.go('/dashboard/shopkeeper');
        } else if (role.contains('delivery') || role.contains('rider')) {
          GoRouter.maybeOf(context)?.go('/dashboard/delivery');
        } else {
          GoRouter.maybeOf(context)?.go('/role-selection');
        }
      }
      return;
    }

    final rawCity = (active['city'] ?? '').toString().trim();
    if (rawCity.isNotEmpty && mounted) {
      setState(() {
        _partnerCity = rawCity;
      });
    }
    final syncRecord = LiveBookingSyncService.instance.getPartnerVerification(active['id']?.toString() ?? '') ??
        LiveBookingSyncService.instance.getPartnerVerification(active['user_id']?.toString() ?? '') ??
        LiveBookingSyncService.instance.getPartnerVerification(active['phone']?.toString() ?? '');
    final syncStatus = (syncRecord?['status'] ?? syncRecord?['verification_status'] ?? '').toString().toUpperCase();
    final status = (syncStatus.isNotEmpty ? syncStatus : (active['verification_status'] ?? active['status'] ?? 'PENDING')).toString().toUpperCase();

    var isApproved = status == 'VERIFIED' || status == 'APPROVED';

    if (!isApproved) {
      try {
        final client = Supabase.instance.client;
        final uId = (active['user_id'] ?? active['id'] ?? '').toString();
        final pId = (active['partner_id'] ?? '').toString();
        final phone = (active['phone'] ?? '').toString();
        final username = (active['username'] ?? '').toString().trim();
        final cleanDigits = phone.replaceAll(RegExp(r'\D'), '');
        final last10 = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : '';

        // 1. Check users table
        Map<String, dynamic>? uRes;
        if (uId.isNotEmpty && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(uId)) {
          uRes = await client.from('users').select('account_status, user_id').eq('user_id', uId).maybeSingle();
        }
        if (uRes == null && last10.length >= 10) {
          uRes = await client
              .from('users')
              .select('account_status, user_id')
              .or('phone.eq.$cleanDigits,phone.eq.+91$last10,phone.ilike.*$last10*')
              .limit(1)
              .maybeSingle();
        }
        if (uRes == null && username.isNotEmpty) {
          uRes = await client
              .from('users')
              .select('account_status, user_id')
              .eq('username', username)
              .limit(1)
              .maybeSingle();
        }

        if (uRes != null) {
          final userAccStatus = (uRes['account_status'] ?? '').toString().toUpperCase();
          final targetUid = uRes['user_id']?.toString() ?? uId;
          if (userAccStatus == 'ACTIVE') {
            isApproved = true;
          } else if (targetUid.isNotEmpty) {
            final vr = await client
                .from('verification_requests')
                .select('status')
                .eq('user_id', targetUid)
                .order('submitted_at', ascending: false)
                .limit(1)
                .maybeSingle();
            if (vr != null && (vr['status'] == 'APPROVED' || vr['status'] == 'VERIFIED')) {
              isApproved = true;
            }
          }
        }

        // 2. Check partners table directly
        if (!isApproved) {
          if (pId.isNotEmpty && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(pId)) {
            final pRes = await client.from('partners').select('verification_status').eq('partner_id', pId).maybeSingle();
            if (pRes != null && (pRes['verification_status'] == 'VERIFIED' || pRes['verification_status'] == 'APPROVED')) {
              isApproved = true;
            }
          }
          final checkUid = (uRes?['user_id']?.toString() ?? uId);
          if (!isApproved && checkUid.isNotEmpty && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(checkUid)) {
            final pRes = await client.from('partners').select('verification_status').eq('user_id', checkUid).maybeSingle();
            if (pRes != null && (pRes['verification_status'] == 'VERIFIED' || pRes['verification_status'] == 'APPROVED')) {
              isApproved = true;
            }
          }
        }

        if (isApproved) {
          await LocalRegistrationCache.updateActiveServiceProvider({
            ...active,
            'verification_status': 'VERIFIED',
            'status': 'APPROVED',
            'account_status': 'ACTIVE',
          });
        }
      } catch (e) {
        debugPrint('[ProviderDashboard] Live Supabase verification error: $e');
      }
    }

    if (!isApproved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Application is pending Admin approval. Please login after Admin approval.'),
            backgroundColor: Color(0xFFD97706),
            behavior: SnackBarBehavior.floating,
          ),
        );
        GoRouter.maybeOf(context)?.go('/login/service-provider');
      }
    } else {
      _checkAndRequestPermissions();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionStatuses();
      ref.read(acProviderDashboardProvider.notifier).refresh();
    }
  }

  Future<void> _checkAndRequestPermissions() async {
    try {
      final notifStatus = await Permission.notification.status;
      if (!notifStatus.isGranted) {
        final req = await Permission.notification.request();
        if (mounted) setState(() => _hasNotificationPermission = req.isGranted);
      } else {
        if (mounted) setState(() => _hasNotificationPermission = true);
      }

      // Check Display Over Other Apps permission (SYSTEM_ALERT_WINDOW) for service providers
      final overlayStatus = await Permission.systemAlertWindow.status;
      if (mounted) {
        setState(() {
          _hasDisplayOverAppsPermission = overlayStatus.isGranted;
        });
      }

      await Permission.locationWhenInUse.request();
    } catch (_) {}
  }

  Future<void> _checkPermissionStatuses() async {
    try {
      final notifStatus = await Permission.notification.status;
      final overlayStatus = await Permission.systemAlertWindow.status;
      if (mounted) {
        setState(() {
          _hasNotificationPermission = notifStatus.isGranted;
          _hasDisplayOverAppsPermission = overlayStatus.isGranted;
        });
      }
    } catch (_) {}
  }

  Future<void> _requestDisplayOverAppsPermission() async {
    try {
      final res = await Permission.systemAlertWindow.request();
      if (!res.isGranted) {
        await openAppSettings();
      }
      final updated = await Permission.systemAlertWindow.status;
      if (mounted) {
        setState(() {
          _hasDisplayOverAppsPermission = updated.isGranted;
        });
      }
    } catch (_) {}
  }

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

  // ignore: unused_element
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

  void _showIncomingJobOverlay(BuildContext context, Map<String, dynamic> offer) async {
    if (_isOverlayShowing) return;

    // Strict Role Isolation: Only verified service_provider accounts can see AC alerts
    final active = await LocalRegistrationCache.getActiveServiceProvider() ??
        await LocalRegistrationCache.getActivePartner();
    final role = (active?['role_name'] ?? active?['role'] ?? '').toString().toLowerCase();
    if (role.contains('shop') || role.contains('store') || role.contains('delivery') || role.contains('rider')) {
      debugPrint('[ProviderDashboard] Suppressing overlay alert for non-service_provider: $role');
      return;
    }

    _isOverlayShowing = true;
    _lastShownOfferId = (offer['booking_id'] ?? offer['id'] ?? offer['request_id'] ?? '').toString();

    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return _IncomingJobAlertOverlayDialog(
          offer: offer,
          onAccept: () async {
            Navigator.of(dialogCtx, rootNavigator: true).pop();
            _isOverlayShowing = false;
            final result = await ref.read(acProviderDashboardProvider.notifier).acceptOffer(offer);
            if (result['success'] == true) {
              if (context.mounted) {
                final activeJob = result['activeJob'] as Map<String, dynamic>? ?? offer;
                context.push('/dashboard/ac-job-navigation', extra: activeJob);
              }
            } else {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message'] ?? 'This job was already accepted by another technician.'),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          onDecline: () {
            Navigator.of(dialogCtx, rootNavigator: true).pop();
            _isOverlayShowing = false;
            ref.read(acProviderDashboardProvider.notifier).declineOffer(offer);
          },
        );
      },
    ).then((_) {
      _isOverlayShowing = false;
    });
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
                  const Expanded(
                    child: Text(
                      '⚡ Live AC Service Requests',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(width: 8),
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
                                    onPressed: () async {
                                      final result = await ref.read(acProviderDashboardProvider.notifier).acceptOffer(offer);
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (result['success'] == true) {
                                        if (context.mounted) {
                                          final activeJob = result['activeJob'] as Map<String, dynamic>? ?? offer;
                                          context.push('/dashboard/ac-job-navigation', extra: activeJob);
                                        }
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(result['message'] ?? 'This job was already accepted by another technician.'),
                                              backgroundColor: const Color(0xFFDC2626),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    child: const Text('ACCEPT & NAVIGATE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

    // Auto-trigger Display Over App Heads-up Alert Dialog for new incoming AC offers
    ref.listen<ACProviderDashboardState>(acProviderDashboardProvider, (previous, next) {
      if (next.isOnline && next.activeJob == null && next.incomingOffers.isNotEmpty) {
        final topOffer = next.incomingOffers.first;
        final offerId = (topOffer['booking_id'] ?? topOffer['id'] ?? topOffer['request_id'] ?? '').toString();
        if (offerId != _lastShownOfferId && !_isOverlayShowing) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showIncomingJobOverlay(context, topOffer);
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FD),
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
                        // 0. NOTIFICATION PERMISSION BANNER (If not granted)
                        if (!_hasNotificationPermission) ...[
                          _buildNotificationPermissionBanner(),
                          const SizedBox(height: 14),
                        ],

                        // 0.1 DISPLAY OVER OTHER APPS PERMISSION BANNER (If not granted)
                        if (!_hasDisplayOverAppsPermission) ...[
                          _buildDisplayOverAppsPermissionBanner(),
                          const SizedBox(height: 14),
                        ],

                        // 1. ONLINE STATUS TOGGLE CARD
                        _buildOnlineStatusCard(dashboardState),
                        const SizedBox(height: 16),

                        // 2. ACTIVE JOB IN PROGRESS CARD (If an active job exists)
                        if (dashboardState.activeJob != null) ...[
                          _buildActiveJobProgressCard(dashboardState.activeJob!),
                          const SizedBox(height: 16),
                        ],

                        // 3. OFFLINE NOTICE OR LIVE REQUESTS BANNER
                        if (!dashboardState.isOnline) ...[
                          _buildOfflineWarningBanner(),
                          const SizedBox(height: 16),
                        ] else if (dashboardState.incomingOffers.isNotEmpty) ...[
                          _buildLiveOffersBanner(dashboardState),
                          const SizedBox(height: 16),
                        ],

                        // 4. TODAY'S WORK OVERVIEW SECTION (4 CARDS: New Requests, In Progress, Completed, Cancelled)
                        _buildWorkOverviewSection(dashboardState),
                        const SizedBox(height: 18),

                        // 5. BUSINESS OVERVIEW (TODAY) SECTION (4 CARDS: Today's Earnings, Jobs Completed, Average Rating, Repeat Customers)
                        _buildBusinessOverviewSection(dashboardState),
                        const SizedBox(height: 18),

                        // 6. COMPLETED JOBS – TODAY SECTION (Customer Name, Time, Price, Paid Badge ONLY)
                        _buildCompletedJobsSection(dashboardState),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
              ),
            ),
      bottomNavigationBar: _buildElevatedBottomNav(context, dashboardState),
    );
  }

  // --- 1. Custom App Bar matching exact uploaded design ---
  PreferredSizeWidget _buildCustomHeader(BuildContext context, ACProviderDashboardState state) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF1D4ED8), size: 28),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  '${_getGreeting()}, ${state.providerName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              const Text('👋', style: TextStyle(fontSize: 16)),
            ],
          ),
          const SizedBox(height: 1),
          const Text(
            'Stay Active, Keep Growing',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
      actions: [
        // Notification bell with red badge
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 26),
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

        // Profile Avatar with Online Indicator Dot
        GestureDetector(
          onTap: () => context.push('/profile'),
          child: Padding(
            padding: const EdgeInsets.only(right: 16, left: 4),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF2563EB),
                    border: Border.all(color: const Color(0xFF93C5FD), width: 1.5),
                  ),
                  child: const Center(
                    child: Icon(Icons.person, color: Colors.white, size: 24),
                  ),
                ),
                if (state.isOnline)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- 1.5 Notification Permission Banner ---
  Widget _buildNotificationPermissionBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFCA5A5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0AEF4444),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_off_rounded, color: Color(0xFFDC2626), size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications are Disabled',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Enable notifications to get instant alerts for incoming AC bookings.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB91C1C),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final res = await Permission.notification.request();
              if (res.isPermanentlyDenied) {
                await openAppSettings();
              }
              setState(() {
                _hasNotificationPermission = res.isGranted;
              });
            },
            child: const Text('Enable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // --- 1.6 Display Over Other Apps Permission Banner ---
  Widget _buildDisplayOverAppsPermissionBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE68A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0AD97706),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.layers_rounded, color: Color(0xFFD97706), size: 22),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Display Over Other Apps Required',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF92400E),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Enable to receive full-screen incoming AC service job alerts with YES/NO actions even when other apps are open.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFFB45309),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _requestDisplayOverAppsPermission,
            child: const Text('Enable', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showLiveRadarMapModal(BuildContext context, ACProviderDashboardState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 12),
              _buildLiveServiceAreaMapCard(state),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  key: const Key('open_fullscreen_radar_map_button'),
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.push('/dashboard/provider/map');
                  },
                  icon: const Icon(Icons.fullscreen_rounded, color: Colors.white),
                  label: const Text(
                    'Open Full-Screen Map',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- 1.8 Live Service Area & Coverage Radar Map Card ---
  Widget _buildLiveServiceAreaMapCard(ACProviderDashboardState state) {
    const partnerCenter = LatLng(22.4707, 70.0577); // Jamnagar Central Operations Hub

    // Generate markers for all pending customer requests
    final markers = <Marker>[
      // Partner Core Marker
      Marker(
        point: partnerCenter,
        width: 48,
        height: 48,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2563EB),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: const Icon(Icons.hvac_rounded, color: Colors.white, size: 24),
        ),
      ),
    ];

    for (final offer in state.incomingOffers) {
      final lat = (offer['customer_lat'] as num?)?.toDouble() ?? 22.4725;
      final lng = (offer['customer_lng'] as num?)?.toDouble() ?? 70.0610;
      markers.add(
        Marker(
          point: LatLng(lat, lng),
          width: 42,
          height: 42,
          child: GestureDetector(
            onTap: () => _showLiveOffersModal(context, state),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2.5),
                boxShadow: const [
                  BoxShadow(color: Color(0x40EF4444), blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
              child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 22),
            ),
          ),
        ),
      );
    }

    if (state.activeJob != null) {
      final actLat = (state.activeJob!['customer_lat'] as num?)?.toDouble() ?? 22.4725;
      final actLng = (state.activeJob!['customer_lng'] as num?)?.toDouble() ?? 70.0610;
      markers.add(
        Marker(
          point: LatLng(actLat, actLng),
          width: 46,
          height: 46,
          child: GestureDetector(
            onTap: () {
              context.push('/dashboard/ac-job-navigation', extra: state.activeJob);
            },
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0x4010B981), blurRadius: 8, offset: Offset(0, 3)),
                ],
              ),
              child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 24),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
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
                        child: const Icon(Icons.map_rounded, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live Service Area & Radar',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '10 km Coverage Radius • $_partnerCity',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.isOnline ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: state.isOnline ? const Color(0xFF16A34A) : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        state.isOnline ? 'RADAR ACTIVE' : 'RADAR PAUSED',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: state.isOnline ? const Color(0xFF15803D) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Map Container
          SizedBox(
            height: 220,
            width: double.infinity,
            child: FlutterMap(
              options: const MapOptions(
                initialCenter: partnerCenter,
                initialZoom: 13.2,
                interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.servicehub.partner',
                  tileProvider: !kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')
                      ? NetworkTileProvider(silenceExceptions: true)
                      : null,
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: partnerCenter,
                      radius: 260,
                      useRadiusInMeter: false,
                      color: const Color(0xFF2563EB).withValues(alpha: 0.10),
                      borderColor: const Color(0xFF2563EB).withValues(alpha: 0.5),
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                MarkerLayer(markers: markers),
              ],
            ),
          ),

          // Bottom Action Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFFF8FAFC),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.radar_rounded, color: Color(0xFF2563EB), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${state.incomingOffers.length} Customer Booking(s) Nearby',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (state.activeJob != null)
                  ElevatedButton.icon(
                    icon: const Icon(Icons.navigation_rounded, size: 14, color: Colors.white),
                    label: const Text('Live Navigation', style: TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      context.push('/dashboard/ac-job-navigation', extra: state.activeJob);
                    },
                  )
                else if (state.incomingOffers.isNotEmpty)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _showLiveOffersModal(context, state),
                    child: Text('View (${state.incomingOffers.length})', style: const TextStyle(fontSize: 11.5, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
        ],
      ),
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
          Expanded(
            child: Row(
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.isOnline ? 'You are Online' : 'You are Offline',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        state.isOnline ? 'You are accepting new service requests' : 'Go online to receive service requests',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: state.isOnline,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF2563EB),
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

  // --- Active Job in Progress Card ---
  Widget _buildActiveJobProgressCard(Map<String, dynamic> job) {
    final customerName = (job['customer_name'] ?? 'Customer').toString();
    final customerAddress = (job['customer_address'] ?? job['address'] ?? '').toString();
    final serviceName = (job['service_name'] ?? 'Service').toString();
    final price = (job['price'] as num?)?.toDouble() ?? (job['final_amount'] as num?)?.toDouble() ?? 499.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2563EB), width: 1.8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A2563EB),
            blurRadius: 12,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDBEAFE),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.directions_run_rounded, size: 14, color: Color(0xFF1E40AF)),
                    SizedBox(width: 4),
                    Text(
                      'ACTIVE AC SERVICE JOB',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                    ),
                  ],
                ),
              ),
              Text(
                '₹${price.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            customerName,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0F172A)),
          ),
          Text(
            '$serviceName • $customerAddress',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.map_rounded, color: Colors.white, size: 18),
              label: const Text('OPEN MAP & NAVIGATION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              onPressed: () {
                context.push('/dashboard/ac-job-navigation', extra: job);
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Offline Warning Banner ---
  Widget _buildOfflineWarningBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.2),
      ),
      child: const Row(
        children: [
          Icon(Icons.cloud_off_rounded, color: Color(0xFFD97706), size: 22),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You are currently Offline',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF92400E)),
                ),
                Text(
                  'Turn switch ON to receive incoming AC service booking requests.',
                  style: TextStyle(fontSize: 11, color: Color(0xFFB45309)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 4. Today's Work Overview Section (4 Cards Matching Design) ---
  Widget _buildWorkOverviewSection(ACProviderDashboardState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF5FE),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isNarrow = headerConstraints.maxWidth < 360;
              final displayDate = DateFormat(isNarrow ? 'd MMM' : 'EEE, d MMM').format(DateTime.now());

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB), size: 24),
                        SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Today's Work Overview",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              SizedBox(height: 1),
                              Text(
                                "Here's what's happening today",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: Color(0xFF2563EB)),
                        const SizedBox(width: 4),
                        Text(
                          displayDate,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // 4 Work Overview Cards in a Row
          Row(
            children: [
              // 1. New Requests
              Expanded(
                child: _buildOverviewMetricCard(
                  title: 'New Requests',
                  value: '${state.newRequestsCount}',
                  bgColor: const Color(0xFFE8F1FF),
                  iconBg: const Color(0xFF3B82F6),
                  icon: Icons.assignment_outlined,
                  onTap: () => _showLiveOffersModal(context, state),
                ),
              ),
              const SizedBox(width: 8),

              // 2. In Progress
              Expanded(
                child: _buildOverviewMetricCard(
                  title: 'In Progress',
                  value: '${state.inProgressCount}',
                  bgColor: const Color(0xFFFFF7E6),
                  iconBg: const Color(0xFFF59E0B),
                  icon: Icons.access_time_filled_rounded,
                  onTap: () {
                    if (state.activeJob != null) {
                      context.push('/dashboard/ac-job-navigation', extra: state.activeJob);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('No active jobs in progress right now.')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 3. Completed
              Expanded(
                child: _buildOverviewMetricCard(
                  title: 'Completed',
                  value: '${state.completedTodayCount}',
                  bgColor: const Color(0xFFEAF8EE),
                  iconBg: const Color(0xFF10B981),
                  icon: Icons.check_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${state.completedTodayCount} jobs completed today.')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),

              // 4. Cancelled
              Expanded(
                child: _buildOverviewMetricCard(
                  title: 'Cancelled',
                  value: '${state.cancelledTodayCount}',
                  bgColor: const Color(0xFFFFECEF),
                  iconBg: const Color(0xFFEF4444),
                  icon: Icons.close_rounded,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${state.cancelledTodayCount} jobs cancelled today.')),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetricCard({
    required String title,
    required String value,
    required Color bgColor,
    required Color iconBg,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. Business Overview (Today) Section (4 Cards Matching Design) ---
  Widget _buildBusinessOverviewSection(ACProviderDashboardState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 380;
              final headerContent = Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3E8FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bar_chart_rounded, color: Color(0xFF8B5CF6), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Overview (Today)',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 1),
                        Text(
                          'Your business performance at a glance',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final actionBtn = InkWell(
                onTap: () => _showTimeframePicker(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 15, color: Color(0xFF2563EB)),
                    ],
                  ),
                ),
              );

              if (isCompact) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerContent,
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: actionBtn,
                    ),
                  ],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: headerContent),
                  const SizedBox(width: 8),
                  actionBtn,
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // 4 Business Overview Cards in a Row
          Row(
            children: [
              // 1. Today's Earnings
              Expanded(
                child: _buildBusinessCard(
                  title: "Today's Earnings",
                  value: '₹${state.todayIncome == 0 ? "0" : state.todayIncome.toStringAsFixed(0)}',
                  trendPercent: '0%',
                  trendText: 'vs yesterday',
                  bgColor: const Color(0xFFF0F6FE),
                  iconBg: const Color(0xFF2563EB),
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ),
              const SizedBox(width: 8),

              // 2. Jobs Completed
              Expanded(
                child: _buildBusinessCard(
                  title: 'Jobs Completed',
                  value: '${state.completedTodayCount}',
                  trendPercent: '0%',
                  trendText: 'vs yesterday',
                  bgColor: const Color(0xFFF7F3FE),
                  iconBg: const Color(0xFF8B5CF6),
                  icon: Icons.business_center_rounded,
                ),
              ),
              const SizedBox(width: 8),

              // 3. Average Rating
              Expanded(
                child: _buildBusinessCard(
                  title: 'Average Rating',
                  value: state.customerRating.toStringAsFixed(1),
                  trendPercent: '0.0',
                  trendText: 'vs yesterday',
                  bgColor: const Color(0xFFF0FDF4),
                  iconBg: const Color(0xFF10B981),
                  icon: Icons.star_rounded,
                ),
              ),
              const SizedBox(width: 8),

              // 4. Repeat Customers
              Expanded(
                child: _buildBusinessCard(
                  title: 'Repeat Customers',
                  value: '${state.repeatCustomers}',
                  trendPercent: '0%',
                  trendText: 'vs yesterday',
                  bgColor: const Color(0xFFFFF7ED),
                  iconBg: const Color(0xFFF97316),
                  icon: Icons.people_alt_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessCard({
    required String title,
    required String value,
    required String trendPercent,
    required String trendText,
    required Color bgColor,
    required Color iconBg,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.arrow_upward_rounded, size: 11, color: Color(0xFF16A34A)),
                const SizedBox(width: 1),
                Text(
                  trendPercent,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ],
            ),
          ),
          Text(
            trendText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8.5,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. Completed Jobs – Today Section (Customer Name, Time, Price, Paid Badge ONLY) ---
  Widget _buildCompletedJobsSection(ACProviderDashboardState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
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
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Completed Jobs – Today',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 1),
                          Text(
                            'Successfully completed services',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Showing all completed tasks.')),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFDBEAFE)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 15, color: Color(0xFF2563EB)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (state.todayCompletedJobs.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment_turned_in_outlined, size: 30, color: Color(0xFF94A3B8)),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No jobs completed yet today',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Completed jobs and verified customer payments will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: state.todayCompletedJobs.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFFF1F5F9), height: 20),
              itemBuilder: (context, index) {
                final job = state.todayCompletedJobs[index];
                return _buildCompletedJobRow(job, index);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCompletedJobRow(Map<String, dynamic> job, int index) {
    final customerName = (job['customer_name'] ?? 'Customer').toString();
    final completedAt = (job['completed_at'] ?? '10:45 AM').toString();
    final price = (job['price'] as num?)?.toDouble() ?? 0.0;

    // Pastel Avatar Colors
    final avatarColors = [
      {'bg': const Color(0xFFDBEAFE), 'text': const Color(0xFF1D4ED8)}, // Blue
      {'bg': const Color(0xFFF3E8FF), 'text': const Color(0xFF7E22CE)}, // Purple
      {'bg': const Color(0xFFFFEDD5), 'text': const Color(0xFFC2410C)}, // Orange
      {'bg': const Color(0xFFFCE7F3), 'text': const Color(0xFFBE185D)}, // Pink
      {'bg': const Color(0xFFDCFCE7), 'text': const Color(0xFF15803D)}, // Green
    ];
    final colorScheme = avatarColors[index % avatarColors.length];
    final initialLetter = customerName.isNotEmpty ? customerName[0].toUpperCase() : 'C';

    return InkWell(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Job for $customerName: Verified and Paid')),
        );
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // 1. Initial Letter Circle Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colorScheme['bg'],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initialLetter,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: colorScheme['text'],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // 2. Customer Name & Time ONLY (Customer privacy protected: NO phone, NO address)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customerName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded, size: 12, color: Color(0xFF64748B)),
                      const SizedBox(width: 4),
                      Text(
                        completedAt,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 3. Price & Paid Badge & Chevron
            Row(
              children: [
                Text(
                  '₹${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Paid',
                    style: TextStyle(
                      color: Color(0xFF16A34A),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
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
              Expanded(
                child: Center(
                  child: InkWell(
                    key: const Key('bottom_nav_center_map_button'),
                    onTap: () {
                      setState(() => _currentBottomNavIndex = 2);
                      _showLiveRadarMapModal(context, state);
                    },
                    borderRadius: BorderRadius.circular(27),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
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
                          Icon(Icons.map_rounded, color: Colors.white, size: 20),
                          Text('Map', style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
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
                  context.push('/profile/earnings');
                },
              ),

              // 5. Profile Tab
              _buildBottomNavItem(
                icon: Icons.person_outline_rounded,
                label: 'Profile',
                isSelected: _currentBottomNavIndex == 4,
                onTap: () {
                  setState(() => _currentBottomNavIndex = 4);
                  context.push('/profile');
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
    return Expanded(
      child: InkWell(
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
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF0052CC) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
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
                      Flexible(
                        child: Text(
                          state.providerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
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
            ListTile(
              leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF0052CC)),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context);
                context.push('/profile');
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

class _IncomingJobAlertOverlayDialog extends StatefulWidget {
  final Map<String, dynamic> offer;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingJobAlertOverlayDialog({
    required this.offer,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  State<_IncomingJobAlertOverlayDialog> createState() => _IncomingJobAlertOverlayDialogState();
}

class _IncomingJobAlertOverlayDialogState extends State<_IncomingJobAlertOverlayDialog> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _secondsRemaining = 30;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        t.cancel();
        widget.onDecline();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = (widget.offer['price'] as num?)?.toDouble() ?? 498.0;
    final serviceName = widget.offer['service_name'] ?? 'AC Service (Split AC)';
    final customerName = widget.offer['customer_name'] ?? 'Customer';
    final customerAddress = widget.offer['customer_address'] ?? 'Digvijay Plot, Jamnagar';
    final problemDesc = widget.offer['problem_description'] ?? 'AC Service & Diagnostics';
    final scheduledTime = widget.offer['scheduled_time'] ?? 'Today';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Top Urgent Red/Orange Alert Bar
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFEA580C)],
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.flash_on_rounded, color: Color(0xFFDC2626), size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'NEW AC SERVICE REQUEST!',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    // Countdown Circle
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(
                            value: _secondsRemaining / 30.0,
                            strokeWidth: 3.5,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        Text(
                          '${_secondsRemaining}s',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Price & Service Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xFFBFDBFE)),
                                ),
                                child: const Text(
                                  '❄️ AC SPECIALIST JOB',
                                  style: TextStyle(color: Color(0xFF1D4ED8), fontSize: 11, fontWeight: FontWeight.w900),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                serviceName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                            const Text(
                              'Visiting + Protection',
                              style: TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFE2E8F0)),
                    const SizedBox(height: 14),

                    // Customer & Location Details
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.person_pin_circle_rounded, color: Color(0xFF2563EB), size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customerAddress,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Road Routing & ETA Chips
                    Builder(builder: (context) {
                      final distanceKm = (widget.offer['distance_km'] as num?)?.toDouble() ?? 2.8;
                      final etaMinutes = (widget.offer['eta_minutes'] as num?)?.toInt() ?? 8;
                      return Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBBF7D0)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.near_me_rounded, color: Color(0xFF16A34A), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${distanceKm.toStringAsFixed(1)} km road distance',
                                  style: const TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.timer_outlined, color: Color(0xFF2563EB), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '~$etaMinutes mins ETA',
                                  style: const TextStyle(color: Color(0xFF1D4ED8), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }),

                    const SizedBox(height: 12),

                    // Issue details card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.build_circle_outlined, color: Color(0xFF64748B), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Issue: $problemDesc • Slot: $scheduledTime',
                              style: const TextStyle(color: Color(0xFF334155), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Prominent YES and NO Action Buttons (Display Over Other Apps Heads-Up Alert)
                    Row(
                      children: [
                        // NO Button (Decline)
                        Expanded(
                          flex: 2,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              backgroundColor: const Color(0xFFFEF2F2),
                              side: const BorderSide(color: Color(0xFFFCA5A5), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 0,
                            ),
                            onPressed: widget.onDecline,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.close_rounded, color: Color(0xFFDC2626), size: 20),
                                SizedBox(width: 6),
                                Text(
                                  'NO',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // YES Button (Accept)
                        Expanded(
                          flex: 3,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF16A34A), Color(0xFF15803D)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF16A34A).withValues(alpha: 0.45),
                                  blurRadius: 14,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              onPressed: widget.onAccept,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'YES',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

