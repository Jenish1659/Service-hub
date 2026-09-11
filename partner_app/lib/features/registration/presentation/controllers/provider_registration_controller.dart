import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/partner_basic_info.dart';
import '../../domain/repositories/registration_repository.dart';
import '../../../../core/services/registration_service.dart';

class ProviderRegistrationController extends ChangeNotifier {
  final RegistrationRepository repository;

  ProviderRegistrationController({required this.repository});

  final formKey = GlobalKey<FormState>();
  final fullNameController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final usernameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String countryCode = '+91';
  String? selectedState = 'Gujarat';
  String? selectedCity = 'Jamnagar';

  bool isOtpSent = false;
  bool isMobileVerified = false;
  bool isUsernameChecked = false;
  bool isUsernameAvailable = false;
  bool isCheckingUsername = false;
  String? usernameError;
  List<String> usernameSuggestions = [];
  bool agreedToTerms = true;
  bool isLoading = false;

  List<String> availableCities = [
    'Ahmedabad',
    'Surat',
    'Vadodara',
    'Rajkot',
    'Bhavnagar',
    'Jamnagar',
    'Gandhinagar',
    'Junagadh',
    'Anand',
    'Navsari',
    'Morbi',
    'Nadiad',
    'Surendranagar',
    'Bharuch',
    'Mehsana',
    'Bhuj',
    'Porbandar',
    'Palanpur',
    'Valsad',
    'Vapi',
    'Gondal',
    'Veraval',
    'Godhra',
    'Patan',
    'Dahod',
    'Botad',
    'Amreli',
    'Deesa',
    'Jetpur',
  ];

  void onMobileChanged(String val) {
    if (val.length == 10 && !isOtpSent) {
      isOtpSent = true;
      notifyListeners();
    } else if (val.length < 10 && isOtpSent) {
      isOtpSent = false;
      isMobileVerified = false;
      notifyListeners();
    }
  }

  void onMobileVerified(bool verified) {
    isMobileVerified = verified;
    _autoSaveDraft();
    notifyListeners();
  }

  /// Username condition:
  /// - Minimum 6 characters
  /// - Numbers allowed
  /// - Allowed special characters ONLY: '_' and '.'
  /// - At most 1 special character allowed (more than 1 shows error)
  bool isValidUsernameFormat(String username) {
    final clean = username.trim();
    if (clean.length < 6) return false;
    // Disallow any characters other than letters, digits, '_' and '.'
    if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(clean)) return false;
    // Count special characters
    final specialCount = RegExp(r'[_.]').allMatches(clean).length;
    if (specialCount > 1) return false;
    return true;
  }

  List<String> generateUsernameSuggestions(String base) {
    var clean = base.trim().toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (clean.isEmpty) {
      clean = effectiveFirstName.toLowerCase().replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    }
    if (clean.length < 4) {
      clean = '${clean}expert';
    }

    final candidates = <String>[
      '${clean}_01',
      '$clean.pro',
      '${clean}_99',
      '$clean.hub',
      '${clean}_hub',
    ];

    return candidates.where((s) => isValidUsernameFormat(s)).take(4).toList();
  }

  void onUsernameChanged(String val) {
    final clean = val.trim();
    isUsernameChecked = false;
    isUsernameAvailable = false;
    usernameError = null;
    if (clean.isNotEmpty) {
      usernameSuggestions = generateUsernameSuggestions(clean);
    } else {
      usernameSuggestions = [];
    }
    _autoSaveDraft();
    notifyListeners();
  }

  void selectUsernameSuggestion(String suggestion) {
    usernameController.text = suggestion;
    usernameSuggestions = [];
    checkUsernameInDatabase(suggestion);
  }

  Future<bool> checkUsernameInDatabase(String username) async {
    final clean = username.trim().toLowerCase();

    // Check conditions: length >= 6, max 1 special char (_ or .)
    if (!isValidUsernameFormat(clean)) {
      isUsernameChecked = true;
      isUsernameAvailable = false;
      usernameError = 'please enter username as per conditions';
      usernameSuggestions = generateUsernameSuggestions(clean);
      _autoSaveDraft();
      notifyListeners();
      return false;
    }

    isCheckingUsername = true;
    usernameError = null;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('users')
          .select('username')
          .ilike('username', clean)
          .limit(1);

      final isTaken = res.isNotEmpty;
      isCheckingUsername = false;
      isUsernameChecked = true;
      isUsernameAvailable = !isTaken;

      if (isTaken) {
        usernameError = 'use different username it is already availble';
        usernameSuggestions = generateUsernameSuggestions(clean);
      } else {
        usernameError = null;
        usernameSuggestions = [];
      }

      _autoSaveDraft();
      notifyListeners();
      return !isTaken;
    } catch (_) {
      isCheckingUsername = false;
      isUsernameChecked = true;
      isUsernameAvailable = true;
      usernameError = null;
      _autoSaveDraft();
      notifyListeners();
      return true;
    }
  }

  void checkUsernameAvailability(String username) {
    checkUsernameInDatabase(username);
  }

  bool handleStateSelection(String state, BuildContext context, VoidCallback onShowComingSoon) {
    if (!LocationService.isStateAllowed(state)) {
      onShowComingSoon();
      return false;
    }
    selectedState = state;
    availableCities = LocationService.getCitiesForState(state);
    selectedCity = null;
    _autoSaveDraft();
    notifyListeners();
    return true;
  }

  void selectCity(String city) {
    selectedCity = city;
    _autoSaveDraft();
    notifyListeners();
  }

  void toggleTerms(bool? val) {
    agreedToTerms = val ?? true;
    notifyListeners();
  }

  String get effectiveFirstName {
    if (firstNameController.text.trim().isNotEmpty) {
      return firstNameController.text.trim();
    }
    final parts = fullNameController.text.trim().split(' ');
    return parts.isNotEmpty ? parts.first : 'Provider';
  }

  String get effectiveLastName {
    if (lastNameController.text.trim().isNotEmpty) {
      return lastNameController.text.trim();
    }
    final parts = fullNameController.text.trim().split(' ');
    return parts.length > 1 ? parts.sublist(1).join(' ') : '';
  }

  bool get isFormValid {
    final nameValid = fullNameController.text.trim().isNotEmpty || firstNameController.text.trim().isNotEmpty;
    return nameValid &&
        phoneController.text.length == 10 &&
        isMobileVerified &&
        passwordController.text.isNotEmpty &&
        passwordController.text == confirmPasswordController.text &&
        selectedState == 'Gujarat' &&
        selectedCity != null &&
        agreedToTerms;
  }

  void _autoSaveDraft() {
    final name = fullNameController.text.trim().isNotEmpty ? fullNameController.text.trim() : '${firstNameController.text.trim()} ${lastNameController.text.trim()}'.trim();
    if (name.isNotEmpty || phoneController.text.isNotEmpty) {
      final info = PartnerBasicInfo(
        username: usernameController.text.trim().isNotEmpty ? usernameController.text.trim() : null,
        firstName: effectiveFirstName,
        lastName: effectiveLastName,
        mobileNumber: phoneController.text.trim(),
        mobileVerified: isMobileVerified,
        email: emailController.text.trim(),
        password: passwordController.text,
        state: selectedState ?? 'Gujarat',
        city: selectedCity ?? '',
        termsAccepted: agreedToTerms,
      );
      repository.saveBasicInformation(info);
    }
  }

  Future<bool> submitBasicInformation() async {
    if (!isFormValid) return false;
    isLoading = true;
    notifyListeners();

    final info = PartnerBasicInfo(
      username: usernameController.text.trim().isNotEmpty ? usernameController.text.trim() : null,
      firstName: effectiveFirstName,
      lastName: effectiveLastName,
      mobileNumber: phoneController.text.trim(),
      mobileVerified: isMobileVerified,
      email: emailController.text.trim(),
      password: passwordController.text,
      state: selectedState ?? 'Gujarat',
      city: selectedCity ?? 'Jamnagar',
      termsAccepted: agreedToTerms,
    );

    final regId = await repository.saveBasicInformation(info);
    isLoading = false;
    notifyListeners();
    return regId.isNotEmpty;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
