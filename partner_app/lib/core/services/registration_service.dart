class LocationService {
  static const String allowedState = 'Gujarat';
  static const String allowedCity = 'Jamnagar';
  static const String outsideAreaMessage =
      'Sorry, we are not available at your location. ServiceHub is currently available only in Jamnagar.';

  static const List<String> supportedStates = [
    'Gujarat',
  ];

  static const List<String> gujaratCities = [
    'Jamnagar',
  ];

  static bool isStateAllowed(String state) {
    return state.trim().toLowerCase() == allowedState.toLowerCase();
  }

  static bool isCityAllowed(String city) {
    return city.trim().toLowerCase().contains(allowedCity.toLowerCase());
  }

  static List<String> getCitiesForState(String state) {
    if (isStateAllowed(state)) {
      return List.from(gujaratCities)..sort();
    }
    return [];
  }
}
