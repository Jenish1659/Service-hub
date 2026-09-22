import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/shopkeeper_profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_documents_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_contact_details_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_bank_details_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_screens_test');
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
  });

  group('Screen 7: ShopkeeperDocumentsScreen Tests', () {
    testWidgets('Renders header, document cards with verified/optional pills, security callout & upload button', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = ShopkeeperProfileController();
      controller.phone = '+91 98765 43210';
      controller.shopPhotos = ['local_shop_front.jpg'];
      controller.aadhaarNumber = 'XXXX-XXXX-9268';
      controller.panNumber = 'ABCDE1234F';
      controller.shopRegistrationNo = 'RJK/SHOP/2024/1587';
      controller.gstNumber = '';

      await tester.pumpWidget(
        MaterialApp(
          home: ShopkeeperDocumentsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header with Back button, 'Documents & Verification', subtitle 'Upload and manage your documents'
      expect(find.text('Documents & Verification'), findsOneWidget);
      expect(find.text('Upload and manage your documents'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // 2. Document cards with clean icons and green 'Verified ✓' pills
      // - Shop Photo (Verified ✓)
      expect(find.text('Shop Photo'), findsOneWidget);
      // - Owner ID Proof (Verified ✓)
      expect(find.text('Owner ID Proof'), findsOneWidget);
      // - Shop Registration (Verified ✓)
      expect(find.text('Shop Registration'), findsOneWidget);
      // - GST Certificate (Optional grey pill)
      expect(find.text('GST Certificate'), findsOneWidget);

      // Verify pill occurrences
      expect(find.text('Verified ✓'), findsNWidgets(3));
      expect(find.text('Optional'), findsOneWidget);

      // 3. Security callout: Lock icon: 'All documents are encrypted and secure with us.'
      expect(find.byIcon(Icons.lock_rounded), findsOneWidget);
      expect(find.text('All documents are encrypted and secure with us.'), findsOneWidget);

      // 4. 'Upload / Update' solid emerald button
      expect(find.text('Upload / Update'), findsOneWidget);

      // 5. Tap document card to view details
      await tester.tap(find.text('Shop Registration'));
      await tester.pumpAndSettle();
      expect(find.text('Shop & Establishment Certificate'), findsOneWidget);

      // Close bottom sheet
      await tester.tap(find.byType(ElevatedButton).last);
      await tester.pumpAndSettle();
    });

    testWidgets('Supports optional controller in constructor (null safe)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShopkeeperDocumentsScreen(),
        ),
      );
      await tester.pump();
      expect(find.text('Documents & Verification'), findsOneWidget);
    });
  });

  group('Screen 8: ShopkeeperContactDetailsScreen Tests', () {
    testWidgets('Renders contact details, pencil edit icons, and updates contact info via controller', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = ShopkeeperProfileController();
      controller.phone = '+91 98765 11111';
      controller.alternatePhone = '+91 98765 22222';
      controller.email = 'store@servicehub.com';
      controller.whatsappNumber = '+91 98765 33333';

      await tester.pumpWidget(
        MaterialApp(
          home: ShopkeeperContactDetailsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header with Back button, 'Contact Details', subtitle 'Manage your contact information'
      expect(find.text('Contact Details'), findsOneWidget);
      expect(find.text('Manage your contact information'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // 2. Detail cards with pencil edit icons
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('+91 98765 11111'), findsOneWidget);

      expect(find.text('Alternate Phone'), findsOneWidget);
      expect(find.text('+91 98765 22222'), findsOneWidget);

      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('store@servicehub.com'), findsOneWidget);

      expect(find.text('WhatsApp Number'), findsOneWidget);
      expect(find.text('+91 98765 33333'), findsOneWidget);

      // Pencil edit icons present
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(4));

      // 3. Tapping edit opens dialog/sheet to update contact values and calls updateContactDetails
      await tester.tap(find.byIcon(Icons.edit_outlined).first);
      await tester.pumpAndSettle();

      expect(find.text('Update Contact Details'), findsOneWidget);
      expect(find.text('Save Contact Details'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('Save Contact Details'));
      await tester.pumpAndSettle();

      expect(find.text('✓ Contact details updated successfully!'), findsOneWidget);
    });

    testWidgets('Supports optional controller in constructor (null safe)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShopkeeperContactDetailsScreen(),
        ),
      );
      await tester.pump();
      expect(find.text('Contact Details'), findsOneWidget);
    });
  });

  group('Screen 9: ShopkeeperBankDetailsScreen Tests', () {
    testWidgets('Renders bank details cards, masked account, and updates bank info via controller', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = ShopkeeperProfileController();
      controller.accountHolderName = 'Rajesh Kumar';
      controller.bankName = 'HDFC Bank';
      controller.accountNumber = '50100428914321';
      controller.ifscCode = 'HDFC0001234';
      controller.accountType = 'Savings Account';

      await tester.pumpWidget(
        MaterialApp(
          home: ShopkeeperBankDetailsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Header with Back button, 'Bank Details', subtitle 'For payouts and settlements'
      expect(find.text('Bank Details'), findsOneWidget);
      expect(find.text('For payouts and settlements'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

      // 2. Details cards:
      // Account Holder Name (_controller.accountHolderName)
      expect(find.text('Account Holder Name'), findsOneWidget);
      expect(find.text('Rajesh Kumar'), findsAtLeastNWidgets(1));

      // Bank Name (_controller.bankName)
      expect(find.text('Bank Name'), findsOneWidget);
      expect(find.text('HDFC Bank'), findsAtLeastNWidgets(1));

      // Account Number (masked _controller.accountNumber)
      expect(find.text('Account Number'), findsOneWidget);
      expect(find.text('•••• •••• 4321'), findsAtLeastNWidgets(1));

      // IFSC Code (_controller.ifscCode)
      expect(find.text('IFSC Code'), findsOneWidget);
      expect(find.text('HDFC0001234'), findsAtLeastNWidgets(1));

      // Account Type (_controller.accountType)
      expect(find.text('Account Type'), findsOneWidget);
      expect(find.text('Savings Account'), findsAtLeastNWidgets(1));

      // 3. 'Edit Bank Details' solid emerald button with dialog/modal to edit bank info
      expect(find.text('Edit Bank Details'), findsOneWidget);

      await tester.tap(find.text('Edit Bank Details'));
      await tester.pumpAndSettle();

      expect(find.text('Update Bank Details'), findsOneWidget);

      // Tap Save/Update
      await tester.tap(find.text('Update Bank Details'));
      await tester.pumpAndSettle();

      expect(find.text('✓ Bank details updated successfully for payouts!'), findsOneWidget);
    });

    testWidgets('Supports optional controller in constructor (null safe)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ShopkeeperBankDetailsScreen(),
        ),
      );
      await tester.pump();
      expect(find.text('Bank Details'), findsOneWidget);
    });
  });
}
