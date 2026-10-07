import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/dashboard/presentation/ac_provider_dashboard_controller.dart';
import 'package:service_hub_partner/features/dashboard/presentation/delivery_dashboard_screen.dart';
import 'package:service_hub_partner/features/dashboard/presentation/provider_dashboard_screen.dart';
import 'package:service_hub_partner/features/dashboard/presentation/provider_live_radar_map_screen.dart';
import 'package:service_hub_partner/features/dashboard/presentation/shopkeeper_dashboard_screen.dart';
import 'package:service_hub_partner/features/dashboard/presentation/shopkeeper_store_map_screen.dart';
import 'package:service_hub_partner/features/dashboard/presentation/widgets/delivery_recent_and_nav_widget.dart';

class MockACProviderDashboardNotifier extends ACProviderDashboardNotifier {
  MockACProviderDashboardNotifier([ACProviderDashboardState initial = const ACProviderDashboardState()]) {
    state = initial;
  }

  @override
  Future<void> initDashboard() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync('hive_center_map_nav_test');
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
    LiveBookingSyncService.instance.stopPolling();

    // Mock permissions and geolocator method channels
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/permissions/methods'), (call) async {
      return 1;
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/geolocator'), (call) async {
      if (call.method == 'checkPermission') return 3; // whileInUse
      if (call.method == 'requestPermission') return 3;
      return null;
    });
  });

  setUp(() async {
    final box = Hive.box('partner_cache');
    await box.clear();
    await LocalRegistrationCache.clearActiveSession();
    LocalRegistrationCache.clearMemorySession();
    LiveBookingSyncService.instance.stopPolling();
  });

  tearDown(() async {
    LiveBookingSyncService.instance.stopPolling();
  });

  tearDownAll(() async {
    LiveBookingSyncService.instance.stopPolling();
  });

  group('OpenStreetMap Centered Bottom Navigation Bar Tests (All 3 Partner Dashboards)', () {
    // -------------------------------------------------------------------------
    // Test 1: Shopkeeper Dashboard renders 5 bottom nav items with center Map
    // button (Index 2) themed emerald #059669, and tapping Profile (Index 4)
    // navigates to /profile/shopkeeper.
    // -------------------------------------------------------------------------
    testWidgets(
      'Test 1: Shopkeeper Dashboard renders 5 bottom nav items with center Map button (Index 2) themed emerald #059669, and tapping Profile (Index 4) navigates to /profile/shopkeeper',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2200);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.runAsync(() async {
          await LocalRegistrationCache.updateActiveShopkeeper({
            'user_id': 'shop_qa_test_01',
            'name': 'Rajesh Kumar',
            'business_name': 'Rajesh Electronics Store',
            'phone': '9824411223',
            'account_status': 'ACTIVE',
            'verification_status': 'VERIFIED',
          });
        });

        String? navigatedRoute;
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
                navigatedRoute = '/profile/shopkeeper';
                return const Scaffold(body: Text('SHOPKEEPER_PROFILE_DESTINATION'));
              },
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        // 1. Verify BottomNavigationBar is present
        final bottomNavBarFinder = find.byType(BottomNavigationBar);
        expect(bottomNavBarFinder, findsOneWidget);
        final bottomNavBar = tester.widget<BottomNavigationBar>(bottomNavBarFinder);

        // 2. Verify exactly 5 bottom nav items
        expect(bottomNavBar.items.length, equals(5));

        // Verify ordering: Home (0), Orders (1), Map (2), Products (3), Profile (4)
        expect(bottomNavBar.items[0].label, equals('Home'));
        expect(bottomNavBar.items[1].label, equals('Orders'));
        expect(bottomNavBar.items[2].label, equals('Map'));
        expect(bottomNavBar.items[3].label, equals('Products'));
        expect(bottomNavBar.items[4].label, equals('Profile'));

        // 3. Verify Emerald #059669 theme
        expect(bottomNavBar.selectedItemColor, equals(const Color(0xFF059669)));

        // Verify Center Map button (Index 2) container is styled with emerald #059669
        final centerMapBtnFinder = find.byKey(const Key('shopkeeper_bottom_nav_center_map_button'));
        expect(centerMapBtnFinder, findsOneWidget);
        final centerContainer = tester.widget<Container>(centerMapBtnFinder);
        final boxDec = centerContainer.decoration as BoxDecoration;
        final gradient = boxDec.gradient as LinearGradient;
        expect(gradient.colors, contains(const Color(0xFF059669)));

        // 4. Tap Profile item (Index 4) and verify navigation to /profile/shopkeeper
        final profileTab = find.text('Profile');
        expect(profileTab, findsOneWidget);
        await tester.tap(profileTab);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        expect(navigatedRoute, equals('/profile/shopkeeper'));
        expect(find.text('SHOPKEEPER_PROFILE_DESTINATION'), findsOneWidget);
      },
    );

    // -------------------------------------------------------------------------
    // Test 2: Shopkeeper Dashboard tapping center Map button launches
    // ShopkeeperStoreMapScreen or modal.
    // -------------------------------------------------------------------------
    testWidgets(
      'Test 2: Shopkeeper Dashboard tapping center Map button launches ShopkeeperStoreMapScreen or modal',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2200);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.runAsync(() async {
          await LocalRegistrationCache.updateActiveShopkeeper({
            'user_id': 'shop_qa_test_02',
            'name': 'Rajesh Kumar',
            'business_name': 'Rajesh Electronics Store',
            'phone': '9824411223',
            'account_status': 'ACTIVE',
            'verification_status': 'VERIFIED',
          });
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: ShopkeeperDashboardScreen(),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        // Locate center Map button
        final centerMapBtn = find.byKey(const Key('shopkeeper_bottom_nav_center_map_button'));
        expect(centerMapBtn, findsOneWidget);

        // Tap the center Map button
        await tester.tap(centerMapBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify ShopkeeperStoreMapScreen modal launches with OpenStreetMap TileLayer
        expect(find.byType(ShopkeeperStoreMapScreen), findsOneWidget);
        expect(find.byType(FlutterMap), findsWidgets);
        expect(find.byType(TileLayer), findsWidgets);
      },
    );

    // -------------------------------------------------------------------------
    // Test 3: Provider Dashboard renders bottom navbar with elevated center
    // Map button (Index 2) themed blue #2563EB, and tapping it opens the live radar map.
    // -------------------------------------------------------------------------
    testWidgets(
      'Test 3: Provider Dashboard renders bottom navbar with elevated center Map button (Index 2) themed blue #2563EB, and tapping it opens the live radar map',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2200);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.runAsync(() async {
          await LocalRegistrationCache.updateActiveServiceProvider({
            'user_id': 'provider_qa_test_01',
            'name': 'Rajesh AC Expert',
            'role_name': 'service_provider',
            'phone': '9876543210',
            'verification_status': 'VERIFIED',
            'city': 'Jamnagar',
          });
        });

        const testState = ACProviderDashboardState(
          isOnline: true,
          providerName: 'Rajesh AC Expert',
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              acProviderDashboardProvider.overrideWith((ref) => MockACProviderDashboardNotifier(testState)),
            ],
            child: const MaterialApp(
              home: ProviderDashboardScreen(),
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        // 1. Locate elevated center Map button at Index 2
        final centerMapBtn = find.byKey(const Key('bottom_nav_center_map_button'));
        expect(centerMapBtn, findsOneWidget);

        // 2. Verify blue theme #2563EB decoration
        final containerFinder = find.descendant(
          of: centerMapBtn,
          matching: find.byType(Container),
        );
        final container = tester.widget<Container>(containerFinder.first);
        final boxDec = container.decoration as BoxDecoration;
        final gradient = boxDec.gradient as LinearGradient;
        expect(gradient.colors.first, equals(const Color(0xFF2563EB)));

        // Verify other tabs exist: Dashboard (0), Jobs (1), Map (2), Earnings (3), Profile (4)
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Jobs'), findsWidgets);
        expect(find.descendant(of: centerMapBtn, matching: find.text('Map')), findsOneWidget);
        expect(find.text('Earnings'), findsWidgets);
        expect(find.text('Profile'), findsWidgets);

        // 3. Tap center Map button and verify live radar map opens directly
        await tester.tap(centerMapBtn);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Verify live radar map screen opens directly with OpenStreetMap FlutterMap & TileLayer
        expect(find.byType(ProviderLiveRadarMapScreen), findsOneWidget);
        expect(find.byType(FlutterMap), findsWidgets);
        expect(find.byType(TileLayer), findsWidgets);
      },
    );

    // -------------------------------------------------------------------------
    // Test 4: Delivery Dashboard renders DeliveryBottomCurvedNavBar with elevated
    // center Map button (Index 2) themed orange #EA580C, and tapping it opens the delivery live map.
    // -------------------------------------------------------------------------
    testWidgets(
      'Test 4: Delivery Dashboard renders DeliveryBottomCurvedNavBar with elevated center Map button (Index 2) themed orange #EA580C, and tapping it opens the delivery live map',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2200);
        tester.view.devicePixelRatio = 2.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.runAsync(() async {
          await LocalRegistrationCache.updateActiveDeliveryAgent({
            'user_id': 'rider_qa_test_01',
            'name': 'Ramesh Courier',
            'verification_status': 'VERIFIED',
            'account_status': 'ACTIVE',
          });
        });

        String? navigatedRoute;
        final router = GoRouter(
          initialLocation: '/dashboard/delivery',
          routes: [
            GoRoute(
              path: '/dashboard/delivery',
              builder: (context, state) => const DeliveryDashboardScreen(),
            ),
            GoRoute(
              path: '/delivery/map',
              builder: (context, state) {
                navigatedRoute = '/delivery/map';
                return const Scaffold(body: Text('DELIVERY_LIVE_MAP_DESTINATION'));
              },
            ),
          ],
        );

        await tester.pumpWidget(MaterialApp.router(routerConfig: router));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        // 1. Verify DeliveryBottomCurvedNavBar is rendered
        final navBarFinder = find.byType(DeliveryBottomCurvedNavBar);
        expect(navBarFinder, findsOneWidget);
        final navBar = tester.widget<DeliveryBottomCurvedNavBar>(navBarFinder);

        // 2. Verify elevated center Map button is themed orange #EA580C
        expect(navBar.centerButtonColor, equals(const Color(0xFFEA580C)));

        final elevatedMapBtn = find.byKey(const Key('elevated_map_circle_button'));
        expect(elevatedMapBtn, findsOneWidget);

        // Verify 5 navigation items: Home, Orders, Map, Earnings, Profile
        expect(find.descendant(of: navBarFinder, matching: find.text('Home')), findsOneWidget);
        expect(find.descendant(of: navBarFinder, matching: find.text('Orders')), findsOneWidget);
        expect(find.descendant(of: navBarFinder, matching: find.text('Map')), findsOneWidget);
        expect(find.descendant(of: navBarFinder, matching: find.text('Earnings')), findsOneWidget);
        expect(find.descendant(of: navBarFinder, matching: find.text('Profile')), findsOneWidget);

        // 3. Tap elevated center Map button
        await tester.tap(elevatedMapBtn);
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump(const Duration(milliseconds: 200));

        // 4. Verify it opens the delivery live map route /delivery/map
        expect(navigatedRoute, equals('/delivery/map'));
        expect(find.text('DELIVERY_LIVE_MAP_DESTINATION'), findsOneWidget);
      },
    );
  });
}
