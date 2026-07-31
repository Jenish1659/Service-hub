class LocationUpdateModel {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double speed;

  LocationUpdateModel({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.speed,
  });
}
