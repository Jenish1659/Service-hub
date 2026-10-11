import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/services/supabase_auth_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/delivery_agent_profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/shopkeeper_profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync('hive_db_sync_test');
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
  });

  setUp(() async {
    LocalRegistrationCache.clearMemorySession();
    if (Hive.isBoxOpen('partner_cache')) {
      final box = Hive.box('partner_cache');
      await box.clear();
    }
  });

  tearDown(() {
    LiveBookingSyncService.instance.stopPolling();
  });

  group('True Database Synchronization Tests', () {
    test('1. SupabaseAuthService.updatePassword synchronizes password across all active sessions and cache', () async {
      final box = Hive.box('partner_cache');
      await box.put('active_user_session', {'user_id': 'usr_999', 'password': 'OldPassword@123'});
      await box.put('active_delivery_agent_session', {'user_id': 'usr_999', 'password': 'OldPassword@123'});
      await box.put('registered_users_list', [
        {'user_id': 'usr_999', 'username': 'testrider', 'password': 'OldPassword@123'}
      ]);

      final result = await SupabaseAuthService.updatePassword(
        newPassword: 'NewSecurePassword@456',
        currentPassword: 'OldPassword@123',
        userId: 'usr_999',
      );

      expect(result, isTrue);

      final userSession = box.get('active_user_session') as Map;
      expect(userSession['password'], 'NewSecurePassword@456');

      final delivSession = box.get('active_delivery_agent_session') as Map;
      expect(delivSession['password'], 'NewSecurePassword@456');

      final regList = box.get('registered_users_list') as List;
      expect(regList.first['password'], 'NewSecurePassword@456');
    });

    test('2. SupabaseAuthService.updateDeliveryAgentInDatabase handles updates gracefully and synchronizes live verifications', () async {
      await LiveBookingSyncService.instance.submitPartnerVerification({
        'user_id': 'rider_101',
        'name': 'Old Rider Name',
        'phone': '+91 90000 00001',
        'email': 'old.rider@servicehub.in',
      });

      final result = await SupabaseAuthService.updateDeliveryAgentInDatabase(
        userId: 'rider_101',
        name: 'New Rider Name',
        phone: '+91 90000 99999',
        email: 'new.rider@servicehub.in',
        vehicleType: 'Electric Scooter',
        vehicleNumber: 'GJ-10-EE-1234',
        drivingLicenseNumber: 'GJ1020260009999',
        bankName: 'HDFC Bank',
        accountNumber: '50100987654321',
        ifscCode: 'HDFC0001234',
        operatingRadius: 15.0,
      );

      expect(result, isTrue);

      final liveVer = LiveBookingSyncService.instance.getPartnerVerification('rider_101');
      expect(liveVer, isNotNull);
      expect(liveVer!['name'], 'New Rider Name');
      expect(liveVer['phone'], '+91 90000 99999');
      expect(liveVer['email'], 'new.rider@servicehub.in');
      expect(liveVer['bank_name'], 'HDFC Bank');
      expect(liveVer['account_number'], '50100987654321');
    });

    test('3. SupabaseAuthService.updateShopkeeperInDatabase synchronizes store profile and live verifications', () async {
      await LiveBookingSyncService.instance.submitPartnerVerification({
        'user_id': 'shop_202',
        'name': 'Old Owner',
        'business_name': 'Old Store',
        'phone': '+91 91111 00001',
      });

      final result = await SupabaseAuthService.updateShopkeeperInDatabase(
        userId: 'shop_202',
        ownerName: 'Fresh Mart Owner',
        shopName: 'Fresh Mart Supermarket',
        phone: '+91 91111 99999',
        email: 'freshmart@servicehub.in',
        address: '101 Market Lane',
        city: 'Jamnagar',
        category: 'Grocery & Spares',
        bankName: 'SBI Bank',
        accountNumber: '302010405060',
        ifscCode: 'SBIN0004321',
        serviceRadiusKm: 8.0,
        isOpen: true,
      );

      expect(result, isTrue);

      final liveVer = LiveBookingSyncService.instance.getPartnerVerification('shop_202');
      expect(liveVer, isNotNull);
      expect(liveVer!['name'], 'Fresh Mart Owner');
      expect(liveVer['business_name'], 'Fresh Mart Supermarket');
      expect(liveVer['phone'], '+91 91111 99999');
    });

    test('4. DeliveryAgentProfileController updates local state, cache, and database sync', () async {
      final controller = DeliveryAgentProfileController();
      controller.agentData = {'user_id': 'deliv_303', 'partner_id': 'part_deliv_303'};

      await controller.updateProfile(
        name: 'Vikram Singh',
        phone: '+91 98888 77777',
        email: 'vikram.singh@servicehub.in',
        address: 'Sector 5, Jamnagar',
        city: 'Jamnagar',
        state: 'Gujarat',
        vehicleType: 'Motorcycle',
        vehicleRegNumber: 'GJ-10-AB-5555',
        drivingLicenseNumber: 'GJ10DL5555',
        bankName: 'ICICI Bank',
        accountNumber: '123456789012',
        ifscCode: 'ICIC0001234',
      );

      expect(controller.agentName, 'Vikram Singh');
      expect(controller.phone, '+91 98888 77777');
      expect(controller.email, 'vikram.singh@servicehub.in');
      expect(controller.address, 'Sector 5, Jamnagar');
      expect(controller.vehicleRegNumber, 'GJ-10-AB-5555');

      final cached = await LocalRegistrationCache.getActiveDeliveryAgent();
      expect(cached, isNotNull);
      expect(cached!['name'], 'Vikram Singh');
      expect(cached['phone'], '+91 98888 77777');
      expect(cached['vehicle_number'], 'GJ-10-AB-5555');

      // Test toggleOnline
      await controller.toggleOnline(false);
      expect(controller.isOnline, isFalse);

      final cachedAfterToggle = await LocalRegistrationCache.getActiveDeliveryAgent();
      expect(cachedAfterToggle!['is_online'], isFalse);
    });

    test('5. ShopkeeperProfileController updates local state, cache, and database sync', () async {
      final controller = ShopkeeperProfileController();
      controller.shopData = {'user_id': 'shop_404', 'partner_id': 'part_shop_404'};

      await controller.updateStoreDetails(
        newShopName: 'Reliance Spares & Hardware',
        newOwnerName: 'Dhirubhai Merchant',
        newPhone: '+91 99999 88888',
        newEmail: 'reliance.spares@servicehub.in',
        newAddress: 'MG Road, Commercial Center',
        newCity: 'Jamnagar',
        newPincode: '361005',
        newCategory: 'AC Hardware & Parts',
        newDescription: 'Top quality hardware and spare components',
      );

      expect(controller.shopName, 'Reliance Spares & Hardware');
      expect(controller.ownerName, 'Dhirubhai Merchant');
      expect(controller.address, 'MG Road, Commercial Center');
      expect(controller.pincode, '361005');

      final cached = await LocalRegistrationCache.getActiveShopkeeper();
      expect(cached, isNotNull);
      expect(cached!['business_name'], 'Reliance Spares & Hardware');
      expect(cached['name'], 'Dhirubhai Merchant');

      // Test bank details update
      await controller.updateBankDetails(
        newAccountHolder: 'Dhirubhai Merchant',
        newBankName: 'Bank of Baroda',
        newAccountNumber: '987654321098',
        newIfsc: 'BARB0JAMNAG',
        newAccountType: 'Current',
      );

      expect(controller.bankName, 'Bank of Baroda');
      expect(controller.accountNumber, '987654321098');

      final cachedBank = await LocalRegistrationCache.getActiveShopkeeper();
      expect(cachedBank!['bank_name'], 'Bank of Baroda');
      expect(cachedBank['account_number'], '987654321098');
    });

    test('6. ProfileController executes real password updates and synchronizes cache and database', () async {
      final box = Hive.box('partner_cache');
      await box.put('active_user_session', {'user_id': 'usr_service_101', 'password': 'OldPassword@123'});

      final controller = ProfileController();
      controller.partnerData = {'user_id': 'usr_service_101'};

      final success = await controller.changePassword(
        currentPassword: 'OldPassword@123',
        newPassword: 'NewSecurePassword@456',
      );
      expect(success, isTrue);

      final updatedSession = box.get('active_user_session') as Map?;
      expect(updatedSession?['password'], 'NewSecurePassword@456');
    });

    testWidgets('7. DeliveryEditProfileScreen saves new name & contact and triggers updates', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = DeliveryAgentProfileController();
      controller.agentName = 'Original Name';
      controller.phone = '+91 91234 56789';
      controller.email = 'original@servicehub.in';

      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryEditProfileScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Enter new name
      final nameFinder = find.widgetWithText(TextField, 'Original Name');
      expect(nameFinder, findsOneWidget);
      await tester.enterText(nameFinder, 'Updated Database Rider');

      // Tap Save Changes
      final saveBtn = find.text('Save Changes');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 600));

      expect(controller.agentName, 'Updated Database Rider');

      final cached = await LocalRegistrationCache.getActiveDeliveryAgent();
      expect(cached!['name'], 'Updated Database Rider');

      // Drain SnackBar timer
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
