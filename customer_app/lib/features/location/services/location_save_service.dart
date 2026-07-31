import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/location_model.dart';
import '../models/customer_location_model.dart';
import 'location_api_service.dart';

class LocationSaveService {
  final LocationApiService _apiService = LocationApiService();

  Future<CustomerLocationModel> confirmAndSaveLocation(LocationModel location, {AddressType addressType = AddressType.home}) async {
    final user = Supabase.instance.client.auth.currentUser;
    final customerId = user?.id ?? 'cust_guest_${DateTime.now().millisecondsSinceEpoch}';

    final customerLocation = CustomerLocationModel(
      id: const Uuid().v4(),
      customerId: customerId,
      latitude: location.latitude,
      longitude: location.longitude,
      address: location.address,
      area: location.area,
      city: location.city,
      state: location.state,
      country: location.country,
      postalCode: location.postalCode,
      addressType: addressType,
      createdAt: DateTime.now(),
    );

    await _apiService.saveCustomerLocation(customerLocation);
    return customerLocation;
  }
}
