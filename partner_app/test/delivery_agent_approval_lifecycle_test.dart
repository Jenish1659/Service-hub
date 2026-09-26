import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/registration/presentation/screens/provider_application_status_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('delivery_agent_lifecycle_test_');
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
  });

  tearDownAll(() async {
    LiveBookingSyncService.instance.stopPolling();
  });

  group('Delivery Agent Registration Payload & Approval Lifecycle Tests', () {
    testWidgets('1. Delivery Agent registration persists complete payload and handles logout cleanly', (tester) async {
      await tester.runAsync(() async {
        final syncService = LiveBookingSyncService.instance;

        final verificationPayload = {
          'id': 'vr_del_test_001',
          'verification_id': 'vr_del_test_001',
          'user_id': 'usr_del_test_001',
          'partner_id': 'part_del_test_001',
          'delivery_agent_id': 'agent_del_test_001',
          'name': 'Vikram Rathore',
          'full_name': 'Vikram Rathore',
          'phone': '+91 9876500001',
          'email': 'vikram_del@servicehub.com',
          'business_name': 'Vikram Rathore Express Delivery',
          'category': 'delivery_agent',
          'category_name': 'Delivery Partner (Bike)',
          'role': 'delivery_agent',
          'role_name': 'delivery_agent',
          'document_type': 'DELIVERY_ONBOARDING',
          'verification_type': 'DRIVING_LICENSE',
          'vehicle_type': 'Bike',
          'vehicle_number': 'GJ-10-AB-5678',
          'vehicle_no': 'GJ-10-AB-5678',
          'driving_license_number': 'DL-GJ10-20265678',
          'driving_licence': 'DL-GJ10-20265678',
          'aadhaar_number': '987654321012',
          'bank_name': 'State Bank of India',
          'account_number': '12345678901',
          'ifsc_code': 'SBIN0001234',
          'account_holder_name': 'Vikram Rathore',
          'city': 'Jamnagar',
          'state': 'Gujarat',
          'verification_status': 'PENDING',
          'status': 'PENDING',
        };

        await syncService.submitPartnerVerification(verificationPayload);
        await LocalRegistrationCache.updateActiveDeliveryAgent(verificationPayload);

        final cached = await LocalRegistrationCache.getActiveDeliveryAgent();
        expect(cached, isNotNull);
        expect(cached!['role_name'], equals('delivery_agent'));
        expect(cached['role'], equals('delivery_agent'));
        expect(cached['category'], equals('delivery_agent'));
        expect(cached['document_type'], equals('DELIVERY_ONBOARDING'));
        expect(cached['verification_type'], equals('DRIVING_LICENSE'));
        expect(cached['vehicle_number'], equals('GJ-10-AB-5678'));
        expect(cached['driving_license_number'], equals('DL-GJ10-20265678'));
        expect(cached['bank_name'], equals('State Bank of India'));
        expect(cached['aadhaar_number'], equals('987654321012'));
        expect(cached['verification_status'], equals('PENDING'));

        // Verify logout
        await LocalRegistrationCache.logoutDeliveryAgent();
        final afterLogout = await LocalRegistrationCache.getActiveDeliveryAgent();
        expect(afterLogout, isNull);
      });
    });

    testWidgets('2. ProviderApplicationStatusScreen shows approved state for delivery agent and launches /dashboard/delivery', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const riderPhone = '9876500002';
      final syncService = LiveBookingSyncService.instance;

      await tester.runAsync(() async {
        final payload = {
          'id': 'vr_del_test_002',
          'verification_id': 'vr_del_test_002',
          'user_id': 'usr_del_test_002',
          'partner_id': 'part_del_test_002',
          'delivery_agent_id': 'agent_del_test_002',
          'name': 'Karan Singh',
          'full_name': 'Karan Singh',
          'phone': riderPhone,
          'category': 'delivery_agent',
          'category_name': 'Delivery Partner (Bike)',
          'role': 'delivery_agent',
          'role_name': 'delivery_agent',
          'document_type': 'DELIVERY_ONBOARDING',
          'verification_type': 'DRIVING_LICENSE',
          'vehicle_type': 'Bike',
          'vehicle_number': 'GJ-03-CD-9999',
          'driving_license_number': 'DL-GJ03-20269999',
          'aadhaar_number': '112233445566',
          'status': 'APPROVED',
          'verification_status': 'VERIFIED',
          'account_status': 'ACTIVE',
        };

        await syncService.submitPartnerVerification(payload);
        await syncService.approvePartnerVerification(riderPhone);
        await syncService.approvePartnerVerification('vr_del_test_002');
        await LocalRegistrationCache.updateActiveDeliveryAgent(payload);
      });

      String? navigatedRoute;
      final router = GoRouter(
        initialLocation: '/tracker',
        routes: [
          GoRoute(
            path: '/tracker',
            builder: (context, state) => const ProviderApplicationStatusScreen(initialIdentifier: riderPhone),
          ),
          GoRoute(
            path: '/dashboard/delivery',
            builder: (context, state) {
              navigatedRoute = '/dashboard/delivery';
              return const Scaffold(body: Text('DELIVERY_DASHBOARD_SCREEN'));
            },
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      // 1. Verify delivery context header & celebration card
      expect(find.text('Delivery Partner Status'), findsOneWidget);
      expect(find.text('🎉 Delivery Partner Activated!'), findsOneWidget);
      expect(find.text('Admin has approved your driver KYC. You can now accept deliveries!'), findsOneWidget);

      // 2. Verify Delivery Dashboard Launch Button
      final launchBtn = find.text('Launch Delivery Dashboard 🛵');
      expect(launchBtn, findsOneWidget);

      // 3. Tap button to launch /dashboard/delivery
      await tester.tap(launchBtn);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));

      expect(navigatedRoute, equals('/dashboard/delivery'));
      expect(find.text('DELIVERY_DASHBOARD_SCREEN'), findsOneWidget);

      // 4. Verify LocalRegistrationCache active delivery agent is updated to ACTIVE
      Map<String, dynamic>? activeAgent;
      await tester.runAsync(() async {
        activeAgent = await LocalRegistrationCache.getActiveDeliveryAgent();
      });
      expect(activeAgent, isNotNull);
      expect(activeAgent!['role_name'], equals('delivery_agent'));
      expect(activeAgent!['verification_status'], equals('VERIFIED'));
      expect(activeAgent!['account_status'], equals('ACTIVE'));

      LiveBookingSyncService.instance.stopPolling();
    });
  });
}
