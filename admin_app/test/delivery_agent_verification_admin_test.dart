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
    {
      'id': 'vr_del_003',
      'verification_id': 'vr_del_003',
      'user_id': 'usr_del_003',
      'name': 'Suresh Kumar',
      'full_name': 'Suresh Kumar',
      'phone': '+91 9876500003',
      'category': 'delivery_agent',
      'category_name': 'Delivery Partner (Motorcycle / Bike)',
      'business_name': 'Suresh Kumar Express Delivery',
      'role_name': 'delivery_agent',
      'role': 'delivery_agent',
      'vehicle_type': 'Motorcycle / Bike',
      'vehicle_number': 'GJ-10-AB-1234',
      'driving_license_number': 'DL-GJ10-20260012',
      'status': 'PENDING',
      'city': 'Rajkot',
      'state': 'Gujarat',
      'aadhaar_number': '987654321098',
    },
  ];

  group('Admin Sidebar Delivery Agent Navigation Tests', () {
    testWidgets('1. AdminSidebar renders Delivery Agent Verification in line with Partner Verification', (tester) async {
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

      // Verify all partner operations navigation items exist
      expect(find.text('Partner Verification'), findsOneWidget);
      expect(find.text('Shopkeeper Verification'), findsOneWidget);
      expect(find.text('Delivery Agent Verification'), findsOneWidget);
      expect(find.text('Service Partners'), findsOneWidget);

      // Tap on Delivery Agent Verification
      await tester.tap(find.text('Delivery Agent Verification'));
      await tester.pumpAndSettle();

      expect(selectedTab, equals('Delivery Agent Verification'));
    });
  });

  group('Dedicated Delivery Agent vs Other Queues Filtering Tests', () {
    testWidgets('2. AdminPartnersView with filterRole: "delivery_agent" isolates rider applications', (tester) async {
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
              filterRole: 'delivery_agent',
              unverifiedPartners: mockCandidates,
              onApprove: (id, name, [p]) {},
              onReject: (id, name, [p]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header verifies delivery agent context
      expect(find.text('Delivery Agent Verification & Rider KYC Queue'), findsOneWidget);
      expect(find.text('1 Real Delivery Agent Application(s) Waiting'), findsOneWidget);

      // Isolated applicant details
      expect(find.text('Suresh Kumar'), findsOneWidget);
      expect(find.text('Ramesh Sharma'), findsNothing);
      expect(find.text('Prakash Patel'), findsNothing);

      // Vehicle details rendered
      expect(find.textContaining('GJ-10-AB-1234'), findsOneWidget);
    });

    testWidgets('3. Service Provider queue does not mix delivery agents or shopkeepers', (tester) async {
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

      expect(find.text('Ramesh Sharma'), findsOneWidget);
      expect(find.text('Prakash Patel'), findsNothing);
      expect(find.text('Suresh Kumar'), findsNothing);
    });

    testWidgets('4. Approving delivery agent triggers onApprove callback with correct ID', (tester) async {
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
              filterRole: 'delivery_agent',
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

      // Find approve button
      final approveButton = find.text('Approve Rider & Activate');
      expect(approveButton, findsOneWidget);

      await tester.tap(approveButton);
      await tester.pumpAndSettle();

      expect(approvedId, equals('vr_del_003'));
      expect(approvedName, equals('Suresh Kumar'));
    });
  });
}
