import '../../domain/entities/partner_basic_info.dart';
import '../../domain/repositories/registration_repository.dart';
import '../datasource/registration_remote_datasource.dart';
import '../models/partner_basic_info_model.dart';
import '../../../../core/storage/local_registration_cache.dart';

class RegistrationRepositoryImpl implements RegistrationRepository {
  final RegistrationRemoteDataSource remoteDataSource;

  RegistrationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<bool> checkMobileExists(String mobileNumber) {
    return remoteDataSource.checkMobileExists(mobileNumber);
  }

  @override
  Future<bool> checkEmailExists(String email) {
    return remoteDataSource.checkEmailExists(email);
  }

  @override
  Future<String> saveBasicInformation(PartnerBasicInfo basicInfo) async {
    final model = PartnerBasicInfoModel(
      id: basicInfo.id,
      firstName: basicInfo.firstName,
      lastName: basicInfo.lastName,
      mobileNumber: basicInfo.mobileNumber,
      mobileVerified: basicInfo.mobileVerified,
      email: basicInfo.email,
      password: basicInfo.password,
      state: basicInfo.state,
      city: basicInfo.city,
      termsAccepted: basicInfo.termsAccepted,
      currentStep: basicInfo.currentStep,
      progressPercentage: basicInfo.progressPercentage,
      status: basicInfo.status,
    );

    // Auto save to local storage for crash/session recovery (PR-004, PR-008)
    await LocalRegistrationCache.saveDraft(model.toJson());

    return remoteDataSource.saveBasicInformation(model);
  }

  @override
  Future<PartnerBasicInfo?> loadDraftRegistration() async {
    final json = await LocalRegistrationCache.getDraft();
    if (json != null) {
      return PartnerBasicInfoModel.fromJson(json);
    }
    return null;
  }
}
