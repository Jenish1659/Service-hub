import 'package:flutter/material.dart';
import '../../domain/entities/partner_basic_info.dart';
import '../../domain/repositories/registration_repository.dart';
import '../../../../core/services/registration_service.dart';

class ProviderRegistrationController extends ChangeNotifier {
  final RegistrationRepository repository;

  ProviderRegistrationController({required this.repository});

  final formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String countryCode = '+91';
  String? selectedState;
  String? selectedCity;

  bool isOtpSent = false;
  bool isMobileVerified = false;
  bool agreedToTerms = true;
  bool isLoading = false;

  List<String> availableCities = [];

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

  bool get isFormValid {
    return firstNameController.text.trim().isNotEmpty &&
        lastNameController.text.trim().isNotEmpty &&
        phoneController.text.length == 10 &&
        isMobileVerified &&
        passwordController.text.isNotEmpty &&
        passwordController.text == confirmPasswordController.text &&
        selectedState == 'Gujarat' &&
        selectedCity != null &&
        agreedToTerms;
  }

  void _autoSaveDraft() {
    if (firstNameController.text.isNotEmpty || phoneController.text.isNotEmpty) {
      final info = PartnerBasicInfo(
        firstName: firstNameController.text.trim(),
        lastName: lastNameController.text.trim(),
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
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      mobileNumber: phoneController.text.trim(),
      mobileVerified: isMobileVerified,
      email: emailController.text.trim(),
      password: passwordController.text,
      state: selectedState!,
      city: selectedCity!,
      termsAccepted: agreedToTerms,
    );

    final regId = await repository.saveBasicInformation(info);
    isLoading = false;
    notifyListeners();
    return regId.isNotEmpty;
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    phoneController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
