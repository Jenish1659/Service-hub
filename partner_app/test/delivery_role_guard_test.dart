import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/dashboard/presentation/delivery_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync('hive_deliv_guard_test');
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
    LiveBookingSyncService.instance.stopPolling();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter.baseflow.com/permissions/methods'), (call) async {
      return 1;
    });
  });

  setUp(() async {
    await LocalRegistrationCache.clearActiveSession();
    LiveBookingSyncService.instance.stopPolling();
  });

  tearDown(() async {
    LiveBookingSyncService.instance.stopPolling();
  });

  testWidgets('DeliveryDashboardScreen rejects access when active session is shopkeeper', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Populate a shopkeeper session
    await LocalRegistrationCache.updateActiveShopkeeper({
      'user_id': '2987897d-7070-422e-bce9-008e6fb5c5b7',
      'name': 'Jenish Bheda',
      'role_name': 'shopkeeper',
      'business_name': 'Bheda Electronics Store',
      'verification_status': 'VERIFIED',
      'account_status': 'ACTIVE',
    });

    String? redirectedRoute;
    final router = GoRouter(
      initialLocation: '/dashboard/delivery',
      routes: [
        GoRoute(
          path: '/dashboard/delivery',
          builder: (context, state) => const DeliveryDashboardScreen(),
        ),
        GoRoute(
          path: '/dashboard/shopkeeper',
          builder: (context, state) {
            redirectedRoute = '/dashboard/shopkeeper';
            return const Scaffold(body: Text('REDIRECTED_TO_SHOPKEEPER'));
          },
        ),
        GoRoute(
          path: '/login/delivery-agent',
          builder: (context, state) {
            redirectedRoute = '/login/delivery-agent';
            return const Scaffold(body: Text('REDIRECTED_TO_LOGIN'));
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Must redirect to shopkeeper dashboard
    expect(redirectedRoute, equals('/dashboard/shopkeeper'));
    expect(find.text('REDIRECTED_TO_SHOPKEEPER'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
