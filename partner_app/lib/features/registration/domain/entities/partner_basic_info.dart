class PartnerBasicInfo {
  final String? id;
  final String firstName;
  final String lastName;
  final String mobileNumber;
  final bool mobileVerified;
  final String? email;
  final String password;
  final String state;
  final String city;
  final bool termsAccepted;
  final int currentStep;
  final int progressPercentage;
  final String status;

  PartnerBasicInfo({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.mobileNumber,
    required this.mobileVerified,
    this.email,
    required this.password,
    required this.state,
    required this.city,
    required this.termsAccepted,
    this.currentStep = 1,
    this.progressPercentage = 14,
    this.status = 'Draft',
  });
}
