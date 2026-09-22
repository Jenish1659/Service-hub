import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/storage/local_registration_cache.dart';

class ShopkeeperProfileController extends ChangeNotifier {
  bool isLoading = false;
  Map<String, dynamic>? shopData;

  // Store & Owner Details (Strictly Shopkeeper)
  String shopName = 'ServiceHub Store';
  String ownerName = 'Store Owner';
  String phone = '';
  String email = '';
  String category = 'AC Service Parts & Hardware';
  String address = 'Main Market Road';
  String city = 'Jamnagar';
  String state = 'Gujarat';
  String pincode = '361001';
  String yearsInBusiness = '3 Years';
  String? profilePhotoPath;

  // KYC & Verification
  bool isVerified = true;
  String aadhaarNumber = 'XXXX-XXXX-9268';
  String panNumber = 'ABCDE1234F';
  String shopLicenseNumber = 'GJ-JAM-SHOP-2026-8921';
  String bankName = 'State Bank of India';
  String accountNumber = 'XXXX-XXXX-7721';
  String ifscCode = 'SBIN0001234';

  // Store Business Metrics
  int activeProductsCount = 24;
  int ordersProcessedCount = 48;
  double totalStoreRevenue = 34500.0;
  double rating = 4.9;

  // Store Operational Timings
  bool isOpen = true;
  String openTime = '09:00 AM';
  String closeTime = '09:00 PM';
  List<String> workingDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

  // Notification & Settings
  bool orderSoundEnabled = true;
  bool pushNotificationsEnabled = true;
  bool autoAcceptOrders = false;

  Future<void> loadShopkeeperProfile() async {
    isLoading = true;
    notifyListeners();

    try {
      // 1. Read strictly from isolated shopkeeper cache
      final cached = await LocalRegistrationCache.getActiveShopkeeper();
      if (cached != null) {
        shopData = cached;
        _populateFromMap(cached);
      }

      // 2. Fetch live store data from Supabase if online
      final userId = cached?['user_id']?.toString() ?? Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        try {
          final client = Supabase.instance.client;
          final userRes = await client
              .from('users')
              .select('*, partners(*, shopkeeper_profiles(*)), user_addresses(*)')
              .eq('user_id', userId)
              .maybeSingle();

          if (userRes != null) {
            _populateFromSupabase(userRes);
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
    if (oName.isNotEmpty) ownerName = oName;

    phone = (data['phone'] ?? data['mobile'] ?? phone).toString().trim();
    email = (data['email'] ?? email).toString().trim();

    final cat = (data['category'] ?? data['business_type'] ?? data['category_name'] ?? '').toString().trim();
    if (cat.isNotEmpty) category = cat;

    final addr = (data['business_address'] ?? data['shop_address'] ?? data['address'] ?? '').toString().trim();
    if (addr.isNotEmpty) address = addr;

    final c = (data['city'] ?? '').toString().trim();
    if (c.isNotEmpty) city = c;

    final pin = (data['pincode'] ?? '').toString().trim();
    if (pin.isNotEmpty) pincode = pin;

    final exp = (data['years_in_business'] ?? data['yearsInBusiness'] ?? data['experience'] ?? '').toString().trim();
    if (exp.isNotEmpty) yearsInBusiness = exp.contains('Year') ? exp : '$exp Years';

    final aadhaar = (data['aadhaar_number'] ?? data['aadhaar'] ?? '').toString().trim();
    if (aadhaar.isNotEmpty) aadhaarNumber = aadhaar;

    final pan = (data['pan_number'] ?? data['pan'] ?? '').toString().trim();
    if (pan.isNotEmpty) panNumber = pan;

    final bBank = (data['bank_name'] ?? '').toString().trim();
    if (bBank.isNotEmpty) bankName = bBank;

    final bAcc = (data['account_number'] ?? '').toString().trim();
    if (bAcc.isNotEmpty) accountNumber = bAcc;

    final bIfsc = (data['ifsc_code'] ?? '').toString().trim();
    if (bIfsc.isNotEmpty) ifscCode = bIfsc;

    final status = (data['verification_status'] ?? data['status'] ?? data['account_status'] ?? '').toString().toUpperCase();
    isVerified = status == 'VERIFIED' || status == 'APPROVED' || status == 'ACTIVE';

    if (data['is_open'] != null) isOpen = data['is_open'] == true;
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
      final shopProfile = pMap['shopkeeper_profiles'];
      if (shopProfile is Map) {
        final bName = (shopProfile['business_name'] ?? '').toString().trim();
        if (bName.isNotEmpty) shopName = bName;
        final bType = (shopProfile['business_type'] ?? '').toString().trim();
        if (bType.isNotEmpty) category = bType;
        final exp = shopProfile['business_experience']?.toString();
        if (exp != null && exp.isNotEmpty) yearsInBusiness = '$exp Years';
      }
    }

    final addresses = userRes['user_addresses'];
    if (addresses is List && addresses.isNotEmpty) {
      final addrMap = addresses.first as Map<String, dynamic>;
      final line1 = (addrMap['address_line1'] ?? '').toString().trim();
      if (line1.isNotEmpty) address = line1;
      final c = (addrMap['city'] ?? '').toString().trim();
      if (c.isNotEmpty) city = c;
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
  }) async {
    shopName = newShopName;
    ownerName = newOwnerName;
    phone = newPhone;
    email = newEmail;
    address = newAddress;
    city = newCity;
    pincode = newPincode;
    category = newCategory;
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
      'role_name': 'shopkeeper',
    };
    await LocalRegistrationCache.updateActiveShopkeeper(updates);

    // Update in Supabase asynchronously
    try {
      final client = Supabase.instance.client;
      final userId = shopData?['user_id']?.toString() ?? client.auth.currentUser?.id;
      if (userId != null) {
        final partnerId = shopData?['partner_id']?.toString();
        if (partnerId != null) {
          await client.from('shopkeeper_profiles').upsert({
            'partner_id': partnerId,
            'business_name': shopName,
            'business_type': category,
          });
        }
      }
    } catch (_) {}
  }

  void toggleStoreStatus(bool status) {
    isOpen = status;
    notifyListeners();
    LocalRegistrationCache.updateActiveShopkeeper({'is_open': isOpen});
  }

  void toggleSound(bool val) {
    orderSoundEnabled = val;
    notifyListeners();
  }

  void toggleNotifications(bool val) {
    pushNotificationsEnabled = val;
    notifyListeners();
  }

  Future<void> logout() async {
    await LocalRegistrationCache.logoutShopkeeper();
  }
}
