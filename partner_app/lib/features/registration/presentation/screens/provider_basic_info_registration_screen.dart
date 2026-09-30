import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/firebase_otp_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sh_logo_widget.dart';
import '../../../../core/widgets/vector_avatar_widgets.dart';
import '../../../../core/storage/local_registration_cache.dart';
import '../../data/datasource/registration_remote_datasource.dart';
import '../../data/repositories/registration_repository_impl.dart';
import '../../../../core/widgets/top_toast.dart';
import '../controllers/provider_registration_controller.dart';

class ProviderBasicInfoRegistrationScreen extends StatefulWidget {
  const ProviderBasicInfoRegistrationScreen({super.key});

  @override
  State<ProviderBasicInfoRegistrationScreen> createState() => _ProviderBasicInfoRegistrationScreenState();
}

class _ProviderBasicInfoRegistrationScreenState extends State<ProviderBasicInfoRegistrationScreen> {
  late final ProviderRegistrationController _controller;
  int _currentSubStep = 0; // 0: Basic Details, 1: Account Credentials
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    LocalRegistrationCache.clearDraft();
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

  void _showError(String message) {
    TopToast.show(context, message, isError: true);
  }

  void _openOtpModalSheet() {
    final phone = _controller.phoneController.text.trim();
    if (phone.length != 10) {
      _showError('Please enter a valid 10-digit mobile number first.');
      return;
    }

    final List<TextEditingController> otpControllers = List.generate(6, (_) => TextEditingController());
    final List<FocusNode> focusNodes = List.generate(6, (_) => FocusNode());
    int secondsRemaining = 60;
    Timer? countdownTimer;
    bool isVerifying = false;
    String? errorMessage;

    // Trigger Firebase OTP and device notification immediately
    FirebaseOtpService.instance.sendOtp(phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (t) {
            if (secondsRemaining > 0) {
              setSheetState(() => secondsRemaining--);
            } else {
              t.cancel();
            }
          });

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.borderLight,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEFF6FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF2563EB), size: 36),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Verify Phone Number',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter the 6-digit code sent via Firebase notification to +91 $phone',
                      style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // 6 Digit OTP Inputs
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(6, (index) {
                          return Container(
                            width: 44,
                            height: 52,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: TextField(
                              controller: otpControllers[index],
                              focusNode: focusNodes[index],
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              maxLength: 1,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark),
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              decoration: InputDecoration(
                                counterText: '',
                                filled: true,
                                fillColor: AppColors.bgLight,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2)),
                              ),
                              onChanged: (val) {
                                if (val.isNotEmpty && index < 5) {
                                  focusNodes[index + 1].requestFocus();
                                } else if (val.isEmpty && index > 0) {
                                  focusNodes[index - 1].requestFocus();
                                }
                              },
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (errorMessage != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                errorMessage!,
                                style: const TextStyle(color: Color(0xFFDC2626), fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        const Text('Resend code in ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text(
                          '00:${secondsRemaining.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (secondsRemaining == 0)
                      TextButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFF2563EB)),
                        label: const Text('Resend OTP via Notification', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                        onPressed: () async {
                          setSheetState(() {
                            secondsRemaining = 60;
                            errorMessage = null;
                          });
                          await FirebaseOtpService.instance.sendOtp(phone);
                        },
                      ),
                    TextButton(
                      onPressed: () {
                        countdownTimer?.cancel();
                        Navigator.pop(ctx);
                      },
                      child: const Text('Didn\'t receive the code? Change Phone Number', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isVerifying
                            ? null
                            : () async {
                                final otpCode = otpControllers.map((c) => c.text).join();
                                if (otpCode.length != 6) {
                                  setSheetState(() {
                                    errorMessage = 'Please enter all 6 digits of the OTP.';
                                  });
                                  return;
                                }

                                setSheetState(() {
                                  isVerifying = true;
                                  errorMessage = null;
                                });

                                final res = await FirebaseOtpService.instance.verifyOtp(phone, otpCode);

                                if (!res.success) {
                                  setSheetState(() {
                                    isVerifying = false;
                                    errorMessage = res.message;
                                  });
                                  return;
                                }

                                if (!ctx.mounted || !mounted) return;
                                countdownTimer?.cancel();
                                Navigator.pop(ctx);
                                _controller.onMobileVerified(true);
                                setState(() {
                                  _currentSubStep = 1; // Advance to Step 2 (Account Credentials)
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ Phone number verified via Firebase OTP successfully!'),
                                    backgroundColor: Color(0xFF10B981),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                        child: isVerifying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Verify & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      countdownTimer?.cancel();
    });
  }

  void _handleNext() async {
    if (_currentSubStep == 0) {
      if (_controller.fullNameController.text.trim().isEmpty && _controller.firstNameController.text.trim().isEmpty) {
        _showError('Full Name is required *');
        return;
      }
      if (_controller.phoneController.text.trim().length != 10) {
        _showError('Valid 10-digit Phone Number is required *');
        return;
      }
      _openOtpModalSheet();
    } else {
      final uText = _controller.usernameController.text.trim();
      if (uText.isEmpty) {
        TopToast.show(context, 'Username is required *', isError: true);
        return;
      }
      if (!_controller.isValidUsernameFormat(uText)) {
        TopToast.show(context, 'please enter username as per conditions', isError: true);
        return;
      }
      if (!_controller.isUsernameChecked || !_controller.isUsernameAvailable) {
        final isAvail = await _controller.checkUsernameInDatabase(uText);
        if (!mounted) return;
        if (!isAvail) {
          TopToast.show(
            context,
            _controller.usernameError ?? 'use different username it is already availble',
            isError: true,
          );
          return;
        }
      }
      if (_controller.passwordController.text.isEmpty) {
        _showError('Password is required *');
        return;
      }
      if (_controller.confirmPasswordController.text != _controller.passwordController.text) {
        _showError('Confirm Password does not match Password');
        return;
      }
      if (_controller.selectedCity == null || _controller.selectedCity!.isEmpty) {
        _showError('Please select your Service City *');
        return;
      }
      if (!_controller.agreedToTerms) {
        _showError('Please accept Terms & Conditions to proceed *');
        return;
      }

      // Save draft data
      final draftData = {
        'username': _controller.usernameController.text.trim(),
        'first_name': _controller.effectiveFirstName,
        'last_name': _controller.effectiveLastName,
        'full_name': '${_controller.effectiveFirstName} ${_controller.effectiveLastName}'.trim(),
        'mobile_number': _controller.phoneController.text.trim(),
        'phone': _controller.phoneController.text.trim(),
        'email': _controller.emailController.text.trim(),
        'password': _controller.passwordController.text,
        'state': _controller.selectedState ?? 'Gujarat',
        'city': _controller.selectedCity ?? '',
        'terms_accepted': _controller.agreedToTerms,
      };
      await LocalRegistrationCache.saveDraft(draftData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Basic Details & Credentials Saved! Next: Select Service Category.'),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.push('/register/service-category');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
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
            if (_currentSubStep == 1) {
              setState(() => _currentSubStep = 0);
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/role-selection');
            }
          },
        ),
        title: const ShLogoWidget(size: 28, showSubtitle: true),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 580),
              child: _currentSubStep == 0
                  ? _buildStep1BasicDetails()
                  : _buildStep2AccountCredentials(),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 1 — BASIC DETAILS
  // ---------------------------------------------------------------------------
  Widget _buildStep1BasicDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vector Service Provider Header Banner Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E40AF), Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              const ServiceProviderAvatar(size: 75),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SERVICEHUB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1)),
                    const Text('SERVICE PROVIDER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Provide expert services & grow daily', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Create Your Account',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          "Let's get started with your basic information",
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Full Name', isRequired: true),
              TextField(
                controller: _controller.fullNameController,
                decoration: _inputDecoration('Enter your full name', icon: Icons.person_outline_rounded),
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(child: _buildFieldLabel('Phone Number', isRequired: true)),
                  const SizedBox(width: 8),
                  const Flexible(
                    child: Text(
                      '10 digits only',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Row(
                      children: [
                        Text('🇮🇳 +91', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_drop_down, color: AppColors.textMuted, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _controller.phoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: _inputDecoration('Enter phone number').copyWith(counterText: ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _buildFieldLabel('Email Address', isRequired: false, optionalSuffix: '(Optional)'),
              TextField(
                controller: _controller.emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration('Enter your email address', icon: Icons.email_outlined),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: _handleNext,
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Send OTP & Verify', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  GestureDetector(
                    onTap: () => context.go('/login/service-provider'),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // STEP 2 — ACCOUNT CREDENTIALS & SERVICE LOCATION
  // ---------------------------------------------------------------------------
  Widget _buildStep2AccountCredentials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Account',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Set your username, password, and service city',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Username Field with Check Availability Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFieldLabel('Username', isRequired: true),
                  if (_controller.isCheckingUsername)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                    )
                  else if (_controller.isUsernameChecked && _controller.isUsernameAvailable)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF16A34A)),
                        SizedBox(width: 4),
                        Text('✓ Available', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                      ],
                    )
                  else if (_controller.isUsernameChecked && !_controller.isUsernameAvailable)
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cancel_rounded, size: 14, color: Color(0xFFDC2626)),
                        SizedBox(width: 4),
                        Text('Not Available', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                      ],
                    ),
                ],
              ),
              TextField(
                controller: _controller.usernameController,
                onChanged: (val) {
                  _controller.onUsernameChanged(val);
                },
                decoration: _inputDecoration(
                  'e.g. rohit_01 or amit.pro',
                  icon: Icons.alternate_email_rounded,
                  suffixIcon: TextButton(
                    onPressed: () async {
                      final uText = _controller.usernameController.text.trim();
                      if (uText.isEmpty) {
                        TopToast.show(context, 'please enter username as per conditions', isError: true);
                        return;
                      }
                      final isAvailable = await _controller.checkUsernameInDatabase(uText);
                      if (!mounted) return;
                      if (!isAvailable) {
                        if (_controller.usernameError != null) {
                          TopToast.show(context, _controller.usernameError!, isError: true);
                        }
                      } else {
                        TopToast.show(context, '✓ Username "@$uText" is available!', isError: false);
                      }
                    },
                    child: _controller.isCheckingUsername
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
                          )
                        : const Text('Check', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Conditions: Minimum 6 characters. Numbers allowed. Only 1 special character (_ or .) allowed.',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
              ),
              if (_controller.usernameSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFF2563EB)),
                          SizedBox(width: 6),
                          Text('Suggested Available Usernames:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _controller.usernameSuggestions.map((sug) => InkWell(
                          onTap: () {
                            _controller.selectUsernameSuggestion(sug);
                            TopToast.show(context, 'Selected suggested username: @$sug', isError: false);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFF93C5FD)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('@$sug', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8))),
                                const SizedBox(width: 4),
                                const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF2563EB)),
                              ],
                            ),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),

              // Password Field
              _buildFieldLabel('Password', isRequired: true),
              TextField(
                controller: _controller.passwordController,
                obscureText: _obscurePassword,
                decoration: _inputDecoration(
                  'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Confirm Password Field
              _buildFieldLabel('Confirm Password', isRequired: true),
              TextField(
                controller: _controller.confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: _inputDecoration(
                  'Confirm your password',
                  icon: Icons.lock_clock_outlined,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textMuted),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Password Requirements Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Password must contain:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    SizedBox(height: 4),
                    Row(children: [Icon(Icons.check, size: 12, color: Color(0xFF16A34A)), SizedBox(width: 4), Text('At least 6 characters', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted))]),
                    Row(children: [Icon(Icons.check, size: 12, color: Color(0xFF16A34A)), SizedBox(width: 4), Text('One letter or number', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted))]),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // State & City Selection
              _buildFieldLabel('Service State & City', isRequired: true),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.map_rounded, color: Color(0xFF2563EB), size: 16),
                          SizedBox(width: 6),
                          Text('Gujarat', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _controller.selectedCity,
                      hint: const Text('Select City', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      items: _controller.availableCities.map((city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(city, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A))),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          _controller.selectCity(val);
                        }
                      },
                      decoration: _inputDecoration('City', icon: Icons.location_city_rounded),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Terms and Conditions Checkbox
              Row(
                children: [
                  Checkbox(
                    value: _controller.agreedToTerms,
                    activeColor: const Color(0xFF2563EB),
                    onChanged: (val) => _controller.toggleTerms(val),
                  ),
                  const Expanded(
                    child: Text(
                      'I agree to ServiceHub Partner Terms of Service & Privacy Policy.',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Save & Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: _handleNext,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Save & Continue to Service Selection',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
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

  // Label Helper with Asterisk
  Widget _buildFieldLabel(String title, {required bool isRequired, String? optionalSuffix}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark),
            ),
            if (isRequired)
              const TextSpan(
                text: ' *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.red),
              )
            else if (optionalSuffix != null)
              TextSpan(
                text: ' $optionalSuffix',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {IconData? icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
      prefixIcon: icon != null ? Icon(icon, color: const Color(0xFF64748B), size: 18) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.bgLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
      ),
    );
  }
}
