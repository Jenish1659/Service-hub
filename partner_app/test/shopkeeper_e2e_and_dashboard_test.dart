import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/core/services/supabase_auth_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/dashboard/presentation/shopkeeper_dashboard_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  void clearDiskJson() {
    for (final path in [
      r'C:\Users\Public\ServiceHub\service_hub_live_bookings.json',
      r'C:\Users\Public\ServiceHub\service_hub_partner_verifications.json',
    ]) {
      final f = File(path);
      if (f.existsSync()) {
        try {
          f.writeAsStringSync('{}');
        } catch (_) {}
      }
    }
  }

  setUpAll(() async {
    LiveBookingSyncService.instance.stopPolling();
    clearDiskJson();
    final tempDir = Directory.systemTemp.createTempSync('hive_shop_test');
    Hive.init(tempDir.path);
    final box = await Hive.openBox('partner_cache');
    await box.clear();
  });

  setUp(() {
    LiveBookingSyncService.instance.stopPolling();
  });

  tearDownAll(() async {
    LiveBookingSyncService.instance.stopPolling();
    clearDiskJson();
  });

  group('Shopkeeper Registration, Admin Approval & Dashboard E2E Tests', () {
    const testPhone = '9824411223';
    const testUsername = 'rajesh_electronics';
    const testPassword = 'ShopPassword@123';
    String shopkeeperUserId = 'shop_${DateTime.now().millisecondsSinceEpoch}';

    test('1. Shopkeeper registration via SupabaseAuthService sets role=shopkeeper and status=PENDING', () async {
      final regResult = await SupabaseAuthService.registerShopkeeper(
        username: testUsername,
        firstName: 'Rajesh',
        lastName: 'Kumar',
        phone: testPhone,
        password: testPassword,
        shopName: 'Rajesh Electronics',
        category: 'AC Service Parts',
        shopAddress: 'Station Road, Rajkot',
        city: 'Rajkot',
        state: 'Gujarat',
        pincode: '360001',
        aadhaarNumber: '742918456230',
        yearsInBusiness: '5+ years',
      );

      expect(regResult.isSuccess, isTrue);
      expect(regResult.roleName, equals('shopkeeper'));
      expect(regResult.userData?['role_name'], equals('shopkeeper'));
      expect(regResult.userData?['verification_status'], equals('PENDING'));
      expect(regResult.userData?['business_name'], equals('Rajesh Electronics'));

      shopkeeperUserId = (regResult.userData?['user_id'] ?? shopkeeperUserId).toString();

      // Verify LiveBookingSyncService receives the shopkeeper application
      final syncRecord = LiveBookingSyncService.instance.getPartnerVerification(shopkeeperUserId) ??
          LiveBookingSyncService.instance.getPartnerVerification(testPhone) ??
          LiveBookingSyncService.instance.getPartnerVerification(testUsername);

      expect(syncRecord, isNotNull);
      expect(syncRecord!['status'], equals('PENDING'));
      expect(syncRecord['business_name'], equals('Rajesh Electronics'));
      expect(syncRecord['role'], equals('shopkeeper'));
      expect(syncRecord['category'], anyOf(equals('shopkeeper'), equals('AC Service Parts')));
    });

    test('2. Shopkeeper Login is STRICTLY BLOCKED before Admin Approval', () async {
      final loginResult = await SupabaseAuthService.loginWithUsernameOrPhone(
        identifier: testUsername,
        password: testPassword,
        expectedRole: 'shopkeeper',
      );

      // Must be rejected with PENDING_APPROVAL
      expect(loginResult.isSuccess, isFalse);
      expect(loginResult.errorMessage, contains('PENDING_APPROVAL'));
    });

    test('3. Admin Approves Shopkeeper in Verification Queue', () async {
      // Simulate Admin App executing _approvePartnerProfile
      await LiveBookingSyncService.instance.approvePartnerVerification(shopkeeperUserId);
      await LiveBookingSyncService.instance.approvePartnerVerification(testPhone);

      final updatedSync = LiveBookingSyncService.instance.getPartnerVerification(shopkeeperUserId) ??
          LiveBookingSyncService.instance.getPartnerVerification(testPhone);

      expect(updatedSync, isNotNull);
      expect(updatedSync!['status'], anyOf(equals('APPROVED'), equals('VERIFIED')));
    });

    test('4. Shopkeeper Login SUCCEEDS after Admin Approval', () async {
      final loginResult = await SupabaseAuthService.loginWithUsernameOrPhone(
        identifier: testUsername,
        password: testPassword,
        expectedRole: 'shopkeeper',
      );

      expect(loginResult.isSuccess, isTrue);
      expect(loginResult.roleName, equals('shopkeeper'));
      expect(loginResult.userData?['verification_status'], anyOf(equals('VERIFIED'), equals('APPROVED')));
    });

    testWidgets('5. ShopkeeperDashboardScreen renders all visual sections from media_1789904227036.png', (WidgetTester tester) async {
      LiveBookingSyncService.instance.stopPolling();

      // Set active verified partner in cache via runAsync to handle disk I/O
      await tester.runAsync(() async {
        await LocalRegistrationCache.saveRegisteredPartner({
          'user_id': shopkeeperUserId,
          'name': 'Rajesh Kumar',
          'full_name': 'Rajesh Kumar',
          'business_name': 'Rajesh Electronics',
          'business_address': 'Station Road, Rajkot',
          'category': 'AC Service Parts',
          'verification_status': 'VERIFIED',
          'phone': testPhone,
          'role_name': 'shopkeeper',
        });
        final box = Hive.box('partner_cache');
        await box.put('shopkeeper_orders', [
          {
            'order_id': 'SH1024',
            'customer_name': 'Amit Shah',
            'item_title': 'AC Remote',
            'item_count': 1,
            'location': 'Rajkot (Near Kalawad Road)',
            'amount': 450.0,
            'status': 'New',
          },
          {
            'order_id': 'SH1023',
            'customer_name': 'Priya Patel',
            'item_title': 'Water Filter',
            'item_count': 2,
            'location': 'Rajkot (150ft Ring Road)',
            'amount': 850.0,
            'status': 'Preparing',
          },
          {
            'order_id': 'SH1021',
            'customer_name': 'Rahul Verma',
            'item_title': 'Washing Machine Belt',
            'item_count': 1,
            'location': 'Rajkot (University Road)',
            'amount': 320.0,
            'status': 'Completed',
          },
        ]);
      });

      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopkeeperDashboardScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Top Header
      expect(find.text('SERVICEHUB'), findsOneWidget);
      expect(find.text('SHOP PARTNER'), findsOneWidget);

      // Hero Greeting Card
      expect(find.text('Good Morning, Rajesh Kumar 👋'), findsOneWidget);
      expect(find.text('Rajesh Electronics'), findsWidgets);
      expect(find.text('Verified Shop'), findsOneWidget);
      expect(find.text('"Quality Products Happier Homes!"'), findsOneWidget);

      // Status & Hours
      expect(find.text('Shop Status'), findsOneWidget);
      expect(find.text('Today\'s Hours'), findsOneWidget);

      // 4 Key Metrics
      expect(find.text('New Orders'), findsOneWidget);
      expect(find.text('Today\'s Orders'), findsOneWidget);
      expect(find.text('Today\'s Sales'), findsOneWidget);
      expect(find.text('Shop Rating'), findsOneWidget);

      // Quick Actions
      expect(find.text('Add Product'), findsWidgets);
      expect(find.text('Manage Products'), findsOneWidget);
      expect(find.text('Inventory'), findsOneWidget);
      expect(find.text('Offers'), findsOneWidget);
      expect(find.text('View Earnings'), findsOneWidget);

      // Stock Up Banner & Alerts
      expect(find.text('Stock Up. Sell More.'), findsOneWidget);
      expect(find.text('Inventory Alerts'), findsOneWidget);
      expect(find.text('4 Low Stock Items'), findsOneWidget);
      expect(find.text('2 Out of Stock'), findsOneWidget);

      // Recent Orders Header & Items
      expect(find.text('Recent Orders'), findsOneWidget);
      expect(find.text('#SH1024 AC Remote'), findsOneWidget);
      expect(find.text('#SH1023 Water Filter'), findsOneWidget);
      expect(find.text('#SH1021 Washing Machine Belt'), findsOneWidget);

      // Bottom Nav Items (5 items with Elevated Emerald Map at Center)
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('6. Shopkeeper can toggle Open/Closed status and accept orders interactively', (WidgetTester tester) async {
      LiveBookingSyncService.instance.stopPolling();
      await tester.runAsync(() async {
        final box = Hive.box('partner_cache');
        await box.put('shopkeeper_orders', [
          {
            'order_id': 'SH1024',
            'customer_name': 'Amit Shah',
            'item_title': 'AC Remote',
            'item_count': 1,
            'location': 'Rajkot (Near Kalawad Road)',
            'amount': 450.0,
            'status': 'New',
          },
        ]);
      });

      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopkeeperDashboardScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Toggle Open switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Expect toggle update
      expect(find.text('Store is closed'), findsOneWidget);

      // Reopen
      await tester.tap(switchFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('You are open for orders'), findsOneWidget);

      // Tap Accept Order button on the first order (#SH1024)
      final acceptBtn = find.text('Accept Order').first;
      await tester.ensureVisible(acceptBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(acceptBtn, findsOneWidget);
      await tester.runAsync(() async {
        await tester.tap(acceptBtn);
        await Future.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Status should now transition to Preparing!
      expect(find.text('Order #SH1024 marked as Preparing!'), findsOneWidget);
    });

    testWidgets('7. ShopkeeperDashboardScreen displays clean empty state when no orders exist', (WidgetTester tester) async {
      LiveBookingSyncService.instance.stopPolling();
      LiveBookingSyncService.instance.clearBookingsForTest();
      clearDiskJson();
      await tester.runAsync(() async {
        final box = Hive.box('partner_cache');
        await box.put('shopkeeper_orders', []);
      });

      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: ShopkeeperDashboardScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Assert Empty State Content
      expect(find.text('No incoming orders yet'), findsOneWidget);
      expect(find.text('Your store is active and waiting for customer orders'), findsOneWidget);
      expect(find.text('Manage Catalog'), findsOneWidget);
    });
  });
}
