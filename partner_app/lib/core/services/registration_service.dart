class LocationService {
  static const String allowedState = 'Gujarat';

  static const List<String> supportedStates = [
    'Gujarat',
    'Maharashtra',
    'Rajasthan',
    'Madhya Pradesh',
    'Delhi',
    'Karnataka',
    'Tamil Nadu',
    'Punjab',
    'Haryana',
  ];

  static const List<String> gujaratCities = [
    'Ahmedabad',
    'Surat',
    'Vadodara',
    'Rajkot',
    'Bhavnagar',
    'Jamnagar',
    'Junagadh',
    'Gandhinagar',
    'Anand',
    'Nadiad',
    'Morbi',
    'Mehsana',
    'Bharuch',
    'Navsari',
    'Vapi',
    'Valsad',
    'Palanpur',
    'Patan',
    'Amreli',
    'Botad',
    'Surendranagar',
    'Godhra',
    'Dahod',
    'Veraval',
    'Dwarka',
    'Bhuj',
    'Mundra',
    'Kalol',
    'Himmatnagar',
    'Modasa',
    'Vyara',
    'Jetpur',
    'Gondal',
  ];

  static bool isStateAllowed(String state) {
    return state == allowedState;
  }

  static List<String> getCitiesForState(String state) {
    if (state == allowedState) {
      return List.from(gujaratCities)..sort();
    }
    return [];
  }
}
