import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/services/supabase_auth_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/registration/presentation/screens/provider_application_status_screen.dart';
import 'package:service_hub_partner/features/registration/presentation/screens/shopkeeper_registration_flow_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_logout_test');
    Hive.init(tempDir.path);
    final box = await Hive.openBox('partner_cache');
    await box.clear();
  });

  tearDownAll(() async {
    LiveBookingSyncService.instance.stopPolling();
    final file = File(r'C:\Users\Public\ServiceHub\service_hub_partner_verifications.json');
    if (file.existsSync()) {
      try {
        file.writeAsStringSync('{}');
      } catch (_) {}
    }
  });

  group('Session Purge on Logout Tests', () {
    test('1. LocalRegistrationCache.logout() purges both active_partner_session and active_user_session', () async {
      final box = Hive.box('partner_cache');
      await box.put('active_partner_session', {
        'user_id': 'prov_123',
        'name': 'Test Provider',
        'role_name': 'service_provider',
        'verification_status': 'VERIFIED',
      });
      await box.put('active_user_session', {
        'user_id': 'prov_123',
        'name': 'Test Provider',
        'role_name': 'service_provider',
        'verification_status': 'VERIFIED',
      });

      final activeBefore = await LocalRegistrationCache.getActivePartner();
      expect(activeBefore, isNotNull);
      expect(activeBefore!['user_id'], equals('prov_123'));

      // Perform Logout
      await LocalRegistrationCache.logout();

      // Verify both keys are completely purged from Hive box
      expect(box.get('active_partner_session'), isNull);
      expect(box.get('active_user_session'), isNull);

      // Verify getActivePartner returns null (so app launch will NOT auto-open dashboard)
      final activeAfter = await LocalRegistrationCache.getActivePartner();
      expect(activeAfter, isNull);
    });

    test('2. SupabaseAuthService.logout() purges both keys from Hive and memory', () async {
      final box = Hive.box('partner_cache');
      await box.put('active_partner_session', {
        'user_id': 'prov_456',
        'role_name': 'service_provider',
        'verification_status': 'VERIFIED',
      });
      await box.put('active_user_session', {
        'user_id': 'prov_456',
        'role_name': 'service_provider',
        'verification_status': 'VERIFIED',
      });

      await SupabaseAuthService.logout();

      expect(box.get('active_partner_session'), isNull);
      expect(box.get('active_user_session'), isNull);
      expect(await LocalRegistrationCache.getActivePartner(), isNull);
    });
  });

  group('Shopkeeper Registration Step 7 - Track Application UI', () {
    testWidgets('3. Step 7 renders Track Application Status button alongside Back to Login', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final router = GoRouter(
        initialLocation: '/register/shopkeeper',
        routes: [
          GoRoute(
            path: '/register/shopkeeper',
            builder: (context, state) => const ShopkeeperRegistrationFlowScreen(initialStep: 7),
          ),
          GoRoute(
            path: '/register/status-tracker',
            builder: (context, state) => const Scaffold(body: Text('STATUS_TRACKER_PAGE')),
          ),
          GoRoute(
            path: '/login/shopkeeper',
            builder: (context, state) => const Scaffold(body: Text('SHOPKEEPER_LOGIN_PAGE')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Step 7 elements
      expect(find.text('Registration Submitted!'), findsOneWidget);
      expect(find.text('Track Application Status'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);

      // Tap Track Application Status
      await tester.tap(find.text('Track Application Status'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('STATUS_TRACKER_PAGE'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });
  });

  group('Role-Aware Application Status Tracker Tests', () {
    const shopkeeperPhone = '9876500001';
    const shopkeeperName = 'Jay Ambe Stores';

    setUp(() async {
      await LiveBookingSyncService.instance.submitPartnerVerification({
        'id': 'ver_shop_$shopkeeperPhone',
        'verification_id': 'ver_shop_$shopkeeperPhone',
        'phone': shopkeeperPhone,
        'full_name': 'Hiren Patel',
        'business_name': shopkeeperName,
        'category': 'shopkeeper',
        'category_name': 'Shopkeeper (AC Service Parts)',
        'role_name': 'shopkeeper',
        'status': 'PENDING',
        'verification_status': 'PENDING',
      });
    });

    testWidgets('4. ProviderApplicationStatusScreen adapts to Shopkeeper role (Title, Timeline, Locked Dashboard)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
            path: '/login/shopkeeper',
            builder: (context, state) => const Scaffold(body: Text('SHOPKEEPER_LOGIN')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Check title reflects shopkeeper
      expect(find.text('Store Application Status'), findsOneWidget);

      // Check shopkeeper timeline steps
      expect(find.text('1. Store Registration Submitted'), findsOneWidget);
      expect(find.text('2. Store Documents & KYC Verification'), findsOneWidget);
      expect(find.text('3. Admin Store Review & Approval Request'), findsOneWidget);
      expect(find.text('4. Store Dashboard Access'), findsOneWidget);

      // Check locked status
      expect(find.text('Shop Dashboard Locked (Awaiting Admin Approval)'), findsOneWidget);
      expect(find.text('Return to Shopkeeper Login'), findsOneWidget);

      // Clean unmount to cancel poll timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 250));
    });

    testWidgets('5. Admin approval reflects live, unlocks Shopkeeper Dashboard and launches /dashboard/shopkeeper', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
            builder: (context, state) => const Scaffold(body: Text('SHOPKEEPER_DASHBOARD_LIVE')),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Admin approves the shopkeeper verification in LiveBookingSyncService
      await LiveBookingSyncService.instance.approvePartnerVerification(shopkeeperPhone);

      // Pump to let the StreamBuilder receive the update
      await tester.pump(const Duration(milliseconds: 300));

      // Check celebration banner appears
      expect(find.text('🎉 Store Activated & Approved!'), findsOneWidget);

      // Check launch button is now enabled
      final launchButton = find.text('Launch Shop Dashboard 🏪');
      expect(launchButton, findsOneWidget);

      // Tap Launch Shop Dashboard
      await tester.runAsync(() async {
        await tester.tap(launchButton);
        await Future.delayed(const Duration(milliseconds: 150));
      });
      await tester.pumpAndSettle();

      // Verify it navigated to /dashboard/shopkeeper
      expect(find.text('SHOPKEEPER_DASHBOARD_LIVE'), findsOneWidget);

      // Clean unmount to cancel timers
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 250));
    });
  });
}
