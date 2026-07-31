class MapService {
  static const String osmTileUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
  static const String userAgentPackageName = "com.servicehub.customer";
  
  static const double defaultZoom = 15.0;
  static const double minZoom = 5.0;
  static const double maxZoom = 19.0;

  // Default fallback city (Jamnagar, Gujarat)
  static const double defaultLatitude = 22.4707;
  static const double defaultLongitude = 70.0577;
  static const String defaultCity = "Jamnagar";
}
