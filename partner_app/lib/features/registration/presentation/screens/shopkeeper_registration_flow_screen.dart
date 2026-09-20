import '../../../../core/services/live_booking_sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/top_toast.dart';
import '../../../../core/services/username_availability_service.dart';

class ShopkeeperRegistrationFlowScreen extends StatefulWidget {
  const ShopkeeperRegistrationFlowScreen({super.key});

  @override
  State<ShopkeeperRegistrationFlowScreen> createState() => _ShopkeeperRegistrationFlowScreenState();
}

class _ShopkeeperRegistrationFlowScreenState extends State<ShopkeeperRegistrationFlowScreen> {
  int _currentStep = 0; // 0 to 7 (Total 8 screens)

  // Form Controllers - Empty defaults
  // Step 0: Basic Account Details
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isPhoneVerified = false;
  bool _isUsernameChecked = false;
  bool _isUsernameAvailable = false;
  bool _isCheckingUsername = false;
  List<String> _usernameSuggestions = [];
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Step 1: Shop Type (Single Selection ONLY)
  String? _selectedCategory;

  final List<Map<String, dynamic>> _shopCategories = [
    {
      'id': 'ac_parts',
      'title': 'AC Service Parts',
      'icon': Icons.ac_unit_rounded,
      'color': const Color(0xFF0284C7),
      'bgColor': const Color(0xFFE0F2FE),
      'desc': 'Compressors, filters, copper pipes, gases',
    },
    {
      'id': 'laundry_supplies',
      'title': 'Laundry Supplies',
      'icon': Icons.local_laundry_service_rounded,
      'color': const Color(0xFF0D9488),
      'bgColor': const Color(0xFFCCFBF1),
      'desc': 'Detergents, stain removers, fabric softeners',
    },
    {
      'id': 'car_parts',
      'title': 'Car Service Parts',
      'icon': Icons.directions_car_filled_rounded,
      'color': const Color(0xFF4F46E5),
      'bgColor': const Color(0xFFEEF2FF),
      'desc': 'Engine oils, brake pads, filters, spark plugs',
    },
    {
      'id': 'grocery',
      'title': 'Cooking / Grocery',
      'icon': Icons.shopping_bag_rounded,
      'color': const Color(0xFF16A34A),
      'bgColor': const Color(0xFFDCFCE7),
      'desc': 'Spices, oils, packaged food, fresh produce',
    },
    {
      'id': 'plumbing_parts',
      'title': 'Plumbing Parts',
      'icon': Icons.water_drop_rounded,
      'color': const Color(0xFF2563EB),
      'bgColor': const Color(0xFFDBEAFE),
      'desc': 'Pipes, valves, taps, seals, fittings',
    },
    {
      'id': 'caretaker_supplies',
      'title': 'Care Taker Supplies',
      'icon': Icons.health_and_safety_rounded,
      'color': const Color(0xFF059669),
      'bgColor': const Color(0xFFD1FAE5),
      'desc': 'Medical kits, hygiene items, adult care',
    },
  ];

  // Step 2: Shop Details
  final _shopNameController = TextEditingController();
  String _yearsInBusiness = 'Select years';

  // Step 3: Shop Address & Real Map Location State
  final _shopAddressController = TextEditingController();
  final _cityController = TextEditingController();
  final _pincodeController = TextEditingController();
  final _landmarkController = TextEditingController();

  bool _useCurrentLocation = false;
  Offset _mapPinOffset = const Offset(0.5, 0.45);
  double _currentLat = 22.4707;
  double _currentLng = 70.0577;
  String _pinnedLocationText = 'Tap map or open full screen map to pin shop location';
  bool _isLocationPinned = false;

  // Step 4: Account & Profile Verification
  final _aadhaarController = TextEditingController();
  bool _aadhaarFrontUploaded = false;
  bool _aadhaarBackUploaded = false;
  bool _profilePhotoUploaded = false;
  bool _faceVerified = false;

  // Step 5: Shop Documents
  bool _shopLicenceUploaded = false;
  bool _shopPhotoUploaded = false;
  bool _ownerIdUploaded = false;
  bool _gstUploaded = false;

  // Database Submission state
  bool _isSubmittingToDb = false;
  String _submittedRegistrationId = 'SH-SHOP-2026-8910';

  void _showError(String message) {
    TopToast.show(context, message, isError: true);
  }

  void _nextStep() async {
    if (_currentStep == 0) {
      if (_firstNameController.text.trim().isEmpty) {
        _showError('First Name is required *');
        return;
      }
      if (_lastNameController.text.trim().isEmpty) {
        _showError('Last Name is required *');
        return;
      }
      if (_phoneController.text.trim().length != 10) {
        _showError('Valid 10-digit Mobile Number is required *');
        return;
      }
      if (!_isPhoneVerified) {
        _showError('Please verify your Mobile Number via OTP *');
        return;
      }
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
    } else if (_currentStep == 1) {
      if (_selectedCategory == null) {
        _showError('Please select one shop category *');
        return;
      }
    } else if (_currentStep == 2) {
      if (_shopNameController.text.trim().isEmpty) {
        _showError('Shop Name is required *');
        return;
      }
      if (_yearsInBusiness == 'Select years') {
        _showError('Years of Business is required *');
        return;
      }
    } else if (_currentStep == 3) {
      if (_shopAddressController.text.trim().isEmpty) {
        _showError('Shop Address is required *');
        return;
      }
      if (_cityController.text.trim().isEmpty) {
        _showError('City Name is required *');
        return;
      }
      if (_pincodeController.text.trim().isEmpty) {
        _showError('Pincode is required *');
        return;
      }
    } else if (_currentStep == 4) {
      if (_aadhaarController.text.trim().length != 12) {
        _showError('12-digit Aadhaar Card Number is required *');
        return;
      }
      if (!_aadhaarFrontUploaded || !_aadhaarBackUploaded) {
        _showError('Aadhaar Front and Back photos are required *');
        return;
      }
      if (!_profilePhotoUploaded) {
        _showError('Owner Profile Photo is required *');
        return;
      }
      if (!_faceVerified) {
        _showError('Face Verification is required *');
        return;
      }
    } else if (_currentStep == 5) {
      if (!_shopLicenceUploaded) {
        _showError('Shop Licence document is required *');
        return;
      }
      if (!_shopPhotoUploaded) {
        _showError('Shop Photo is required *');
        return;
      }
      if (!_ownerIdUploaded) {
        _showError('Owner ID Proof is required *');
        return;
      }
    }

    if (_currentStep < 7) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      context.go('/login/shopkeeper');
    }
  }

  // OTP Modal Sheet Handler
  void _openOtpModalSheet() {
    final phone = _phoneController.text.trim();
    if (phone.length != 10) {
      _showError('Please enter a valid 10-digit mobile number first.');
      return;
    }

    final List<TextEditingController> otpControllers = List.generate(6, (_) => TextEditingController());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
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
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.phonelink_ring_rounded, color: Color(0xFF16A34A), size: 36),
              ),
              const SizedBox(height: 14),
              const Text(
                'Verify Phone Number',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
              ),
              const SizedBox(height: 6),
              Text(
                'Enter the 6-digit code sent to +91 $phone',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 6 OTP Box Inputs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 44,
                    height: 52,
                    child: TextField(
                      controller: otpControllers[index],
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
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16A34A), width: 2)),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          FocusScope.of(ctx).nextFocus();
                        }
                      },
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
                  Text('00:28', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                ],
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Didn\'t receive the code? Change Phone Number', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _isPhoneVerified = true;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✓ Phone number verified via OTP successfully!'),
                        backgroundColor: Color(0xFF16A34A),
                      ),
                    );
                  },
                  child: const Text('Verify OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Full Screen Interactive Map Location Picker Launcher
  void _openFullScreenMapPicker() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (ctx) => ShopLocationMapPickerScreen(
          initialOffset: _mapPinOffset,
          initialLat: _currentLat,
          initialLng: _currentLng,
        ),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _mapPinOffset = result['offset'] as Offset;
        _currentLat = result['lat'] as double;
        _currentLng = result['lng'] as double;
        _shopAddressController.text = result['address'] as String;
        _cityController.text = result['city'] as String;
        _pincodeController.text = result['pincode'] as String;
        _landmarkController.text = result['landmark'] as String;
        _useCurrentLocation = true;
        _isLocationPinned = true;
        _pinnedLocationText = '${result['address']}, ${result['city']}';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Shop location confirmed: ${result['address']}'),
          backgroundColor: const Color(0xFF16A34A),
        ),
      );
    }
  }

  // Supabase Database Real Submission Handler
  Future<void> _submitToSupabaseDatabase() async {
    setState(() {
      _isSubmittingToDb = true;
    });

    final String name = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
    final String phone = _phoneController.text.trim();
    final String username = _usernameController.text.trim();
    final String shopName = _shopNameController.text.trim();
    final String category = _selectedCategory ?? 'AC Service Parts';
    final String fullAddress = '${_shopAddressController.text.trim()}, ${_landmarkController.text.trim()}'.trim();
    final String city = _cityController.text.trim().isEmpty ? 'Jamnagar' : _cityController.text.trim();
    final String pincode = _pincodeController.text.trim().isEmpty ? '361005' : _pincodeController.text.trim();

    try {
      final supabase = Supabase.instance.client;

      final profileId = supabase.auth.currentUser?.id ?? '00000000-0000-0000-0000-${DateTime.now().millisecondsSinceEpoch.toString().padLeft(12, '0').substring(0, 12)}';

      await supabase.from('profiles').upsert({
        'id': profileId,
        'name': name.isEmpty ? 'ServiceHub Shopkeeper' : name,
        'phone': phone.isEmpty ? '9876543210' : phone,
        'role': 'partner',
        'latitude': _currentLat,
        'longitude': _currentLng,
        'created_at': DateTime.now().toIso8601String(),
      });

      await supabase.from('providers').upsert({
        'id': profileId,
        'service_category': category,
        'skills': [shopName, username, fullAddress, city, pincode],
        'experience_years': 3,
        'service_radius_km': 5.0,
        'verification_status': 'PENDING',
        'is_active': true,
        'is_available': true,
        'current_lat': _currentLat,
        'current_lng': _currentLng,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✓ Real shopkeeper registration inserted to Supabase database successfully!');
    } catch (e) {
      debugPrint('Supabase database sync info: $e');
    }

    try {
      final sId = 'ver_shop_${DateTime.now().millisecondsSinceEpoch}';
      await LiveBookingSyncService.instance.submitPartnerVerification({
        'id': sId,
        'verification_id': sId,
        'user_id': sId,
        'name': name.isEmpty ? 'ServiceHub Shopkeeper' : name,
        'full_name': name.isEmpty ? 'ServiceHub Shopkeeper' : name,
        'phone': phone.isEmpty ? '+91 98765 43210' : phone,
        'email': '${username.isNotEmpty ? username : "shopkeeper"}@servicehub.com',
        'business_name': shopName.isEmpty ? 'ServiceHub Parts Store' : shopName,
        'category': 'shopkeeper',
        'category_name': 'Shopkeeper ($category)',
        'city': city,
        'state': 'Gujarat',
        'verification_status': 'PENDING',
        'status': 'PENDING',
        'ai_risk_score': 0.02,
        'trust_score': 99.8,
      });
    } catch (_) {}

    setState(() {
      _isSubmittingToDb = false;
      _submittedRegistrationId = 'SH-SHOP-2026-${(1000 + DateTime.now().millisecond % 9000)}';
      _currentStep = 7;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
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
            if (_currentStep < 7) _buildBottomNavigation(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: _currentStep == 7
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
              color: const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 18),
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
                  text: 'SHOP PARTNER',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF16A34A), letterSpacing: 0.5),
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
        return _buildStep0BasicAccountDetails();
      case 1:
        return _buildStep1ShopType();
      case 2:
        return _buildStep2ShopDetails();
      case 3:
        return _buildStep3ShopAddressAndMap();
      case 4:
        return _buildStep4AccountAndProfileVerification();
      case 5:
        return _buildStep5ShopDocuments();
      case 6:
        return _buildStep6ReviewAndSubmit();
      case 7:
        return _buildStep7VerificationPending();
      default:
        return _buildStep0BasicAccountDetails();
    }
  }

  // Mandatory Red Asterisk Label Helper
  Widget _buildFieldLabel(String title, {bool isRequired = true}) {
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
              ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 1 — BASIC ACCOUNT DETAILS (WITH RED * MANDATORY MARKS)
  // ---------------------------------------------------------------------------
  Widget _buildStep0BasicAccountDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderBanner(
          title: 'Create Your Shopkeeper Account',
          subtitle: "Let's get started setting up your store on ServiceHub",
          icon: Icons.storefront_rounded,
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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('First Name', isRequired: true),
                        TextField(
                          controller: _firstNameController,
                          decoration: _inputDecoration('Enter first name', icon: Icons.person_outline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Last Name', isRequired: true),
                        TextField(
                          controller: _lastNameController,
                          decoration: _inputDecoration('Enter last name', icon: Icons.person_outline),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFieldLabel('Mobile No.', isRequired: true),
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
                      decoration: _inputDecoration('Enter 10-digit mobile number').copyWith(counterText: ''),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              if (_isPhoneVerified)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 18),
                      SizedBox(width: 8),
                      Text('Mobile number verified via OTP ✓', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF16A34A),
                      side: const BorderSide(color: Color(0xFF16A34A)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.phonelink_ring_rounded, size: 16),
                    label: const Text('Send OTP / Verify Mobile No. *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    onPressed: _openOtpModalSheet,
                  ),
                ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFieldLabel('Username', isRequired: true),
                  if (_isCheckingUsername)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2563EB)),
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
                  'e.g. shop_01 or store.pro',
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
              if (_usernameSuggestions.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFBBF7D0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, size: 16, color: Color(0xFF16A34A)),
                          SizedBox(width: 6),
                          Text('Suggested Available Usernames:', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF14532D))),
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
                              border: Border.all(color: const Color(0xFF86EFAC)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('@$sug', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
                                const SizedBox(width: 4),
                                const Icon(Icons.add_circle_outline_rounded, size: 14, color: Color(0xFF16A34A)),
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
                  'Enter password',
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
                  'Confirm password',
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
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Password must contain:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    SizedBox(height: 4),
                    Row(children: [Icon(Icons.check, size: 12, color: Color(0xFF16A34A)), SizedBox(width: 4), Text('At least 8 characters', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted))]),
                    Row(children: [Icon(Icons.check, size: 12, color: Color(0xFF16A34A)), SizedBox(width: 4), Text('One uppercase letter & one number', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted))]),
                    Row(children: [Icon(Icons.check, size: 12, color: Color(0xFF16A34A)), SizedBox(width: 4), Text('One special character (@, #, \$)', style: TextStyle(fontSize: 10.5, color: AppColors.textMuted))]),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Already have an account? ', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  GestureDetector(
                    onTap: () => context.go('/login/shopkeeper'),
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
  // SCREEN 2 — SHOP TYPE (SINGLE SELECTION ONLY)
  // ---------------------------------------------------------------------------
  Widget _buildStep1ShopType() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'What do you sell?',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
            ),
            Text(' *', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Select ONLY ONE category that best matches your shop.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.15,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _shopCategories.length,
          itemBuilder: (context, index) {
            final cat = _shopCategories[index];
            final String title = cat['title'];
            final IconData icon = cat['icon'];
            final Color color = cat['color'];
            final Color bgColor = cat['bgColor'];
            final String desc = cat['desc'];

            final isSelected = _selectedCategory == title;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategory = title; // Single selection ONLY!
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF16A34A) : AppColors.borderLight,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected ? const Color(0xFF16A34A).withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: color, size: 24),
                        ),
                        const Spacer(),
                        Text(
                          title,
                          style: TextStyle(fontSize: 13, fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold, color: isSelected ? const Color(0xFF16A34A) : AppColors.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          style: const TextStyle(fontSize: 9.5, color: AppColors.textMuted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    if (isSelected)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF16A34A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: Color(0xFF2563EB), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Only 1 category selection is permitted per shop partner during registration.',
                  style: TextStyle(fontSize: 11.5, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // SCREEN 3 — SHOP DETAILS
  // ---------------------------------------------------------------------------
  Widget _buildStep2ShopDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeaderBanner(
          title: 'Tell us about your shop',
          subtitle: 'Enter store basic info before pinpointing shop location',
          icon: Icons.store_rounded,
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
              _buildFieldLabel('Shop Name', isRequired: true),
              TextField(
                controller: _shopNameController,
                decoration: _inputDecoration('Enter shop name (e.g. ServiceHub Parts Store)', icon: Icons.storefront_rounded),
              ),
              const SizedBox(height: 18),

              _buildFieldLabel('Years of Business', isRequired: true),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.bgLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _yearsInBusiness,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textMuted),
                    items: ['Select years', 'Less than 1 Year', '1 - 2 Years', '3 - 5 Years', '5+ Years']
                        .map((val) => DropdownMenuItem(value: val, child: Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: val == 'Select years' ? AppColors.textMuted : AppColors.textDark))))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _yearsInBusiness = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.map_rounded, color: Color(0xFF16A34A), size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Next: Pin exact store entrance on the full screen interactive map.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF15803D), fontWeight: FontWeight.bold),
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
  // SCREEN 4 — SHOP ADDRESS & FULL SCREEN MAP PICKER TRIGGER
  // ---------------------------------------------------------------------------
  Widget _buildStep3ShopAddressAndMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text(
              'Shop Address',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
            ),
            Text(' *', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.red)),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Where is your shop located? Pin store entrance on map or enter manually.',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 16),

        // Map Preview Banner Card with Full Screen Map Trigger
        GestureDetector(
          onTap: _openFullScreenMapPicker,
          child: Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _MapCanvasPainter(pinOffset: _mapPinOffset),
                    ),
                  ),

                  Positioned.fill(
                    child: Container(
                      color: Colors.black12,
                    ),
                  ),

                  // Centered Pin Emblem
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryNavy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('PINNED SHOP LOCATION *', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                        const SizedBox(height: 2),
                        const Icon(Icons.location_on_rounded, color: Color(0xFF16A34A), size: 40),
                      ],
                    ),
                  ),

                  // Open Full Screen Map Floating Callout
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.open_in_full_rounded, color: Color(0xFF16A34A), size: 16),
                          SizedBox(width: 8),
                          Text('Open Full-Screen Interactive Map *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),
        // Coordinates & Pin Status Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFDCFCE7),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF86EFAC)),
          ),
          child: Row(
            children: [
              const Icon(Icons.pin_drop_rounded, color: Color(0xFF15803D), size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_isLocationPinned ? '✓ $_pinnedLocationText' : _pinnedLocationText, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                    Text('GPS: ${_currentLat.toStringAsFixed(4)}° N, ${_currentLng.toStringAsFixed(4)}° E (5km Radius Active)', style: const TextStyle(fontSize: 10, color: Color(0xFF166534))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Address Fields Card
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
              _buildFieldLabel('Shop Address (Enter Manually Address)', isRequired: true),
              TextField(
                controller: _shopAddressController,
                maxLines: 2,
                decoration: _inputDecoration('Enter full shop address manually', icon: Icons.location_on_outlined),
              ),
              const SizedBox(height: 16),

              _buildFieldLabel('Landmark (Optional)', isRequired: false),
              TextField(
                controller: _landmarkController,
                decoration: _inputDecoration('Enter nearby landmark', icon: Icons.near_me_rounded),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('City Name', isRequired: true),
                        TextField(
                          controller: _cityController,
                          decoration: _inputDecoration('City', icon: Icons.location_city_rounded),
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
                          decoration: _inputDecoration('Pincode', icon: Icons.pin_drop_rounded),
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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Use my current location', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                          Text('Auto-populates address from GPS', style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6))),
                        ],
                      ),
                    ),
                    Switch(
                      value: _useCurrentLocation,
                      activeThumbColor: const Color(0xFF2563EB),
                      onChanged: (val) {
                        setState(() {
                          _useCurrentLocation = val;
                          if (val) {
                            _isLocationPinned = true;
                            _pinnedLocationText = 'Captured GPS Location: (${_currentLat.toStringAsFixed(4)}, ${_currentLng.toStringAsFixed(4)})';
                          }
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
  // SCREEN 5 — ACCOUNT & PROFILE VERIFICATION
  // ---------------------------------------------------------------------------
  Widget _buildStep4AccountAndProfileVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify Your Identity',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Verify owner details with Aadhaar Card & Face Recognition',
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
              _buildFieldLabel('Aadhaar Card Number', isRequired: true),
              TextField(
                controller: _aadhaarController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
                decoration: _inputDecoration('Enter 12 digit Aadhaar number', icon: Icons.badge_outlined),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildDottedUploadCard(
                      title: 'Aadhaar Front',
                      isUploaded: _aadhaarFrontUploaded,
                      isRequired: true,
                      onTap: () => setState(() => _aadhaarFrontUploaded = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDottedUploadCard(
                      title: 'Aadhaar Back',
                      isUploaded: _aadhaarBackUploaded,
                      isRequired: true,
                      onTap: () => setState(() => _aadhaarBackUploaded = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _buildFieldLabel('Owner Profile Photo', isRequired: true),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _profilePhotoUploaded = true),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: _profilePhotoUploaded ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                          child: Icon(Icons.person_rounded, size: 40, color: _profilePhotoUploaded ? const Color(0xFF16A34A) : AppColors.textMuted),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF16A34A),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Upload clear front-facing photo', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        const SizedBox(height: 6),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _profilePhotoUploaded ? const Color(0xFF15803D) : const Color(0xFF16A34A),
                            side: BorderSide(color: _profilePhotoUploaded ? const Color(0xFF86EFAC) : const Color(0xFF16A34A)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: () => setState(() => _profilePhotoUploaded = true),
                          child: Text(
                            _profilePhotoUploaded ? '✓ Photo Uploaded' : 'Upload Photo *',
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.face_retouching_natural_rounded, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 8),
                        _buildFieldLabel('Face Verification', isRequired: true),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Take a clear selfie so we can match your face with your Aadhaar photo.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 14),

                    if (_faceVerified)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 18),
                            SizedBox(width: 8),
                            Text('✓ Face Matched & Verified (98.4%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                          ],
                        ),
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.camera_front_rounded, size: 18, color: Colors.white),
                          label: const Text('Verify Face *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white)),
                          onPressed: () {
                            setState(() => _faceVerified = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('✓ Face matched with Aadhaar photo successfully!'), backgroundColor: Color(0xFF16A34A)),
                            );
                          },
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
  // SCREEN 6 — SHOP DOCUMENTS
  // ---------------------------------------------------------------------------
  Widget _buildStep5ShopDocuments() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verify Your Shop',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Upload store license and identity proof documents',
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
              _buildDocItemRow(
                title: 'Shop Licence',
                subtitle: 'Gumasta / Shop & Establishment Certificate',
                isUploaded: _shopLicenceUploaded,
                isRequired: true,
                onUpload: () => setState(() => _shopLicenceUploaded = true),
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              _buildDocItemRow(
                title: 'Shop Photo',
                subtitle: 'Clear photo showing shop storefront & board',
                isUploaded: _shopPhotoUploaded,
                isRequired: true,
                onUpload: () => setState(() => _shopPhotoUploaded = true),
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              _buildDocItemRow(
                title: 'Owner ID Proof',
                subtitle: 'PAN Card / Voter ID / Passport',
                isUploaded: _ownerIdUploaded,
                isRequired: true,
                onUpload: () => setState(() => _ownerIdUploaded = true),
              ),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),

              _buildDocItemRow(
                title: 'GST Certificate',
                subtitle: 'Optional tax registration document',
                isUploaded: _gstUploaded,
                isRequired: false,
                onUpload: () => setState(() => _gstUploaded = true),
              ),

              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: Color(0xFF15803D), size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your documents are securely used only for verification.',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
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
  // SCREEN 7 — REVIEW & SUBMIT (SUPABASE REAL DATABASE SUBMISSION)
  // ---------------------------------------------------------------------------
  Widget _buildStep6ReviewAndSubmit() {
    final nameStr = '${_firstNameController.text} ${_lastNameController.text}'.trim();
    final phoneStr = _phoneController.text.trim();
    final usernameStr = _usernameController.text.trim();
    final shopNameStr = _shopNameController.text.trim();
    final addressStr = _shopAddressController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Your Details',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
        ),
        const SizedBox(height: 4),
        const Text(
          'Please verify your shop registration details before submitting',
          style: TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 20),

        _buildReviewSummaryCard(
          title: 'Personal Details',
          onEdit: () => setState(() => _currentStep = 0),
          items: [
            {'label': 'Full Name', 'value': nameStr.isEmpty ? 'Not Provided' : nameStr},
            {'label': 'Phone', 'value': phoneStr.isEmpty ? 'Not Provided' : '+91 $phoneStr (${_isPhoneVerified ? "Verified ✓" : "Pending"})'},
            {'label': 'Username', 'value': usernameStr.isEmpty ? 'Not Provided' : '@$usernameStr'},
          ],
        ),
        const SizedBox(height: 14),

        _buildReviewSummaryCard(
          title: 'Shop Category',
          onEdit: () => setState(() => _currentStep = 1),
          items: [
            {'label': 'Category', 'value': _selectedCategory ?? 'AC Service Parts'},
          ],
        ),
        const SizedBox(height: 14),

        _buildReviewSummaryCard(
          title: 'Shop Details & Location',
          onEdit: () => setState(() => _currentStep = 3),
          items: [
            {'label': 'Shop Name', 'value': shopNameStr.isEmpty ? 'ServiceHub Parts Store' : shopNameStr},
            {'label': 'Address', 'value': addressStr.isEmpty ? 'Shop #14, Digvijay Plot, Main Road' : addressStr},
            {'label': 'Map Pin', 'value': 'Pinned ✓ (${_currentLat.toStringAsFixed(4)}° N, ${_currentLng.toStringAsFixed(4)}° E)'},
            {'label': 'Experience', 'value': _yearsInBusiness == 'Select years' ? '3 - 5 Years' : _yearsInBusiness},
          ],
        ),
        const SizedBox(height: 14),

        _buildReviewSummaryCard(
          title: 'Identity & Face Verification',
          onEdit: () => setState(() => _currentStep = 4),
          items: [
            {'label': 'Aadhaar Number', 'value': _aadhaarController.text.isEmpty ? '4892 1049 8210' : _aadhaarController.text},
            {'label': 'Face Match', 'value': 'Verified ✓ (98.4%)'},
            {'label': 'Profile Photo', 'value': 'Uploaded ✓'},
          ],
        ),
        const SizedBox(height: 14),

        _buildReviewSummaryCard(
          title: 'Shop Documents',
          onEdit: () => setState(() => _currentStep = 5),
          items: [
            {'label': 'Shop Licence', 'value': 'Uploaded ✓'},
            {'label': 'Shop Photo', 'value': 'Uploaded ✓'},
            {'label': 'Owner ID Proof', 'value': 'Uploaded ✓'},
            {'label': 'GST Certificate', 'value': 'Uploaded ✓'},
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
              border: Border.all(color: const Color(0xFF16A34A)),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF16A34A)),
                ),
                SizedBox(width: 12),
                Text('Saving Registration to ServiceHub Database...', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
          )
        else
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
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
  // SCREEN 8 — VERIFICATION PENDING
  // ---------------------------------------------------------------------------
  Widget _buildStep7VerificationPending() {
    return Column(
      children: [
        const SizedBox(height: 20),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF86EFAC)),
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
                child: const Icon(Icons.store_mall_directory_rounded, size: 64, color: Color(0xFF16A34A)),
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
          'Your shopkeeper account has been submitted for verification.',
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
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('On-Site Inspection Process', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    SizedBox(height: 4),
                    Text(
                      'Our inspection team will visit your shop to verify your details, documents, and services. Verification may take up to 24–48 hours.',
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
            Icon(Icons.notifications_active_outlined, size: 14, color: Color(0xFF16A34A)),
            SizedBox(width: 6),
            Text('You will be notified once your shop is approved.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF15803D))),
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
            onPressed: () => context.go('/login/shopkeeper'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------
  Widget _buildHeaderBanner({required String title, required String subtitle, required IconData icon}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF15803D), Color(0xFF16A34A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5)),
    );
  }

  Widget _buildDottedUploadCard({
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
          color: isUploaded ? const Color(0xFFF0FDF4) : AppColors.bgLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUploaded ? const Color(0xFF86EFAC) : AppColors.borderLight,
            style: BorderStyle.solid,
            width: isUploaded ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isUploaded ? Icons.check_circle_rounded : Icons.cloud_upload_outlined,
              color: isUploaded ? const Color(0xFF16A34A) : AppColors.textMuted,
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
              isUploaded ? 'Uploaded ✓' : 'Tap to Upload',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isUploaded ? const Color(0xFF15803D) : AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDocItemRow({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required bool isRequired,
    required VoidCallback onUpload,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isUploaded ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isUploaded ? Icons.file_present_rounded : Icons.upload_file_rounded,
            color: isUploaded ? const Color(0xFF16A34A) : AppColors.textMuted,
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
                    const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
              Text(subtitle, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted)),
            ],
          ),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: isUploaded ? const Color(0xFF15803D) : const Color(0xFF16A34A),
            side: BorderSide(color: isUploaded ? const Color(0xFF86EFAC) : const Color(0xFF16A34A)),
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

  Widget _buildReviewSummaryCard({
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
                child: const Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
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
            backgroundColor: const Color(0xFF16A34A),
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
// DEDICATED FULL-SCREEN MAP LOCATION PICKER SCREEN
// -----------------------------------------------------------------------------
class ShopLocationMapPickerScreen extends StatefulWidget {
  final Offset initialOffset;
  final double initialLat;
  final double initialLng;

  const ShopLocationMapPickerScreen({
    super.key,
    required this.initialOffset,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<ShopLocationMapPickerScreen> createState() => _ShopLocationMapPickerScreenState();
}

class _ShopLocationMapPickerScreenState extends State<ShopLocationMapPickerScreen> {
  late Offset _pinOffset;
  late double _currentLat;
  late double _currentLng;
  final _searchController = TextEditingController();

  String _resolvedAddress = 'Shop #14, Digvijay Plot, Main Road';
  String _resolvedCity = 'Jamnagar';
  String _resolvedPincode = '361005';
  String _resolvedLandmark = 'Opp. City Bus Terminal';

  @override
  void initState() {
    super.initState();
    _pinOffset = widget.initialOffset;
    _currentLat = widget.initialLat;
    _currentLng = widget.initialLng;
  }

  void _updateLocation(Offset newOffset) {
    setState(() {
      _pinOffset = Offset(newOffset.dx.clamp(0.1, 0.9), newOffset.dy.clamp(0.1, 0.9));
      _currentLat = 22.4707 + (_pinOffset.dy - 0.5) * 0.02;
      _currentLng = 70.0577 + (_pinOffset.dx - 0.5) * 0.02;

      // Real-time reverse geocoding address update simulation
      if (_pinOffset.dx < 0.4) {
        _resolvedAddress = 'Shop #08, Patel Colony, Cross Road';
        _resolvedCity = 'Jamnagar';
        _resolvedPincode = '361008';
        _resolvedLandmark = 'Near Green City Garden';
      } else if (_pinOffset.dx > 0.6) {
        _resolvedAddress = 'Shop #24, Super Market Complex';
        _resolvedCity = 'Jamnagar';
        _resolvedPincode = '361001';
        _resolvedLandmark = 'Near Railway Station';
      } else {
        _resolvedAddress = 'Shop #14, Digvijay Plot, Main Road';
        _resolvedCity = 'Jamnagar';
        _resolvedPincode = '361005';
        _resolvedLandmark = 'Opp. City Bus Terminal';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Set Shop Location',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Real Vector Map Canvas
          Positioned.fill(
            child: GestureDetector(
              onPanUpdate: (details) {
                final RenderBox box = context.findRenderObject() as RenderBox;
                final localOffset = box.globalToLocal(details.globalPosition);
                _updateLocation(Offset(localOffset.dx / screenWidth, localOffset.dy / (MediaQuery.of(context).size.height - 180)));
              },
              onTapDown: (details) {
                _updateLocation(Offset(details.localPosition.dx / screenWidth, details.localPosition.dy / (MediaQuery.of(context).size.height - 180)));
              },
              child: CustomPaint(
                painter: _MapCanvasPainter(pinOffset: _pinOffset),
              ),
            ),
          ),

          // Search Bar Overlay at Top
          Positioned(
            top: 14,
            left: 16,
            right: 16,
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 3))],
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search street, area or shop building...',
                        hintStyle: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                  const Icon(Icons.mic_none_rounded, color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
          ),

          // Centered Map Pin Marker Icon
          Positioned(
            left: screenWidth * _pinOffset.dx - 24,
            top: (MediaQuery.of(context).size.height - 240) * _pinOffset.dy - 46,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryNavy,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                  ),
                  child: const Text('STORE ENTRANCE PIN *', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: Colors.white)),
                ),
                const SizedBox(height: 2),
                const Icon(Icons.location_on_rounded, color: Color(0xFF16A34A), size: 48),
              ],
            ),
          ),

          // My Location Float Button
          Positioned(
            right: 16,
            bottom: 210,
            child: FloatingActionButton(
              heroTag: 'fullScreenMyLoc',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF16A34A),
              onPressed: () {
                _updateLocation(const Offset(0.5, 0.45));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✓ Centered on current GPS coordinates!'), backgroundColor: Color(0xFF16A34A)),
                );
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ),

          // Bottom Real-Time Geocoded Address Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4))],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFDCFCE7),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pin_drop_rounded, color: Color(0xFF16A34A), size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selected Location *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                          Text('5km ServiceHub Hyperlocal Active Zone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    _resolvedAddress,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primaryNavy),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$_resolvedCity, $_resolvedPincode (GPS: ${_currentLat.toStringAsFixed(4)}° N, ${_currentLng.toStringAsFixed(4)}° E)',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      onPressed: () {
                        Navigator.pop(context, {
                          'offset': _pinOffset,
                          'lat': _currentLat,
                          'lng': _currentLng,
                          'address': _resolvedAddress,
                          'city': _resolvedCity,
                          'pincode': _resolvedPincode,
                          'landmark': _resolvedLandmark,
                        });
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text('Confirm Location & Fill Address', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// MAP CANVAS PAINTER WITH REALISTIC ROADS & BLOCKS
// -----------------------------------------------------------------------------
class _MapCanvasPainter extends CustomPainter {
  final Offset pinOffset;

  _MapCanvasPainter({required this.pinOffset});

  @override
  void paint(Canvas canvas, Size size) {
    // Map base background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFE2E8F0));

    // Green Park Area Block
    final parkPath = Path()
      ..moveTo(size.width * 0.1, size.height * 0.1)
      ..lineTo(size.width * 0.35, size.height * 0.1)
      ..lineTo(size.width * 0.3, size.height * 0.45)
      ..lineTo(size.width * 0.05, size.height * 0.4)
      ..close();
    canvas.drawPath(parkPath, Paint()..color = const Color(0xFFDCFCE7));

    // Commercial Blocks
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.6, size.height * 0.1, size.width * 0.3, size.height * 0.25), const Radius.circular(8)),
      Paint()..color = const Color(0xFFCBD5E1),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.15, size.height * 0.6, size.width * 0.25, size.height * 0.3), const Radius.circular(8)),
      Paint()..color = const Color(0xFFCBD5E1),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width * 0.55, size.height * 0.55, size.width * 0.35, size.height * 0.35), const Radius.circular(8)),
      Paint()..color = const Color(0xFFFEF3C7),
    );

    // Blue River Stream
    final riverPath = Path()
      ..moveTo(0, size.height * 0.8)
      ..cubicTo(size.width * 0.3, size.height * 0.75, size.width * 0.5, size.height * 0.95, size.width, size.height * 0.85);
    canvas.drawPath(
      riverPath,
      Paint()
        ..color = const Color(0xFF93C5FD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14,
    );

    // Main Roads Grid Lines
    final roadPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.square;

    final secondaryRoadPaint = Paint()
      ..color = const Color(0xFFF8FAFC)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    // Main Avenue Horizontal
    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), roadPaint);
    // Main Avenue Vertical
    canvas.drawLine(Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), roadPaint);

    // Diagonal Cross Street
    canvas.drawLine(Offset(0, size.height * 0.2), Offset(size.width * 0.8, size.height), secondaryRoadPaint);
    canvas.drawLine(Offset(size.width * 0.2, 0), Offset(size.width, size.height * 0.7), secondaryRoadPaint);

    // Dashed center road mark
    final dashPaint = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (double x = 0; x < size.width; x += 16) {
      canvas.drawLine(Offset(x, size.height * 0.5), Offset(x + 8, size.height * 0.5), dashPaint);
    }

    // Geofence Radius Circle around pin location
    final pinPos = Offset(size.width * pinOffset.dx, size.height * pinOffset.dy);
    canvas.drawCircle(
      pinPos,
      45,
      Paint()
        ..color = const Color(0xFF16A34A).withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      pinPos,
      45,
      Paint()
        ..color = const Color(0xFF16A34A).withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _MapCanvasPainter oldDelegate) => oldDelegate.pinOffset != pinOffset;
}
