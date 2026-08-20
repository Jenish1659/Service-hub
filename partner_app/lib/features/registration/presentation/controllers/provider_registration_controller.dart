import 'package:flutter/material.dart';
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
  String? selectedCity;

  bool isOtpSent = false;
  bool isMobileVerified = false;
  bool isUsernameChecked = false;
  bool isUsernameAvailable = false;
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

  void checkUsernameAvailability(String username) {
    final clean = username.trim();
    if (clean.isNotEmpty) {
      isUsernameChecked = true;
      isUsernameAvailable = true;
      _autoSaveDraft();
      notifyListeners();
    }
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
