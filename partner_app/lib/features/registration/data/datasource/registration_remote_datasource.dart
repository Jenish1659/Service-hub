import 'dart:async';
import '../models/partner_basic_info_model.dart';

class RegistrationRemoteDataSource {
  final Set<String> _registeredMobiles = {'9999999999', '9876543210'};
  final Set<String> _registeredEmails = {'existing@servicehub.com'};

  Future<bool> checkMobileExists(String mobileNumber) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _registeredMobiles.contains(mobileNumber);
  }

  Future<bool> checkEmailExists(String email) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _registeredEmails.contains(email.toLowerCase().trim());
  }

  Future<String> saveBasicInformation(PartnerBasicInfoModel model) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final regId = model.id ?? 'REG_${DateTime.now().millisecondsSinceEpoch}';
    return regId;
  }
}
