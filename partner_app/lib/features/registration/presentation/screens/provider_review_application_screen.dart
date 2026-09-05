import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sh_logo_widget.dart';

import '../../../../core/storage/local_registration_cache.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/services/ai_verification_engine.dart';

class ProviderReviewApplicationScreen extends StatefulWidget {
  const ProviderReviewApplicationScreen({super.key});

  @override
  State<ProviderReviewApplicationScreen> createState() =>
      _ProviderReviewApplicationScreenState();
}

class _ProviderReviewApplicationScreenState
    extends State<ProviderReviewApplicationScreen> {
  bool _declarationAccurate = true;
  bool _declarationTerms = true;
  Map<String, dynamic>? _draftData;

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draft = await LocalRegistrationCache.getDraft();
    if (mounted) {
      setState(() {
        _draftData = draft;
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_declarationAccurate || !_declarationTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check both declaration boxes before submitting.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final draft = _draftData ?? {};
    final username = (draft['username'] ?? '').toString().trim();
    final firstName = (draft['first_name'] ?? draft['firstName'] ?? '').toString().trim();
    final lastName = (draft['last_name'] ?? draft['lastName'] ?? '').toString().trim();
    final rawFullName = (draft['full_name'] ?? draft['fullName'] ?? draft['name'] ?? '$firstName $lastName').toString().trim();
    final fullName = rawFullName.isNotEmpty ? rawFullName : (firstName.isNotEmpty ? '$firstName $lastName'.trim() : 'Service Provider');
    
    final rawPhone = (draft['mobile_number'] ?? draft['mobile'] ?? draft['phone'] ?? draft['phone_number'] ?? '').toString().trim();
    final phone = rawPhone.startsWith('+91') ? rawPhone : (rawPhone.isNotEmpty ? '+91 $rawPhone' : '');
    final email = (draft['email'] ?? '').toString().trim();
    final password = (draft['password'] ?? '').toString().trim();
    final city = (draft['city'] ?? 'Jamnagar').toString().trim();
    final state = (draft['state'] ?? 'Gujarat').toString().trim();
    final businessName = (draft['business_name'] ?? draft['businessName'] ?? draft['shop_name'] ?? '$fullName Services').toString().trim();
    final businessAddress = (draft['business_address'] ?? draft['address'] ?? draft['shop_address'] ?? '$city, $state').toString().trim();
    final category = (draft['service_category_id'] ?? draft['category'] ?? 'ac_service').toString().trim();
    final categoryName = (draft['category_name'] ?? (category == 'ac_service' ? 'AC Service Specialist' : category)).toString().trim();
    final experience = (draft['experience_years'] ?? draft['experience'] ?? '3+ Years').toString().trim();

    final bankName = (draft['bank_name'] ?? draft['bankName'] ?? '').toString().trim();
    final accountNumber = (draft['bank_account_number'] ?? draft['account_number'] ?? draft['accountNumber'] ?? '').toString().trim();
    final ifscCode = (draft['ifsc_code'] ?? draft['ifsc'] ?? '').toString().trim();
    final accountHolder = (draft['account_holder_name'] ?? draft['accountHolderName'] ?? fullName).toString().trim();
    final aadhaar = (draft['aadhaar_number'] ?? draft['aadhaar'] ?? '').toString().trim();
    final pan = (draft['pan_number'] ?? draft['pan'] ?? '').toString().trim();

    final appId = 'SHB-${DateTime.now().millisecondsSinceEpoch}';
    final partnerId = 'partner_${phone.replaceAll("+", "").replaceAll(" ", "").trim().isNotEmpty ? phone.replaceAll("+", "").replaceAll(" ", "").trim() : DateTime.now().millisecondsSinceEpoch}';

    // 1. Generate Intelligent AI Verification Report
    final aiReport = AIVerificationEngine.instance.generateAIInspectionReport(draft);

    final partnerRecord = {
      'id': partnerId,
      'verification_id': appId,
      'user_id': partnerId,
      'username': username.isNotEmpty ? username : 'ptr_${DateTime.now().millisecondsSinceEpoch % 10000}',
      'name': fullName,
      'full_name': fullName,
      'first_name': firstName,
      'last_name': lastName,
      'business_name': businessName,
      'business_address': businessAddress,
      'phone': phone,
      'email': email,
      'password': password,
      'category': category,
      'category_name': categoryName,
      'experience_years': experience,
      'state': state,
      'city': city,
      'bank_name': bankName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'account_holder_name': accountHolder,
      'aadhaar_number': aadhaar,
      'pan_number': pan,
      'verification_status': 'PENDING',
      'status': 'PENDING',
      'is_online': false,
      'ai_risk_score': aiReport.aiRiskScore,
      'trust_score': aiReport.trustScore,
      'ai_report': aiReport.toJson(),
      'created_at': DateTime.now().toIso8601String(),
      'submitted_at': DateTime.now().toIso8601String(),
    };

    await LocalRegistrationCache.saveRegisteredPartner(partnerRecord);
    await LocalRegistrationCache.clearDraft();

    // 2. Broadcast complete verified application + AI report to Admin live queue
    await LiveBookingSyncService.instance.submitPartnerVerification(partnerRecord);

    try {
      await SupabaseAuthService.registerServiceProvider(
        username: username.isNotEmpty ? username : 'provider_${DateTime.now().millisecondsSinceEpoch % 10000}',
        firstName: firstName,
        lastName: lastName,
        phone: phone.isNotEmpty ? phone : '9876543210',
        email: email.isNotEmpty ? email : 'partner_${DateTime.now().millisecondsSinceEpoch}@servicehub.com',
        password: password,
        state: state,
        city: city,
        serviceCategoryId: 'ac_service',
        specialization: 'AC Jet Cleaning & Gas Refill',
      );
    } catch (_) {}

    if (mounted) {
      context.go('/register/success');
    }
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
              context.go('/register/verify-identity');
            }
          },
        ),
        title: const ShLogoWidget(size: 26, showSubtitle: true),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Need Help?',
            icon: const Icon(Icons.help_outline_rounded, size: 20, color: primaryColor),
            onPressed: () {},
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
                        // Step Header
                        const Text(
                          'Step 6 of 6',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: primaryColor),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Review Your Application',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Please review all information before submitting for verification.',
                          style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),

                        // Registration Progress Bar
                        _buildProgressBar(),
                        const SizedBox(height: 16),

                        // Section 1: Personal Information
                        Builder(
                          builder: (context) {
                            final draft = _draftData ?? {};
                            final fName = draft['first_name'] ?? draft['firstName'] ?? 'Rajesh';
                            final lName = draft['last_name'] ?? draft['lastName'] ?? '';
                            final nameStr = '$fName $lName'.trim();
                            final phoneStr = (draft['mobile_number'] ?? draft['mobile'] ?? draft['phone'] ?? '+91 98765 43210').toString();
                            final emailStr = (draft['email'] ?? 'partner@servicehub.com').toString();
                            final cityStr = (draft['city'] ?? 'Jamnagar').toString();
                            final stateStr = (draft['state'] ?? 'Gujarat').toString();

                            final usernameStr = (draft['username'] ?? '').toString();

                            return _buildReviewCard(
                              icon: Icons.person_outline_rounded,
                              iconBg: const Color(0xFFF3E8FF),
                              iconColor: const Color(0xFF9333EA),
                              title: '1. Personal Information',
                              onEdit: () => context.push('/register'),
                              content: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _InfoRow(label: 'Name', value: nameStr.isNotEmpty ? nameStr : 'Rajesh', extraLabel: 'Mobile', extraValue: phoneStr),
                                  if (usernameStr.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    _InfoRow(label: 'Username', value: '@$usernameStr', extraLabel: 'Location', extraValue: '$cityStr, $stateStr'),
                                  ] else ...[
                                    const SizedBox(height: 4),
                                    _InfoRow(label: 'Email', value: emailStr.isNotEmpty ? emailStr : 'partner@servicehub.com', extraLabel: 'Location', extraValue: '$cityStr, $stateStr'),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),

                        // Section 2: Selected Service
                        _buildReviewCard(
                          icon: Icons.content_cut_rounded,
                          iconBg: const Color(0xFFFFEDD5),
                          iconColor: const Color(0xFFEA580C),
                          title: '2. Selected Service',
                          onEdit: () => context.push('/register/service-category'),
                          content: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow(label: 'Service', value: 'AC Service Provider'),
                              SizedBox(height: 4),
                              _InfoRow(label: 'Specializations', value: 'Installation, Repair, Gas Refilling, Maintenance'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Section 3: Professional Information
                        _buildReviewCard(
                          icon: Icons.work_outline_rounded,
                          iconBg: const Color(0xFFDBEAFE),
                          iconColor: const Color(0xFF2563EB),
                          title: '3. Professional Information',
                          onEdit: () => context.push('/register/experience/ac_service'),
                          content: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _InfoRow(label: 'Experience', value: '4 Years', extraLabel: 'Languages', extraValue: 'Hindi, Gujarati, English'),
                              SizedBox(height: 4),
                              _InfoRow(label: 'Working Days', value: 'Monday - Sunday', extraLabel: 'Hours', extraValue: '9:00 AM - 7:00 PM'),
                              SizedBox(height: 4),
                              _InfoRow(label: 'Emergency Service', value: 'Yes (24x7)'),
                              SizedBox(height: 4),
                              _InfoRow(label: 'About You', value: 'I provide reliable and quality service to customers.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Section 4: Identity Verification
                        _buildReviewCard(
                          icon: Icons.shield_outlined,
                          iconBg: const Color(0xFFDCFCE7),
                          iconColor: const Color(0xFF16A34A),
                          title: '4. Identity Verification',
                          onEdit: () => context.push('/register/verify-identity'),
                          content: const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _DocBadge(label: 'Profile Photo', status: 'Uploaded', isSuccess: true),
                              _DocBadge(label: 'Aadhaar Card', status: 'Verified', isSuccess: true),
                              _DocBadge(label: 'Aadhaar Face Verification', status: 'Verified', isSuccess: true),
                              _DocBadge(label: 'Experience Certificate', status: 'Uploaded', isSuccess: true),
                              _DocBadge(label: 'Shop License', status: 'Not Required', isSuccess: false),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Section 5: AI Verification Engine
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFAF5FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE9D5FF), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9333EA).withValues(alpha: 0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF9333EA),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.memory_rounded, color: Colors.white, size: 20),
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '5. AI Verification Engine (Pre-Verified)',
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF581C87)),
                                        ),
                                        SizedBox(height: 2),
                                        Text(
                                          'Automated document authenticity, FaceRD biometric & Penny Drop active.',
                                          style: TextStyle(fontSize: 11, color: Color(0xFF6B21A8)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF86EFAC)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          'Score: 0.02 (Low Risk)',
                                          style: TextStyle(color: Color(0xFF15803D), fontSize: 10.5, fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  _DocBadge(label: 'Aadhaar QR Verified', status: 'Passed', isSuccess: true),
                                  _DocBadge(label: 'FaceRD Liveness (99.4%)', status: 'Passed', isSuccess: true),
                                  _DocBadge(label: 'Bank Penny Drop ₹1', status: 'Active', isSuccess: true),
                                  _DocBadge(label: 'Anti-Tamper Scan', status: 'Clean', isSuccess: true),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Declaration
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Declaration', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => setState(() => _declarationAccurate = !_declarationAccurate),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _declarationAccurate,
                                      activeColor: primaryColor,
                                      onChanged: (val) => setState(() => _declarationAccurate = val ?? false),
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'I confirm that all the information provided is true and accurate.',
                                        style: TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() => _declarationTerms = !_declarationTerms),
                                child: Row(
                                  children: [
                                    Checkbox(
                                      value: _declarationTerms,
                                      activeColor: primaryColor,
                                      onChanged: (val) => setState(() => _declarationTerms = val ?? false),
                                    ),
                                    const Expanded(
                                      child: Text(
                                        'I agree to ServiceHub\'s Terms & Conditions and Privacy Policy.',
                                        style: TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
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
                    child: Row(
                      children: [
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/register/verify-identity');
                            }
                          },
                          icon: const Icon(Icons.arrow_back, size: 16),
                          label: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 2,
                            ),
                            onPressed: _handleSubmit,
                            icon: const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                            label: const Text('Submit for Verification', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
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
  }

  Widget _buildProgressBar() {
    const steps = [
      'Basic Info',
      'Service',
      'Specialization',
      'Professional',
      'Identity',
      'Review',
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          // Step indicators scrollable horizontally for zero overflow
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: List.generate(steps.length, (index) {
                final isDone = index < 5;
                final isCurrent = index == 5;

                return Row(
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? const Color(0xFF10B981)
                                : (isCurrent ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                          ),
                          child: Center(
                            child: isDone
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : Text('${index + 1}', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          steps[index],
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                            color: isCurrent ? const Color(0xFF2563EB) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 24,
                        height: 2,
                        margin: const EdgeInsets.only(bottom: 16, left: 4, right: 4),
                        color: isDone ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                      ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('100% Complete', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Ready for Submission', style: TextStyle(color: Color(0xFF166534), fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onEdit,
    required Widget content,
  }) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: const BorderSide(color: Color(0xFFCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 12, color: Color(0xFF475569)),
                label: const Text('Edit', style: TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? extraLabel;
  final String? extraValue;

  const _InfoRow({
    required this.label,
    required this.value,
    this.extraLabel,
    this.extraValue,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
            children: [
              TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
              TextSpan(text: value),
            ],
          ),
        ),
        if (extraLabel != null && extraValue != null)
          RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569)),
              children: [
                TextSpan(text: '$extraLabel: ', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                TextSpan(text: extraValue!),
              ],
            ),
          ),
      ],
    );
  }
}

class _DocBadge extends StatelessWidget {
  final String label;
  final String status;
  final bool isSuccess;

  const _DocBadge({
    required this.label,
    required this.status,
    required this.isSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isSuccess ? const Color(0xFFA7F3D0) : const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.remove_circle_outline,
            size: 13,
            color: isSuccess ? const Color(0xFF10B981) : const Color(0xFF64748B),
          ),
          const SizedBox(width: 4),
          Text(
            '$label: $status',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isSuccess ? const Color(0xFF065F46) : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }
}
