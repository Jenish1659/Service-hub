import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_admin/features/dashboard/presentation/widgets/admin_sidebar.dart';
import 'package:service_hub_admin/features/partners/presentation/admin_partners_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockCandidates = [
    {
      'id': 'vr_prov_001',
      'verification_id': 'vr_prov_001',
      'user_id': 'usr_prov_001',
      'name': 'Ramesh Sharma',
      'full_name': 'Ramesh Sharma',
      'phone': '+91 9876543210',
      'category': 'ac_service',
      'category_name': 'AC Service & Repair',
      'business_name': 'Ramesh AC Works',
      'role_name': 'service_provider',
      'role': 'service_provider',
      'status': 'PENDING',
      'city': 'Jamnagar',
      'state': 'Gujarat',
    },
    {
      'id': 'vr_shop_002',
      'verification_id': 'vr_shop_002',
      'user_id': 'usr_shop_002',
      'name': 'Prakash Patel',
      'full_name': 'Prakash Patel',
      'phone': '+91 9825100000',
      'category': 'shopkeeper',
      'category_name': 'Shopkeeper (AC Service Parts)',
      'business_name': 'Patel Electronics & Spares',
      'business_address': 'Shop 12, Market Yard, Jamnagar',
      'role_name': 'shopkeeper',
      'role': 'shopkeeper',
      'status': 'PENDING',
      'city': 'Jamnagar',
      'state': 'Gujarat',
      'aadhaar_number': '123456789012',
    },
  ];

  group('Admin Sidebar Navigation Tests', () {
    testWidgets('1. AdminSidebar renders Shopkeeper Verification in line with Partner Verification', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      String selectedTab = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminSidebar(
              activeTab: 'Dashboard',
              onTabSelected: (tab) => selectedTab = tab,
              onToggleCollapse: () {},
            ),
          ),
        ),
      );

      // Verify both items exist in the sidebar
      expect(find.text('Partner Verification'), findsOneWidget);
      expect(find.text('Shopkeeper Verification'), findsOneWidget);
      expect(find.text('Service Partners'), findsOneWidget);

      // Tap on Shopkeeper Verification
      await tester.tap(find.text('Shopkeeper Verification'));
      await tester.pumpAndSettle();

      expect(selectedTab, equals('Shopkeeper Verification'));
    });
  });

  group('Dedicated Shopkeeper vs Partner Queue Filtering Tests', () {
    testWidgets('2. AdminPartnersView with filterRole: "shopkeeper" isolates store applications', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPartnersView(
              filterRole: 'shopkeeper',
              unverifiedPartners: mockCandidates,
              onApprove: (id, name, [p]) {},
              onReject: (id, name, [p]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header verifies store context
      expect(find.text('Shopkeeper Verification & Store KYC Queue'), findsOneWidget);
      expect(find.text('1 Real Store Application(s) Waiting'), findsOneWidget);

      // Store candidate is visible
      expect(find.text('Prakash Patel'), findsOneWidget);
      expect(find.text('Shop Partner'), findsOneWidget);
      expect(find.text('Approve Store & Activate'), findsOneWidget);

      // Service provider candidate is NOT visible in shopkeeper queue
      expect(find.text('Ramesh Sharma'), findsNothing);
    });

    testWidgets('3. AdminPartnersView with filterRole: "service_provider" isolates partner applications', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPartnersView(
              filterRole: 'service_provider',
              unverifiedPartners: mockCandidates,
              onApprove: (id, name, [p]) {},
              onReject: (id, name, [p]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header verifies partner context
      expect(find.text('Partner Verification & KYC Queue'), findsOneWidget);
      expect(find.text('1 Real Application(s) Waiting'), findsOneWidget);

      // Provider candidate is visible
      expect(find.text('Ramesh Sharma'), findsOneWidget);
      expect(find.text('Approve & Activate'), findsOneWidget);

      // Shopkeeper candidate is NOT visible in provider queue
      expect(find.text('Prakash Patel'), findsNothing);
    });

    testWidgets('4. Approving shopkeeper triggers callback and removes card locally', (tester) async {
      tester.view.physicalSize = const Size(1280, 1024);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String approvedId = '';
      String approvedName = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPartnersView(
              filterRole: 'shopkeeper',
              unverifiedPartners: mockCandidates,
              onApprove: (id, name, [p]) {
                approvedId = id;
                approvedName = name;
              },
              onReject: (id, name, [p]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final approveBtn = find.text('Approve Store & Activate');
      expect(approveBtn, findsOneWidget);

      await tester.tap(approveBtn);
      await tester.pumpAndSettle();

      expect(approvedId, equals('vr_shop_002'));
      expect(approvedName, equals('Prakash Patel'));

      // Card is locally removed, empty state appears
      expect(find.text('No Pending Store Applications in Queue'), findsOneWidget);
    });
  });
}
