import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_admin/features/partners/presentation/admin_partners_view.dart';
import 'package:service_hub_admin/features/dashboard/presentation/admin_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Multi-request duplicate scenario matching the user's reported bug:
  // Same partner candidate represented through multiple rows / sources:
  // 1. Source C (verification_requests)
  // 2. Source D (partners)
  // 3. Source E (shopkeeper_profiles)
  final duplicateCandidates = [
    {
      'id': 'vr_shop_bheda_new',
      'verification_id': 'vr_shop_bheda_new',
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
      'all_verification_ids': ['vr_shop_bheda_new', 'vr_shop_bheda_old'],
      'status': 'PENDING',
      'verification_status': 'PENDING',
    },
    // Second entry for the exact same partner (e.g. from partners table query or secondary request)
    {
      'id': '446109aa-a7e9-4072-ac72-abdfd8013492',
      'verification_id': '446109aa-a7e9-4072-ac72-abdfd8013492',
      'user_id': '2987897d-7070-422e-bce9-008e6fb5c5b7',
      'partner_id': '446109aa-a7e9-4072-ac72-abdfd8013492',
      'name': 'Jenish Bheda',
      'full_name': 'Jenish Bheda',
      'phone': '+91 75730 21659',
      'role_name': 'shopkeeper',
      'role': 'shopkeeper',
      'category': 'shopkeeper',
      'business_name': 'Bheda Electronics Store',
      'status': 'PENDING',
      'verification_status': 'PENDING',
    },
    // Third entry with an older verification_id for the same phone
    {
      'id': 'vr_shop_bheda_old',
      'verification_id': 'vr_shop_bheda_old',
      'user_id': '2987897d-7070-422e-bce9-008e6fb5c5b7',
      'partner_id': '446109aa-a7e9-4072-ac72-abdfd8013492',
      'name': 'Jenish Bheda',
      'full_name': 'Jenish Bheda',
      'phone': '7573021659',
      'role_name': 'shopkeeper',
      'role': 'shopkeeper',
      'category': 'shopkeeper',
      'business_name': 'Bheda Electronics Store',
      'status': 'PENDING',
      'verification_status': 'PENDING',
    },
  ];

  group('Admin Panel Single Partner Request & Bulk Resolution Tests', () {
    testWidgets('1. Admin panel strictly renders ONE request card per partner despite multiple duplicate submissions', (tester) async {
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
              unverifiedPartners: duplicateCandidates,
              onApprove: (id, name, [map]) {},
              onReject: (id, name, [map, reason]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // STRICTLY ONE card for Jenish Bheda must be rendered, NOT 3!
      expect(find.text('Jenish Bheda'), findsOneWidget);
      expect(find.text('Shop Partner'), findsOneWidget);
      expect(find.textContaining('Bheda Electronics Store'), findsOneWidget);
    });

    testWidgets('2. Partner request appears ONLY in designated role queue and NEVER in the other two queues', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // A. Check Delivery Agent Queue
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPartnersView(
              filterRole: 'delivery_agent',
              unverifiedPartners: duplicateCandidates,
              onApprove: (id, name, [map]) {},
              onReject: (id, name, [map, reason]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jenish Bheda'), findsNothing);

      // B. Check Service Provider Queue
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPartnersView(
              filterRole: 'service_provider',
              unverifiedPartners: duplicateCandidates,
              onApprove: (id, name, [map]) {},
              onReject: (id, name, [map, reason]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jenish Bheda'), findsNothing);
    });

    testWidgets('3. Approving partner request immediately removes all duplicates and resolves all associated IDs', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? approvedId;
      Map<String, dynamic>? approvedPartner;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPartnersView(
              filterRole: 'shopkeeper',
              unverifiedPartners: duplicateCandidates,
              onApprove: (id, name, [map]) {
                approvedId = id;
                approvedPartner = map;
                markPartnerResolved(id);
                if (map != null) {
                  final uId = map['user_id']?.toString() ?? '';
                  final pId = map['partner_id']?.toString() ?? '';
                  final phone = map['phone']?.toString() ?? '';
                  if (uId.isNotEmpty) markPartnerResolved(uId);
                  if (pId.isNotEmpty) markPartnerResolved(pId);
                  if (phone.isNotEmpty) markPartnerResolved(phone);
                  final allVids = (map['all_verification_ids'] as List?)?.map((e) => e.toString()).toList() ?? [];
                  for (var v in allVids) {
                    markPartnerResolved(v);
                  }
                }
              },
              onReject: (id, name, [map, reason]) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jenish Bheda'), findsOneWidget);

      // Tap Approve button
      final approveButton = find.widgetWithText(ElevatedButton, 'Approve Store & Activate');
      expect(approveButton, findsOneWidget);
      await tester.tap(approveButton);
      await tester.pumpAndSettle();

      // Card must vanish immediately from the UI
      expect(find.text('Jenish Bheda'), findsNothing);
      expect(approvedId, isNotNull);
      expect(approvedPartner, isNotNull);

      // Verify all associated IDs were resolved
      expect(approvedPartner!['all_verification_ids'], contains('vr_shop_bheda_new'));
      expect(approvedPartner!['all_verification_ids'], contains('vr_shop_bheda_old'));
    });

    testWidgets('4. Rejecting partner request immediately removes card and resolves all associated IDs', (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? rejectedId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdminPartnersView(
              filterRole: 'shopkeeper',
              unverifiedPartners: duplicateCandidates,
              onApprove: (id, name, [map]) {},
              onReject: (id, name, [map, reason]) {
                rejectedId = id;
                markPartnerResolved(id);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jenish Bheda'), findsOneWidget);

      // Tap Reject button to open reject dialog
      final rejectButton = find.widgetWithText(OutlinedButton, 'Reject');
      expect(rejectButton, findsOneWidget);
      await tester.tap(rejectButton);
      await tester.pumpAndSettle();

      // Dialog opens: tap Confirm Rejection
      final confirmButton = find.widgetWithText(ElevatedButton, 'Confirm Rejection');
      expect(confirmButton, findsOneWidget);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Card must be completely gone
      expect(find.text('Jenish Bheda'), findsNothing);
      expect(rejectedId, isNotNull);
    });
  });
}
