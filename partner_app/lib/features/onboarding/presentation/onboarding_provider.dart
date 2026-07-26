import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingData {
  final int currentStage;
  final String partnerType; // 'provider', 'seller', 'delivery'

  // Stage 1 & 2 Personal Details
  final String fullName;
  final String phone;
  final String email;
  final String password;
  final String confirmPassword;
  final bool isPhoneVerified;

  // Stage 3 Operational Details (5 Categories)
  final String selectedCategory;
  final int yearsExperience;
  final String shopName;
  final String vehicleType;
  final String vehicleNumber;

  // Stage 4 Documents
  final String idDocumentName;
  final bool isIdUploaded;
  final String drivingLicenceName;
  final bool isDrivingLicenceUploaded;
  final String skillCertName;
  final bool isSkillCertUploaded;

  // AI Verification Background Flag
  final bool isAiVerified;

  OnboardingData({
    this.currentStage = 1,
    this.partnerType = 'provider',
    this.fullName = 'Jenish Bheda',
    this.phone = '9876543210',
    this.email = 'jenish@servicehub.com',
    this.password = 'partner123',
    this.confirmPassword = 'partner123',
    this.isPhoneVerified = false,
    this.selectedCategory = 'AC Repair (All types of AC repair & maintenance)',
    this.yearsExperience = 3,
    this.shopName = 'ServiceHub Care Center',
    this.vehicleType = 'Motorcycle / Scooter',
    this.vehicleNumber = 'GJ-03-AB-1234',
    this.idDocumentName = 'Aadhaar_Card.pdf',
    this.isIdUploaded = false,
    this.drivingLicenceName = 'Driving_Licence.pdf',
    this.isDrivingLicenceUploaded = false,
    this.skillCertName = 'Skill_Certificate.pdf',
    this.isSkillCertUploaded = false,
    this.isAiVerified = true,
  });

  OnboardingData copyWith({
    int? currentStage,
    String? partnerType,
    String? fullName,
    String? phone,
    String? email,
    String? password,
    String? confirmPassword,
    bool? isPhoneVerified,
    String? selectedCategory,
    int? yearsExperience,
    String? shopName,
    String? vehicleType,
    String? vehicleNumber,
    String? idDocumentName,
    bool? isIdUploaded,
    String? drivingLicenceName,
    bool? isDrivingLicenceUploaded,
    String? skillCertName,
    bool? isSkillCertUploaded,
    bool? isAiVerified,
  }) {
    return OnboardingData(
      currentStage: currentStage ?? this.currentStage,
      partnerType: partnerType ?? this.partnerType,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      shopName: shopName ?? this.shopName,
      vehicleType: vehicleType ?? this.vehicleType,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      idDocumentName: idDocumentName ?? this.idDocumentName,
      isIdUploaded: isIdUploaded ?? this.isIdUploaded,
      drivingLicenceName: drivingLicenceName ?? this.drivingLicenceName,
      isDrivingLicenceUploaded: isDrivingLicenceUploaded ?? this.isDrivingLicenceUploaded,
      skillCertName: skillCertName ?? this.skillCertName,
      isSkillCertUploaded: isSkillCertUploaded ?? this.isSkillCertUploaded,
      isAiVerified: isAiVerified ?? this.isAiVerified,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingData> {
  OnboardingNotifier() : super(OnboardingData());

  void setStage(int stage) {
    state = state.copyWith(currentStage: stage);
  }

  void setPartnerType(String type) {
    state = state.copyWith(partnerType: type);
  }

  void updatePersonalInfo({
    String? fullName,
    String? phone,
    String? email,
    String? password,
    String? confirmPassword,
  }) {
    state = state.copyWith(
      fullName: fullName ?? state.fullName,
      phone: phone ?? state.phone,
      email: email ?? state.email,
      password: password ?? state.password,
      confirmPassword: confirmPassword ?? state.confirmPassword,
    );
  }

  void verifyPhone() {
    state = state.copyWith(isPhoneVerified: true);
  }

  void updateOperationalDetails({
    String? category,
    int? experience,
    String? shopName,
    String? vehicleType,
    String? vehicleNumber,
  }) {
    state = state.copyWith(
      selectedCategory: category ?? state.selectedCategory,
      yearsExperience: experience ?? state.yearsExperience,
      shopName: shopName ?? state.shopName,
      vehicleType: vehicleType ?? state.vehicleType,
      vehicleNumber: vehicleNumber ?? state.vehicleNumber,
    );
  }

  void uploadIdDoc() {
    state = state.copyWith(isIdUploaded: true);
  }

  void uploadDrivingLicence() {
    state = state.copyWith(isDrivingLicenceUploaded: true);
  }

  void uploadSkillCert() {
    state = state.copyWith(isSkillCertUploaded: true);
  }
}

final partnerOnboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingData>((ref) {
  return OnboardingNotifier();
});
