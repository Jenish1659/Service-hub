import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/dashboard/presentation/shopkeeper_dashboard_screen.dart';
import 'package:service_hub_partner/features/registration/presentation/screens/provider_application_status_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync('hive_role_routing_test');
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
    LiveBookingSyncService.instance.stopPolling();

    // Mock platform channel for permission_handler to prevent test stalls
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/permissions/methods'), (call) async {
      return 1; // Granted
    });
  });

  setUp(() async {
    await LocalRegistrationCache.clearActiveSession();
    LiveBookingSyncService.instance.stopPolling();
  });

  tearDown(() async {
    LiveBookingSyncService.instance.stopPolling();
  });

  tearDownAll(() async {
    LiveBookingSyncService.instance.stopPolling();
  });

  group('BUG 1: Role Routing & Session Isolation Tests', () {
    test('1. LocalRegistrationCache: Multi-role isolation prevents cross-role leakage', () async {
      // Step A: Save Service Provider
      await LocalRegistrationCache.updateActiveServiceProvider({
        'user_id': 'sp_user_001',
        'name': 'Ramesh Technician',
        'role_name': 'service_provider',
        'verification_status': 'VERIFIED',
      });

      expect(await LocalRegistrationCache.getActiveServiceProvider(), isNotNull);
      expect(await LocalRegistrationCache.getActivePartner('service_provider'), isNotNull);
      expect(await LocalRegistrationCache.getActiveShopkeeper(), isNull);
      expect(await LocalRegistrationCache.getActivePartner('shopkeeper'), isNull);
      expect(await LocalRegistrationCache.getActiveDeliveryAgent(), isNull);
      expect(await LocalRegistrationCache.getActivePartner('delivery_agent'), isNull);

      // Step B: Save Shopkeeper with empty string vehicle/delivery keys (real-world bheda_1 data)
      await LocalRegistrationCache.updateActiveShopkeeper({
        'user_id': '2987897d-7070-422e-bce9-008e6fb5c5b7',
        'partner_id': '446109aa-a7e9-4072-ac72-abdfd8013492',
        'name': 'Jenish Bheda',
        'business_name': 'Bheda Electronics Store',
        'role_name': 'shopkeeper',
        'delivery_agent_id': '', // Empty string in joined record
        'vehicle_type': '',      // Empty string in joined record
        'verification_status': 'VERIFIED',
        'account_status': 'ACTIVE',
      });

      final shop = await LocalRegistrationCache.getActiveShopkeeper();
      expect(shop, isNotNull);
      expect(shop!['role_name'], equals('shopkeeper'));
      expect(shop['business_name'], equals('Bheda Electronics Store'));

      // Strict negative assertions: Shopkeeper MUST NOT resolve as delivery agent or service provider
      expect(await LocalRegistrationCache.getActivePartner('shopkeeper'), isNotNull);
      expect(await LocalRegistrationCache.getActiveDeliveryAgent(), isNull);
      expect(await LocalRegistrationCache.getActivePartner('delivery_agent'), isNull);

      // Step C: Save Delivery Agent
      await LocalRegistrationCache.updateActiveDeliveryAgent({
        'user_id': 'deliv_user_001',
        'name': 'Suresh Express Rider',
        'role_name': 'delivery_agent',
        'vehicle_type': 'Motorcycle',
        'vehicle_number': 'GJ-10-AB-1234',
        'verification_status': 'VERIFIED',
      });

      final deliv = await LocalRegistrationCache.getActiveDeliveryAgent();
      expect(deliv, isNotNull);
      expect(deliv!['role_name'], equals('delivery_agent'));
      expect(await LocalRegistrationCache.getActivePartner('delivery_agent'), isNotNull);

      // Step D: Logout purges all role sessions
      await LocalRegistrationCache.clearActiveSession();
      expect(await LocalRegistrationCache.getActiveShopkeeper(), isNull);
      expect(await LocalRegistrationCache.getActiveServiceProvider(), isNull);
      expect(await LocalRegistrationCache.getActiveDeliveryAgent(), isNull);
      expect(await LocalRegistrationCache.getActivePartner(), isNull);
    });

    testWidgets('2. ProviderApplicationStatusScreen routes strictly to /dashboard/shopkeeper for shopkeeper role', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const shopkeeperPhone = '9998887771';
      await LiveBookingSyncService.instance.submitPartnerVerification({
        'id': 'ver_test_$shopkeeperPhone',
        'verification_id': 'ver_test_$shopkeeperPhone',
        'phone': shopkeeperPhone,
        'full_name': 'Shop Owner',
        'business_name': 'My Supermarket',
        'role_name': 'shopkeeper',
        'category': 'shopkeeper',
        'status': 'APPROVED',
        'verification_status': 'VERIFIED',
      });

      String? launchedRoute;
      final router = GoRouter(
        initialLocation: '/register/status-tracker',
        routes: [
          GoRoute(
            path: '/register/status-tracker',
            builder: (context, state) => const ProviderApplicationStatusScreen(
              initialIdentifier: shopkeeperPhone,
            ),
          ),
          GoRoute(
            path: '/dashboard/shopkeeper',
            builder: (context, state) {
              launchedRoute = '/dashboard/shopkeeper';
              return const Scaffold(body: Text('SHOPKEEPER_DASHBOARD_LANDING'));
            },
          ),
          GoRoute(
            path: '/dashboard/delivery',
            builder: (context, state) {
              launchedRoute = '/dashboard/delivery';
              return const Scaffold(body: Text('DELIVERY_DASHBOARD_LANDING'));
            },
          ),
          GoRoute(
            path: '/dashboard',
            builder: (context, state) {
              launchedRoute = '/dashboard';
              return const Scaffold(body: Text('PROVIDER_DASHBOARD_LANDING'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final launchButton = find.widgetWithText(ElevatedButton, 'Launch Shop Dashboard 🏪');
      expect(launchButton, findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(launchButton);
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      // MUST route to /dashboard/shopkeeper, NOT /dashboard/delivery
      expect(launchedRoute, equals('/dashboard/shopkeeper'));
      expect(find.text('SHOPKEEPER_DASHBOARD_LANDING'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('3. ShopkeeperDashboardScreen rejects access when active session is delivery agent', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // Populate a delivery agent session
      await LocalRegistrationCache.updateActiveDeliveryAgent({
        'user_id': 'deliv_intruder',
        'name': 'Rider User',
        'role_name': 'delivery_agent',
        'verification_status': 'VERIFIED',
        'account_status': 'ACTIVE',
      });

      String? redirectedRoute;
      final router = GoRouter(
        initialLocation: '/dashboard/shopkeeper',
        routes: [
          GoRoute(
            path: '/dashboard/shopkeeper',
            builder: (context, state) => const ShopkeeperDashboardScreen(),
          ),
          GoRoute(
            path: '/dashboard/delivery',
            builder: (context, state) {
              redirectedRoute = '/dashboard/delivery';
              return const Scaffold(body: Text('REDIRECTED_TO_DELIVERY'));
            },
          ),
          GoRoute(
            path: '/login/shopkeeper',
            builder: (context, state) {
              redirectedRoute = '/login/shopkeeper';
              return const Scaffold(body: Text('REDIRECTED_TO_LOGIN'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Must redirect to delivery dashboard because role is delivery_agent
      expect(redirectedRoute, equals('/dashboard/delivery'));
      expect(find.text('REDIRECTED_TO_DELIVERY'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
