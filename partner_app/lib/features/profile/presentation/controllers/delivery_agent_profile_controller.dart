import 'package:flutter/material.dart';
import '../../../../core/storage/local_registration_cache.dart';

class DeliveryAgentProfileController extends ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? agentData;

  // Rider Details (Strictly Delivery Agent)
  String agentName = 'Delivery Partner';
  String phone = '+91 98765 43210';
  String email = 'rider@servicehub.com';
  String vehicleType = 'Motorcycle / Scooter';
  String vehicleRegNumber = 'GJ-10-AB-1234';
  String drivingLicenseNumber = 'DL-GJ10-20210004567';

  // Metrics
  int completedDeliveries = 126;
  double onTimeRate = 98.5;
  double totalEarnings = 12450.0;
  double rating = 4.8;
  bool isOnline = true;

  // Banking
  String bankName = 'HDFC Bank';
  String accountNumber = 'XXXX-XXXX-9901';
  String ifscCode = 'HDFC0002345';

  Future<void> loadDeliveryProfile() async {
    isLoading = true;
    notifyListeners();

    try {
      final cached = await LocalRegistrationCache.getActiveDeliveryAgent();
      if (cached != null) {
        agentData = cached;
        _populateFromMap(cached);
      }
    } catch (e) {
      debugPrint('[DeliveryAgentProfileController] Error loading profile: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _populateFromMap(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['agent_name'] ?? data['fullName'] ?? data['username'] ?? '').toString().trim();
    if (name.isNotEmpty) agentName = name;

    phone = (data['phone'] ?? data['mobile'] ?? phone).toString().trim();
    email = (data['email'] ?? email).toString().trim();

    final vType = (data['vehicle_type'] ?? data['vehicleType'] ?? '').toString().trim();
    if (vType.isNotEmpty) vehicleType = vType;

    final vReg = (data['vehicle_number'] ?? data['vehicle_reg_number'] ?? '').toString().trim();
    if (vReg.isNotEmpty) vehicleRegNumber = vReg;

    final dl = (data['driving_license'] ?? data['license_number'] ?? '').toString().trim();
    if (dl.isNotEmpty) drivingLicenseNumber = dl;

    if (data['is_online'] != null) isOnline = data['is_online'] == true;
  }

  void toggleOnline(bool val) {
    isOnline = val;
    notifyListeners();
    LocalRegistrationCache.updateActiveDeliveryAgent({'is_online': isOnline});
  }

  Future<void> logout() async {
    await LocalRegistrationCache.logoutDeliveryAgent();
  }
}
