class LocationModel {
  final double latitude;
  final double longitude;
  final String address;
  final String city;
  final String area;
  final String state;
  final String country;
  final String postalCode;

  LocationModel({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.city,
    required this.area,
    this.state = '',
    this.country = 'India',
    this.postalCode = '',
  });

  LocationModel copyWith({
    double? latitude,
    double? longitude,
    String? address,
    String? city,
    String? area,
    String? state,
    String? country,
    String? postalCode,
  }) {
    return LocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      city: city ?? this.city,
      area: area ?? this.area,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'city': city,
      'area': area,
      'state': state,
      'country': country,
      'postalCode': postalCode,
    };
  }

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      area: json['area'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      postalCode: json['postalCode'] as String? ?? '',
    );
  }
}
