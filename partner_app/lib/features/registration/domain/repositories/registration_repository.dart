import '../entities/partner_basic_info.dart';

abstract class RegistrationRepository {
  Future<bool> checkMobileExists(String mobileNumber);
  Future<bool> checkEmailExists(String email);
  Future<String> saveBasicInformation(PartnerBasicInfo basicInfo);
  Future<PartnerBasicInfo?> loadDraftRegistration();
}
