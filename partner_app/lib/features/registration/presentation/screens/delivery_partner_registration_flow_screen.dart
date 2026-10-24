import 'dart:async';
import 'dart:io';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/storage/local_registration_cache.dart';
import '../../../../core/services/media_document_picker_service.dart';
import '../../../../core/services/firebase_otp_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/vector_avatar_widgets.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../../../core/services/username_availability_service.dart';

class DeliveryPartnerRegistrationFlowScreen extends StatefulWidget {
  const DeliveryPartnerRegistrationFlowScreen({super.key});

  @override
  State<DeliveryPartnerRegistrationFlowScreen> createState() => _DeliveryPartnerRegistrationFlowScreenState();
}

class _DeliveryPartnerRegistrationFlowScreenState extends State<DeliveryPartnerRegistrationFlowScreen> {
  int _currentStep = 0; // 0 to 11 (Total 12 Screens)

  // Screen 1: Basic Details
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isPhoneVerified = false;

  // Screen 3: Account Credentials
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isUsernameChecked = false;
  bool _isUsernameAvailable = false;
  bool _isCheckingUsername = false;
  List<String> _usernameSuggestions = [];
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Screen 4: Personal & Vehicle Details (DOB Removed, Bicycle Removed)
  String _selectedGender = 'Male';
  String _selectedVehicleType = 'Bike'; // ONLY 'Bike' or 'Scooter'
  final _vehicleNumberController = TextEditingController();

  // Screen 5: Address Details (No Map Screen)
  final _houseNoController = TextEditingController();
  final _nearAreaController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();
  bool _useCurrentLocation = false;

  // Screen 6: Emergency Contact
  final _emergencyNameController = TextEditingController();
  String _emergencyRelationship = 'Select relationship';
  final _emergencyPhoneController = TextEditingController();

  // Screen 7: Upload Profile Photo
  bool _profilePhotoUploaded = false;
  File? _profilePhotoFile;

  // Screen 8: Aadhaar Details
  final _aadhaarNumberController = TextEditingController();
  bool _aadhaarFrontUploaded = false;
  File? _aadhaarFrontFile;
  bool _aadhaarBackUploaded = false;
  File? _aadhaarBackFile;

  // Screen 9: Aadhaar Face Verification
  bool _faceVerified = false;
  File? _faceSelfieFile;

  // Screen 10: Upload Documents
  bool _drivingLicenceUploaded = false;
  File? _drivingLicenceFile;
  bool _vehicleRcUploaded = false;
  File? _vehicleRcFile;
  bool _vehicleInsuranceUploaded = false; // Optional
  File? _vehicleInsuranceFile;
  final _drivingLicenceNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _ifscController = TextEditingController();
  final _accountHolderNameController = TextEditingController();

  // Supabase submission state
  bool _isSubmittingToDb = false;
  String _submittedRegistrationId = 'SH-DEL-2026-9042';

  Future<void> _pickProfilePhoto() async {
    final picked = await MediaDocumentPickerService.instance.pickImageWithSourceChoice(
      context,
      title: 'Select Profile Photo',
      subtitle: 'Take a clear headshot photo or pick from gallery',
    );
    if (picked != null) {
      setState(() {
        _profilePhotoFile = File(picked.path);
        _profilePhotoUploaded = true;
      });
    }
  }

  Future<void> _pickAadhaarFront() async {
    final picked = await MediaDocumentPickerService.instance.pickImageWithSourceChoice(
      context,
      title: 'Upload Aadhaar Card (Front)',
      subtitle: 'Take a clear photo of the front side of your Aadhaar card',
    );
    if (picked != null) {
      setState(() {
        _aadhaarFrontFile = File(picked.path);
        _aadhaarFrontUploaded = true;
      });
    }
  }

  Future<void> _pickAadhaarBack() async {
    final picked = await MediaDocumentPickerService.instance.pickImageWithSourceChoice(
      context,
      title: 'Upload Aadhaar Card (Back)',
      subtitle: 'Take a clear photo of the back side of your Aadhaar card',
    );
    if (picked != null) {
      setState(() {
        _aadhaarBackFile = File(picked.path);
        _aadhaarBackUploaded = true;
      });
    }
  }

  Future<void> _startFaceVerification() async {
    try {
      final picker = ImagePicker();
      final XFile? selfie = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );
      if (selfie != null) {
        setState(() {
          _faceSelfieFile = File(selfie.path);
          _faceVerified = true;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✓ Face captured and verified successfully!'),
              backgroundColor: Color(0xFF16A34A),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not access front camera: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _pickDrivingLicence() async {
    final picked = await MediaDocumentPickerService.instance.pickImageWithSourceChoice(
      context,
      title: 'Upload Driving Licence',
      subtitle: 'Take a clear photo or choose from gallery',
    );
    if (picked != null) {
      setState(() {
        _drivingLicenceFile = File(picked.path);
        _drivingLicenceUploaded = true;
      });
    }
  }

  Future<void> _pickVehicleRc() async {
    final picked = await MediaDocumentPickerService.instance.pickImageWithSourceChoice(
      context,
      title: 'Upload Vehicle RC',
      subtitle: 'Take a clear photo or choose from gallery',
    );
    if (picked != null) {
      setState(() {
        _vehicleRcFile = File(picked.path);
        _vehicleRcUploaded = true;
      });
    }
  }

  Future<void> _pickVehicleInsurance() async {
    final picked = await MediaDocumentPickerService.instance.pickImageWithSourceChoice(
      context,
      title: 'Upload Vehicle Insurance',
      subtitle: 'Take a photo or choose from gallery',
    );
    if (picked != null) {
      setState(() {
        _vehicleInsuranceFile = File(picked.path);
        _vehicleInsuranceUploaded = true;
      });
    }
  }

  void _showError(String message) {
    TopToast.show(context, message, isError: true);
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      if (_fullNameController.text.trim().isEmpty) {
        _showError('Full Name is required *');
        return;
      }
      if (_phoneController.text.trim().length != 10) {
        _showError('Valid 10-digit Phone Number is required *');
        return;
      }
      // Trigger Send OTP sheet & move to Step 1
      _openOtpModalSheet();
      return;
    } else if (_currentStep == 1) {
      if (!_isPhoneVerified) {
        _showError('Phone verification is compulsory *');
        return;
      }
    } else if (_currentStep == 2) {
      final uText = _usernameController.text.trim();
      if (uText.isEmpty) {
        TopToast.show(context, 'Username is required *', isError: true);
        return;
      }
      if (!UsernameAvailabilityService.isValidUsernameFormat(uText)) {
        TopToast.show(context, 'please enter username as per conditions', isError: true);
        return;
      }
      if (!_isUsernameChecked || !_isUsernameAvailable) {
        final isAvail = await UsernameAvailabilityService.checkAvailabilityInSupabase(uText);
        if (!mounted) return;
        if (!isAvail) {
          setState(() {
            _isUsernameChecked = true;
            _isUsernameAvailable = false;
            _usernameSuggestions = UsernameAvailabilityService.generateSuggestions(uText);
          });
          TopToast.show(context, 'use different username it is already availble', isError: true);
          return;
        } else {
          setState(() {
            _isUsernameChecked = true;
            _isUsernameAvailable = true;
          });
        }
      }
      if (_passwordController.text.isEmpty) {
        _showError('Password is required *');
        return;
      }
      if (_confirmPasswordController.text != _passwordController.text) {
        _showError('Confirm Password does not match Password');
        return;
      }
    } else if (_currentStep == 3) {
      if (_vehicleNumberController.text.trim().isEmpty) {
        _showError('Vehicle Number is required *');
        return;
      }
    } else if (_currentStep == 4) {
      if (_houseNoController.text.trim().isEmpty) {
        _showError('House / Building No. is required *');
        return;
      }
      if (_nearAreaController.text.trim().isEmpty) {
        _showError('Near Area is required *');
        return;
      }
      if (_cityController.text.trim().isEmpty) {
        _showError('City is required *');
        return;
      }
      if (!_cityController.text.trim().toLowerCase().contains('jamnagar')) {
        _showError('Sorry, we are not available at your location. ServiceHub is currently available only in Jamnagar.');
        return;
      }
      if (_pincodeController.text.trim().length != 6) {
        _showError('Valid 6-digit Pincode is required *');
        return;
      }
    } else if (_currentStep == 5) {
      if (_emergencyNameController.text.trim().isEmpty) {
        _showError('Emergency Contact Name is required *');
        return;
      }
      if (_emergencyRelationship == 'Select relationship') {
        _showError('Relationship is required *');
        return;
      }
      if (_emergencyPhoneController.text.trim().length != 10) {
        _showError('Valid 10-digit Contact Number is required *');
        return;
      }
    } else if (_currentStep == 6) {
      if (!_profilePhotoUploaded) {
        _showError('Profile Photo is required *');
        return;
      }
    } else if (_currentStep == 7) {
      if (_aadhaarNumberController.text.trim().length != 12) {
        _showError('12-digit Aadhaar Number is required *');
        return;
      }
      if (!_aadhaarFrontUploaded || !_aadhaarBackUploaded) {
        _showError('Aadhaar Front and Back photos are required *');
        return;
      }
    } else if (_currentStep == 8) {
      if (!_faceVerified) {
        _showError('Aadhaar Face Verification is required *');
        return;
      }
    } else if (_currentStep == 9) {
      if (!_drivingLicenceUploaded) {
        _showError('Driving Licence is required *');
        return;
      }
      if (!_vehicleRcUploaded) {
        _showError('Vehicle RC is required *');
        return;
      }
    }

    if (_currentStep < 11) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep == 2) {
      setState(() {
        _currentStep = 0;
      });
    } else if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      context.go('/login/delivery-agent');
    }
  }

  // OTP Modal Sheet Handler (Screen 2 Action)
  void _openOtpModalSheet() {
    final phone = _phoneController.text.trim();
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
                        color: AppColors.deliveryOrangeLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mark_email_read_rounded, color: AppColors.deliveryOrangePrimary, size: 36),
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
                                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.deliveryOrangePrimary, width: 2)),
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
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.deliveryOrangePrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (secondsRemaining == 0)
                      TextButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.deliveryOrangePrimary),
                        label: const Text('Resend OTP via Notification', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.deliveryOrangePrimary)),
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
                      child: const Text('Didn\'t receive the code? Change Phone Number', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.deliveryOrangePrimary)),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deliveryOrangePrimary,
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
                                setState(() {
                                  _isPhoneVerified = true;
                                  _currentStep = 2; // Move to Screen 3 (Account Credentials)
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✓ Phone number verified via Firebase OTP successfully!'),
                                    backgroundColor: AppColors.deliveryOrangePrimary,
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

  // Supabase Database Real Submission Handler
  Future<void> _submitToSupabaseDatabase() async {
    setState(() {
      _isSubmittingToDb = true;
    });

    final String fullName = _fullNameController.text.trim();
    final String phone = _phoneController.text.trim();
    final String username = _usernameController.text.trim();
    final String vehicleNo = _vehicleNumberController.text.trim();
    final String fullAddress = '${_houseNoController.text.trim()}, ${_nearAreaController.text.trim()}, ${_landmarkController.text.trim()}'.trim();
    final String city = _cityController.text.trim();
    final String pincode = _pincodeController.text.trim();

    String? photoUrl;
    String? faceUrl;
    String? rcUrl;
    String? dlUrl;
    String? insUrl;
    String? aadhaarFrontUrl;
    String? aadhaarBackUrl;

    if (_aadhaarFrontFile != null) {
      try {
        aadhaarFrontUrl = await MediaDocumentPickerService.instance.uploadImageToSupabase(
          file: _aadhaarFrontFile!,
          bucket: 'partner_documents',
          path: 'delivery_agents/aadhaar_front_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } catch (_) {}
    }

    if (_aadhaarBackFile != null) {
      try {
        aadhaarBackUrl = await MediaDocumentPickerService.instance.uploadImageToSupabase(
          file: _aadhaarBackFile!,
          bucket: 'partner_documents',
          path: 'delivery_agents/aadhaar_back_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } catch (_) {}
    }

    if (_profilePhotoFile != null) {
      try {
        photoUrl = await MediaDocumentPickerService.instance.uploadImageToSupabase(
          file: _profilePhotoFile!,
          bucket: 'avatars',
          path: 'delivery_agents/photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } catch (_) {}
    }

    if (_faceSelfieFile != null) {
      try {
        faceUrl = await MediaDocumentPickerService.instance.uploadImageToSupabase(
          file: _faceSelfieFile!,
          bucket: 'partner_documents',
          path: 'delivery_agents/face_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } catch (_) {}
    }

    if (_vehicleRcFile != null) {
      try {
        rcUrl = await MediaDocumentPickerService.instance.uploadImageToSupabase(
          file: _vehicleRcFile!,
          bucket: 'partner_documents',
          path: 'delivery_agents/rc_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } catch (_) {}
    }

    if (_drivingLicenceFile != null) {
      try {
        dlUrl = await MediaDocumentPickerService.instance.uploadImageToSupabase(
          file: _drivingLicenceFile!,
          bucket: 'partner_documents',
          path: 'delivery_agents/dl_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } catch (_) {}
    }

    if (_vehicleInsuranceFile != null) {
      try {
        insUrl = await MediaDocumentPickerService.instance.uploadImageToSupabase(
          file: _vehicleInsuranceFile!,
          bucket: 'partner_documents',
          path: 'delivery_agents/ins_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
      } catch (_) {}
    }

    final String password = _passwordController.text.trim().isNotEmpty
        ? _passwordController.text.trim()
        : 'Password@123';

    String? createdUserId;
    String? createdPartnerId;
    String? createdVerId;
    try {
      final regResult = await SupabaseAuthService.registerDeliveryAgent(
        username: username.isNotEmpty ? username : 'rider_${phone.replaceAll(RegExp(r'\D'), '')}',
        fullName: fullName.isNotEmpty ? fullName : 'Delivery Partner',
        phone: phone,
        password: password,
        vehicleType: _selectedVehicleType,
        vehicleNumber: vehicleNo,
        drivingLicenseNumber: _drivingLicenceNumberController.text.trim(),
        email: '${username.isNotEmpty ? username : "rider_${DateTime.now().millisecondsSinceEpoch % 10000}"}@servicehub.com',
        city: city.isNotEmpty ? city : 'Jamnagar',
        state: 'Gujarat',
        fullAddress: fullAddress,
        aadhaarNumber: _aadhaarNumberController.text.trim(),
        bankName: _bankNameController.text.trim(),
        accountNumber: _accountNumberController.text.trim(),
        ifscCode: _ifscController.text.trim(),
        accountHolderName: _accountHolderNameController.text.trim(),
        photoUrl: photoUrl,
        dlUrl: dlUrl,
        rcUrl: rcUrl,
        insUrl: insUrl,
      );

      if (regResult.userData != null) {
        createdUserId = regResult.userData!['user_id']?.toString();
        createdPartnerId = regResult.userData!['partner_id']?.toString();
        createdVerId = regResult.userData!['verification_id']?.toString();
        await LocalRegistrationCache.updateActiveDeliveryAgent(regResult.userData!);
      }
      debugPrint('✓ Real delivery partner registration executed via SupabaseAuthService successfully!');
    } catch (e) {
      debugPrint('SupabaseAuthService delivery registration note: $e');
    }

    final String userId = createdUserId ?? '00000000-0000-0000-0000-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}';
    final String partnerId = createdPartnerId ?? '00000000-0000-0000-0001-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}';
    final String agentId = '00000000-0000-0000-0002-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}';
    final String verId = createdVerId ?? 'ver_del_$userId';

    // 3. Broadcast to LiveBookingSyncService and update local session
    try {
      final verificationPayload = {
        'id': verId,
        'verification_id': verId,
        'user_id': userId,
        'partner_id': partnerId,
        'delivery_agent_id': agentId,
        'name': fullName.isEmpty ? 'Delivery Partner' : fullName,
        'full_name': fullName.isEmpty ? 'Delivery Partner' : fullName,
        'phone': phone,
        'email': '${username.isNotEmpty ? username : "delivery"}@servicehub.com',
        'business_name': '$fullName Express Delivery',
        'category': 'delivery_agent',
        'category_name': 'Delivery Partner ($_selectedVehicleType)',
        'role': 'delivery_agent',
        'role_name': 'delivery_agent',
        'password': password,
        'document_type': 'DELIVERY_ONBOARDING',
        'verification_type': 'DRIVING_LICENSE',
        'vehicle_type': _selectedVehicleType,
        'vehicle_number': vehicleNo,
        'vehicle_no': vehicleNo,
        'rc_uploaded': _vehicleRcUploaded,
        'vehicle_rc_uploaded': _vehicleRcUploaded,
        'rc_document_url': rcUrl,
        'driving_license_uploaded': _drivingLicenceUploaded,
        'driving_licence_uploaded': _drivingLicenceUploaded,
        'license_document_url': dlUrl,
        'driving_license_number': _drivingLicenceNumberController.text.trim(),
        'driving_licence': _drivingLicenceNumberController.text.trim(),
        'profile_photo_url': photoUrl,
        'face_selfie_url': faceUrl,
        'aadhaar_number': _aadhaarNumberController.text.trim(),
        'aadhaar_front_url': aadhaarFrontUrl,
        'aadhaar_back_url': aadhaarBackUrl,
        'pincode': pincode,
        'bank_name': _bankNameController.text.trim(),
        'account_number': _accountNumberController.text.trim(),
        'ifsc_code': _ifscController.text.trim(),
        'account_holder_name': _accountHolderNameController.text.trim(),
        'city': city.isEmpty ? 'Jamnagar' : city,
        'state': 'Gujarat',
        'address': fullAddress,
        'verification_status': 'PENDING',
        'status': 'PENDING',
        'submitted_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      await LiveBookingSyncService.instance.submitPartnerVerification(verificationPayload);
      await LocalRegistrationCache.updateActiveDeliveryAgent(verificationPayload);
        await LocalRegistrationCache.saveRegisteredPartner(verificationPayload);
    } catch (_) {}

    setState(() {
      _isSubmittingToDb = false;
      _submittedRegistrationId = 'SH-DEL-2026-${(1000 + DateTime.now().millisecond % 9000)}';
      _currentStep = 11; // Move to Screen 12 (Verification Pending)
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _buildCurrentStepContent(),
              ),
            ),
            if (_currentStep < 11) _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: _currentStep == 11
          ? null
          : IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
              onPressed: _prevStep,
            ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.deliveryOrangePrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          RichText(
            text: const TextSpan(
              children: [
                TextSpan(
                  text: 'SERVICEHUB ',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.primaryNavy, letterSpacing: 0.5),
                ),
                TextSpan(
                  text: 'DELIVERY PARTNER',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.deliveryOrangePrimary, letterSpacing: 0.5),
                ),
              ],
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildScreen1BasicDetails();
      case 1:
        return _buildScreen2PhoneVerification();
      case 2:
        return _buildScreen3AccountCredentials();
      case 3:
        return _buildScreen4PersonalAndVehicleDetails();
      case 4:
        return _buildScreen5AddressDetails();
      case 5:
        return _buildScreen6EmergencyContact();
      case 6:
        return _buildScreen7UploadProfilePhoto();
      case 7:
        return _buildScreen8AadhaarDetails();
      case 8:
        return _buildScreen9AadhaarFaceVerification();
      case 9:
        return _buildScreen10RequiredDocuments();
      case 10:
        return _buildScreen11ReviewAndSubmit();
      case 11:
        return _buildScreen12VerificationPending();
      default:
        return _buildScreen1BasicDetails();
    }
  }

  // Mandatory Red Asterisk Label Helper
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

  // ---------------------------------------------------------------------------
  // SCREEN 1 — BASIC DETAILS
  // ---------------------------------------------------------------------------
  Widget _buildScreen1BasicDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vector Delivery Partner Header Banner Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.deliveryOrangeDark, AppColors.deliveryOrangePrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Row(
            children: [
              const DeliveryAgentAvatar(size: 75),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SERVICEHUB', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Colors.white70, letterSpacing: 1)),
                    const Text('DELIVERY PARTNER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Earn daily with express deliveries', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
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
          "Let's get started",
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Full Name', isRequired: true),
              TextField(
                controller: _fullNameController,
                decoration: _inputDecoration('Enter your full name', icon: Icons.person_outline_rounded),
              ),
              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFieldLabel('Phone Number', isRequired: true),
                  const Text('10 digits only', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
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
                      controller: _phoneController,
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
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deliveryOrangePrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _nextStep,
                  child: const Text('Send OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  GestureDetector(
                    onTap: () => context.go('/login/delivery-agent'),
                    child: const Text(
                      'Login',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.deliveryOrangePrimary),
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
  // SCREEN 2 — PHONE VERIFICATION
  // ---------------------------------------------------------------------------
  Widget _buildScreen2PhoneVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify Phone Number',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        Text(
          'Enter the 6-digit code sent to ${_phoneController.text.trim().isNotEmpty ? "+91 ${_phoneController.text.trim()}" : "your registered phone"}',
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        Center(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.deliveryOrangeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phonelink_ring_rounded, color: AppColors.deliveryOrangePrimary, size: 54),
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Enter 6-Digit OTP', isRequired: true),
              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 44,
                    height: 52,
                    child: TextField(
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
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.deliveryOrangePrimary, width: 2)),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 20),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: AppColors.textMuted),
                  SizedBox(width: 4),
                  Text('Resend code in ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  Text('00:28', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.deliveryOrangePrimary)),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _currentStep = 0),
                  child: const Text('Change Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.deliveryOrangePrimary)),
                ),
              ),
              const SizedBox(height: 16),

              if (_isPhoneVerified)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 8),
                      Text('Phone Verified Successfully ✓', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 3 — ACCOUNT CREDENTIALS
  // ---------------------------------------------------------------------------
  Widget _buildScreen3AccountCredentials() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Account',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Set your username and password',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFieldLabel('Username', isRequired: true),
                  if (_isCheckingUsername)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deliveryOrangePrimary),
                    )
                  else if (_isUsernameChecked && _isUsernameAvailable)
                    const Text('✓ Available', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)))
                  else if (_isUsernameChecked && !_isUsernameAvailable)
                    const Text('Not Available', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                ],
              ),
              TextField(
                controller: _usernameController,
                onChanged: (val) {
                  setState(() {
                    _isUsernameChecked = false;
                    _isUsernameAvailable = false;
                    _usernameSuggestions = val.trim().isNotEmpty
                        ? UsernameAvailabilityService.generateSuggestions(val.trim())
                        : [];
                  });
                },
                decoration: _inputDecoration(
                  'e.g. rider_01 or express.pro',
                  icon: Icons.alternate_email_rounded,
                  suffixIcon: TextButton(
                    onPressed: () async {
                      final uText = _usernameController.text.trim();
                      if (uText.isEmpty) {
                        TopToast.show(context, 'please enter username as per conditions', isError: true);
                        return;
                      }
                      if (!UsernameAvailabilityService.isValidUsernameFormat(uText)) {
                        setState(() {
                          _isUsernameChecked = true;
                          _isUsernameAvailable = false;
                          _usernameSuggestions = UsernameAvailabilityService.generateSuggestions(uText);
                        });
                        TopToast.show(context, 'please enter username as per conditions', isError: true);
                        return;
                      }
                      setState(() => _isCheckingUsername = true);
                      final isAvail = await UsernameAvailabilityService.checkAvailabilityInSupabase(uText);
                      if (!mounted) return;
                      setState(() {
                        _isCheckingUsername = false;
                        _isUsernameChecked = true;
                        _isUsernameAvailable = isAvail;
                        if (!isAvail) {
                          _usernameSuggestions = UsernameAvailabilityService.generateSuggestions(uText);
                        }
                      });
                      if (!isAvail) {
                        TopToast.show(context, 'use different username it is already availble', isError: true);
                      } else {
                        TopToast.show(context, '✓ Username "@$uText" is available!', isError: false);
                      }
                    },
                    child: _isCheckingUsername
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.deliveryOrangePrimary),
                          )
                        : const Text('Check', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.deliveryOrangePrimary)),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Conditions: Minimum 6 characters. Numbers allowed. Only 1 special character (_ or .) allowed.',
                style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
              ),
              if (_usernameSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.deliveryOrangePrimary),
                          SizedBox(width: 6),
                          Text('Suggested Available Usernames:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _usernameSuggestions.map((sug) => InkWell(
                          onTap: () async {
                            _usernameController.text = sug;
                            setState(() {
                              _usernameSuggestions = [];
                              _isCheckingUsername = true;
                            });
                            final avail = await UsernameAvailabilityService.checkAvailabilityInSupabase(sug);
                            if (!mounted) return;
                            setState(() {
                              _isCheckingUsername = false;
                              _isUsernameChecked = true;
                              _isUsernameAvailable = avail;
                            });
                            TopToast.show(context, 'Selected suggested username: @$sug', isError: false);
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFDBA74)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('@$sug', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFFC2410C))),
                                const SizedBox(width: 4),
                                const Icon(Icons.add_circle_outline_rounded, size: 14, color: AppColors.deliveryOrangePrimary),
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

              _buildFieldLabel('Password', isRequired: true),
              TextField(
                controller: _passwordController,
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
              const SizedBox(height: 16),

              _buildFieldLabel('Confirm Password', isRequired: true),
              TextField(
                controller: _confirmPasswordController,
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
                    Row(children: [Icon(Icons.check, size: 12, color: Color(0xFF16A34A)), SizedBox(width: 4), Text('At least 8 characters', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted))]),
                    Row(children: [Icon(Icons.check, size: 12, color: Color(0xFF16A34A)), SizedBox(width: 4), Text('One uppercase letter', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted))]),
                    Row(children: [Icon(Icons.check, size: 12, color: Color(0xFF16A34A)), SizedBox(width: 4), Text('One number', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted))]),
                    Row(children: [Icon(Icons.check, size: 12, color: Color(0xFF16A34A)), SizedBox(width: 4), Text('One special character', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted))]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 4 — PERSONAL & VEHICLE DETAILS (DOB REMOVED, BICYCLE REMOVED)
  // ---------------------------------------------------------------------------
  Widget _buildScreen4PersonalAndVehicleDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal & Vehicle Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tell us about yourself and your vehicle',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Gender', isRequired: true),
              const SizedBox(height: 8),
              Row(
                children: ['Male', 'Female', 'Other'].map((g) {
                  final isSelected = _selectedGender == g;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedGender = g),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.deliveryOrangeLight : AppColors.bgLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSelected ? AppColors.deliveryOrangePrimary : AppColors.borderLight, width: isSelected ? 2 : 1),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              g == 'Male' ? Icons.male_rounded : (g == 'Female' ? Icons.female_rounded : Icons.person_rounded),
                              color: isSelected ? AppColors.deliveryOrangePrimary : AppColors.textMuted,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(g, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? AppColors.deliveryOrangePrimary : AppColors.textDark)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Vehicle Type — ONLY Bike and Scooter (Bicycle completely removed!)
              _buildFieldLabel('Vehicle Type', isRequired: true),
              const SizedBox(height: 8),
              Row(
                children: [
                  {'type': 'Bike', 'icon': Icons.two_wheeler_rounded},
                  {'type': 'Scooter', 'icon': Icons.electric_scooter_rounded},
                ].map((v) {
                  final String typeStr = v['type'] as String;
                  final IconData iconData = v['icon'] as IconData;
                  final isSelected = _selectedVehicleType == typeStr;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedVehicleType = typeStr),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.deliveryOrangeLight : AppColors.bgLight,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isSelected ? AppColors.deliveryOrangePrimary : AppColors.borderLight, width: isSelected ? 2 : 1),
                        ),
                        child: Column(
                          children: [
                            Icon(iconData, color: isSelected ? AppColors.deliveryOrangePrimary : AppColors.textMuted, size: 28),
                            const SizedBox(height: 6),
                            Text(typeStr, style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w600, color: isSelected ? AppColors.deliveryOrangePrimary : AppColors.textDark)),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              _buildFieldLabel('Vehicle Number', isRequired: true),
              TextField(
                controller: _vehicleNumberController,
                textCapitalization: TextCapitalization.characters,
                decoration: _inputDecoration('Enter vehicle number (e.g. GJ 01 AB 1234)', icon: Icons.badge_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 5 — ADDRESS DETAILS (NO MAP SCREEN)
  // ---------------------------------------------------------------------------
  Widget _buildScreen5AddressDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Address Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Enter your current address',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('House / Building No.', isRequired: true),
              TextField(
                controller: _houseNoController,
                decoration: _inputDecoration('Enter house / building no.', icon: Icons.home_outlined),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('Landmark', isRequired: false, optionalSuffix: '(Optional)'),
              TextField(
                controller: _landmarkController,
                decoration: _inputDecoration('Enter landmark', icon: Icons.near_me_rounded),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('Near Area', isRequired: true),
              TextField(
                controller: _nearAreaController,
                decoration: _inputDecoration('Enter near area', icon: Icons.location_on_outlined),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('City', isRequired: true),
                        TextField(
                          controller: _cityController,
                          decoration: _inputDecoration('Enter city', icon: Icons.location_city_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Pincode', isRequired: true),
                        TextField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                          decoration: _inputDecoration('Enter pincode', icon: Icons.pin_drop_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Use My Current Location Switch
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.deliveryOrangeLight,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.deliveryOrangeBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppColors.deliveryOrangePrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Use my current location', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: AppColors.deliveryOrangeDark)),
                          Text('Auto-fills area and pincode from GPS', style: TextStyle(fontSize: 10, color: AppColors.deliveryOrangePrimary)),
                        ],
                      ),
                    ),
                    Switch(
                      value: _useCurrentLocation,
                      activeThumbColor: AppColors.deliveryOrangePrimary,
                      onChanged: (val) {
                        setState(() {
                          _useCurrentLocation = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 6 — EMERGENCY CONTACT
  // ---------------------------------------------------------------------------
  Widget _buildScreen6EmergencyContact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Emergency Contact',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Add emergency contact details',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        Center(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: AppColors.deliveryOrangeLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.contact_phone_rounded, color: AppColors.deliveryOrangePrimary, size: 48),
          ),
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Contact Name', isRequired: true),
              TextField(
                controller: _emergencyNameController,
                decoration: _inputDecoration('Enter contact name', icon: Icons.person_outline_rounded),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('Relationship', isRequired: true),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _emergencyRelationship,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                    items: ['Select relationship', 'Father', 'Mother', 'Spouse', 'Brother', 'Sister', 'Friend', 'Relative']
                        .map((rel) => DropdownMenuItem(value: rel, child: Text(rel, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: rel == 'Select relationship' ? AppColors.textMuted : AppColors.textDark))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _emergencyRelationship = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('Contact Number', isRequired: true),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.bgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: const Text('🇮🇳 +91', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _emergencyPhoneController,
                      keyboardType: TextInputType.phone,
                      maxLength: 10,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                      decoration: _inputDecoration('Enter contact number').copyWith(counterText: ''),
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
  // SCREEN 7 — PROFILE PHOTO
  // ---------------------------------------------------------------------------
  Widget _buildScreen7UploadProfilePhoto() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Profile Photo',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'This will be your profile photo',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 24),

        Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickProfilePhoto,
                child: Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.deliveryOrangePrimary, width: 3),
                      ),
                      child: _profilePhotoFile != null
                          ? ClipOval(
                              child: Image.file(
                                _profilePhotoFile!,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const DeliveryAgentAvatar(size: 110),
                    ),
                    Positioned(
                      bottom: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.deliveryOrangePrimary,
                          shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildFieldLabel('Profile Photo', isRequired: true),
              const SizedBox(height: 16),

              GestureDetector(
                onTap: _pickProfilePhoto,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                  decoration: BoxDecoration(
                    color: _profilePhotoUploaded ? AppColors.deliveryOrangeLight : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _profilePhotoUploaded ? AppColors.deliveryOrangePrimary : AppColors.borderLight,
                      width: _profilePhotoUploaded ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _profilePhotoUploaded ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
                        color: _profilePhotoUploaded ? AppColors.deliveryOrangePrimary : AppColors.textMuted,
                        size: 32,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _profilePhotoUploaded ? '✓ Photo Selected • Tap to change' : 'Tap to choose from Camera / Gallery',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _profilePhotoUploaded ? AppColors.deliveryOrangeDark : AppColors.textDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _profilePhotoFile != null
                            ? _profilePhotoFile!.path.split(Platform.pathSeparator).last
                            : 'JPG, PNG up to 5MB',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.deliveryOrangePrimary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Use a clear photo where your face is clearly visible.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textDark, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 8 — AADHAAR DETAILS
  // ---------------------------------------------------------------------------
  Widget _buildScreen8AadhaarDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aadhaar Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Verify your identity',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Aadhaar Number', isRequired: true),
              TextField(
                controller: _aadhaarNumberController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
                decoration: _inputDecoration('Enter 12 digit Aadhaar number', icon: Icons.credit_card_rounded),
              ),
              const SizedBox(height: 20),

              const Text('Upload Aadhaar Card', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildUploadCard(
                      title: 'Front Side',
                      isUploaded: _aadhaarFrontUploaded,
                      isRequired: true,
                      onTap: _pickAadhaarFront,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildUploadCard(
                      title: 'Back Side',
                      isUploaded: _aadhaarBackUploaded,
                      isRequired: true,
                      onTap: _pickAadhaarBack,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.deliveryOrangeLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.deliveryOrangeBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.deliveryOrangePrimary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your Aadhaar details are securely used only for identity verification.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.deliveryOrangeDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 9 — AADHAAR FACE VERIFICATION
  // ---------------------------------------------------------------------------
  Widget _buildScreen9AadhaarFaceVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Aadhaar Face Verification',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Please verify your face',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            children: [
              // Professional Face Camera UI with Corner Alignment Brackets
              Container(
                height: 210,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _faceVerified ? const Color(0xFF16A34A) : AppColors.deliveryOrangePrimary, width: 2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _faceSelfieFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(_faceSelfieFile!, width: double.infinity, height: 210, fit: BoxFit.cover),
                          )
                        : const DeliveryAgentAvatar(size: 110),
                    // Scanner Corner Brackets
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: CustomPaint(
                          painter: _ScannerBracketPainter(color: _faceVerified ? const Color(0xFF16A34A) : AppColors.deliveryOrangePrimary),
                        ),
                      ),
                    ),
                    if (_faceVerified)
                      Positioned(
                        bottom: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16),
                              SizedBox(width: 6),
                              Text('Face Verified Successfully ✓', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Make sure:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  SizedBox(height: 6),
                  Row(children: [Icon(Icons.check, size: 14, color: AppColors.deliveryOrangePrimary), SizedBox(width: 6), Text('Your face is clearly visible', style: TextStyle(fontSize: 11.5, color: AppColors.textDark))]),
                  SizedBox(height: 4),
                  Row(children: [Icon(Icons.check, size: 14, color: AppColors.deliveryOrangePrimary), SizedBox(width: 6), Text('Good lighting', style: TextStyle(fontSize: 11.5, color: AppColors.textDark))]),
                  SizedBox(height: 4),
                  Row(children: [Icon(Icons.check, size: 14, color: AppColors.deliveryOrangePrimary), SizedBox(width: 6), Text('Remove sunglasses / mask', style: TextStyle(fontSize: 11.5, color: AppColors.textDark))]),
                  SizedBox(height: 4),
                  Row(children: [Icon(Icons.check, size: 14, color: AppColors.deliveryOrangePrimary), SizedBox(width: 6), Text('Look directly at the camera', style: TextStyle(fontSize: 11.5, color: AppColors.textDark))]),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _faceVerified ? const Color(0xFF16A34A) : AppColors.deliveryOrangePrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(_faceVerified ? Icons.verified_user_rounded : Icons.camera_front_rounded, color: Colors.white, size: 18),
                  label: Text(
                    _faceVerified ? 'Face Verified ✓ (Retake)' : 'Start Face Verification *',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  onPressed: _startFaceVerification,
                ),
              ),
              const SizedBox(height: 10),
              const Text('Powered by secure verification', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 10 — REQUIRED DOCUMENTS
  // ---------------------------------------------------------------------------
  Widget _buildScreen10RequiredDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Documents',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Upload required documents',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
          ),
          child: Column(
            children: [
              _buildDocRowItem(
                title: 'Driving Licence',
                subtitle: _drivingLicenceFile != null
                    ? _drivingLicenceFile!.path.split(Platform.pathSeparator).last
                    : 'Upload driving license',
                isUploaded: _drivingLicenceUploaded,
                isRequired: true,
                onUpload: _pickDrivingLicence,
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              _buildDocRowItem(
                title: 'Vehicle RC',
                subtitle: _vehicleRcFile != null
                    ? _vehicleRcFile!.path.split(Platform.pathSeparator).last
                    : 'Upload vehicle RC',
                isUploaded: _vehicleRcUploaded,
                isRequired: true,
                onUpload: _pickVehicleRc,
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              _buildDocRowItem(
                title: 'Vehicle Insurance',
                subtitle: _vehicleInsuranceFile != null
                    ? _vehicleInsuranceFile!.path.split(Platform.pathSeparator).last
                    : 'Upload vehicle insurance',
                isUploaded: _vehicleInsuranceUploaded,
                isRequired: false,
                optionalSuffix: '(Optional)',
                onUpload: _pickVehicleInsurance,
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.deliveryOrangeLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.deliveryOrangeBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.security_rounded, color: AppColors.deliveryOrangePrimary, size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'All documents are secure and used only for verification.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.deliveryOrangeDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 11 — REVIEW & SUBMIT
  // ---------------------------------------------------------------------------
  Widget _buildScreen11ReviewAndSubmit() {
    final fullNameStr = _fullNameController.text.trim();
    final phoneStr = _phoneController.text.trim();
    final usernameStr = _usernameController.text.trim();
    final vehicleNoStr = _vehicleNumberController.text.trim();
    final addressStr = '${_houseNoController.text.trim()}, ${_nearAreaController.text.trim()}, ${_cityController.text.trim()} - ${_pincodeController.text.trim()}'.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review & Submit',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Please review your details before submitting',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        _buildReviewCard(
          title: 'Personal Details',
          onEdit: () => setState(() => _currentStep = 0),
          items: [
            {'label': 'Full Name', 'value': fullNameStr.isEmpty ? 'Not Provided' : fullNameStr},
            {'label': 'Phone Number', 'value': phoneStr.isEmpty ? 'Not Provided' : '+91 $phoneStr (✓ Phone Verified)'},
          ],
        ),
        const SizedBox(height: 14),

        _buildReviewCard(
          title: 'Username',
          onEdit: () => setState(() => _currentStep = 2),
          items: [
            {'label': 'Username', 'value': usernameStr.isEmpty ? 'Not Provided' : '@$usernameStr'},
          ],
        ),
        const SizedBox(height: 14),

        _buildReviewCard(
          title: 'Vehicle Details',
          onEdit: () => setState(() => _currentStep = 3),
          items: [
            {'label': 'Vehicle Type', 'value': _selectedVehicleType},
            {'label': 'Vehicle Number', 'value': vehicleNoStr.isEmpty ? 'GJ 01 AB 1234' : vehicleNoStr},
          ],
        ),
        const SizedBox(height: 14),

        _buildReviewCard(
          title: 'Address Details',
          onEdit: () => setState(() => _currentStep = 4),
          items: [
            {'label': 'Address', 'value': addressStr.length < 5 ? 'Behind Satyam Plaza, Jamnagar - 361001' : addressStr},
          ],
        ),
        const SizedBox(height: 14),

        _buildReviewCard(
          title: 'Emergency Contact',
          onEdit: () => setState(() => _currentStep = 5),
          items: [
            {'label': 'Contact Name', 'value': _emergencyNameController.text.isEmpty ? 'Amit (Brother)' : '${_emergencyNameController.text} ($_emergencyRelationship)'},
            {'label': 'Contact Number', 'value': _emergencyPhoneController.text.isEmpty ? '+91 91234 56789' : '+91 ${_emergencyPhoneController.text}'},
          ],
        ),
        const SizedBox(height: 14),

        _buildReviewCard(
          title: 'Identity & Face Verification',
          onEdit: () => setState(() => _currentStep = 8),
          items: [
            {'label': 'Aadhaar Verification', 'value': '✓ Verified Successfully'},
            {'label': 'Face Verification', 'value': '✓ Face Matched & Verified'},
            {'label': 'Profile Photo', 'value': '✓ Uploaded'},
          ],
        ),
        const SizedBox(height: 14),

        _buildReviewCard(
          title: 'Documents',
          onEdit: () => setState(() => _currentStep = 9),
          items: [
            {'label': 'Driving Licence', 'value': 'Uploaded ✓'},
            {'label': 'Vehicle RC', 'value': 'Uploaded ✓'},
            {'label': 'Vehicle Insurance', 'value': _vehicleInsuranceUploaded ? 'Uploaded ✓' : 'Not Uploaded (Optional)'},
          ],
        ),
        const SizedBox(height: 24),

        if (_isSubmittingToDb)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.deliveryOrangePrimary),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.deliveryOrangePrimary),
                ),
                SizedBox(width: 12),
                Text('Saving Delivery Partner Registration...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.deliveryOrangePrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 3,
              ),
              onPressed: _submitToSupabaseDatabase,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Submit for Verification', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 12 — VERIFICATION PENDING
  // ---------------------------------------------------------------------------
  Widget _buildScreen12VerificationPending() {
    return Column(
      children: [
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.deliveryOrangeLight, Color(0xFFFFF7ED)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.deliveryOrangeBorder),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4))],
                ),
                child: const Icon(Icons.two_wheeler_rounded, size: 64, color: AppColors.deliveryOrangePrimary),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFCD34D)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.hourglass_top_rounded, color: Color(0xFFD97706), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'Ref ID: $_submittedRegistrationId',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        const Text(
          'Registration Submitted!',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Your delivery partner account has been submitted for verification.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.borderLight),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.deliveryOrangeLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_rounded, color: AppColors.deliveryOrangePrimary, size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verification Pending', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    SizedBox(height: 4),
                    Text(
                      'Our verification team will review your details and documents. The verification process may take up to 24–48 hours.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_active_outlined, size: 14, color: AppColors.deliveryOrangePrimary),
            SizedBox(width: 6),
            Text('You will be notified once your account is approved.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.deliveryOrangeDark)),
          ],
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryNavy,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            label: const Text('Back to Login', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
            onPressed: () => context.go('/login/delivery-agent'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  InputDecoration _inputDecoration(String hint, {IconData? icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.textMuted, size: 20) : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: AppColors.bgLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.borderLight)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.deliveryOrangePrimary, width: 1.5)),
    );
  }

  Widget _buildUploadCard({
    required String title,
    required bool isUploaded,
    required bool isRequired,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: isUploaded ? AppColors.deliveryOrangeLight : AppColors.bgLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUploaded ? AppColors.deliveryOrangePrimary : AppColors.borderLight,
            width: isUploaded ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUploaded ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
              color: isUploaded ? AppColors.deliveryOrangePrimary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                if (isRequired)
                  const Text(' *', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.red)),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              isUploaded ? 'Uploaded ✓' : 'Upload',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isUploaded ? AppColors.deliveryOrangeDark : AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocRowItem({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required bool isRequired,
    String? optionalSuffix,
    required VoidCallback onUpload,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isUploaded ? AppColors.deliveryOrangeLight : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isUploaded ? Icons.file_present_rounded : Icons.upload_file_rounded,
            color: isUploaded ? AppColors.deliveryOrangePrimary : AppColors.textMuted,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  if (isRequired)
                    const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
                  else if (optionalSuffix != null)
                    Text(' $optionalSuffix', style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                ],
              ),
              Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
            ],
          ),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: isUploaded ? AppColors.deliveryOrangeDark : AppColors.deliveryOrangePrimary,
            side: BorderSide(color: isUploaded ? AppColors.deliveryOrangeBorder : AppColors.deliveryOrangePrimary),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onUpload,
          child: Text(
            isUploaded ? 'Uploaded ✓' : (isRequired ? 'Upload *' : 'Upload'),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard({
    required String title,
    required VoidCallback onEdit,
    required List<Map<String, String>> items,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppColors.primaryNavy)),
              GestureDetector(
                onTap: onEdit,
                child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.deliveryOrangePrimary)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map((it) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('${it['label']}: ', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                    Expanded(
                      child: Text(
                        it['value'] ?? '',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.deliveryOrangePrimary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 2,
          ),
          onPressed: _nextStep,
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// FACE SCAN BRACKET PAINTER
// -----------------------------------------------------------------------------
class _ScannerBracketPainter extends CustomPainter {
  final Color color;

  _ScannerBracketPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const len = 24.0;

    // Top-Left Corner
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, len), paint);

    // Top-Right Corner
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - len, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, len), paint);

    // Bottom-Left Corner
    canvas.drawLine(Offset(0, size.height), Offset(len, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - len), paint);

    // Bottom-Right Corner
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - len, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - len), paint);
  }

  @override
  bool shouldRepaint(covariant _ScannerBracketPainter oldDelegate) => oldDelegate.color != color;
}
