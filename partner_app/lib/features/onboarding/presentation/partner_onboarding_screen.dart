import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

import '../../profile/presentation/profile_provider.dart';
import 'onboarding_provider.dart';

class PartnerOnboardingScreen extends ConsumerStatefulWidget {
  const PartnerOnboardingScreen({super.key});

  @override
  ConsumerState<PartnerOnboardingScreen> createState() => _PartnerOnboardingScreenState();
}

class _PartnerOnboardingScreenState extends ConsumerState<PartnerOnboardingScreen> {
  final PageController _pageController = PageController();

  // Step 2 & 3 Controllers
  final TextEditingController _phoneController = TextEditingController(text: '9876543210');
  final TextEditingController _phoneOtpController = TextEditingController();
  final TextEditingController _emailController = TextEditingController(text: 'jenish@servicehub.com');
  final TextEditingController _emailOtpController = TextEditingController();

  // Step 8 Controllers
  final TextEditingController _shopNameController = TextEditingController(text: 'ServiceHub Premier Hub');
  final TextEditingController _experienceController = TextEditingController(text: '5');

  // Step 9 Controllers
  final TextEditingController _accountHolderController = TextEditingController(text: 'Jenish Bheda');
  final TextEditingController _bankNameController = TextEditingController(text: 'HDFC Bank Ltd');
  final TextEditingController _accountNumberController = TextEditingController(text: '50100239481234');
  final TextEditingController _ifscController = TextEditingController(text: 'HDFC0000240');
  final TextEditingController _upiController = TextEditingController(text: 'jenish@upi');

  // Step 10 Signature
  bool _termsAccepted = false;
  bool _signatureDrawn = false;

  @override
  void dispose() {
    _pageController.dispose();
    _phoneController.dispose();
    _phoneOtpController.dispose();
    _emailController.dispose();
    _emailOtpController.dispose();
    _shopNameController.dispose();
    _experienceController.dispose();
    _accountHolderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _goToStep(int step) {
    ref.read(partnerOnboardingProvider.notifier).setStep(step);
    _pageController.animateToPage(
      step - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _nextStep() {
    final current = ref.read(partnerOnboardingProvider).currentStep;
    if (current < 12) {
      _goToStep(current + 1);
    }
  }

  void _prevStep() {
    final current = ref.read(partnerOnboardingProvider).currentStep;
    if (current > 1) {
      _goToStep(current - 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(partnerOnboardingProvider);
    final partnerName = ref.watch(loggedInPartnerNameProvider);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: onboarding.currentStep > 1 && onboarding.currentStep < 12
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimaryColor, size: 20),
                onPressed: _prevStep,
              )
            : null,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.shield_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Become a ServiceHub Partner',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                ),
                Text(
                  'Step ${onboarding.currentStep} of 12 · Onboarding & AI Verification',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xffeff6ff),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffbfdbfe)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.verified_user_rounded, color: AppTheme.primaryColor, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'AI Safe 2.4',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. Watermark Background Logo (5-8% Opacity)
          const Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.05,
                child: Icon(
                  Icons.handshake_rounded,
                  size: 320,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ),

          // 2. Main Step Content
          Column(
            children: [
              // Animated Top Progress Bar
              LinearProgressIndicator(
                value: onboarding.currentStep / 12.0,
                backgroundColor: const Color(0xffe2e8f0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                minHeight: 4,
              ),

              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStep1PartnerCategory(onboarding),
                    _buildStep2MobileVerification(onboarding),
                    _buildStep3EmailVerification(onboarding),
                    _buildStep4AadhaarOcr(onboarding),
                    _buildStep5FaceLiveness(onboarding),
                    _buildStep6DocumentUpload(onboarding),
                    _buildStep7VehicleVerification(onboarding),
                    _buildStep8ProfessionalDetails(onboarding),
                    _buildStep9BankPennyDrop(onboarding),
                    _buildStep10LegalAndSignature(onboarding),
                    _buildStep11AiFraudRadar(onboarding),
                    _buildStep12Celebration(onboarding, partnerName),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 1: PARTNER CATEGORY SELECTION
  // ==========================================
  Widget _buildStep1PartnerCategory(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge('STEP 1 OF 12', 'Choose Your Partner Category'),
          const SizedBox(height: 8),
          const Text(
            'Select how you wish to join the ServiceHub ecosystem. Your verification requirements will automatically adapt.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          _buildCategoryCard(
            type: 'provider',
            title: 'Service Provider',
            subtitle: 'AC Repair · Plumbing · Car Service · Cooking · Laundry',
            earnings: 'Est. ₹45,000 - ₹85,000 / month',
            icon: Icons.construction_rounded,
            badgeColor: const Color(0xffeff6ff),
            iconColor: AppTheme.primaryColor,
            isSelected: data.partnerType == 'provider',
            onTap: () => ref.read(partnerOnboardingProvider.notifier).setPartnerType('provider'),
          ),
          const SizedBox(height: 16),

          _buildCategoryCard(
            type: 'seller',
            title: 'Seller / Shopkeeper',
            subtitle: 'AC Parts · Plumbing Store · Car Supplies · Grocery · Laundry',
            earnings: 'Est. ₹60,000 - ₹1,50,000 / month',
            icon: Icons.storefront_rounded,
            badgeColor: const Color(0xfff5f3ff),
            iconColor: const Color(0xff7c3aed),
            isSelected: data.partnerType == 'seller',
            onTap: () => ref.read(partnerOnboardingProvider.notifier).setPartnerType('seller'),
          ),
          const SizedBox(height: 16),

          _buildCategoryCard(
            type: 'delivery',
            title: 'Delivery Agent',
            subtitle: 'Delivers products ordered on ServiceHub (No food/meds)',
            earnings: 'Est. ₹25,000 - ₹40,000 / month',
            icon: Icons.two_wheeler_rounded,
            badgeColor: const Color(0xffecfdf5),
            iconColor: const Color(0xff059669),
            isSelected: data.partnerType == 'delivery',
            onTap: () => ref.read(partnerOnboardingProvider.notifier).setPartnerType('delivery'),
          ),
          const SizedBox(height: 32),

          _buildPrimaryButton('Continue to Mobile Verification', _nextStep),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 2: MOBILE VERIFICATION
  // ==========================================
  Widget _buildStep2MobileVerification(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge('STEP 2 OF 12', 'Mobile Number & OTP Verification'),
          const SizedBox(height: 8),
          const Text(
            'We will send a 6-digit OTP to verify your mobile number. This will be your primary login credential.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Mobile Phone Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    prefixIcon: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('+91 ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    suffixIcon: data.isMobileVerified
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xff10b981))
                        : null,
                    hintText: 'Enter 10-digit number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                if (!data.isMobileVerified) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      _phoneOtpController.text = '981245';
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('OTP sent to +91 9876543210! (Auto-filled: 981245)')),
                      );
                    },
                    icon: const Icon(Icons.sms_rounded, size: 18),
                    label: const Text('Send SMS OTP'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff10b981), foregroundColor: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  const Text('Enter 6-Digit Verification Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneOtpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: 'e.g. 981245',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(partnerOnboardingProvider.notifier).verifyMobile();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Mobile Number Verified Successfully!')),
                      );
                    },
                    icon: const Icon(Icons.verified_rounded, size: 18),
                    label: const Text('Verify Mobile OTP'),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffecfdf5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffa7f3d0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xff059669), size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Mobile Number Verified & Linked',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff065f46), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildPrimaryButton(
            'Continue to Email Verification',
            data.isMobileVerified ? _nextStep : null,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 3: EMAIL VERIFICATION
  // ==========================================
  Widget _buildStep3EmailVerification(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge('STEP 3 OF 12', 'Email Address Verification'),
          const SizedBox(height: 8),
          const Text(
            'Enter your official business email address. Temporary or disposable emails are automatically rejected.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_rounded, color: AppTheme.primaryColor),
                    suffixIcon: data.isEmailVerified
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xff10b981))
                        : null,
                    hintText: 'name@example.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                if (!data.isEmailVerified) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      final email = _emailController.text.trim();
                      if (email.contains('mailinator.com') || email.contains('tempmail.com')) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('❌ Disposable email address detected and rejected by AI Security filter.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      _emailOtpController.text = '542109';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Verification code sent to $email! (Auto-filled: 542109)')),
                      );
                    },
                    icon: const Icon(Icons.mark_email_read_rounded, size: 18),
                    label: const Text('Send Email Security Code'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  const Text('Enter Email Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailOtpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      hintText: 'e.g. 542109',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(partnerOnboardingProvider.notifier).verifyEmail();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Email Address Verified Successfully!')),
                      );
                    },
                    icon: const Icon(Icons.verified_user_rounded, size: 18),
                    label: const Text('Verify Email Code'),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffecfdf5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffa7f3d0)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xff059669), size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Email Verified & Security Filter Cleared',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff065f46), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildPrimaryButton(
            'Continue to Aadhaar Verification',
            data.isEmailVerified ? _nextStep : null,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 4: AADHAAR OCR & QR VERIFICATION
  // ==========================================
  Widget _buildStep4AadhaarOcr(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge('STEP 4 OF 12', 'Aadhaar Card AI OCR & QR Scan'),
          const SizedBox(height: 8),
          const Text(
            'Upload front and back photos of your Aadhaar card. Our AI OCR engine will instantly extract and validate your details.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: _buildUploadBox(
                  title: 'Aadhaar Front',
                  icon: Icons.credit_card_rounded,
                  isUploaded: data.isAadhaarVerified,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildUploadBox(
                  title: 'Aadhaar Back',
                  icon: Icons.flip_to_back_rounded,
                  isUploaded: data.isAadhaarVerified,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (!data.isAadhaarVerified) ...[
            ElevatedButton.icon(
              onPressed: () {
                ref.read(partnerOnboardingProvider.notifier).performAadhaarOcr();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('⚡ AI OCR Extraction & QR Validation Complete!')),
                );
              },
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
              label: const Text('Simulate AI OCR & QR Scan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: _cardDecoration(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: Color(0xff10b981), size: 20),
                      SizedBox(width: 8),
                      Text('Extracted Aadhaar Metadata (OCR Verified)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor)),
                    ],
                  ),
                  const Divider(height: 20),
                  _buildDetailRow('Full Name', data.aadhaarName),
                  _buildDetailRow('Aadhaar Number', data.aadhaarNumber),
                  _buildDetailRow('Date of Birth', data.aadhaarDob),
                  _buildDetailRow('Gender', data.aadhaarGender),
                  _buildDetailRow('Address', data.aadhaarAddress),
                ],
              ),
            ),
          ],
          const SizedBox(height: 32),

          _buildPrimaryButton(
            'Continue to Face Liveness Verification',
            data.isAadhaarVerified ? _nextStep : null,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 5: FACE LIVENESS & ANTI-DEEPFAKE SCAN
  // ==========================================
  Widget _buildStep5FaceLiveness(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge('STEP 5 OF 12', 'Live Face Liveness & Anti-Deepfake Scan'),
          const SizedBox(height: 8),
          const Text(
            'Look into the camera scanner and perform random micro-actions to verify live presence and prevent static photo or deepfake spoofing.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xfff1f5f9),
                    border: Border.all(
                      color: data.isFaceVerified ? const Color(0xff10b981) : AppTheme.primaryColor,
                      width: 4,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      data.isFaceVerified ? Icons.face_retouching_natural_rounded : Icons.camera_front_rounded,
                      size: 80,
                      color: data.isFaceVerified ? const Color(0xff10b981) : AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                if (!data.isFaceVerified) ...[
                  const Text('Perform Action: Blink Eyes & Smile',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor)),
                  const SizedBox(height: 4),
                  const Text('AI Scanner active · Position face inside circle',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                  const SizedBox(height: 20),

                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(partnerOnboardingProvider.notifier).performLivenessMatch();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Live Face Scan Passed! (98.4% Aadhaar Match)')),
                      );
                    },
                    icon: const Icon(Icons.center_focus_strong_rounded),
                    label: const Text('Start AI Liveness Check'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffecfdf5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffa7f3d0)),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xff059669), size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Face Liveness & Aadhaar Match: 98.4%',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff065f46)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('Anti-spoofing check passed · Zero static photo / deepfake detected',
                            style: TextStyle(fontSize: 11, color: Colors.green[800])),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildPrimaryButton(
            'Continue to Document Upload',
            data.isFaceVerified ? _nextStep : null,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 6: ROLE-ADAPTIVE DOCUMENT UPLOAD
  // ==========================================
  Widget _buildStep6DocumentUpload(OnboardingData data) {
    final String partnerType = data.partnerType;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge('STEP 6 OF 12', 'Role-Specific Document Upload'),
          const SizedBox(height: 8),
          Text(
            partnerType == 'provider'
                ? 'Upload your technical skill certs and experience letter.'
                : partnerType == 'seller'
                    ? 'Upload shop front photo, interior photo, and GST/Trade licence.'
                    : 'Upload Driving Licence, RC book, Vehicle Insurance, and PUC.',
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          if (partnerType == 'provider') ...[
            _buildUploadCard('Experience Certificate / Skill Card', data.isDocsUploaded),
            _buildUploadCard('Previous Company ID / ITI Diploma', data.isDocsUploaded),
          ] else if (partnerType == 'seller') ...[
            _buildUploadCard('Shop Front Photo with Board', data.isDocsUploaded),
            _buildUploadCard('Shop Interior Photo', data.isDocsUploaded),
            _buildUploadCard('Business Address Proof / GST (Optional)', data.isDocsUploaded),
          ] else ...[
            _buildUploadCard('Driving Licence (DL)', data.isDocsUploaded),
            _buildUploadCard('Vehicle Registration Certificate (RC)', data.isDocsUploaded),
            _buildUploadCard('Vehicle Insurance & PUC', data.isDocsUploaded),
          ],
          const SizedBox(height: 20),

          if (!data.isDocsUploaded) ...[
            OutlinedButton.icon(
              onPressed: () {
                ref.read(partnerOnboardingProvider.notifier).uploadDocs();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Required documents uploaded & encrypted.')),
                );
              },
              icon: const Icon(Icons.cloud_upload_rounded),
              label: const Text('Auto-Upload Demo Document Set'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            ),
          ],
          const SizedBox(height: 32),

          _buildPrimaryButton(
            'Continue to Vehicle Inspection',
            data.isDocsUploaded ? _nextStep : null,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 7: VEHICLE VERIFICATION
  // ==========================================
  Widget _buildStep7VehicleVerification(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge('STEP 7 OF 12', 'Vehicle Details & Plate Scan'),
          const SizedBox(height: 8),
          const Text(
            'Verify vehicle details for dispatch compliance and hyperlocal service delivery radius.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(color: Color(0xffeff6ff), shape: BoxShape.circle),
                      child: const Icon(Icons.two_wheeler_rounded, color: AppTheme.primaryColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data.vehicleModel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Plate No: ${data.vehicleNumber} · ${data.vehicleColour}',
                            style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const Divider(height: 24),
                _buildDetailRow('Registration Number', data.vehicleNumber),
                _buildDetailRow('Vehicle Model', data.vehicleModel),
                _buildDetailRow('Color', data.vehicleColour),
                _buildDetailRow('Insurance Expiry', '15 Nov 2027 (Valid)'),
                _buildDetailRow('PUC Certificate', '04 Aug 2026 (Valid)'),
                const SizedBox(height: 12),

                if (!data.isVehicleVerified) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(partnerOnboardingProvider.notifier).verifyVehicle();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Vehicle Plate OCR & Insurance Verified!')),
                      );
                    },
                    icon: const Icon(Icons.verified_rounded),
                    label: const Text('Verify Vehicle Plate & RC'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffecfdf5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xff059669), size: 20),
                        SizedBox(width: 8),
                        Text('Vehicle Verified & Approved for Dispatch',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff065f46), fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildPrimaryButton(
            'Continue to Professional Details',
            data.isVehicleVerified ? _nextStep : null,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 8: PROFESSIONAL & BUSINESS INFORMATION
  // ==========================================
  Widget _buildStep8ProfessionalDetails(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge('STEP 8 OF 12', 'Professional & Business Information'),
          const SizedBox(height: 8),
          const Text(
            'Provide details regarding your service domain, experience level, and operational radius.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Service / Shop Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _shopNameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.business_center_rounded, color: AppTheme.primaryColor),
                    hintText: 'e.g. ServiceHub Care Center',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Primary Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xffcbd5e1)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: data.selectedServiceCategory,
                      isExpanded: true,
                      items: [
                        'AC Repair & Electricals',
                        'Plumbing & Sanitation',
                        'Car Care & Detailing',
                        'Cooking & Catering',
                        'Laundry & Dry Cleaning',
                      ].map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(partnerOnboardingProvider.notifier).updateProfessionalInfo(selectedServiceCategory: val);
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text('Years of Experience: ${data.yearsExperience} Years',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Slider(
                  value: data.yearsExperience.toDouble(),
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '${data.yearsExperience} Yrs',
                  onChanged: (val) {
                    ref.read(partnerOnboardingProvider.notifier).updateProfessionalInfo(yearsExperience: val.toInt());
                  },
                ),

                Text('Service / Delivery Radius: ${data.workingRadiusKm.toStringAsFixed(1)} km',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Slider(
                  value: data.workingRadiusKm,
                  min: 1.0,
                  max: 25.0,
                  divisions: 24,
                  label: '${data.workingRadiusKm.toStringAsFixed(1)} km',
                  onChanged: (val) {
                    ref.read(partnerOnboardingProvider.notifier).updateProfessionalInfo(workingRadiusKm: val);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildPrimaryButton('Continue to Bank Verification', _nextStep),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 9: BANK PENNY DROP VERIFICATION
  // ==========================================
  Widget _buildStep9BankPennyDrop(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge('STEP 9 OF 12', 'Bank Account & Penny Drop Verification'),
          const SizedBox(height: 8),
          const Text(
            'We will deposit ₹1.00 via NPCI Penny Drop to instantly confirm your bank account name and enable direct payouts.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Account Holder Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _accountHolderController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bank Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _bankNameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('IFSC Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _ifscController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text('Account Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                TextField(
                  controller: _accountNumberController,
                  obscureText: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                if (!data.isPennyDropVerified) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(partnerOnboardingProvider.notifier).performPennyDrop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('⚡ ₹1.00 NPCI Penny Drop Successful! Name Matched 100%.')),
                      );
                    },
                    icon: const Icon(Icons.account_balance_rounded, size: 18),
                    label: const Text('Initiate NPCI Penny Drop (₹1.00 Test)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff10b981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffecfdf5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffa7f3d0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: Color(0xff059669), size: 20),
                            SizedBox(width: 8),
                            Text('Bank Account Verified & Penny Drop Matched',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff065f46), fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('NPCI Ref ID: ${data.pennyDropTxnId} · Beneficiary: ${data.accountHolderName}',
                            style: TextStyle(fontSize: 11, color: Colors.green[800])),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildPrimaryButton(
            'Continue to Legal & Signature',
            data.isPennyDropVerified ? _nextStep : null,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 10: LEGAL AGREEMENT & DIGITAL SIGNATURE
  // ==========================================
  Widget _buildStep10LegalAndSignature(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge('STEP 10 OF 12', 'Legal Terms & Touch Digital Signature'),
          const SizedBox(height: 8),
          const Text(
            'Review and sign the partner agreement. Commission cuts: 10% Service Bookings / 8% Hyperlocal Product Sales.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffe2e8f0)),
            ),
            child: const SingleChildScrollView(
              child: Text(
                'SERVICEHUB PARTNER AGREEMENT v2.4\n\n'
                '1. Standard Commission: ServiceHub retains a 10% cut on completed service tasks and 8% on products.\n'
                '2. Payouts: Automatic daily bank payouts are settled into your verified account.\n'
                '3. Quality Assurance: Partners must maintain a minimum customer satisfaction rating of 4.2 stars.\n'
                '4. Geofence Compliance: Services must be rendered strictly within the assigned 5.0 km geofence zone.',
                style: TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor, height: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Digital Signature Box
          Container(
            height: 130,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _signatureDrawn ? const Color(0xff10b981) : const Color(0xffcbd5e1),
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: () {
                setState(() => _signatureDrawn = true);
                ref.read(partnerOnboardingProvider.notifier).setTermsAndSignature(_termsAccepted, 'signature_data_bytes');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Touch Signature Captured & Hash Recorded!')),
                );
              },
              child: Center(
                child: _signatureDrawn
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.draw_rounded, color: Colors.green[700], size: 36),
                          const SizedBox(height: 4),
                          const Text('Digital Signature Signed & Timestamped',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff059669), fontSize: 12)),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gesture_rounded, color: AppTheme.textSecondaryColor, size: 32),
                          SizedBox(height: 4),
                          Text('Tap to Sign Digital Signature Box', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Checkbox(
                value: _termsAccepted,
                onChanged: (val) {
                  setState(() => _termsAccepted = val ?? false);
                  ref.read(partnerOnboardingProvider.notifier).setTermsAndSignature(_termsAccepted, _signatureDrawn ? 'signed' : '');
                },
              ),
              const Expanded(
                child: Text(
                  'I accept the ServiceHub Partner Agreement, Terms of Service & Privacy Policy.',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          _buildPrimaryButton(
            'Continue to AI Fraud Radar Scan',
            (_termsAccepted && _signatureDrawn) ? _nextStep : null,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 11: AI MULTI-POINT FRAUD RADAR SCAN
  // ==========================================
  Widget _buildStep11AiFraudRadar(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderBadge('STEP 11 OF 12', 'AI Multi-Point Risk & Fraud Radar'),
          const SizedBox(height: 8),
          const Text(
            'Our neural security engine conducts a multi-dimensional analysis on your application metadata.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              children: [
                _buildAiScanItem('Mobile Number & SIM Carrier Check', data.isAiScanningComplete),
                _buildAiScanItem('Disposable Email & Domain Security Check', data.isAiScanningComplete),
                _buildAiScanItem('Aadhaar QR Digital Signature Validation', data.isAiScanningComplete),
                _buildAiScanItem('Live Face vs Aadhaar Biometric Match (98.4%)', data.isAiScanningComplete),
                _buildAiScanItem('Anti-Photoshop & Image Metadata Scan', data.isAiScanningComplete),
                _buildAiScanItem('Vehicle Plate & Insurance Database Lookup', data.isAiScanningComplete),
                _buildAiScanItem('Bank NPCI Penny Drop & Name Verification', data.isAiScanningComplete),
                _buildAiScanItem('Anti-Root, Anti-Emulator & GPS Spoofing Scan', data.isAiScanningComplete),
                const Divider(height: 24),

                if (!data.isAiScanningComplete) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(partnerOnboardingProvider.notifier).runAiScan();
                    },
                    icon: const Icon(Icons.security_rounded),
                    label: const Text('Execute AI Fraud Scan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xffecfdf5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user_rounded, color: Color(0xff059669), size: 24),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data.aiRiskLevel, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xff065f46))),
                            Text('Fraud Risk Score: ${(data.aiRiskScore * 100).toStringAsFixed(1)}% (Passed All Checks)',
                                style: const TextStyle(fontSize: 11, color: Color(0xff047857))),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),

          _buildPrimaryButton(
            'Submit Verification Request',
            data.isAiScanningComplete
                ? () {
                    ref.read(partnerOnboardingProvider.notifier).submitRegistration();
                  }
                : null,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 12: CELEBRATION & STATUS TRACKER
  // ==========================================
  Widget _buildStep12Celebration(OnboardingData data, String partnerName) {
    final String displayName = partnerName.isNotEmpty && partnerName != 'Ravi Kumar' ? partnerName : 'Jenish Bheda';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 90,
            height: 90,
            decoration: const BoxDecoration(
              color: Color(0xffecfdf5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xff10b981), size: 64),
          ),
          const SizedBox(height: 16),

          const Text(
            '🎉 Congratulations!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Welcome to ServiceHub, $displayName!',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your partner onboarding profile & AI verification dossier have been successfully submitted.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor, height: 1.4),
          ),
          const SizedBox(height: 24),

          // Simulated Notifications Preview Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffeff6ff),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffbfdbfe)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.mark_email_read_rounded, color: AppTheme.primaryColor, size: 20),
                    SizedBox(width: 8),
                    Text('Automated Dispatch Notifications Sent',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
                  ],
                ),
                const SizedBox(height: 8),
                Text('📲 SMS sent to +91 ${data.mobileNumber}', style: const TextStyle(fontSize: 12, color: AppTheme.textPrimaryColor)),
                Text('✉️ Confirmation Email sent to ${data.email}', style: const TextStyle(fontSize: 12, color: AppTheme.textPrimaryColor)),
                Text('🆔 Partner Reg ID: ${data.registrationId}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor)),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Verification Status Tracker Checklist
          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Partner Onboarding Audit Checklist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const Divider(height: 20),
                _buildStatusItem('Mobile OTP Verified', true),
                _buildStatusItem('Email Domain & OTP Verified', true),
                _buildStatusItem('Aadhaar QR & Metadata OCR Verified', true),
                _buildStatusItem('Live Face Liveness Scan (98.4% Match)', true),
                _buildStatusItem('Vehicle Plate & Document Inspection', true),
                _buildStatusItem('NPCI Bank Penny Drop Verified', true),
                _buildStatusItem('Legal Terms & Touch Signature Recorded', true),
                _buildStatusItem('AI Fraud Neural Radar Clear', true),
                _buildStatusItem('Executive Admin Review Pending (Est 24 hrs)', false, isPending: true),
              ],
            ),
          ),
          const SizedBox(height: 28),

          ElevatedButton.icon(
            onPressed: () {
              // Update state & navigate to partner dashboard
              ref.read(loggedInPartnerNameProvider.notifier).state = displayName;
              context.go('/provider-dashboard');
            },
            icon: const Icon(Icons.dashboard_rounded),
            label: const Text('Enter Partner Workspace Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HELPER WIDGETS
  // ==========================================
  Widget _buildHeaderBadge(String tag, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xffeff6ff),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            tag,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
        ),
      ],
    );
  }

  Widget _buildCategoryCard({
    required String type,
    required String title,
    required String subtitle,
    required String earnings,
    required IconData icon,
    required Color badgeColor,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xffeff6ff) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : const Color(0xffe2e8f0),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: const [BoxShadow(color: Color(0x0a000000), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xffecfdf5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(earnings, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff059669))),
                    ),
                  ],
                ),
              ),
              if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadBox({required String title, required IconData icon, required bool isUploaded}) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: isUploaded ? const Color(0xffecfdf5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isUploaded ? const Color(0xff10b981) : const Color(0xffcbd5e1)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isUploaded ? Icons.verified_rounded : icon, color: isUploaded ? const Color(0xff10b981) : AppTheme.primaryColor, size: 32),
            const SizedBox(height: 6),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isUploaded ? const Color(0xff065f46) : AppTheme.textPrimaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadCard(String title, bool isUploaded) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Icon(isUploaded ? Icons.task_alt_rounded : Icons.cloud_upload_rounded,
              color: isUploaded ? const Color(0xff10b981) : AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
          Text(isUploaded ? 'Uploaded ✓' : 'Upload',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isUploaded ? const Color(0xff10b981) : AppTheme.primaryColor)),
        ],
      ),
    );
  }

  Widget _buildAiScanItem(String label, bool isDone) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(isDone ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
              color: isDone ? const Color(0xff10b981) : AppTheme.textSecondaryColor, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
          if (isDone) const Text('PASS', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff10b981), fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, bool isComplete, {bool isPending = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            isComplete
                ? Icons.check_circle_rounded
                : isPending
                    ? Icons.pending_rounded
                    : Icons.radio_button_unchecked_rounded,
            color: isComplete
                ? const Color(0xff10b981)
                : isPending
                    ? const Color(0xfff59e0b)
                    : const Color(0xffcbd5e1),
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isComplete || isPending ? FontWeight.bold : FontWeight.normal,
                color: isPending ? const Color(0xffd97706) : AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textPrimaryColor)),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: const [BoxShadow(color: Color(0x0a000000), blurRadius: 10, offset: Offset(0, 4))],
      border: Border.all(color: const Color(0xffe2e8f0)),
    );
  }

  Widget _buildPrimaryButton(String text, VoidCallback? onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xffcbd5e1),
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }
}
