class SearchLocationModel {
  final String name;
  final double latitude;
  final double longitude;
  final String displayAddress;

  SearchLocationModel({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.displayAddress,
  });

  factory SearchLocationModel.fromNominatimJson(Map<String, dynamic> json) {
    final String displayName = json['display_name'] as String? ?? 'Unknown Location';
    final List<String> parts = displayName.split(',');
    final String nameStr = parts.isNotEmpty ? parts.first.trim() : displayName;

    return SearchLocationModel(
      name: nameStr,
      latitude: double.parse(json['lat'].toString()),
      longitude: double.parse(json['lon'].toString()),
      displayAddress: displayName,
    );
  }
}
