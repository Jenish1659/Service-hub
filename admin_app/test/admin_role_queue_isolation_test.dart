import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_admin/features/partners/presentation/admin_partners_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final candidates = [
    // Real-world candidate matching bheda_1 (shopkeeper with unpopulated/empty delivery profile keys)
    {
      'id': 'vr_shop_bheda',
      'verification_id': 'vr_shop_bheda',
      'user_id': '2987897d-7070-422e-bce9-008e6fb5c5b7',
      'partner_id': '446109aa-a7e9-4072-ac72-abdfd8013492',
      'name': 'Jenish Bheda',
      'full_name': 'Jenish Bheda',
      'phone': '7573021659',
      'role_name': 'shopkeeper',
      'role': 'shopkeeper',
      'category': 'shopkeeper',
      'category_name': 'Shopkeeper / Retail Store',
      'business_name': 'Bheda Electronics Store',
      'shop_name': 'Bheda Electronics Store',
      'shop_id': 'shop_123',
      'delivery_agent_id': '', // Empty string in DB join
      'vehicle_type': '',      // Empty string
      'vehicle_number': '',    // Empty string
      'driving_license_number': '',
      'status': 'PENDING',
      'verification_status': 'PENDING',
    },
    // Real-world candidate matching rrexpert_01 (service provider)
    {
      'id': 'vr_sp_rrexpert',
      'verification_id': 'vr_sp_rrexpert',
      'user_id': 'e1701cff-b9d6-4401-8fcc-af5a31bb5df3',
      'name': 'Rajesh Sharma',
      'full_name': 'Rajesh Sharma',
      'phone': '9876543210',
      'role_name': 'service_provider',
      'role': 'service_provider',
      'category': 'ac_service',
      'category_name': 'AC Service & Repair',
      'business_name': 'Rajesh AC Expert',
      'delivery_agent_id': '',
      'vehicle_type': '',
      'status': 'PENDING',
      'verification_status': 'PENDING',
    },
    // Real-world delivery agent candidate
    {
      'id': 'vr_del_rider1',
      'verification_id': 'vr_del_rider1',
      'user_id': '33333333-3333-3333-3333-333333333333',
      'name': 'Suresh Express Rider',
      'full_name': 'Suresh Express Rider',
      'phone': '9988776655',
      'role_name': 'delivery_agent',
      'role': 'delivery_agent',
      'category': 'delivery_agent',
      'category_name': 'Delivery Partner',
      'business_name': 'Suresh Fast Express',
      'delivery_agent_id': 'da_uuid_001',
      'vehicle_type': 'Motorcycle',
      'vehicle_number': 'GJ-10-AB-9999',
      'driving_license_number': 'DL-GJ10-2024-9999',
      'status': 'PENDING',
      'verification_status': 'PENDING',
    },
  ];

  group('Admin Queue Isolation & Cross-Contamination Prevention Tests', () {
    testWidgets('1. Shopkeeper queue displays ONLY shopkeepers and never leaks into delivery queue', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
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
              unverifiedPartners: candidates,
              onApprove: (id, name, [map]) {},
              onReject: (id, name, [map, reason]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Jenish Bheda (Shopkeeper) MUST be visible
      expect(find.text('Jenish Bheda'), findsOneWidget);
      expect(find.text('Shop Partner'), findsOneWidget);

      // Service Provider and Delivery Agent MUST NOT be visible in Shopkeeper queue
      expect(find.text('Rajesh Sharma'), findsNothing);
      expect(find.text('Suresh Express Rider'), findsNothing);
    });

    testWidgets('2. Delivery queue displays ONLY delivery agents and NEVER contains shopkeeper or provider', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
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
              unverifiedPartners: candidates,
              onApprove: (id, name, [map]) {},
              onReject: (id, name, [map, reason]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Suresh Rider MUST be visible
      expect(find.text('Suresh Express Rider'), findsOneWidget);
      expect(find.text('Delivery Partner'), findsOneWidget);

      // Shopkeeper with empty delivery keys MUST NOT cross-contaminate into delivery queue
      expect(find.text('Jenish Bheda'), findsNothing);
      // Service provider MUST NOT cross-contaminate into delivery queue
      expect(find.text('Rajesh Sharma'), findsNothing);
    });

    testWidgets('3. Service Provider queue displays ONLY service providers and NEVER contains shopkeeper or delivery', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
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
              unverifiedPartners: candidates,
              onApprove: (id, name, [map]) {},
              onReject: (id, name, [map, reason]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Rajesh Sharma MUST be visible
      expect(find.text('Rajesh Sharma'), findsOneWidget);
      expect(find.text('Approve & Activate'), findsOneWidget);
      expect(find.text('Partner Verification & KYC Queue'), findsOneWidget);

      // Shopkeeper and Delivery Agent MUST NOT be visible in Service Provider queue
      expect(find.text('Rajesh Sharma'), findsOneWidget);
      expect(find.text('Jenish Bheda'), findsNothing);
      expect(find.text('Suresh Express Rider'), findsNothing);
    });

    testWidgets('4. Complex edge case: Service Provider with "Store", "Enterprise", or "Delivery" in business name / category NEVER leaks into Shopkeeper or Delivery Agent queues', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final complexCandidates = [
        {
          'id': 'vr_laundry_sp',
          'verification_id': 'vr_laundry_sp',
          'user_id': 'user_laundry_99',
          'partner_id': 'part_laundry_99',
          'name': 'Rushi Laundry Express',
          'full_name': 'Rushi Laundry Express',
          'phone': '8460249346',
          'role_name': 'service_provider',
          'role': 'service_provider',
          'category': 'laundry',
          'category_name': 'Laundry Pickup & Delivery Services',
          'business_name': 'Rushi Enterprise Store & Laundry Service',
          'document_type': 'PROVIDER_ONBOARDING',
          'verification_type': 'AADHAAR',
          'status': 'PENDING',
        },
      ];

      // Test A: Shopkeeper queue MUST NOT show Rushi
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPartnersView(
              filterRole: 'shopkeeper',
              unverifiedPartners: complexCandidates,
              onApprove: (id, name, [map]) {},
              onReject: (id, name, [map, reason]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rushi Laundry Express'), findsNothing);

      // Test B: Delivery queue MUST NOT show Rushi
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPartnersView(
              filterRole: 'delivery_agent',
              unverifiedPartners: complexCandidates,
              onApprove: (id, name, [map]) {},
              onReject: (id, name, [map, reason]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rushi Laundry Express'), findsNothing);

      // Test C: Service Provider queue MUST show Rushi
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPartnersView(
              filterRole: 'service_provider',
              unverifiedPartners: complexCandidates,
              onApprove: (id, name, [map]) {},
              onReject: (id, name, [map, reason]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Rushi Laundry Express'), findsOneWidget);
    });
  });
}
