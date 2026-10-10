import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/ac_booking_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';
import 'ac_issue_details_screen.dart';
import 'ac_select_date_screen.dart';

class ACServiceOverviewScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic>? issueDetails;

  const ACServiceOverviewScreen({
    super.key,
    this.issueDetails,
  });

  @override
  ConsumerState<ACServiceOverviewScreen> createState() => _ACServiceOverviewScreenState();
}

class _ACServiceOverviewScreenState extends ConsumerState<ACServiceOverviewScreen> {
  late Map<String, dynamic> _activeIssueDetails;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (widget.issueDetails != null && widget.issueDetails!.isNotEmpty) {
      _activeIssueDetails = Map<String, dynamic>.from(widget.issueDetails!);
    } else {
      final draft = ACIssueBookingService.instance.loadDraft();
      _activeIssueDetails = draft ?? {};
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _navigateToIssueEdit() async {
    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ACIssueDetailsScreen(
          serviceName: _activeIssueDetails['service_name'] as String?,
          servicePrice: (_activeIssueDetails['service_price'] as num?)?.toDouble(),
        ),
      ),
    );
    if (result != null && result is Map<String, dynamic> && mounted) {
      setState(() {
        _activeIssueDetails = Map<String, dynamic>.from(result);
      });
    }
  }

  void _proceedToSelectDate() {
    if (_activeIssueDetails['ac_type'] == null ||
        _activeIssueDetails['ac_brand'] == null ||
        _activeIssueDetails['problem_description'] == null) {
      _navigateToIssueEdit();
      return;
    }
    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ACSelectDateScreen(issueDetails: _activeIssueDetails),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? acType = _activeIssueDetails['ac_type'] as String?;
    final String? acBrand = _activeIssueDetails['ac_brand'] as String?;
    final String? problemDesc = _activeIssueDetails['problem_description'] as String?;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: () => ACDateTimeAIChatbotSheet.show(
                context,
              ),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.support_agent_rounded, size: 18, color: Color(0xFF3B49DF)),
                    SizedBox(width: 6),
                    Text(
                      'Need Help?',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B49DF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Headline Title & Subtext (Matching Screen 1 Reference)
              const Text(
                'AC Service',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "We'll keep you\ncool & comfortable.",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  height: 1.2,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Book a service with our experts\nat your convenience.',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  height: 1.35,
                ),
              ),

              const SizedBox(height: 20),

              // Hero Illustration: AC Unit on Wall with Breeze
              Center(
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        right: 20,
                        bottom: 12,
                        child: Icon(
                          Icons.eco_rounded,
                          size: 44,
                          color: const Color(0xFF10B981).withValues(alpha: 0.4),
                        ),
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 170,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  bottom: 4,
                                  left: 20,
                                  right: 20,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF94A3B8),
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 12,
                                  top: 14,
                                  child: Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF3B49DF),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              5,
                              (i) => Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Container(
                                  width: 4,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF93C5FD).withValues(alpha: 0.7 - i * 0.1),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // "Your AC" Summary Card (Matching Reference Card with Chevron)
              InkWell(
                onTap: _navigateToIssueEdit,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // AC Badge
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.air_rounded, color: Color(0xFF3B49DF), size: 24),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: Color(0xFF3B49DF),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 10),
                          ),
                        ],
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
                                  (acType != null || acBrand != null) ? 'Your AC' : 'Your AC Details *',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded, color: Color(0xFF3B49DF), size: 20),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if ((acType != null && acType.isNotEmpty) || (acBrand != null && acBrand.isNotEmpty))
                              Row(
                                children: [
                                  if (acType != null && acType.isNotEmpty) ...[
                                    _buildTag('Type', acType),
                                    const SizedBox(width: 6),
                                  ],
                                  if (acBrand != null && acBrand.isNotEmpty)
                                    _buildTag('Brand', acBrand),
                                ],
                              ),
                            const SizedBox(height: 4),
                            Text(
                              (problemDesc != null && problemDesc.isNotEmpty)
                                  ? 'Issue: $problemDesc'
                                  : 'Tap to configure AC type, brand & problem details *',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: (problemDesc != null && problemDesc.isNotEmpty)
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF3B49DF),
                                fontWeight: (problemDesc != null && problemDesc.isNotEmpty)
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 4-Item Status Grid
              Row(
                children: [
                  Expanded(
                    child: _buildGridItem(
                      icon: Icons.access_time_rounded,
                      iconColor: const Color(0xFF3B49DF),
                      title: 'Service Duration',
                      value: '60 – 90 min',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGridItem(
                      icon: Icons.location_on_outlined,
                      iconColor: const Color(0xFF6366F1),
                      title: 'Service Mode',
                      value: 'At your location',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildGridItem(
                      icon: Icons.verified_user_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Quality Standard',
                      value: '100% Certified Technicians',
                      isHighlight: true,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildGridItem(
                      icon: Icons.alarm_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'Time Zone',
                      value: 'Local Time (Auto-detected)',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // 100% Hygiene Maintained Assurance Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFDCFCE7)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sanitizer_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '100% Hygiene Maintained',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Sanitized tools, protective masks & gloves, and mess-free AC catch bags for clean service.',
                            style: TextStyle(fontSize: 11.5, color: Color(0xFF15803D), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Book Service Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B49DF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 2,
                  ),
                  onPressed: _proceedToSelectDate,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Book Service',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11, color: Color(0xFF3B49DF), fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    bool isHighlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: isHighlight ? const Color(0xFF059669) : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
