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

  // Stage 2 Controllers
  final TextEditingController _nameController = TextEditingController(text: 'Jenish Bheda');
  final TextEditingController _phoneController = TextEditingController(text: '9876543210');
  final TextEditingController _emailController = TextEditingController(text: 'jenish@servicehub.com');
  final TextEditingController _passwordController = TextEditingController(text: 'partner123');
  final TextEditingController _confirmPasswordController = TextEditingController(text: 'partner123');

  // Stage 3 Controllers
  final TextEditingController _experienceController = TextEditingController(text: '3');
  final TextEditingController _vehicleNumberController = TextEditingController(text: 'GJ-03-AB-1234');
  final TextEditingController _shopNameController = TextEditingController(text: 'ServiceHub Care Center');

  bool _passwordMismatch = false;
  bool _experienceIneligible = false;

  final List<String> _serviceCategories = [
    'AC Repair (All types of AC repair & maintenance)',
    'Plumbing (Knowledge about all faults & pipe repair)',
    'Car Repair (Complete knowledge of auto repair & diagnostics)',
    'Cooking Chef (Pure Vegetarian food only & daily household routine meals)',
    'Laundry Service (All laundry knowledge & professional tools)',
    'Care Taker (Senior citizen care, medical assistance & patient support)',
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _experienceController.dispose();
    _vehicleNumberController.dispose();
    _shopNameController.dispose();
    super.dispose();
  }

  void _goToStage(int stage) {
    ref.read(partnerOnboardingProvider.notifier).setStage(stage);
    _pageController.animateToPage(
      stage - 1,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _nextStage() {
    final current = ref.read(partnerOnboardingProvider).currentStage;
    if (current < 5) {
      _goToStage(current + 1);
    }
  }

  void _prevStage() {
    final current = ref.read(partnerOnboardingProvider).currentStage;
    if (current > 1) {
      _goToStage(current - 1);
    }
  }

  void _validatePasswords() {
    final pass = _passwordController.text;
    final confirm = _confirmPasswordController.text;
    setState(() {
      _passwordMismatch = (pass != confirm && confirm.isNotEmpty);
    });
  }

  void _validateExperience(String category, int exp) {
    final isAcOrPlumbing = category.contains('AC Repair') || category.contains('Plumbing');
    setState(() {
      _experienceIneligible = isAcOrPlumbing && exp < 2;
    });
  }

  @override
  Widget build(BuildContext context) {
    final onboarding = ref.watch(partnerOnboardingProvider);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: onboarding.currentStage > 1 && onboarding.currentStage < 5
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimaryColor, size: 20),
                onPressed: _prevStage,
              )
            : null,
        title: const Row(
          children: [
            Icon(Icons.handshake_rounded, color: AppTheme.primaryColor, size: 22),
            SizedBox(width: 10),
            Text(
              'Partner Account Registration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              LinearProgressIndicator(
                value: onboarding.currentStage / 5.0,
                backgroundColor: const Color(0xffe2e8f0),
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                minHeight: 4,
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _buildStage1ChooseRole(onboarding),
                    _buildStage2PersonalDetails(onboarding),
                    _buildStage3OperationalDetails(onboarding),
                    _buildStage4DocumentUpload(onboarding),
                    _buildStage5Completion(onboarding),
                  ],
                ),
              ),
            ],
          ),

          // Bottom-Right Floating Next Action Button
          if (onboarding.currentStage < 5)
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingActionButton.extended(
                onPressed: _canProceed(onboarding) ? _handleNextClick : null,
                backgroundColor: _canProceed(onboarding) ? AppTheme.primaryColor : const Color(0xffcbd5e1),
                elevation: 4,
                icon: Text(
                  onboarding.currentStage == 4 ? 'Submit' : 'Next',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                ),
                label: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  bool _canProceed(OnboardingData data) {
    if (data.currentStage == 2) {
      if (_passwordMismatch || _passwordController.text != _confirmPasswordController.text) return false;
      if (!data.isPhoneVerified) return false;
    }
    if (data.currentStage == 3) {
      if (_experienceIneligible) return false;
    }
    if (data.currentStage == 4) {
      if (!data.isIdUploaded) return false;
      final isCompulsoryDl = data.selectedCategory.contains('AC Repair') ||
          data.selectedCategory.contains('Plumbing') ||
          data.selectedCategory.contains('Car Repair');
      if (isCompulsoryDl && !data.isDrivingLicenceUploaded) return false;
    }
    return true;
  }

  void _handleNextClick() {
    final onboarding = ref.read(partnerOnboardingProvider);
    if (onboarding.currentStage == 2) {
      ref.read(partnerOnboardingProvider.notifier).updatePersonalInfo(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            confirmPassword: _confirmPasswordController.text,
          );
    }
    if (onboarding.currentStage == 3) {
      final exp = int.tryParse(_experienceController.text.trim()) ?? 3;
      ref.read(partnerOnboardingProvider.notifier).updateOperationalDetails(
            experience: exp,
            shopName: _shopNameController.text.trim(),
            vehicleNumber: _vehicleNumberController.text.trim(),
          );
    }
    _nextStage();
  }

  // ==========================================
  // STAGE 1: ROLE SELECTION (No Income Text)
  // ==========================================
  Widget _buildStage1ChooseRole(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Your Partner Category',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose your operational role to begin registration.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          _buildCleanRoleCard(
            type: 'provider',
            title: 'Service Provider Agent',
            description: 'AC Repair Agent · Plumber · Car Repair · Cooking Chef · Laundry',
            icon: Icons.construction_rounded,
            badgeColor: const Color(0xffeff6ff),
            iconColor: AppTheme.primaryColor,
            isSelected: data.partnerType == 'provider',
            onTap: () => ref.read(partnerOnboardingProvider.notifier).setPartnerType('provider'),
          ),
          const SizedBox(height: 16),

          _buildCleanRoleCard(
            type: 'seller',
            title: 'Seller / Shopkeeper',
            description: 'Spare Parts Store · Plumbing Hardware · Electrical Supplies',
            icon: Icons.storefront_rounded,
            badgeColor: const Color(0xfff5f3ff),
            iconColor: const Color(0xff7c3aed),
            isSelected: data.partnerType == 'seller',
            onTap: () => ref.read(partnerOnboardingProvider.notifier).setPartnerType('seller'),
          ),
          const SizedBox(height: 16),

          _buildCleanRoleCard(
            type: 'delivery',
            title: 'Delivery Agent',
            description: 'Delivers products ordered on ServiceHub (No food/meds)',
            icon: Icons.two_wheeler_rounded,
            badgeColor: const Color(0xffecfdf5),
            iconColor: const Color(0xff059669),
            isSelected: data.partnerType == 'delivery',
            onTap: () => ref.read(partnerOnboardingProvider.notifier).setPartnerType('delivery'),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==========================================
  // STAGE 2: PERSONAL DETAILS & PHONE VERIFY
  // ==========================================
  Widget _buildStage2PersonalDetails(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personal & Login Details',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 6),
          const Text(
            'Enter your contact details and password for your partner account.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_rounded, color: AppTheme.primaryColor),
                    hintText: 'Enter full legal name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

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
                    suffixIcon: data.isPhoneVerified
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xff10b981))
                        : null,
                    hintText: '10-digit number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),

                // Green Only Phone Verification Button
                if (!data.isPhoneVerified) ...[
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(partnerOnboardingProvider.notifier).verifyPhone();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('✓ Mobile Phone Verified Successfully!'), backgroundColor: Color(0xff10b981)),
                      );
                    },
                    icon: const Icon(Icons.verified_user_rounded, size: 18),
                    label: const Text('Click here to verify your number', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff10b981),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xffecfdf5), borderRadius: BorderRadius.circular(10)),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_rounded, color: Color(0xff059669), size: 18),
                        SizedBox(width: 8),
                        Text('Phone Number Verified', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff065f46), fontSize: 13)),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_rounded, color: AppTheme.primaryColor),
                    hintText: 'name@example.com',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),

                // Password Input
                const Text('Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  onChanged: (_) => _validatePasswords(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_rounded, color: AppTheme.primaryColor),
                    hintText: 'Create password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _passwordMismatch ? Colors.red : const Color(0xffcbd5e1)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Confirm Password Input with RED border on mismatch
                const Text('Re-write Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  onChanged: (_) => _validatePasswords(),
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.lock_reset_rounded, color: _passwordMismatch ? Colors.red : AppTheme.primaryColor),
                    hintText: 'Re-enter password to confirm',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _passwordMismatch ? Colors.red : const Color(0xffcbd5e1), width: _passwordMismatch ? 2 : 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _passwordMismatch ? Colors.red : AppTheme.primaryColor, width: 2),
                    ),
                  ),
                ),
                if (_passwordMismatch) ...[
                  const SizedBox(height: 6),
                  const Text('❌ Passwords do not match. Please re-type correctly.', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==========================================
  // STAGE 3: OPERATIONAL DETAILS (5 Services)
  // ==========================================
  Widget _buildStage3OperationalDetails(OnboardingData data) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Operational Specialization',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 6),
          const Text(
            'Specify your primary service category and years of field experience.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.partnerType == 'provider') ...[
                  const Text('Select Service Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: data.selectedCategory,
                    isExpanded: true,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: _serviceCategories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 12)))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(partnerOnboardingProvider.notifier).updateOperationalDetails(category: val);
                        final exp = int.tryParse(_experienceController.text) ?? 3;
                        _validateExperience(val, exp);
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  const Text('Years of Experience (Minimum 2 Years Required)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: data.yearsExperience.toDouble().clamp(1.0, 10.0),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: '${data.yearsExperience} Yrs',
                          onChanged: (val) {
                            final intExp = val.toInt();
                            _experienceController.text = intExp.toString();
                            ref.read(partnerOnboardingProvider.notifier).updateOperationalDetails(experience: intExp);
                            _validateExperience(data.selectedCategory, intExp);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Manual Experience Input Box
                      SizedBox(
                        width: 70,
                        child: TextField(
                          controller: _experienceController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (val) {
                            final exp = int.tryParse(val) ?? 0;
                            ref.read(partnerOnboardingProvider.notifier).updateOperationalDetails(experience: exp);
                            _validateExperience(data.selectedCategory, exp);
                          },
                          decoration: InputDecoration(
                            suffixText: 'yrs',
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _experienceIneligible ? Colors.red : const Color(0xffcbd5e1), width: _experienceIneligible ? 2 : 1),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: _experienceIneligible ? Colors.red : AppTheme.primaryColor, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Eligibility Error Note (Red)
                  if (_experienceIneligible) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xfffef2f2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'You are not eligible for this service (Minimum 2 years experience required).',
                              style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Vehicle Info (Optional / Compulsory based on vehicle)
                  const Text('Vehicle Number (Bike / Scooter)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _vehicleNumberController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.two_wheeler_rounded, color: AppTheme.primaryColor),
                      hintText: 'e.g. GJ-03-AB-1234',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else if (data.partnerType == 'seller') ...[
                  const Text('Shop / Store Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _shopNameController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.storefront_rounded, color: AppTheme.primaryColor),
                      hintText: 'e.g. ServiceHub Premier Store',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ] else ...[
                  const Text('Vehicle Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: data.vehicleType,
                    decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    items: ['Motorcycle / Scooter', 'Electric Scooter / Bike', 'Bicycle'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        ref.read(partnerOnboardingProvider.notifier).updateOperationalDetails(vehicleType: val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('Vehicle Registration Number', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _vehicleNumberController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.two_wheeler_rounded, color: AppTheme.primaryColor),
                      hintText: 'e.g. GJ-03-AB-1234',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==========================================
  // STAGE 4: DOCUMENT UPLOAD (Compulsory DL Rules)
  // ==========================================
  Widget _buildStage4DocumentUpload(OnboardingData data) {
    final isCompulsoryDl = data.selectedCategory.contains('AC Repair') ||
        data.selectedCategory.contains('Plumbing') ||
        data.selectedCategory.contains('Car Repair');
    final isOptionalSkillCert = data.selectedCategory.contains('AC Repair') || data.selectedCategory.contains('Plumbing');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Document Attachments',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 6),
          const Text(
            'Attach your government identity card and license documents for background verification.',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 24),

          // Aadhaar Card (Compulsory for all)
          _buildDocRowCard(
            title: 'Aadhaar Card (Identity Proof)',
            isCompulsory: true,
            isUploaded: data.isIdUploaded,
            fileName: data.idDocumentName,
            onUpload: () {
              ref.read(partnerOnboardingProvider.notifier).uploadIdDoc();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Aadhaar Card Uploaded & Background AI Verified!')));
            },
          ),
          const SizedBox(height: 16),

          // Driving Licence (Compulsory for AC/Plumbing/Car, Optional for Cook/Laundry)
          _buildDocRowCard(
            title: 'Driving Licence (DL)',
            isCompulsory: isCompulsoryDl,
            isUploaded: data.isDrivingLicenceUploaded,
            fileName: data.drivingLicenceName,
            onUpload: () {
              ref.read(partnerOnboardingProvider.notifier).uploadDrivingLicence();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Driving Licence Uploaded & Background AI Verified!')));
            },
          ),
          const SizedBox(height: 16),

          // Skill Certificate (Optional for AC/Plumbing)
          if (isOptionalSkillCert) ...[
            _buildDocRowCard(
              title: 'Skill / Experience Certificate',
              isCompulsory: false,
              isUploaded: data.isSkillCertUploaded,
              fileName: data.skillCertName,
              onUpload: () {
                ref.read(partnerOnboardingProvider.notifier).uploadSkillCert();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('✓ Skill Certificate Uploaded!')));
              },
            ),
          ],
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ==========================================
  // STAGE 5: COMPLETION & INITIALIZATION (00 Values)
  // ==========================================
  Widget _buildStage5Completion(OnboardingData data) {
    final name = data.fullName.isNotEmpty ? data.fullName : 'Jenish Bheda';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 84,
            height: 84,
            decoration: const BoxDecoration(color: Color(0xffecfdf5), shape: BoxShape.circle),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xff10b981), size: 56),
          ),
          const SizedBox(height: 20),

          const Text(
            'Registration Complete!',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
          ),
          const SizedBox(height: 6),
          Text(
            'Thank you for registering, $name!',
            style: const TextStyle(fontSize: 15, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xffeff6ff),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xffbfdbfe)),
            ),
            child: const Row(
              children: [
                Icon(Icons.sms_rounded, color: AppTheme.primaryColor, size: 22),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'SMS notification dispatched to your verified phone number. Your account is active with zero initial values.',
                    style: TextStyle(fontSize: 12, color: Color(0xff1e3a8a), height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () {
              ref.read(loggedInPartnerNameProvider.notifier).state = name;
              ref.read(loggedInPartnerRoleProvider.notifier).state = data.partnerType;
              String route = '/provider-dashboard';
              if (data.partnerType == 'seller') route = '/seller-dashboard';
              if (data.partnerType == 'delivery') route = '/delivery-dashboard';
              context.go(route);
            },
            icon: const Icon(Icons.dashboard_rounded),
            label: const Text('Open Partner Workspace', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
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
  Widget _buildCleanRoleCard({
    required String type,
    required String title,
    required String description,
    required IconData icon,
    required Color badgeColor,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xffeff6ff) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isSelected ? AppTheme.primaryColor : const Color(0xffe2e8f0), width: isSelected ? 2 : 1),
        boxShadow: const [BoxShadow(color: Color(0x0a000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimaryColor)),
                    const SizedBox(height: 3),
                    Text(description, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ),
              if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.primaryColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocRowCard({
    required String title,
    required bool isCompulsory,
    required bool isUploaded,
    required String fileName,
    required VoidCallback onUpload,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isCompulsory ? const Color(0xfffef2f2) : const Color(0xfff1f5f9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCompulsory ? 'Compulsory' : 'Optional',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isCompulsory ? Colors.red : const Color(0xff64748b)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(isUploaded ? Icons.verified_user_rounded : Icons.insert_drive_file_outlined,
                  color: isUploaded ? const Color(0xff10b981) : AppTheme.textSecondaryColor, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isUploaded ? '$fileName (AI Verified)' : 'No file selected',
                  style: TextStyle(fontSize: 12, fontWeight: isUploaded ? FontWeight.bold : FontWeight.normal, color: isUploaded ? const Color(0xff065f46) : AppTheme.textSecondaryColor),
                ),
              ),
              OutlinedButton.icon(
                onPressed: onUpload,
                icon: Icon(isUploaded ? Icons.refresh_rounded : Icons.upload_file_rounded, size: 16),
                label: Text(isUploaded ? 'Replace' : 'Upload'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xffe2e8f0)),
      boxShadow: const [BoxShadow(color: Color(0x0a000000), blurRadius: 8, offset: Offset(0, 3))],
    );
  }
}
