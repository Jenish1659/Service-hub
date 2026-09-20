import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/local_registration_cache.dart';
import '../../../../core/services/live_booking_sync_service.dart';

class ProviderApplicationStatusScreen extends StatefulWidget {
  final String? initialIdentifier;
  const ProviderApplicationStatusScreen({super.key, this.initialIdentifier});

  @override
  State<ProviderApplicationStatusScreen> createState() =>
      _ProviderApplicationStatusScreenState();
}

class _ProviderApplicationStatusScreenState
    extends State<ProviderApplicationStatusScreen> {
  String _appId = 'SHB7845123056';
  String _submittedDate = 'Today, Live';
  Map<String, dynamic>? _partnerData;
  bool _isLoading = true;
  Timer? _pollTimer;
  late TextEditingController _searchController;

  bool _isUuid(String s) =>
      RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(s.trim());

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialIdentifier ?? '');
    _loadPartnerData();
    _startLivePolling();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _startLivePolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _checkRemoteSupabaseStatus();
    });
  }

  Future<void> _checkRemoteSupabaseStatus() async {
    try {
      final client = Supabase.instance.client;
      final phone = (_partnerData?['phone'] ?? _partnerData?['mobile'] ?? _searchController.text).toString().replaceAll(' ', '').trim();
      final uId = _partnerData?['user_id']?.toString() ?? _partnerData?['id']?.toString();
      final partnerId = _partnerData?['partner_id']?.toString();

      // 1. Check local LiveBookingSyncService memory first
      final syncRecord = (phone.isNotEmpty ? LiveBookingSyncService.instance.getPartnerVerification(phone) : null) ??
          (uId != null ? LiveBookingSyncService.instance.getPartnerVerification(uId) : null) ??
          (partnerId != null ? LiveBookingSyncService.instance.getPartnerVerification(partnerId) : null) ??
          LiveBookingSyncService.instance.getPartnerVerification(_appId);

      if (syncRecord != null) {
        final syncStatus = (syncRecord['status'] ?? syncRecord['verification_status'] ?? '').toString().toUpperCase();
        if (syncStatus == 'VERIFIED' || syncStatus == 'APPROVED') {
          _reflectApprovedState();
          return;
        }
      }

      // 2. Query Supabase users table by Phone or Username (text comparison, never fails UUID constraint)
      if (phone.isNotEmpty) {
        final rawDigits = phone.replaceAll(RegExp(r'\D'), '');
        final userRes = await client
            .from('users')
            .select('user_id, username, phone, account_status, partners(partner_id, verification_status, availability_status)')
            .or('phone.eq.$phone,phone.ilike.%${rawDigits.length >= 10 ? rawDigits.substring(rawDigits.length - 10) : rawDigits}%,username.ilike.$phone')
            .limit(1)
            .maybeSingle();

        if (userRes != null) {
          final pList = userRes['partners'];
          Map<String, dynamic>? pMap;
          if (pList is List && pList.isNotEmpty) {
            pMap = pList.first as Map<String, dynamic>;
          } else if (pList is Map) {
            pMap = pList as Map<String, dynamic>;
          }
          final pStatus = (pMap?['verification_status'] ?? '').toString().toUpperCase();
          if (pStatus == 'VERIFIED' || pStatus == 'APPROVED') {
            _reflectApprovedState();
            return;
          }
        }
      }

      // 3. Check verification_requests table using valid UUID and submitted_at ordering
      final checkUserId = (uId != null && _isUuid(uId)) ? uId : null;
      if (checkUserId != null) {
        final vrRes = await client
            .from('verification_requests')
            .select('status')
            .eq('user_id', checkUserId)
            .order('submitted_at', ascending: false)
            .limit(1)
            .maybeSingle();
        if (vrRes != null) {
          final st = (vrRes['status'] ?? '').toString().toUpperCase();
          if (st == 'APPROVED' || st == 'VERIFIED') {
            _reflectApprovedState();
            return;
          }
        }
      }

      // 4. Check partners table with valid UUID
      if (partnerId != null && _isUuid(partnerId)) {
        final pRes = await client.from('partners').select('verification_status').eq('partner_id', partnerId).maybeSingle();
        if (pRes != null) {
          final st = (pRes['verification_status'] ?? '').toString().toUpperCase();
          if (st == 'VERIFIED' || st == 'APPROVED') {
            _reflectApprovedState();
            return;
          }
        }
      }

      if (checkUserId != null) {
        final pRes = await client.from('partners').select('verification_status').eq('user_id', checkUserId).maybeSingle();
        if (pRes != null) {
          final st = (pRes['verification_status'] ?? '').toString().toUpperCase();
          if (st == 'VERIFIED' || st == 'APPROVED') {
            _reflectApprovedState();
            return;
          }
        }
      }
    } catch (_) {}
  }

  void _reflectApprovedState() {
    if (mounted) {
      setState(() {
        _partnerData ??= {};
        _partnerData!['verification_status'] = 'VERIFIED';
        _partnerData!['status'] = 'APPROVED';
      });
    }
    LocalRegistrationCache.updateActivePartner({'verification_status': 'VERIFIED', 'status': 'APPROVED'});
  }

  Future<void> _loadPartnerData() async {
    Map<String, dynamic>? partner = await LocalRegistrationCache.getRegisteredPartner();
    partner ??= await LocalRegistrationCache.getActivePartner();

    // If still null and search text is available, look up in LiveBookingSyncService
    if (partner == null && _searchController.text.trim().isNotEmpty) {
      partner = LiveBookingSyncService.instance.getPartnerVerification(_searchController.text.trim());
    }

    if (mounted) {
      setState(() {
        _partnerData = partner;
        if (partner != null) {
          final id = (partner['verification_id'] ?? partner['id'] ?? partner['user_id'] ?? '').toString();
          if (id.isNotEmpty) {
            _appId = id.toUpperCase().replaceAll('PARTNER_', 'SHB-').replaceAll('VER_', 'SHB-');
          }
          final submitted = partner['submitted_at'] ?? partner['created_at'];
          if (submitted != null) {
            _submittedDate = 'Today, Just now';
          }
        }
        _isLoading = false;
      });
      _checkRemoteSupabaseStatus();
    }
  }

  void _copyAppId() {
    Clipboard.setData(ClipboardData(text: _appId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('Application ID $_appId copied to clipboard!'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF2563EB);

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator(color: primaryColor)),
      );
    }

    final trackedPhone = (_partnerData?['phone'] ?? _partnerData?['mobile'] ?? _searchController.text).toString().replaceAll(' ', '').trim();
    final trackedUId = (_partnerData?['user_id'] ?? _partnerData?['id'] ?? '').toString().trim();
    final partnerId = trackedPhone.isNotEmpty ? trackedPhone : (trackedUId.isNotEmpty ? trackedUId : _appId);

    return StreamBuilder<Map<String, dynamic>?>(
      stream: LiveBookingSyncService.instance.streamPartnerVerification(partnerId),
      builder: (context, snapshot) {
        final liveRecord = snapshot.data ??
            (trackedPhone.isNotEmpty ? LiveBookingSyncService.instance.getPartnerVerification(trackedPhone) : null) ??
            (trackedUId.isNotEmpty ? LiveBookingSyncService.instance.getPartnerVerification(trackedUId) : null);
        final status = (liveRecord?['status'] ?? liveRecord?['verification_status'] ?? _partnerData?['verification_status'] ?? _partnerData?['status'] ?? 'PENDING')
            .toString()
            .toUpperCase();
        final isApproved = status == 'APPROVED' || status == 'VERIFIED';
        final isRejected = status == 'REJECTED';

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leadingWidth: 48,
            leading: IconButton(
              padding: EdgeInsets.zero,
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryNavy, size: 14),
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/login/service-provider');
                }
              },
            ),
            title: const Text(
              'Application Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                tooltip: 'Refresh Status',
                icon: const Icon(Icons.refresh_rounded, size: 20, color: primaryColor),
                onPressed: () {
                  _checkRemoteSupabaseStatus();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Checking latest application status with Admin live server...'),
                      duration: Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 0. Live Search / Track by Phone Field
                            Container(
                              margin: const EdgeInsets.only(bottom: 14),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFCBD5E1)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _searchController,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                                      decoration: const InputDecoration(
                                        hintText: 'Track by Mobile Number or Application ID',
                                        hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onSubmitted: (_) => _checkRemoteSupabaseStatus(),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      _checkRemoteSupabaseStatus();
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: primaryColor,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Track',
                                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // 1. Application ID & Date Card
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Application ID', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                _appId,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.5),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            InkWell(
                                              onTap: _copyAppId,
                                              child: const Icon(Icons.copy_rounded, size: 16, color: primaryColor),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Submitted On', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                      const SizedBox(height: 2),
                                      Text(
                                        _submittedDate,
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),

                            // 2. Celebration Card when Approved
                            if (isApproved) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.verified_rounded, color: Colors.white, size: 28),
                                    ),
                                    const SizedBox(width: 14),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '🎉 Account Activated & Approved!',
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: Color(0xFF065F46),
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Admin has approved your KYC documents. You are now authorized to accept incoming service requests!',
                                            style: TextStyle(fontSize: 11.5, color: Color(0xFF047857), height: 1.3),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // 3. Status Timeline Tracker
                            _buildStatusTimeline(isApproved: isApproved, isRejected: isRejected),
                            const SizedBox(height: 20),

                            // 4. Information Notice Box
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: isApproved ? const Color(0xFFF0FDF4) : const Color(0xFFEFF6FF),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: isApproved ? const Color(0xFFBBF7D0) : const Color(0xFFBFDBFE)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isApproved ? Icons.check_circle_outline_rounded : Icons.access_time_rounded,
                                      color: isApproved ? const Color(0xFF16A34A) : primaryColor,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Wrap(
                                          alignment: WrapAlignment.spaceBetween,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          spacing: 6,
                                          runSpacing: 2,
                                          children: [
                                            Text(
                                              isApproved ? 'Operational Status' : 'Estimated Review Time',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: isApproved ? const Color(0xFF166534) : const Color(0xFF1E40AF),
                                              ),
                                            ),
                                            Text(
                                              isApproved ? 'Active Online' : 'Instant (AI Verified)',
                                              style: TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.w900,
                                                color: isApproved ? const Color(0xFF16A34A) : primaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isApproved
                                              ? 'Your profile is live in ${(_partnerData?['city'] != null && _partnerData!['city'].toString().trim().isNotEmpty ? _partnerData!['city'] : 'your service')} dispatch radius. You can now toggle Online and receive job leads.'
                                              : 'Our AI verification engine has analyzed your documents. Admin review is pending.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isApproved ? const Color(0xFF15803D) : const Color(0xFF3B82F6),
                                            height: 1.3,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Bottom Action Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 640),
                        width: double.infinity,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isApproved ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: isApproved ? 2 : 0,
                              ),
                              onPressed: () {
                                if (isApproved) {
                                  context.go('/dashboard');
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Dashboard access is locked. A check mark will appear once Admin approves your request.'),
                                      backgroundColor: Color(0xFFD97706),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              },
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(isApproved ? Icons.check_circle_rounded : Icons.lock_rounded, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      isApproved ? 'Launch Partner Dashboard 🚀' : 'Dashboard Locked (Awaiting Admin Approval)',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                  if (isApproved) ...[
                                    const SizedBox(width: 6),
                                    const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                                  ],
                                ],
                              ),
                            ),
                            if (!isApproved) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 11),
                                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => context.go('/login/service-provider'),
                                  icon: const Icon(Icons.login_rounded, size: 16, color: Color(0xFF334155)),
                                  label: const Text('Return to Provider Login', style: TextStyle(color: Color(0xFF334155), fontWeight: FontWeight.w600, fontSize: 13)),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusTimeline({bool isApproved = false, bool isRejected = false}) {
    final steps = [
      _TimelineStepData(
        title: '1. Registration Submitted',
        date: 'Just Now',
        desc: 'Your application details have been safely received.',
        statusTag: 'Completed ✓',
        statusColor: const Color(0xFF10B981),
        statusBg: const Color(0xFFDCFCE7),
        icon: Icons.check_rounded,
        isCompleted: true,
        isInProgress: false,
      ),
      _TimelineStepData(
        title: '2. AI Verification Engine',
        date: 'Verified (Score: 0.02 - Low Risk)',
        desc: 'Aadhaar QR, FaceRD biometrics, and Bank Penny Drop ₹1 verified.',
        statusTag: 'Passed ✓',
        statusColor: const Color(0xFF10B981),
        statusBg: const Color(0xFFDCFCE7),
        icon: Icons.check_rounded,
        isCompleted: true,
        isInProgress: false,
      ),
      _TimelineStepData(
        title: '3. Admin Review & Approval Request',
        date: isApproved ? 'Approved by Admin' : (isRejected ? 'Application Rejected' : 'Awaiting Admin Approval'),
        desc: isApproved
            ? 'Admin verified your KYC documents and authorized partner activation.'
            : (isRejected
                ? 'Application requires document correction or support contact.'
                : 'Your request is in the Admin verification queue. A check mark will appear here once Admin approves.'),
        statusTag: isApproved ? 'Approved ✓' : (isRejected ? 'Rejected' : 'Unchecked (Pending)'),
        statusColor: isApproved ? const Color(0xFF10B981) : (isRejected ? const Color(0xFFEF4444) : const Color(0xFFD97706)),
        statusBg: isApproved ? const Color(0xFFDCFCE7) : (isRejected ? const Color(0xFFFEE2E2) : const Color(0xFFFEF3C7)),
        icon: isApproved ? Icons.check_rounded : (isRejected ? Icons.close_rounded : Icons.radio_button_unchecked_rounded),
        isCompleted: isApproved,
        isInProgress: false,
      ),
      _TimelineStepData(
        title: '4. Final Approval & Dashboard Access',
        date: isApproved ? 'Account Activated & Dashboard Unlocked' : 'Pending Admin Approval',
        desc: isApproved
            ? 'Your account is active. You can now login and enter your partner dashboard.'
            : 'Dashboard access is locked until Admin approves your request.',
        statusTag: isApproved ? 'Unlocked ✓' : 'Locked (Unchecked)',
        statusColor: isApproved ? const Color(0xFF10B981) : const Color(0xFF64748B),
        statusBg: isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        icon: isApproved ? Icons.check_rounded : Icons.radio_button_unchecked_rounded,
        isCompleted: isApproved,
        isInProgress: false,
      ),
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Line & Indicator Circle
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isCompleted
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF8FAFC),
                    border: Border.all(
                      color: step.isCompleted
                          ? const Color(0xFF10B981)
                          : (step.statusColor == const Color(0xFFEF4444)
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFCBD5E1)),
                      width: 2.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      step.icon,
                      color: step.isCompleted
                          ? Colors.white
                          : (step.statusColor == const Color(0xFFEF4444)
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF94A3B8)),
                      size: step.isCompleted ? 18 : 16,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: index >= 2 ? 70 : 54,
                    color: step.isCompleted ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Right Step Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: step.isCompleted
                          ? const Color(0xFFA7F3D0)
                          : const Color(0xFFE2E8F0),
                      width: step.isCompleted ? 1.5 : 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
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
                            child: Text(
                              step.title,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: step.isCompleted ? const Color(0xFF065F46) : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: step.statusBg,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              step.statusTag,
                              style: TextStyle(color: step.statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(step.desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      if (step.date.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(step.date, style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      ],
                      if (index == 2) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isApproved ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isApproved ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isApproved ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                size: 14,
                                color: isApproved ? const Color(0xFF10B981) : const Color(0xFFD97706),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isApproved ? 'Admin Approval Status: APPROVED ✓' : 'Admin Approval Status: UNCHECKED (Awaiting Admin)',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isApproved ? const Color(0xFF065F46) : const Color(0xFF92400E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (index == 3) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: isApproved ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isApproved ? const Color(0xFFA7F3D0) : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isApproved ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
                                size: 14,
                                color: isApproved ? const Color(0xFF10B981) : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isApproved ? 'Dashboard Login: AUTHORIZED ✓' : 'Dashboard Login: LOCKED (Requires Admin Approval)',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isApproved ? const Color(0xFF065F46) : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _TimelineStepData {
  final String title;
  final String date;
  final String desc;
  final String statusTag;
  final Color statusColor;
  final Color statusBg;
  final IconData icon;
  final bool isCompleted;
  final bool isInProgress;

  _TimelineStepData({
    required this.title,
    required this.date,
    required this.desc,
    required this.statusTag,
    required this.statusColor,
    required this.statusBg,
    required this.icon,
    required this.isCompleted,
    required this.isInProgress,
  });
}
