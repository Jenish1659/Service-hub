import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sh_logo_widget.dart';
import '../../../../core/widgets/vector_avatar_widgets.dart';
import '../../../../core/services/registration_service.dart';
import '../../data/datasource/registration_remote_datasource.dart';
import '../../data/repositories/registration_repository_impl.dart';
import '../controllers/provider_registration_controller.dart';
import '../widgets/otp_verification_widget.dart';
import '../widgets/gujarat_coming_soon_dialog.dart';

class ProviderBasicInfoRegistrationScreen extends StatefulWidget {
  const ProviderBasicInfoRegistrationScreen({super.key});

  @override
  State<ProviderBasicInfoRegistrationScreen> createState() => _ProviderBasicInfoRegistrationScreenState();
}

class _ProviderBasicInfoRegistrationScreenState extends State<ProviderBasicInfoRegistrationScreen> {
  late final ProviderRegistrationController _controller;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    final repo = RegistrationRepositoryImpl(remoteDataSource: RegistrationRemoteDataSource());
    _controller = ProviderRegistrationController(repository: repo);
    _controller.addListener(_onControllerUpdated);
  }

  void _onControllerUpdated() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdated);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
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
              context.go('/role-selection');
            }
          },
        ),
        title: const ShLogoWidget(size: 32, showSubtitle: true),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              // Hero Vector Illustration Banner Card (Matching Image)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Flex(
                  direction: isDesktop ? Axis.horizontal : Axis.vertical,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                      children: const [
                        Text(
                          'Create Your\nProvider Account',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primaryNavy,
                            height: 1.2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Join ServiceHub and start\ngrowing your business',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isDesktop ? 0 : 16),
                    // Vector Avatar & Floating Service Badges
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const ServiceProviderAvatar(size: 110),
                        Positioned(
                          top: 0,
                          left: 0,
                          child: _buildFloatingBadge(Icons.build, AppColors.providerBluePrimary),
                        ),
                        Positioned(
                          top: 10,
                          right: 0,
                          child: _buildFloatingBadge(Icons.cake, const Color(0xFFEC4899)),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 4,
                          child: _buildFloatingBadge(Icons.directions_car, AppColors.deliveryOrangePrimary),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 10,
                          child: _buildFloatingBadge(Icons.shopping_bag, AppColors.shopkeeperGreenPrimary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Main Basic Information Form Container Card
              Container(
                constraints: const BoxConstraints(maxWidth: 540),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderLight),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 4)),
                  ],
                ),
                child: Form(
                  key: _controller.formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Title: Basic Information
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.providerBlueLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person_outline, color: AppColors.providerBluePrimary, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Basic Information',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryNavy,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                "Let's start with your basic details",
                                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // First Name & Last Name Fields (Responsive Grid)
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('First Name'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _controller.firstNameController,
                                  decoration: _buildInputDecoration('Enter first name', prefixIcon: Icons.person_outline),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Last Name'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _controller.lastNameController,
                                  decoration: _buildInputDecoration('Enter last name', prefixIcon: Icons.person_outline),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Contact Number Field
                      _buildFieldLabel('Contact Number'),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.bgLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.phone_outlined, color: AppColors.textMuted, size: 18),
                                const SizedBox(width: 4),
                                DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _controller.countryCode,
                                    items: const [
                                      DropdownMenuItem(value: '+91', child: Text('+91', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                                    ],
                                    onChanged: null, // Fixed +91 per PR-001
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: _controller.phoneController,
                              keyboardType: TextInputType.phone,
                              maxLength: 10,
                              decoration: _buildInputDecoration('Enter your contact number').copyWith(counterText: ''),
                              onChanged: (val) => _controller.onMobileChanged(val),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Animated OTP Verification Section (Expands on 10 digits)
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: _controller.isOtpSent
                            ? Column(
                                children: [
                                  OtpVerificationWidget(
                                    mobileNumber: _controller.phoneController.text,
                                    onVerificationChanged: (verified) => _controller.onMobileVerified(verified),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              )
                            : const SizedBox.shrink(),
                      ),

                      // Email Address (Optional)
                      _buildFieldLabel('Email Address (Optional)', required: false),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _controller.emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration('Enter your email address', prefixIcon: Icons.email_outlined),
                      ),
                      const SizedBox(height: 16),

                      // Password & Confirm Password Fields
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Password'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _controller.passwordController,
                                  obscureText: _obscurePassword,
                                  decoration: _buildInputDecoration(
                                    'Create password',
                                    prefixIcon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Confirm Password'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _controller.confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: _buildInputDecoration(
                                    'Confirm password',
                                    prefixIcon: Icons.lock_outline,
                                    suffixIcon: IconButton(
                                      icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
                                      onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // State Dropdown (Gujarat Only Restriction with Coming Soon Dialog per PR-003)
                      _buildFieldLabel('State'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _controller.selectedState,
                        hint: const Text('Select your state', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        decoration: _buildInputDecoration('', prefixIcon: Icons.location_on_outlined),
                        items: LocationService.supportedStates.map((s) {
                          return DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 13)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            _controller.handleStateSelection(
                              val,
                              context,
                              () {
                                GujaratComingSoonDialog.show(context, val, () {
                                  _controller.handleStateSelection('Gujarat', context, () {});
                                });
                              },
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // City Searchable/Selectable Dropdown
                      _buildFieldLabel('City'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _controller.selectedCity,
                        hint: const Text('Select your city', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                        decoration: _buildInputDecoration('', prefixIcon: Icons.location_city_outlined),
                        items: _controller.availableCities.map((c) {
                          return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                        }).toList(),
                        onChanged: _controller.selectedState == 'Gujarat'
                            ? (val) {
                                if (val != null) _controller.selectCity(val);
                              }
                            : null,
                      ),
                      const SizedBox(height: 16),

                      // Terms Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _controller.agreedToTerms,
                            activeColor: AppColors.providerBluePrimary,
                            onChanged: (val) => _controller.toggleTerms(val),
                          ),
                          Expanded(
                            child: RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 11, color: AppColors.textDark),
                                children: [
                                  TextSpan(text: 'I agree to the '),
                                  TextSpan(text: 'Terms & Conditions ', style: TextStyle(color: AppColors.providerBluePrimary, fontWeight: FontWeight.bold)),
                                  TextSpan(text: 'and '),
                                  TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.providerBluePrimary, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Primary Button: Save & Continue
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _controller.isFormValid ? AppColors.providerBluePrimary : Colors.grey.shade400,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: _controller.isFormValid ? 4 : 0,
                          ),
                          onPressed: _controller.isFormValid
                              ? () async {
                                  final messenger = ScaffoldMessenger.of(context);
                                  final ok = await _controller.submitBasicInformation();
                                  if (ok && mounted) {
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text('Basic Information Saved Successfully! Draft Created in Database.'),
                                        backgroundColor: AppColors.shopkeeperGreenPrimary,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          child: _controller.isLoading
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text('Save & Continue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Login Link: Already have an account? Login here
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Already have an account? ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          GestureDetector(
                            onTap: () => context.go('/role-selection'),
                            child: const Text(
                              'Login here',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.providerBluePrimary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label, {bool required = true}) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
          ),
          if (required)
            const TextSpan(
              text: ' *',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
            ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {IconData? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppColors.textMuted, size: 18) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.borderLight),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.providerBluePrimary, width: 1.5),
      ),
    );
  }

  Widget _buildFloatingBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Icon(icon, color: Colors.white, size: 12),
    );
  }
}
