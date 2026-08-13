import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class ProviderApplicationStatusScreen extends StatefulWidget {
  const ProviderApplicationStatusScreen({super.key});

  @override
  State<ProviderApplicationStatusScreen> createState() =>
      _ProviderApplicationStatusScreenState();
}

class _ProviderApplicationStatusScreenState
    extends State<ProviderApplicationStatusScreen> {
  final String _appId = 'SHB7845123056';
  final String _submittedDate = '12 May 2025, 10:30 AM';

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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Checking latest application status...'),
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
                        // Application ID & Date Card
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
                        const SizedBox(height: 20),

                        // Timeline Tracker
                        _buildStatusTimeline(),
                        const SizedBox(height: 20),

                        // Estimated Time Box
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
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
                                child: const Icon(Icons.access_time_rounded, color: primaryColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                               const Expanded(
                                 child: Column(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                     Row(
                                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                       children: [
                                         Text('Estimated Time', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                                         Text('24 – 48 Hours', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: primaryColor)),
                                       ],
                                     ),
                                     SizedBox(height: 4),
                                     Text(
                                       'We will notify you on your registered mobile number and email once your account is approved.',
                                       style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6), height: 1.3),
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

            // Bottom Navigation Bar
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
                        backgroundColor: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                      ),
                      onPressed: () => context.go('/login/service-provider'),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Return to Provider Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          SizedBox(width: 6),
                          Icon(Icons.login_rounded, color: Colors.white, size: 18),
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
  }

  Widget _buildStatusTimeline() {
    final steps = [
      _TimelineStepData(
        title: '1. Registration Submitted',
        date: '12 May 2025, 10:30 AM',
        desc: 'Your application details have been safely received.',
        statusTag: 'Completed',
        statusColor: const Color(0xFF10B981),
        statusBg: const Color(0xFFDCFCE7),
        icon: Icons.check,
        isCompleted: true,
        isInProgress: false,
      ),
      _TimelineStepData(
        title: '2. AI Verification (In Progress)',
        date: 'Currently Active',
        desc: 'Your documents are being verified by our AI system.',
        statusTag: 'In Progress',
        statusColor: const Color(0xFF2563EB),
        statusBg: const Color(0xFFDBEAFE),
        icon: Icons.sync_rounded,
        isCompleted: false,
        isInProgress: true,
      ),
      _TimelineStepData(
        title: '3. Admin Review',
        date: 'Pending',
        desc: 'Our team will review your application and verification results.',
        statusTag: 'Pending',
        statusColor: const Color(0xFF64748B),
        statusBg: const Color(0xFFF1F5F9),
        icon: Icons.shield_outlined,
        isCompleted: false,
        isInProgress: false,
      ),
      _TimelineStepData(
        title: '4. Final Approval',
        date: 'Pending',
        desc: 'You will be notified once approved.',
        statusTag: 'Pending',
        statusColor: const Color(0xFF64748B),
        statusBg: const Color(0xFFF1F5F9),
        icon: Icons.verified_user_outlined,
        isCompleted: false,
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
