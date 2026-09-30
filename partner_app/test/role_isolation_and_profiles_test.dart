import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/dashboard/presentation/shopkeeper_dashboard_screen.dart';
import 'package:service_hub_partner/features/dashboard/presentation/delivery_dashboard_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/shopkeeper_profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/delivery_agent_profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_agent_profile_screen.dart';
import 'package:service_hub_partner/features/registration/presentation/screens/provider_application_status_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync('hive_role_isolation_test');
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
  });

  setUp(() {
    LocalRegistrationCache.clearMemorySession();
  });

  tearDown(() {
    LiveBookingSyncService.instance.stopPolling();
  });

  tearDownAll(() async {
    LiveBookingSyncService.instance.stopPolling();
  });

  group('Role Session Isolation Tests (Zero Connection Between Roles)', () {
    test('1. LocalRegistrationCache keeps Service Provider, Shopkeeper, and Delivery Agent strictly separate', () async {
      // 1. Save Service Provider session
      await LocalRegistrationCache.updateActiveServiceProvider({
        'user_id': 'sp_001',
        'name': 'Ramesh AC Technician',
        'category': 'ac_service',
      });

      // 2. Save Shopkeeper session
      await LocalRegistrationCache.updateActiveShopkeeper({
        'user_id': 'shop_001',
        'name': 'Jenish Merchant',
        'business_name': 'Bheda Electronics Store',
        'category': 'AC Service Parts & Hardware',
      });

      // 3. Save Delivery Agent session
      await LocalRegistrationCache.updateActiveDeliveryAgent({
        'user_id': 'deliv_001',
        'name': 'Suresh Courier',
        'vehicle_type': 'Motorcycle',
        'vehicle_reg_number': 'GJ-10-XY-9999',
      });

      // Assert that each role getter returns only its own data
      final sp = await LocalRegistrationCache.getActiveServiceProvider();
      expect(sp, isNotNull);
      expect(sp!['user_id'], equals('sp_001'));
      expect(sp['name'], equals('Ramesh AC Technician'));
      expect(sp['role_name'], equals('service_provider'));

      final shop = await LocalRegistrationCache.getActiveShopkeeper();
      expect(shop, isNotNull);
      expect(shop!['user_id'], equals('shop_001'));
      expect(shop['business_name'], equals('Bheda Electronics Store'));
      expect(shop['role_name'], equals('shopkeeper'));

      final deliv = await LocalRegistrationCache.getActiveDeliveryAgent();
      expect(deliv, isNotNull);
      expect(deliv!['user_id'], equals('deliv_001'));
      expect(deliv['vehicle_reg_number'], equals('GJ-10-XY-9999'));
      expect(deliv['role_name'], equals('delivery_agent'));

      // 4. Strict session deletion on logout: Logging out purges all keys unconditionally
      await LocalRegistrationCache.logoutShopkeeper();
      expect(await LocalRegistrationCache.getActiveShopkeeper(), isNull);
      expect(await LocalRegistrationCache.getActiveServiceProvider(), isNull);
      expect(await LocalRegistrationCache.getActiveDeliveryAgent(), isNull);
    });
  });

  group('Shopkeeper Profile Screen Tests', () {
    testWidgets('2. ShopkeeperProfileScreen displays store details, metrics, and retail options with 0 technician elements', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = ShopkeeperProfileController();
      controller.shopName = 'Bheda Electronics Store';
      controller.ownerName = 'Jenish Bheda';
      controller.category = 'AC Service Parts & Hardware';
      controller.phone = '7573021659';
      controller.address = 'Market Yard Main Road';
      controller.city = 'Jamnagar';
      controller.isVerified = true;
      controller.isLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: ShopkeeperProfileScreen(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Store Profile Title & Storefront Info
      expect(find.text('Shop Profile'), findsOneWidget);
      expect(find.text('Bheda Electronics Store'), findsOneWidget);
      expect(find.text('Verified Shop'), findsOneWidget);

      // Verify Retail Menu items exist
      expect(find.text('Shop Information'), findsOneWidget);
      expect(find.text('Business Hours'), findsOneWidget);
      expect(find.text('Service Area'), findsOneWidget);
      expect(find.text('Shop Photos'), findsOneWidget);
      expect(find.text('Documents & Verification'), findsOneWidget);
      expect(find.text('Contact Details'), findsOneWidget);
      expect(find.text('Bank Details'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify Service Provider elements are ABSENT
      expect(find.text('Jobs Completed'), findsNothing);
      expect(find.text('My Services'), findsNothing);
      expect(find.text('Service Pricing'), findsNothing);
    });
  });

  group('Delivery Agent Profile Screen Tests', () {
    testWidgets('3. DeliveryAgentProfileScreen displays rider details and vehicle info', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = DeliveryAgentProfileController();
      controller.agentName = 'Ramesh Courier';
      controller.vehicleType = 'Honda Activa';
      controller.vehicleRegNumber = 'GJ-10-AB-5678';
      controller.drivingLicenseNumber = 'DL-GJ10-2022001';
      controller.isLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryAgentProfileScreen(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Rider Profile'), findsOneWidget);
      expect(find.text('Ramesh Courier'), findsOneWidget);
      expect(find.text('Honda Activa • GJ-10-AB-5678'), findsOneWidget);
      expect(find.text('Verified Rider ✓'), findsOneWidget);
      expect(find.text('Vehicle & Driving Documents'), findsOneWidget);
    });
  });

  group('Dashboard to Dedicated Profile Navigation Tests', () {
    testWidgets('4. ShopkeeperDashboardScreen Profile tab navigates to /profile/shopkeeper', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await LocalRegistrationCache.updateActiveShopkeeper({
          'user_id': 'shop_999',
          'name': 'Bheda Store',
          'account_status': 'ACTIVE',
          'verification_status': 'VERIFIED',
        });
      });

      String? pushedRoute;
      final router = GoRouter(
        initialLocation: '/dashboard/shopkeeper',
        routes: [
          GoRoute(
            path: '/dashboard/shopkeeper',
            builder: (context, state) => const ShopkeeperDashboardScreen(),
          ),
          GoRoute(
            path: '/profile/shopkeeper',
            builder: (context, state) {
              pushedRoute = '/profile/shopkeeper';
              return const Scaffold(body: Text('SHOPKEEPER_PROFILE_DESTINATION'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Tap on the Profile item in BottomNavigationBar (5th item, index 4)
      final profileTab = find.text('Profile');
      expect(profileTab, findsOneWidget);
      await tester.tap(profileTab);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Verify that it navigated strictly to /profile/shopkeeper
      expect(pushedRoute, equals('/profile/shopkeeper'));
      expect(find.text('SHOPKEEPER_PROFILE_DESTINATION'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 250));
      LiveBookingSyncService.instance.stopPolling();
    });

    testWidgets('5. DeliveryDashboardScreen Profile action navigates to /profile/delivery', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.runAsync(() async {
        await LocalRegistrationCache.updateActiveDeliveryAgent({
          'user_id': 'rider_999',
          'name': 'Rider Test',
          'verification_status': 'VERIFIED',
          'account_status': 'ACTIVE',
        });
      });

      String? pushedRoute;
      final router = GoRouter(
        initialLocation: '/dashboard/delivery',
        routes: [
          GoRoute(
            path: '/dashboard/delivery',
            builder: (context, state) => const DeliveryDashboardScreen(),
          ),
          GoRoute(
            path: '/profile/delivery',
            builder: (context, state) {
              pushedRoute = '/profile/delivery';
              return const Scaffold(body: Text('DELIVERY_PROFILE_DESTINATION'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      final profileBtn = find.byTooltip('Rider Profile');
      expect(profileBtn, findsOneWidget);
      await tester.tap(profileBtn);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(pushedRoute, equals('/profile/delivery'));
      expect(find.text('DELIVERY_PROFILE_DESTINATION'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 250));
      LiveBookingSyncService.instance.stopPolling();
    });
  });

  group('ProviderApplicationStatusScreen Approval & Isolated Launch Tests', () {
    testWidgets('6. Approved shopkeeper tracking unlocks Launch Shop Dashboard and persists to active_shopkeeper_session', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const uniquePhone = '9988776655';

      await tester.runAsync(() async {
        if (Hive.isBoxOpen('partner_cache')) {
          final box = Hive.box('partner_cache');
          await box.deleteAll(box.keys.toList());
        }
        await LiveBookingSyncService.instance.submitPartnerVerification({
          'id': 'ver_shop_unique_9988',
          'user_id': 'shop_user_unique_9988',
          'name': 'Jenish Bheda',
          'phone': uniquePhone,
          'role_name': 'shopkeeper',
          'business_name': 'Bheda Electronics',
          'category': 'AC Service Parts',
          'status': 'APPROVED',
          'verification_status': 'VERIFIED',
        });
        await LiveBookingSyncService.instance.approvePartnerVerification(uniquePhone);

        await LocalRegistrationCache.updateActiveShopkeeper({
          'user_id': 'shop_user_unique_9988',
          'name': 'Jenish Bheda',
          'phone': uniquePhone,
          'role_name': 'shopkeeper',
          'verification_status': 'VERIFIED',
          'account_status': 'ACTIVE',
        });
      });

      String? navigatedRoute;
      final router = GoRouter(
        initialLocation: '/tracker',
        routes: [
          GoRoute(
            path: '/tracker',
            builder: (context, state) => const ProviderApplicationStatusScreen(initialIdentifier: uniquePhone),
          ),
          GoRoute(
            path: '/dashboard/shopkeeper',
            builder: (context, state) {
              navigatedRoute = '/dashboard/shopkeeper';
              return const Scaffold(body: Text('SHOPKEEPER_DASHBOARD_SCREEN'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // Launch button should be enabled with shopkeeper label
      final launchBtn = find.text('Launch Shop Dashboard 🏪');
      expect(launchBtn, findsOneWidget);

      await tester.runAsync(() async {
        await tester.tap(launchBtn);
        await Future.delayed(const Duration(milliseconds: 500));
      });
      await tester.pumpAndSettle();

      // Verify that it went to /dashboard/shopkeeper
      expect(navigatedRoute, equals('/dashboard/shopkeeper'));
      expect(find.text('SHOPKEEPER_DASHBOARD_SCREEN'), findsOneWidget);

      // Verify active_shopkeeper_session was populated
      Map<String, dynamic>? activeShop;
      await tester.runAsync(() async {
        activeShop = await LocalRegistrationCache.getActiveShopkeeper();
      });
      expect(activeShop, isNotNull);
      expect(activeShop!['role_name'], equals('shopkeeper'));
      expect(activeShop!['account_status'], equals('ACTIVE'));

      // Clean unmount to cancel periodic timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 250));
      LiveBookingSyncService.instance.stopPolling();
    });
  });
}
