class ServiceAreaModel {
  final String id;
  final String city;
  final String state;
  final String country;
  final bool active;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusKm;

  ServiceAreaModel({
    required this.id,
    required this.city,
    required this.state,
    required this.country,
    required this.active,
    required this.centerLatitude,
    required this.centerLongitude,
    this.radiusKm = 30.0,
  });

  factory ServiceAreaModel.fromJson(Map<String, dynamic> json) {
    return ServiceAreaModel(
      id: json['id'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      country: json['country'] as String? ?? 'India',
      active: json['active'] as bool? ?? true,
      centerLatitude: (json['centerLatitude'] as num?)?.toDouble() ?? 0.0,
      centerLongitude: (json['centerLongitude'] as num?)?.toDouble() ?? 0.0,
      radiusKm: (json['radiusKm'] as num?)?.toDouble() ?? 30.0,
    );
  }
}
