enum AddressType { home, work, parents, friends, other }

class CustomerLocationModel {
  final String id;
  final String customerId;
  final double latitude;
  final double longitude;
  final String address;
  final String area;
  final String city;
  final String state;
  final String country;
  final String postalCode;
  final AddressType addressType;
  final bool isForSomeoneElse;
  final String? recipientName;
  final String? recipientPhone;
  final String? houseNumber;
  final String? landmark;
  final DateTime createdAt;

  CustomerLocationModel({
    required this.id,
    required this.customerId,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.area,
    required this.city,
    required this.state,
    required this.country,
    required this.postalCode,
    this.addressType = AddressType.home,
    this.isForSomeoneElse = false,
    this.recipientName,
    this.recipientPhone,
    this.houseNumber,
    this.landmark,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'area': area,
      'city': city,
      'state': state,
      'country': country,
      'postal_code': postalCode,
      'address_type': addressType.name,
      'is_for_someone_else': isForSomeoneElse,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'house_number': houseNumber,
      'landmark': landmark,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory CustomerLocationModel.fromJson(Map<String, dynamic> json) {
    return CustomerLocationModel(
      id: json['id'] as String? ?? '',
      customerId: json['customer_id'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String? ?? '',
      area: json['area'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      postalCode: json['postal_code'] as String? ?? '',
      addressType: AddressType.values.firstWhere(
        (e) => e.name == (json['address_type'] as String? ?? 'home'),
        orElse: () => AddressType.home,
      ),
      isForSomeoneElse: json['is_for_someone_else'] as bool? ?? false,
      recipientName: json['recipient_name'] as String?,
      recipientPhone: json['recipient_phone'] as String?,
      houseNumber: json['house_number'] as String?,
      landmark: json['landmark'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}
