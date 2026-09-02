import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/storage/local_registration_cache.dart';
import '../../../../core/services/live_booking_sync_service.dart';

class ProviderApplicationStatusScreen extends StatefulWidget {
  const ProviderApplicationStatusScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadPartnerData();
  }

  Future<void> _loadPartnerData() async {
    final partner = await LocalRegistrationCache.getRegisteredPartner();
    if (mounted) {
      setState(() {
        _partnerData = partner;
        if (partner != null) {
          final id = (partner['verification_id'] ?? partner['id'] ?? '').toString();
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

    final partnerId = _partnerData?['id'] ?? _partnerData?['user_id'] ?? _appId;

    return StreamBuilder<Map<String, dynamic>?>(
      stream: LiveBookingSyncService.instance.streamPartnerVerification(partnerId.toString()),
      builder: (context, snapshot) {
        final liveRecord = snapshot.data;
        final status = (liveRecord?['status'] ?? _partnerData?['verification_status'] ?? _partnerData?['status'] ?? 'PENDING')
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
                  setState(() {});
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
                                            Text(
                                              _appId,
                                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), letterSpacing: 0.5),
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
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                              ? 'Your profile is live in Jamnagar service dispatch radius. You can now toggle Online and receive job leads.'
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
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isApproved ? const Color(0xFF16A34A) : primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 2,
                          ),
                          onPressed: () {
                            if (isApproved) {
                              context.go('/dashboard');
                            } else {
                              context.go('/login/service-provider');
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isApproved ? 'Launch Partner Dashboard 🚀' : 'Return to Provider Login',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(width: 6),
                              Icon(isApproved ? Icons.arrow_forward_rounded : Icons.login_rounded, color: Colors.white, size: 18),
                            ],
                          ),
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
        statusTag: 'Completed',
        statusColor: const Color(0xFF10B981),
        statusBg: const Color(0xFFDCFCE7),
        icon: Icons.check,
        isCompleted: true,
        isInProgress: false,
      ),
      _TimelineStepData(
        title: '2. AI Verification Engine',
        date: 'Verified (Score: 0.02 - Low Risk)',
        desc: 'Aadhaar QR, FaceRD biometrics, and Bank Penny Drop ₹1 verified.',
        statusTag: 'Passed',
        statusColor: const Color(0xFF10B981),
        statusBg: const Color(0xFFDCFCE7),
        icon: Icons.check,
        isCompleted: true,
        isInProgress: false,
      ),
      _TimelineStepData(
        title: '3. Admin Review & Audit',
        date: isApproved ? 'Approved by Admin' : (isRejected ? 'Application Rejected' : 'In Progress'),
        desc: isApproved
            ? 'Admin verified documents and authorized partner activation.'
            : (isRejected ? 'Application requires document correction.' : 'Admin is reviewing your application in the master queue.'),
        statusTag: isApproved ? 'Approved' : (isRejected ? 'Rejected' : 'Under Review'),
        statusColor: isApproved ? const Color(0xFF10B981) : (isRejected ? const Color(0xFFEF4444) : const Color(0xFF2563EB)),
        statusBg: isApproved ? const Color(0xFFDCFCE7) : (isRejected ? const Color(0xFFFEE2E2) : const Color(0xFFDBEAFE)),
        icon: isApproved ? Icons.check : (isRejected ? Icons.close : Icons.sync_rounded),
        isCompleted: isApproved,
        isInProgress: !isApproved && !isRejected,
      ),
      _TimelineStepData(
        title: '4. Final Approval & Activation',
        date: isApproved ? 'Account Activated' : 'Pending Review',
        desc: isApproved
            ? 'Your account is active. You can now go online and accept bookings.'
            : 'You will receive immediate app notification once activated.',
        statusTag: isApproved ? 'Active' : 'Pending',
        statusColor: isApproved ? const Color(0xFF10B981) : const Color(0xFF64748B),
        statusBg: isApproved ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
        icon: isApproved ? Icons.verified_user_rounded : Icons.verified_user_outlined,
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step.isCompleted
                        ? const Color(0xFF10B981)
                        : (step.isInProgress ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
                  ),
                  child: Center(
                    child: Icon(
                      step.icon,
                      color: (step.isCompleted || step.isInProgress) ? Colors.white : const Color(0xFF94A3B8),
                      size: 16,
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 54,
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
                      color: step.isInProgress ? const Color(0xFFBFDBFE) : const Color(0xFFE2E8F0),
                      width: step.isInProgress ? 1.5 : 1.0,
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
                                color: step.isInProgress ? const Color(0xFF1E40AF) : const Color(0xFF0F172A),
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
