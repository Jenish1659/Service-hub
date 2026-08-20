import '../../domain/entities/partner_basic_info.dart';

class PartnerBasicInfoModel extends PartnerBasicInfo {
  PartnerBasicInfoModel({
    super.id,
    super.username,
    required super.firstName,
    required super.lastName,
    required super.mobileNumber,
    required super.mobileVerified,
    super.email,
    required super.password,
    required super.state,
    required super.city,
    required super.termsAccepted,
    super.currentStep,
    super.progressPercentage,
    super.status,
  });

  factory PartnerBasicInfoModel.fromJson(Map<String, dynamic> json) {
    return PartnerBasicInfoModel(
      id: json['id'] as String?,
      username: json['username'] as String?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      mobileNumber: json['mobile_number'] as String? ?? '',
      mobileVerified: json['mobile_verified'] as bool? ?? false,
      email: json['email'] as String?,
      password: json['password'] as String? ?? '',
      state: json['state'] as String? ?? 'Gujarat',
      city: json['city'] as String? ?? '',
      termsAccepted: json['terms_accepted'] as bool? ?? false,
      currentStep: json['current_step'] as int? ?? 1,
      progressPercentage: json['progress_percentage'] as int? ?? 14,
      status: json['status'] as String? ?? 'Draft',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'first_name': firstName,
      'last_name': lastName,
      'mobile_number': mobileNumber,
      'mobile_verified': mobileVerified,
      'email': email,
      'password': password,
      'state': state,
      'city': city,
      'terms_accepted': termsAccepted,
      'current_step': currentStep,
      'progress_percentage': progressPercentage,
      'status': status,
    };
  }
}
