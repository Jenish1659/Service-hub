import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/storage/local_registration_cache.dart';

class ShopkeeperProfileController extends ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? shopData;

  // Store & Owner Details (Strictly Shopkeeper)
  String shopName = 'ServiceHub Store';
  String ownerName = 'Store Owner';
  String phone = '';
  String alternatePhone = '';
  String whatsappNumber = '';
  String email = '';
  String category = 'AC Service Parts & Hardware';
  String description = 'We provide original and genuine AC parts, accessories, and home appliance spare components with verified quality and instant local delivery.';
  String address = 'Main Market Road';
  String city = 'Jamnagar';
  String state = 'Gujarat';
  String pincode = '361001';
  String yearsInBusiness = '0 Years';
  String gstNumber = '';
  String shopRegistrationNo = '';
  String? profilePhotoPath;

  // KYC & Verification
  bool isVerified = false;
  bool get isDocumentsVerified => isVerified || (aadhaarNumber.trim().isNotEmpty && panNumber.trim().isNotEmpty && shopRegistrationNo.trim().isNotEmpty);
  String aadhaarNumber = '';
  String panNumber = '';
  String shopLicenseNumber = '';
  String bankName = '';
  String accountHolderName = '';
  String accountNumber = '';
  String ifscCode = '';
  String accountType = '';
  String? ownerIdDocPath;
  String? shopRegistrationDocPath;
  String? gstDocPath;

  // Store Business Metrics (Strictly start at clean 0)
  int activeProductsCount = 0;
  int ordersProcessedCount = 0;
  double totalStoreRevenue = 0.0;
  double rating = 0.0;
  int reviewCount = 0;

  // Store Operational Timings & Logistics
  bool isOpen = true;
  String openTime = '09:00 AM';
  String closeTime = '08:00 PM';
  double serviceRadiusKm = 5.0;
  String currentArea = 'Rajkot';
  List<String> shopPhotos = [];
  Map<String, Map<String, dynamic>> weeklySchedule = {
    'Monday': {'open': '09:00 AM', 'close': '08:00 PM', 'isClosed': false},
    'Tuesday': {'open': '09:00 AM', 'close': '08:00 PM', 'isClosed': false},
    'Wednesday': {'open': '09:00 AM', 'close': '08:00 PM', 'isClosed': false},
    'Thursday': {'open': '09:00 AM', 'close': '08:00 PM', 'isClosed': false},
    'Friday': {'open': '09:00 AM', 'close': '08:00 PM', 'isClosed': false},
    'Saturday': {'open': '09:00 AM', 'close': '08:00 PM', 'isClosed': false},
    'Sunday': {'open': 'Closed', 'close': 'Closed', 'isClosed': true},
  };

  // Notification & App Preferences
  bool orderNotifications = true;
  bool paymentNotifications = true;
  bool inventoryAlerts = true;
  bool promotionalUpdates = false;
  bool systemNotifications = true;
  String themeMode = 'Light';
  String language = 'English';
  String currency = 'INR (₹)';
  String distanceUnit = 'Kilometres (km)';
  double cacheSizeBytes = 0.0;

  // Security & Active Sessions
  bool loginWithOtp = true;
  bool twoFactorAuth = false;
  late List<Map<String, dynamic>> activeSessions = [
    {
      'id': 'sess_current',
      'device': 'This Device',
      'location': currentArea.isNotEmpty ? currentArea : 'Active Hub',
      'is_current': true,
      'last_active': 'Active Now',
    },
  ];

  void _syncCurrentSessionLocation() {
    final idx = activeSessions.indexWhere((s) => s['id'] == 'sess_current');
    if (idx >= 0) {
      activeSessions[idx]['location'] = currentArea.isNotEmpty ? currentArea : 'Active Hub';
    }
  }

  void _calculateCacheSize() {
    try {
      if (Hive.isBoxOpen('partner_cache')) {
        final box = Hive.box('partner_cache');
        final p = box.path;
        if (p != null) {
          final file = File(p);
          if (file.existsSync()) {
            final parentDir = file.parent;
            int totalBytes = 0;
            if (parentDir.existsSync()) {
              for (final entity in parentDir.listSync()) {
                if (entity is File && entity.path.endsWith('.hive')) {
                  totalBytes += entity.lengthSync();
                }
              }
            }
            if (totalBytes > 0) {
              cacheSizeBytes = double.parse((totalBytes / (1024 * 1024)).toStringAsFixed(2));
              return;
            } else {
              cacheSizeBytes = double.parse((file.lengthSync() / (1024 * 1024)).toStringAsFixed(2));
              return;
            }
          }
        }
      }
      cacheSizeBytes = 0.0;
    } catch (_) {
      cacheSizeBytes = 0.0;
    }
  }

  Future<void> loadShopkeeperProfile() async {
    isLoading = true;
    notifyListeners();

    try {
      _calculateCacheSize();

      // 1. Read strictly from isolated shopkeeper cache
      final cached = await LocalRegistrationCache.getActiveShopkeeper();
      if (cached != null) {
        shopData = cached;
        _populateFromMap(cached);
      }

      // 2. Read products & orders metrics from local Hive storage if present
      try {
        if (Hive.isBoxOpen('partner_cache')) {
          final box = Hive.box('partner_cache');
          final products = box.get('shopkeeper_products');
          if (products is List && products.isNotEmpty) {
            activeProductsCount = products.length;
          }
          final orders = box.get('shopkeeper_orders');
          if (orders is List && orders.isNotEmpty) {
            ordersProcessedCount = orders.length;
            totalStoreRevenue = orders.fold<double>(0.0, (sum, o) {
              if (o is Map && o['amount'] is num) {
                return sum + (o['amount'] as num).toDouble();
              }
              return sum;
            });
          }
        }
      } catch (_) {}

      // Reveal local cached shop data immediately without waiting for network (< 20ms)
      isLoading = false;
      notifyListeners();

      // 3. Fetch live store data from Supabase in the background with strict 3s timeout
      final userId = cached?['user_id']?.toString() ?? Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        try {
          final client = Supabase.instance.client;
          final userRes = await client
              .from('users')
              .select('*, partners(*, shopkeeper_profiles(*)), user_addresses(*)')
              .eq('user_id', userId)
              .maybeSingle()
              .timeout(const Duration(seconds: 3));

          if (userRes != null) {
            _populateFromSupabase(userRes);

            // Fetch real reviews for rating & reviewCount
            final partners = userRes['partners'];
            Map<String, dynamic>? pMap;
            if (partners is List && partners.isNotEmpty) {
              pMap = partners.first as Map<String, dynamic>;
            } else if (partners is Map) {
              pMap = partners as Map<String, dynamic>;
            }

            if (pMap != null) {
              final partnerId = pMap['partner_id']?.toString();
              if (partnerId != null && partnerId.isNotEmpty) {
                try {
                  final reviewsRes = await client
                      .from('reviews')
                      .select('rating')
                      .eq('partner_id', partnerId)
                      .timeout(const Duration(seconds: 3));

                  if (reviewsRes.isNotEmpty) {
                    reviewCount = reviewsRes.length;
                    double totalRating = 0.0;
                    for (final r in reviewsRes) {
                      totalRating += (r['rating'] as num?)?.toDouble() ?? 0.0;
                    }
                    rating = reviewCount > 0 ? (totalRating / reviewCount) : 0.0;
                  }
                } catch (_) {}
              }
            }
            notifyListeners();
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[ShopkeeperProfileController] Error loading profile: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _populateFromMap(Map<String, dynamic> data) {
    final bName = (data['business_name'] ?? data['shop_name'] ?? data['shopName'] ?? '').toString().trim();
    if (bName.isNotEmpty) shopName = bName;

    final oName = (data['name'] ?? data['owner_name'] ?? data['fullName'] ?? data['username'] ?? '').toString().trim();
    if (oName.isNotEmpty) {
      ownerName = oName;
      accountHolderName = oName;
    }

    phone = (data['phone'] ?? data['mobile'] ?? phone).toString().trim();
    alternatePhone = (data['alternate_phone'] ?? alternatePhone).toString().trim();
    whatsappNumber = (data['whatsapp_number'] ?? data['whatsapp'] ?? phone).toString().trim();
    email = (data['email'] ?? email).toString().trim();

    final cat = (data['category'] ?? data['business_type'] ?? data['category_name'] ?? '').toString().trim();
    if (cat.isNotEmpty) category = cat;

    final desc = (data['description'] ?? data['shop_description'] ?? '').toString().trim();
    if (desc.isNotEmpty) description = desc;

    final addr = (data['business_address'] ?? data['shop_address'] ?? data['address'] ?? '').toString().trim();
    if (addr.isNotEmpty) address = addr;

    final c = (data['city'] ?? '').toString().trim();
    if (c.isNotEmpty) {
      city = c;
      currentArea = c;
      _syncCurrentSessionLocation();
    }

    final pin = (data['pincode'] ?? '').toString().trim();
    if (pin.isNotEmpty) pincode = pin;

    final gst = (data['gst_number'] ?? data['gst'] ?? '').toString().trim();
    gstNumber = (gst == '24ABCDE1234F1Z5') ? '' : gst;

    final regNo = (data['shop_registration_no'] ?? data['registration_number'] ?? '').toString().trim();
    shopRegistrationNo = (regNo == 'RJK/SHOP/2024/1587') ? '' : regNo;

    final exp = (data['years_in_business'] ?? data['yearsInBusiness'] ?? data['experience'] ?? '').toString().trim();
    if (exp.isNotEmpty) yearsInBusiness = exp.contains('Year') ? exp : '$exp Years';

    final aadhaar = (data['aadhaar_number'] ?? data['aadhaar'] ?? '').toString().trim();
    aadhaarNumber = (aadhaar == 'XXXX-XXXX-9268') ? '' : aadhaar;

    final pan = (data['pan_number'] ?? data['pan'] ?? '').toString().trim();
    panNumber = (pan == 'ABCDE1234F') ? '' : pan;

    final lic = (data['shop_license_number'] ?? data['license_number'] ?? '').toString().trim();
    shopLicenseNumber = (lic == 'GJ-JAM-SHOP-2026-8921') ? '' : lic;

    final bAcc = (data['account_number'] ?? '').toString().trim();
    accountNumber = (bAcc == '•••• •••• 4321' || bAcc == '1234567894321') ? '' : bAcc;

    final bBank = (data['bank_name'] ?? '').toString().trim();
    bankName = (accountNumber.isEmpty && bBank == 'HDFC Bank') ? '' : bBank;

    final bIfsc = (data['ifsc_code'] ?? '').toString().trim();
    ifscCode = (accountNumber.isEmpty && bIfsc == 'HDFC0001234') ? '' : bIfsc;

    final bAccType = (data['account_type'] ?? '').toString().trim();
    accountType = (accountNumber.isEmpty && bAccType == 'Savings Account') ? '' : bAccType;

    final bHolder = (data['account_holder_name'] ?? '').toString().trim();
    if (bHolder.isNotEmpty && bHolder != 'Rajesh Kumar') {
      accountHolderName = bHolder;
    } else if (accountNumber.isNotEmpty) {
      accountHolderName = ownerName;
    } else {
      accountHolderName = '';
    }

    final rawPhotos = data['shop_photos'] ?? data['photos'] ?? data['store_photos'];
    if (rawPhotos is List) {
      shopPhotos = rawPhotos
          .map((e) => e.toString())
          .where((p) => !p.contains('shop_front_default') && !p.contains('shop_inside_'))
          .toList();
    }

    ownerIdDocPath = data['owner_id_doc_path']?.toString();
    shopRegistrationDocPath = data['shop_registration_doc_path']?.toString();
    gstDocPath = data['gst_doc_path']?.toString();

    final rad = (data['service_radius_km'] ?? data['service_radius'] as num?)?.toDouble();
    if (rad != null && rad > 0) serviceRadiusKm = rad;

    final status = (data['verification_status'] ?? data['status'] ?? data['account_status'] ?? '').toString().toUpperCase();
    isVerified = status == 'VERIFIED' || status == 'APPROVED' || status == 'ACTIVE';

    if (data['is_open'] != null) isOpen = data['is_open'] == true;

    // Real Metrics from map (strictly without falling back to fake numbers)
    if (data['active_products_count'] is num) {
      activeProductsCount = (data['active_products_count'] as num).toInt();
    } else if (data['activeProductsCount'] is num) {
      activeProductsCount = (data['activeProductsCount'] as num).toInt();
    } else if (data['products_count'] is num) {
      activeProductsCount = (data['products_count'] as num).toInt();
    }

    if (data['orders_processed_count'] is num) {
      ordersProcessedCount = (data['orders_processed_count'] as num).toInt();
    } else if (data['ordersProcessedCount'] is num) {
      ordersProcessedCount = (data['ordersProcessedCount'] as num).toInt();
    } else if (data['orders_count'] is num) {
      ordersProcessedCount = (data['orders_count'] as num).toInt();
    }

    if (data['total_store_revenue'] is num) {
      totalStoreRevenue = (data['total_store_revenue'] as num).toDouble();
    } else if (data['totalStoreRevenue'] is num) {
      totalStoreRevenue = (data['totalStoreRevenue'] as num).toDouble();
    } else if (data['total_revenue'] is num) {
      totalStoreRevenue = (data['total_revenue'] as num).toDouble();
    } else if (data['revenue'] is num) {
      totalStoreRevenue = (data['revenue'] as num).toDouble();
    }

    if (data['rating'] is num) {
      rating = (data['rating'] as num).toDouble();
    } else if (data['shop_rating'] is num) {
      rating = (data['shop_rating'] as num).toDouble();
    }

    if (data['review_count'] is num) {
      reviewCount = (data['review_count'] as num).toInt();
    } else if (data['reviewCount'] is num) {
      reviewCount = (data['reviewCount'] as num).toInt();
    } else if (data['reviews_count'] is num) {
      reviewCount = (data['reviews_count'] as num).toInt();
    }
  }

  void _populateFromSupabase(Map<String, dynamic> userRes) {
    _populateFromMap(userRes);

    final partners = userRes['partners'];
    Map<String, dynamic>? pMap;
    if (partners is List && partners.isNotEmpty) {
      pMap = partners.first as Map<String, dynamic>;
    } else if (partners is Map) {
      pMap = partners as Map<String, dynamic>;
    }

    if (pMap != null) {
      if (pMap['rating'] is num) {
        rating = (pMap['rating'] as num).toDouble();
      }
      final shopProfile = pMap['shopkeeper_profiles'];
      Map<String, dynamic>? sMap;
      if (shopProfile is List && shopProfile.isNotEmpty) {
        sMap = shopProfile.first as Map<String, dynamic>;
      } else if (shopProfile is Map) {
        sMap = shopProfile as Map<String, dynamic>;
      }

      if (sMap != null) {
        final bName = (sMap['business_name'] ?? '').toString().trim();
        if (bName.isNotEmpty) shopName = bName;
        final bType = (sMap['business_type'] ?? '').toString().trim();
        if (bType.isNotEmpty) category = bType;
        final exp = sMap['business_experience']?.toString();
        if (exp != null && exp.isNotEmpty) yearsInBusiness = '$exp Years';

        if (sMap['rating'] is num) {
          rating = (sMap['rating'] as num).toDouble();
        }
        if (sMap['review_count'] is num) {
          reviewCount = (sMap['review_count'] as num).toInt();
        }
        if (sMap['active_products_count'] is num) {
          activeProductsCount = (sMap['active_products_count'] as num).toInt();
        }
        if (sMap['orders_processed_count'] is num) {
          ordersProcessedCount = (sMap['orders_processed_count'] as num).toInt();
        }
        if (sMap['total_store_revenue'] is num) {
          totalStoreRevenue = (sMap['total_store_revenue'] as num).toDouble();
        }
      }
    }

    final addresses = userRes['user_addresses'];
    if (addresses is List && addresses.isNotEmpty) {
      final addrMap = addresses.first as Map<String, dynamic>;
      final line1 = (addrMap['address_line1'] ?? '').toString().trim();
      if (line1.isNotEmpty) address = line1;
      final c = (addrMap['city'] ?? '').toString().trim();
      if (c.isNotEmpty) {
        city = c;
        currentArea = c;
        _syncCurrentSessionLocation();
      }
      final pin = (addrMap['pincode'] ?? '').toString().trim();
      if (pin.isNotEmpty) pincode = pin;
    }
  }

  Future<void> updateStoreDetails({
    required String newShopName,
    required String newOwnerName,
    required String newPhone,
    required String newEmail,
    required String newAddress,
    required String newCity,
    required String newPincode,
    required String newCategory,
    String? newDescription,
  }) async {
    shopName = newShopName;
    ownerName = newOwnerName;
    phone = newPhone;
    email = newEmail;
    address = newAddress;
    city = newCity;
    pincode = newPincode;
    category = newCategory;
    if (newDescription != null) description = newDescription;
    notifyListeners();

    // Persist to isolated shopkeeper cache
    final updates = {
      'business_name': shopName,
      'name': ownerName,
      'phone': phone,
      'email': email,
      'business_address': address,
      'city': city,
      'pincode': pincode,
      'category': category,
      'description': description,
      'role_name': 'shopkeeper',
    };
    await LocalRegistrationCache.updateActiveShopkeeper(updates);

    SupabaseAuthService.updateShopkeeperInDatabase(
      userId: shopData?['user_id']?.toString(),
      partnerId: shopData?['partner_id']?.toString(),
      shopName: shopName,
      ownerName: ownerName,
      phone: phone,
      email: email,
      address: address,
      city: city,
      pincode: pincode,
      category: category,
      description: description,
    ).catchError((_) => false);
  }

  Future<void> updateContactDetails({
    required String newPhone,
    required String newAlternatePhone,
    required String newEmail,
    required String newWhatsapp,
  }) async {
    phone = newPhone;
    alternatePhone = newAlternatePhone;
    email = newEmail;
    whatsappNumber = newWhatsapp;
    notifyListeners();

    await LocalRegistrationCache.updateActiveShopkeeper({
      'phone': phone,
      'alternate_phone': alternatePhone,
      'email': email,
      'whatsapp_number': whatsappNumber,
    });

    SupabaseAuthService.updateShopkeeperInDatabase(
      userId: shopData?['user_id']?.toString(),
      partnerId: shopData?['partner_id']?.toString(),
      phone: phone,
      alternatePhone: alternatePhone,
      email: email,
      whatsappNumber: whatsappNumber,
    ).catchError((_) => false);
  }

  Future<void> updateBankDetails({
    required String newAccountHolder,
    required String newBankName,
    required String newAccountNumber,
    required String newIfsc,
    required String newAccountType,
  }) async {
    accountHolderName = newAccountHolder;
    bankName = newBankName;
    accountNumber = newAccountNumber;
    ifscCode = newIfsc;
    accountType = newAccountType;
    notifyListeners();

    await LocalRegistrationCache.updateActiveShopkeeper({
      'account_holder_name': accountHolderName,
      'bank_name': bankName,
      'account_number': accountNumber,
      'ifsc_code': ifscCode,
      'account_type': accountType,
    });

    SupabaseAuthService.updateShopkeeperInDatabase(
      userId: shopData?['user_id']?.toString(),
      partnerId: shopData?['partner_id']?.toString(),
      accountHolderName: accountHolderName,
      bankName: bankName,
      accountNumber: accountNumber,
      ifscCode: ifscCode,
      accountType: accountType,
    ).catchError((_) => false);
  }

  Future<void> updateBusinessHours(Map<String, Map<String, dynamic>> schedule) async {
    weeklySchedule = schedule;
    notifyListeners();

    await LocalRegistrationCache.updateActiveShopkeeper({
      'weekly_schedule': weeklySchedule,
    });
  }

  Future<void> updateServiceArea({required double radiusKm, required String area}) async {
    serviceRadiusKm = radiusKm;
    currentArea = area;
    _syncCurrentSessionLocation();
    notifyListeners();

    await LocalRegistrationCache.updateActiveShopkeeper({
      'service_radius_km': serviceRadiusKm,
      'current_area': currentArea,
    });

    SupabaseAuthService.updateShopkeeperInDatabase(
      userId: shopData?['user_id']?.toString(),
      partnerId: shopData?['partner_id']?.toString(),
      serviceRadiusKm: serviceRadiusKm,
    ).catchError((_) => false);
  }

  void addShopPhoto(String photoPath) {
    shopPhotos.add(photoPath);
    notifyListeners();
    LocalRegistrationCache.updateActiveShopkeeper({'shop_photos': shopPhotos});
  }

  void setPrimaryPhoto(String photoPath) {
    if (shopPhotos.isNotEmpty) {
      shopPhotos[0] = photoPath;
    } else {
      shopPhotos.add(photoPath);
    }
    notifyListeners();
    LocalRegistrationCache.updateActiveShopkeeper({'shop_photos': shopPhotos});
  }

  void updateShopPhoto(int index, String photoPath) {
    if (index >= 0 && index < shopPhotos.length) {
      shopPhotos[index] = photoPath;
      notifyListeners();
      LocalRegistrationCache.updateActiveShopkeeper({'shop_photos': shopPhotos});
    }
  }

  void removeShopPhoto(int index) {
    if (index >= 0 && index < shopPhotos.length) {
      shopPhotos.removeAt(index);
      notifyListeners();
      LocalRegistrationCache.updateActiveShopkeeper({'shop_photos': shopPhotos});
    }
  }

  Future<void> updateDocument({
    String? aadhaar,
    String? pan,
    String? shopReg,
    String? shopLic,
    String? gst,
    String? ownerIdPath,
    String? registrationPath,
    String? gstPath,
  }) async {
    if (aadhaar != null) aadhaarNumber = aadhaar;
    if (pan != null) panNumber = pan;
    if (shopReg != null) shopRegistrationNo = shopReg;
    if (shopLic != null) shopLicenseNumber = shopLic;
    if (gst != null) gstNumber = gst;
    if (ownerIdPath != null) ownerIdDocPath = ownerIdPath;
    if (registrationPath != null) shopRegistrationDocPath = registrationPath;
    if (gstPath != null) gstDocPath = gstPath;

    if (aadhaarNumber.isNotEmpty &&
        panNumber.isNotEmpty &&
        shopRegistrationNo.isNotEmpty &&
        shopPhotos.isNotEmpty) {
      isVerified = true;
    }

    notifyListeners();

    await LocalRegistrationCache.updateActiveShopkeeper({
      'aadhaar_number': aadhaarNumber,
      'pan_number': panNumber,
      'shop_registration_no': shopRegistrationNo,
      'shop_license_number': shopLicenseNumber,
      'gst_number': gstNumber,
      'owner_id_doc_path': ownerIdDocPath,
      'shop_registration_doc_path': shopRegistrationDocPath,
      'gst_doc_path': gstDocPath,
      'verification_status': isVerified ? 'VERIFIED' : 'PENDING',
    });

    SupabaseAuthService.updateShopkeeperInDatabase(
      userId: shopData?['user_id']?.toString(),
      partnerId: shopData?['partner_id']?.toString(),
      aadhaarNumber: aadhaarNumber,
      panNumber: panNumber,
      shopRegistrationNo: shopRegistrationNo,
      shopLicenseNumber: shopLicenseNumber,
      gstNumber: gstNumber,
    ).catchError((_) => false);
  }

  void toggleStoreStatus(bool status) {
    isOpen = status;
    notifyListeners();
    LocalRegistrationCache.updateActiveShopkeeper({'is_open': isOpen});

    SupabaseAuthService.updateShopkeeperInDatabase(
      userId: shopData?['user_id']?.toString(),
      partnerId: shopData?['partner_id']?.toString(),
      isOpen: isOpen,
    ).catchError((_) => false);
  }

  void updateNotificationSettings({
    required bool orders,
    required bool payments,
    required bool inventory,
    required bool promo,
    required bool system,
  }) {
    orderNotifications = orders;
    paymentNotifications = payments;
    inventoryAlerts = inventory;
    promotionalUpdates = promo;
    systemNotifications = system;
    notifyListeners();
  }

  void updateAppPreferences({
    required String newTheme,
    required String newLanguage,
    required String newCurrency,
    required String newDistanceUnit,
  }) {
    themeMode = newTheme;
    language = newLanguage;
    currency = newCurrency;
    distanceUnit = newDistanceUnit;
    notifyListeners();
  }

  void toggleLoginWithOtp(bool value) {
    loginWithOtp = value;
    notifyListeners();
  }

  void toggleTwoFactorAuth(bool value) {
    twoFactorAuth = value;
    notifyListeners();
  }

  void clearCache() {
    cacheSizeBytes = 0.0;
    notifyListeners();
  }

  void terminateSession(String sessionId) {
    activeSessions.removeWhere((s) => s['id'] == sessionId && s['is_current'] != true);
    notifyListeners();
  }

  void terminateAllOtherSessions() {
    activeSessions.removeWhere((s) => s['is_current'] != true);
    notifyListeners();
  }

  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final uid = shopData?['user_id']?.toString();
    await SupabaseAuthService.updatePassword(
      newPassword: newPassword,
      currentPassword: currentPassword,
      userId: uid,
    );
  }

  Future<void> deleteAccount() async {
    try {
      final client = Supabase.instance.client;
      final uid = shopData?['user_id']?.toString() ?? client.auth.currentUser?.id;
      if (uid != null) {
        await client.from('users').update({'account_status': 'DELETED'}).eq('user_id', uid);
      }
    } catch (_) {}
    await LocalRegistrationCache.logoutShopkeeper();
  }

  Future<void> logout() async {
    await LocalRegistrationCache.logoutShopkeeper();
  }
}
