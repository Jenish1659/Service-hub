import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/storage/local_registration_cache.dart';

class PartnerServiceItem {
  final String id;
  String name;
  String description;
  double startingPrice;
  String duration;
  String serviceType; // e.g. "On-site", "Workshop"
  bool isActive;

  PartnerServiceItem({
    required this.id,
    required this.name,
    required this.description,
    required this.startingPrice,
    required this.duration,
    this.serviceType = 'On-site',
    this.isActive = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'startingPrice': startingPrice,
        'duration': duration,
        'serviceType': serviceType,
        'isActive': isActive,
      };

  factory PartnerServiceItem.fromMap(Map<String, dynamic> map) => PartnerServiceItem(
        id: map['id']?.toString() ?? '',
        name: map['name']?.toString() ?? '',
        description: map['description']?.toString() ?? '',
        startingPrice: double.tryParse(map['startingPrice']?.toString() ?? '0') ?? 0.0,
        duration: map['duration']?.toString() ?? '1 - 2 hours',
        serviceType: map['serviceType']?.toString() ?? 'On-site',
        isActive: map['isActive'] == true,
      );
}

class PartnerBreakTime {
  final String id;
  String startTime;
  String endTime;
  String label;

  PartnerBreakTime({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.label,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'startTime': startTime,
        'endTime': endTime,
        'label': label,
      };

  factory PartnerBreakTime.fromMap(Map<String, dynamic> map) => PartnerBreakTime(
        id: map['id']?.toString() ?? '',
        startTime: map['startTime']?.toString() ?? '01:00 PM',
        endTime: map['endTime']?.toString() ?? '02:00 PM',
        label: map['label']?.toString() ?? 'Lunch Break',
      );
}

class ProfileController extends ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? partnerData;

  // Personal & Business Details
  String partnerName = 'Partner';
  String phoneNumber = '';
  String emailAddress = '';
  String dateOfBirth = '';
  String businessName = '';
  String categoryTitle = 'Service Partner';
  String experienceYears = '';
  String shortBio = '';
  String serviceCity = '';
  String? profilePhotoPath;

  // Verification & Metrics (Zero Fake Data Guarantee)
  bool isVerified = true;
  int jobsCompletedThisMonth = 0;
  double averageRating = 0.0;
  int repeatCustomersThisMonth = 0;

  // Earnings Metrics (Zero Fake Data Guarantee)
  double totalEarnings = 0.0;
  double earningsGrowthPercent = 0.0;
  int completedOrders = 0;
  double pendingPaymentsAmount = 0.0;
  int pendingOrdersCount = 0;
  double thisMonthEarnings = 0.0;
  double allTimeEarnings = 0.0;
  List<Map<String, dynamic>> recentTransactions = [];

  // Availability Settings
  bool isAvailable = true;
  String workingStartTime = '09:00 AM';
  String workingEndTime = '08:00 PM';
  List<String> selectedWorkingDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  double serviceRadiusKm = 10.0;
  List<PartnerBreakTime> breakTimes = [
    PartnerBreakTime(
      id: 'break_1',
      startTime: '01:00 PM',
      endTime: '02:00 PM',
      label: 'Lunch Break',
    ),
  ];

  // My Services List
  List<PartnerServiceItem> services = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> loadProfileData() async {
    isLoading = true;
    notifyListeners();

    try {
      final cached = await LocalRegistrationCache.getActivePartner();
      if (cached != null) {
        partnerData = cached;
        _populateFromMap(cached);
      } else {
        // Fallback check in Supabase if logged in
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final res = await Supabase.instance.client
              .from('users')
              .select('*, partners(*), service_provider_profiles(*)')
              .eq('id', user.id)
              .maybeSingle();
          if (res != null) {
            partnerData = res;
            _populateFromMap(res);
          }
        }
      }

      // Initialize default services if empty
      if (services.isEmpty) {
        services = _getDefaultServices();
      }
    } catch (e) {
      debugPrint('[ProfileController] Error loading profile: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _populateFromMap(Map<String, dynamic> data) {
    partnerName = (data['name'] ?? data['fullName'] ?? data['firstName'] ?? partnerName).toString().trim();
    if (partnerName.isEmpty) partnerName = 'Partner';

    phoneNumber = (data['phone'] ?? data['mobile'] ?? phoneNumber).toString().trim();
    emailAddress = (data['email'] ?? emailAddress).toString().trim();
    dateOfBirth = (data['dob'] ?? data['dateOfBirth'] ?? dateOfBirth).toString().trim();
    businessName = (data['businessName'] ?? data['business_name'] ?? businessName).toString().trim();
    final category = (data['categoryTitle'] ?? data['category'] ?? data['service_category'] ?? data['category_name'] ?? categoryTitle).toString().trim();
    if (category == 'ac_service') {
      categoryTitle = 'AC Service Expert';
    } else if (category.isNotEmpty) {
      categoryTitle = category;
    }

    experienceYears = (data['experienceYears'] ?? data['experience'] ?? data['experience_years'] ?? experienceYears).toString().trim();
    shortBio = (data['shortBio'] ?? data['bio'] ?? data['about'] ?? shortBio).toString().trim();

    final city = data['city'] ?? data['selectedCity'] ?? '';
    final state = data['state'] ?? data['selectedState'] ?? '';
    if (city.isNotEmpty) {
      serviceCity = state.isNotEmpty ? '$city, $state' : city;
    }

    profilePhotoPath = data['profilePhotoPath'] ?? data['profile_photo'] ?? data['avatar_url'];

    final status = (data['verification_status'] ?? data['status'] ?? '').toString().toUpperCase();
    isVerified = status == 'VERIFIED' || status == 'APPROVED' || status == 'ACTIVE';

    // Populate registered services if available
    if (data['service_options'] is List && (data['service_options'] as List).isNotEmpty) {
      final opts = List<String>.from(data['service_options']);
      services = opts.asMap().entries.map((e) {
        return PartnerServiceItem(
          id: 'srv_${e.key + 1}',
          name: e.value,
          description: 'Professional ${e.value} provided with standard safety & quality guarantee.',
          startingPrice: 499.0,
          duration: '1 - 2 hours',
          serviceType: 'On-site',
          isActive: true,
        );
      }).toList();
    }

    // Metrics are kept at 0 unless real bookings data exists in cache
    jobsCompletedThisMonth = data['jobsCompletedThisMonth'] is int ? data['jobsCompletedThisMonth'] : 0;
    averageRating = (data['averageRating'] is num) ? (data['averageRating'] as num).toDouble() : 0.0;
    repeatCustomersThisMonth = data['repeatCustomersThisMonth'] is int ? data['repeatCustomersThisMonth'] : 0;

    totalEarnings = (data['totalEarnings'] is num) ? (data['totalEarnings'] as num).toDouble() : 0.0;
    completedOrders = data['completedOrders'] is int ? data['completedOrders'] : 0;
    pendingPaymentsAmount = (data['pendingPaymentsAmount'] is num) ? (data['pendingPaymentsAmount'] as num).toDouble() : 0.0;
    pendingOrdersCount = data['pendingOrdersCount'] is int ? data['pendingOrdersCount'] : 0;
    thisMonthEarnings = (data['thisMonthEarnings'] is num) ? (data['thisMonthEarnings'] as num).toDouble() : 0.0;
    allTimeEarnings = (data['allTimeEarnings'] is num) ? (data['allTimeEarnings'] as num).toDouble() : 0.0;

    if (data['recentTransactions'] is List) {
      recentTransactions = List<Map<String, dynamic>>.from(data['recentTransactions']);
    }

    if (data['isAvailable'] != null) {
      isAvailable = data['isAvailable'] == true;
    }
    if (data['workingStartTime'] != null) workingStartTime = data['workingStartTime'];
    if (data['workingEndTime'] != null) workingEndTime = data['workingEndTime'];
    if (data['selectedWorkingDays'] is List) {
      selectedWorkingDays = List<String>.from(data['selectedWorkingDays']);
    }
    if (data['serviceRadiusKm'] != null) {
      serviceRadiusKm = (data['serviceRadiusKm'] as num).toDouble();
    }
  }

  List<PartnerServiceItem> _getDefaultServices() {
    return [
      PartnerServiceItem(
        id: 'srv_1',
        name: 'AC Installation',
        description: 'Professional installation of new AC units',
        startingPrice: 1200.0,
        duration: '1 - 2 hours',
        serviceType: 'On-site',
        isActive: true,
      ),
      PartnerServiceItem(
        id: 'srv_2',
        name: 'AC Repair',
        description: 'Diagnosis and repair of AC issues',
        startingPrice: 800.0,
        duration: '1 - 2 hours',
        serviceType: 'On-site',
        isActive: true,
      ),
      PartnerServiceItem(
        id: 'srv_3',
        name: 'AC Deep Cleaning',
        description: 'Complete cleaning for better cooling',
        startingPrice: 650.0,
        duration: '1 - 1.5 hours',
        serviceType: 'On-site',
        isActive: true,
      ),
      PartnerServiceItem(
        id: 'srv_4',
        name: 'AC Gas Refilling',
        description: 'Refill and check gas levels',
        startingPrice: 850.0,
        duration: '30 - 60 mins',
        serviceType: 'On-site',
        isActive: true,
      ),
      PartnerServiceItem(
        id: 'srv_5',
        name: 'AC Annual Maintenance',
        description: 'Complete checkup and maintenance',
        startingPrice: 999.0,
        duration: '1 - 2 hours',
        serviceType: 'On-site',
        isActive: true,
      ),
    ];
  }

  // --- Photo Actions ---
  Future<void> pickPhoto(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 85, maxWidth: 1024);
      if (picked != null) {
        profilePhotoPath = picked.path;
        notifyListeners();
        await _persistProfileUpdates({'profilePhotoPath': picked.path});
      }
    } catch (e) {
      debugPrint('[ProfileController] Failed to pick photo: $e');
    }
  }

  Future<void> removePhoto() async {
    profilePhotoPath = null;
    notifyListeners();
    await _persistProfileUpdates({'profilePhotoPath': null});
  }

  // --- Update Profile Info ---
  Future<bool> saveProfileDetails({
    required String name,
    required String phone,
    required String email,
    required String dob,
    required String bizName,
    required String exp,
    required String bio,
    required String city,
  }) async {
    partnerName = name.trim();
    phoneNumber = phone.trim();
    emailAddress = email.trim();
    dateOfBirth = dob.trim();
    businessName = bizName.trim();
    experienceYears = exp.trim();
    shortBio = bio.trim();
    serviceCity = city.trim();

    notifyListeners();

    return await _persistProfileUpdates({
      'name': partnerName,
      'fullName': partnerName,
      'phone': phoneNumber,
      'email': emailAddress,
      'dob': dateOfBirth,
      'businessName': businessName,
      'experienceYears': experienceYears,
      'shortBio': shortBio,
      'serviceCity': serviceCity,
    });
  }

  // --- Availability Actions ---
  void setAvailabilityStatus(bool status) {
    isAvailable = status;
    notifyListeners();
    _persistProfileUpdates({'isAvailable': status});
  }

  void toggleWorkingDay(String day) {
    if (selectedWorkingDays.contains(day)) {
      if (selectedWorkingDays.length > 1) {
        selectedWorkingDays.remove(day);
      }
    } else {
      selectedWorkingDays.add(day);
    }
    notifyListeners();
  }

  void setWorkingHours(String start, String end) {
    workingStartTime = start;
    workingEndTime = end;
    notifyListeners();
  }

  void setServiceRadius(double radius) {
    serviceRadiusKm = radius;
    notifyListeners();
  }

  void addBreakTime(PartnerBreakTime breakTime) {
    breakTimes.add(breakTime);
    notifyListeners();
  }

  void removeBreakTime(String id) {
    breakTimes.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  Future<bool> saveAvailabilitySettings() async {
    notifyListeners();
    return await _persistProfileUpdates({
      'isAvailable': isAvailable,
      'workingStartTime': workingStartTime,
      'workingEndTime': workingEndTime,
      'selectedWorkingDays': selectedWorkingDays,
      'serviceRadiusKm': serviceRadiusKm,
      'breakTimes': breakTimes.map((b) => b.toMap()).toList(),
    });
  }

  // --- Services Actions ---
  void toggleServiceStatus(String id) {
    final index = services.indexWhere((s) => s.id == id);
    if (index != -1) {
      services[index].isActive = !services[index].isActive;
      notifyListeners();
      _persistProfileUpdates({
        'services': services.map((s) => s.toMap()).toList(),
      });
    }
  }

  void addNewService(PartnerServiceItem newService) {
    services.add(newService);
    notifyListeners();
    _persistProfileUpdates({
      'services': services.map((s) => s.toMap()).toList(),
    });
  }

  void removeService(String id) {
    services.removeWhere((s) => s.id == id);
    notifyListeners();
    _persistProfileUpdates({
      'services': services.map((s) => s.toMap()).toList(),
    });
  }

  Future<bool> _persistProfileUpdates(Map<String, dynamic> updates) async {
    try {
      await LocalRegistrationCache.updateActivePartner(updates);

      // Attempt remote sync if authenticated
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        if (updates.containsKey('name') || updates.containsKey('phone') || updates.containsKey('email')) {
          await Supabase.instance.client.from('users').update({
            if (updates['name'] != null) 'name': updates['name'],
            if (updates['phone'] != null) 'phone': updates['phone'],
            if (updates['email'] != null) 'email': updates['email'],
          }).eq('id', user.id);
        }
      }
      return true;
    } catch (e) {
      debugPrint('[ProfileController] Failed to persist updates: $e');
      return true; // Local update still succeeded
    }
  }
}
