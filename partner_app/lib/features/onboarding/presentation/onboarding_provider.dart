import 'package:flutter_riverpod/flutter_riverpod.dart';

class OnboardingData {
  final int currentStep;
  final String partnerType; // 'provider', 'seller', 'delivery'
  
  // Step 2 & 3: Mobile & Email
  final String mobileNumber;
  final String mobileOtp;
  final bool isMobileVerified;
  final String email;
  final String emailOtp;
  final bool isEmailVerified;
  
  // Step 4: Aadhaar OCR
  final String aadhaarFrontPath;
  final String aadhaarBackPath;
  final String aadhaarNumber;
  final String aadhaarName;
  final String aadhaarDob;
  final String aadhaarGender;
  final String aadhaarAddress;
  final bool isAadhaarVerified;
  
  // Step 5: Liveness & Face Match
  final String livenessGesture;
  final bool isLivenessCompleted;
  final String selfiePath;
  final double faceMatchScore;
  final bool isFaceVerified;
  
  // Step 6: Documents
  final String doc1Path; // Skill cert or Shop Front or Driving License
  final String doc2Path; // Company ID or Shop Interior or RC
  final String doc3Path; // Diploma or Address Proof or Insurance
  final String doc4Path; // Extra doc or PUC
  final bool isDocsUploaded;
  
  // Step 7: Vehicle
  final String vehicleNumber;
  final String vehicleModel;
  final String vehicleColour;
  final String bikeFrontPath;
  final bool isVehicleVerified;
  
  // Step 8: Professional Info
  final String selectedServiceCategory;
  final int yearsExperience;
  final String shopName;
  final double workingRadiusKm;
  final List<String> languages;
  final bool emergencyServiceAvailable;
  
  // Step 9: Bank & Penny Drop
  final String accountHolderName;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String upiId;
  final bool isPennyDropVerified;
  final String pennyDropTxnId;
  
  // Step 10: Legal & Signature
  final bool acceptedTerms;
  final bool isSignatureSigned;
  final String digitalSignatureData;
  
  // Step 11: AI Fraud Engine
  final bool isAiScanningComplete;
  final double aiRiskScore; // 0.0 - 1.0 (lower is safer)
  final String aiRiskLevel; // 'Low Risk - Verified'
  
  // Step 12: Final Submission
  final bool isSubmitted;
  final String registrationId;
  final String submissionTimestamp;

  OnboardingData({
    this.currentStep = 1,
    this.partnerType = 'provider',
    this.mobileNumber = '9876543210',
    this.mobileOtp = '',
    this.isMobileVerified = false,
    this.email = '',
    this.emailOtp = '',
    this.isEmailVerified = false,
    this.aadhaarFrontPath = '',
    this.aadhaarBackPath = '',
    this.aadhaarNumber = 'XXXX-XXXX-8912',
    this.aadhaarName = 'Jenish Bheda',
    this.aadhaarDob = '14/08/1998',
    this.aadhaarGender = 'Male',
    this.aadhaarAddress = 'Digvijay Plot, Jamnagar, Gujarat - 361005',
    this.isAadhaarVerified = false,
    this.livenessGesture = 'Smile & Blink',
    this.isLivenessCompleted = false,
    this.selfiePath = '',
    this.faceMatchScore = 98.4,
    this.isFaceVerified = false,
    this.doc1Path = '',
    this.doc2Path = '',
    this.doc3Path = '',
    this.doc4Path = '',
    this.isDocsUploaded = false,
    this.vehicleNumber = 'GJ-03-AB-1234',
    this.vehicleModel = 'Honda Activa 6G',
    this.vehicleColour = 'Pearl White',
    this.bikeFrontPath = '',
    this.isVehicleVerified = false,
    this.selectedServiceCategory = 'AC Repair & Electricals',
    this.yearsExperience = 5,
    this.shopName = 'ServiceHub Care Center',
    this.workingRadiusKm = 5.0,
    this.languages = const ['English', 'Hindi', 'Gujarati'],
    this.emergencyServiceAvailable = true,
    this.accountHolderName = 'Jenish Bheda',
    this.bankName = 'HDFC Bank Ltd',
    this.accountNumber = '50100239481234',
    this.ifscCode = 'HDFC0000240',
    this.upiId = 'jenish@upi',
    this.isPennyDropVerified = false,
    this.pennyDropTxnId = 'NPCI-P2P-9812450',
    this.acceptedTerms = false,
    this.isSignatureSigned = false,
    this.digitalSignatureData = '',
    this.isAiScanningComplete = false,
    this.aiRiskScore = 0.02,
    this.aiRiskLevel = 'Low Risk · Genuine Candidate',
    this.isSubmitted = false,
    this.registrationId = 'SH-PARTNER-2026-9812',
    this.submissionTimestamp = '',
  });

  OnboardingData copyWith({
    int? currentStep,
    String? partnerType,
    String? mobileNumber,
    String? mobileOtp,
    bool? isMobileVerified,
    String? email,
    String? emailOtp,
    bool? isEmailVerified,
    String? aadhaarFrontPath,
    String? aadhaarBackPath,
    String? aadhaarNumber,
    String? aadhaarName,
    String? aadhaarDob,
    String? aadhaarGender,
    String? aadhaarAddress,
    bool? isAadhaarVerified,
    String? livenessGesture,
    bool? isLivenessCompleted,
    String? selfiePath,
    double? faceMatchScore,
    bool? isFaceVerified,
    String? doc1Path,
    String? doc2Path,
    String? doc3Path,
    String? doc4Path,
    bool? isDocsUploaded,
    String? vehicleNumber,
    String? vehicleModel,
    String? vehicleColour,
    String? bikeFrontPath,
    bool? isVehicleVerified,
    String? selectedServiceCategory,
    int? yearsExperience,
    String? shopName,
    double? workingRadiusKm,
    List<String>? languages,
    bool? emergencyServiceAvailable,
    String? accountHolderName,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? upiId,
    bool? isPennyDropVerified,
    String? pennyDropTxnId,
    bool? acceptedTerms,
    bool? isSignatureSigned,
    String? digitalSignatureData,
    bool? isAiScanningComplete,
    double? aiRiskScore,
    String? aiRiskLevel,
    bool? isSubmitted,
    String? registrationId,
    String? submissionTimestamp,
  }) {
    return OnboardingData(
      currentStep: currentStep ?? this.currentStep,
      partnerType: partnerType ?? this.partnerType,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      mobileOtp: mobileOtp ?? this.mobileOtp,
      isMobileVerified: isMobileVerified ?? this.isMobileVerified,
      email: email ?? this.email,
      emailOtp: emailOtp ?? this.emailOtp,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      aadhaarFrontPath: aadhaarFrontPath ?? this.aadhaarFrontPath,
      aadhaarBackPath: aadhaarBackPath ?? this.aadhaarBackPath,
      aadhaarNumber: aadhaarNumber ?? this.aadhaarNumber,
      aadhaarName: aadhaarName ?? this.aadhaarName,
      aadhaarDob: aadhaarDob ?? this.aadhaarDob,
      aadhaarGender: aadhaarGender ?? this.aadhaarGender,
      aadhaarAddress: aadhaarAddress ?? this.aadhaarAddress,
      isAadhaarVerified: isAadhaarVerified ?? this.isAadhaarVerified,
      livenessGesture: livenessGesture ?? this.livenessGesture,
      isLivenessCompleted: isLivenessCompleted ?? this.isLivenessCompleted,
      selfiePath: selfiePath ?? this.selfiePath,
      faceMatchScore: faceMatchScore ?? this.faceMatchScore,
      isFaceVerified: isFaceVerified ?? this.isFaceVerified,
      doc1Path: doc1Path ?? this.doc1Path,
      doc2Path: doc2Path ?? this.doc2Path,
      doc3Path: doc3Path ?? this.doc3Path,
      doc4Path: doc4Path ?? this.doc4Path,
      isDocsUploaded: isDocsUploaded ?? this.isDocsUploaded,
      vehicleNumber: vehicleNumber ?? this.vehicleNumber,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleColour: vehicleColour ?? this.vehicleColour,
      bikeFrontPath: bikeFrontPath ?? this.bikeFrontPath,
      isVehicleVerified: isVehicleVerified ?? this.isVehicleVerified,
      selectedServiceCategory: selectedServiceCategory ?? this.selectedServiceCategory,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      shopName: shopName ?? this.shopName,
      workingRadiusKm: workingRadiusKm ?? this.workingRadiusKm,
      languages: languages ?? this.languages,
      emergencyServiceAvailable: emergencyServiceAvailable ?? this.emergencyServiceAvailable,
      accountHolderName: accountHolderName ?? this.accountHolderName,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      upiId: upiId ?? this.upiId,
      isPennyDropVerified: isPennyDropVerified ?? this.isPennyDropVerified,
      pennyDropTxnId: pennyDropTxnId ?? this.pennyDropTxnId,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      isSignatureSigned: isSignatureSigned ?? this.isSignatureSigned,
      digitalSignatureData: digitalSignatureData ?? this.digitalSignatureData,
      isAiScanningComplete: isAiScanningComplete ?? this.isAiScanningComplete,
      aiRiskScore: aiRiskScore ?? this.aiRiskScore,
      aiRiskLevel: aiRiskLevel ?? this.aiRiskLevel,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      registrationId: registrationId ?? this.registrationId,
      submissionTimestamp: submissionTimestamp ?? this.submissionTimestamp,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingData> {
  OnboardingNotifier() : super(OnboardingData());

  void setStep(int step) {
    if (step >= 1 && step <= 12) {
      state = state.copyWith(currentStep: step);
    }
  }

  void nextStep() {
    if (state.currentStep < 12) {
      state = state.copyWith(currentStep: state.currentStep + 1);
    }
  }

  void previousStep() {
    if (state.currentStep > 1) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setPartnerType(String type) {
    state = state.copyWith(partnerType: type);
  }

  void updateMobile(String mobile) {
    state = state.copyWith(mobileNumber: mobile);
  }

  void verifyMobile() {
    state = state.copyWith(isMobileVerified: true);
  }

  void updateEmail(String email) {
    state = state.copyWith(email: email);
  }

  void verifyEmail() {
    state = state.copyWith(isEmailVerified: true);
  }

  void performAadhaarOcr() {
    state = state.copyWith(
      isAadhaarVerified: true,
      aadhaarFrontPath: 'uploaded_front.jpg',
      aadhaarBackPath: 'uploaded_back.jpg',
    );
  }

  void performLivenessMatch() {
    state = state.copyWith(
      isLivenessCompleted: true,
      isFaceVerified: true,
      faceMatchScore: 98.4,
      selfiePath: 'live_selfie.jpg',
    );
  }

  void uploadDocs() {
    state = state.copyWith(
      isDocsUploaded: true,
      doc1Path: 'uploaded_doc1.pdf',
      doc2Path: 'uploaded_doc2.jpg',
    );
  }

  void verifyVehicle() {
    state = state.copyWith(isVehicleVerified: true);
  }

  void updateProfessionalInfo({
    String? selectedServiceCategory,
    int? yearsExperience,
    String? shopName,
    double? workingRadiusKm,
  }) {
    state = state.copyWith(
      selectedServiceCategory: selectedServiceCategory ?? state.selectedServiceCategory,
      yearsExperience: yearsExperience ?? state.yearsExperience,
      shopName: shopName ?? state.shopName,
      workingRadiusKm: workingRadiusKm ?? state.workingRadiusKm,
    );
  }

  void performPennyDrop() {
    state = state.copyWith(
      isPennyDropVerified: true,
      pennyDropTxnId: 'NPCI-P2P-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
    );
  }

  void setTermsAndSignature(bool accepted, String signature) {
    state = state.copyWith(
      acceptedTerms: accepted,
      isSignatureSigned: signature.isNotEmpty,
      digitalSignatureData: signature,
    );
  }

  void runAiScan() {
    state = state.copyWith(
      isAiScanningComplete: true,
      aiRiskScore: 0.02,
      aiRiskLevel: 'Low Risk · Verified Authentic Candidate',
    );
  }

  void submitRegistration() {
    final now = DateTime.now().toIso8601String();
    state = state.copyWith(
      isSubmitted: true,
      submissionTimestamp: now,
      currentStep: 12,
    );
  }
}

final partnerOnboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingData>((ref) {
  return OnboardingNotifier();
});
