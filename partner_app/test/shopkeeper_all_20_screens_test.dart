import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/shopkeeper_profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_edit_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_info_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_business_hours_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_service_area_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_photos_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_documents_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_contact_details_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_bank_details_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_settings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_account_security_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_notification_settings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_app_preferences_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_privacy_permissions_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_change_password_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_active_sessions_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_delete_account_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_help_support_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_about_screen.dart';
import 'package:service_hub_partner/core/services/media_document_picker_service.dart';

import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ShopkeeperProfileController controller;
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_all_screens_test');
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
  });

  setUp(() {
    controller = ShopkeeperProfileController();
    controller.shopName = 'Apex Retail World';
    controller.ownerName = 'Jenish Bheda';
    controller.category = 'AC & Appliances';
    controller.phone = '9876543210';
    controller.email = 'shop@apex.com';
    controller.isVerified = true;
    controller.isLoading = false;
  });

  tearDownAll(() async {
    try {
      await Hive.close();
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('Shopkeeper 20-Screen Architecture Verification', () {
    test('Zero-State Metric Integrity: Shopkeeper metrics start at 0 and shop photos start empty', () {
      final initialController = ShopkeeperProfileController();
      expect(initialController.activeProductsCount, equals(0));
      expect(initialController.ordersProcessedCount, equals(0));
      expect(initialController.totalStoreRevenue, equals(0.0));
      expect(initialController.rating, equals(0.0));
      expect(initialController.reviewCount, equals(0));
      expect(initialController.shopPhotos, isEmpty);
    });

    testWidgets('Screen 1: ShopkeeperProfileScreen renders header, zero-state rating and 8 cards', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperProfileScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Shop Profile'), findsOneWidget);
      expect(find.text('Apex Retail World'), findsOneWidget);
      expect(find.text('Verified Shop'), findsOneWidget);
      expect(find.text('New Store'), findsOneWidget);
      expect(find.text('Keep your profile updated'), findsOneWidget);
      expect(find.text('Shop Information'), findsOneWidget);
      expect(find.text('Business Hours'), findsOneWidget);
      expect(find.text('Service Area'), findsOneWidget);
      expect(find.text('Shop Photos'), findsOneWidget);
      expect(find.text('Documents & Verification'), findsOneWidget);
      expect(find.text('Contact Details'), findsOneWidget);
      expect(find.text('Bank Details'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Screen 2: ShopkeeperEditProfileScreen renders form fields and save button', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperEditProfileScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Edit Shop Profile'), findsOneWidget);
      expect(find.text('Update your shop details'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Screen 3: ShopkeeperInfoScreen renders store particulars', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperInfoScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Shop Information'), findsOneWidget);
      expect(find.text('View and manage your shop details'), findsOneWidget);
      expect(find.text('Edit Information'), findsOneWidget);
    });

    testWidgets('Screen 4: ShopkeeperBusinessHoursScreen renders hours & open toggle', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperBusinessHoursScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Business Hours'), findsOneWidget);
      expect(find.text('Set your working hours'), findsOneWidget);
      expect(find.text('Save Hours'), findsOneWidget);
    });

    testWidgets('Screen 5: ShopkeeperServiceAreaScreen renders map card and radius slider', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperServiceAreaScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Service Area'), findsOneWidget);
      expect(find.text('Manage your delivery area'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('Screen 6: ShopkeeperPhotosScreen renders hero banner and add photo card with clean zero-state', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperPhotosScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Shop Photos'), findsOneWidget);
      expect(find.text('Showcase your shop'), findsOneWidget);
      expect(find.text('+ Add Photo'), findsOneWidget);
      expect(find.text('0 / 10 Photos'), findsOneWidget);
      expect(controller.shopPhotos, isEmpty);
    });

    testWidgets('Screen 7: ShopkeeperDocumentsScreen renders verified document badges', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperDocumentsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Documents & Verification'), findsOneWidget);
      expect(find.text('Upload / Update'), findsOneWidget);
    });

    testWidgets('Screen 8: ShopkeeperContactDetailsScreen renders phone, email, whatsapp', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperContactDetailsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Contact Details'), findsOneWidget);
      expect(find.text('9876543210'), findsOneWidget);
      expect(find.text('shop@apex.com'), findsOneWidget);
    });

    testWidgets('Screen 9: ShopkeeperBankDetailsScreen renders zero-state and populated state properly', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperBankDetailsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Bank Details'), findsOneWidget);
      expect(find.text('No Bank Account Linked'), findsOneWidget);
      expect(find.text('Add Bank Details'), findsWidgets);

      // Populated state
      controller.accountNumber = '50100428912345';
      controller.bankName = 'HDFC Bank';
      await tester.pumpWidget(MaterialApp(home: ShopkeeperBankDetailsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Edit Bank Details'), findsOneWidget);
    });

    testWidgets('Screens 10 & 18: ShopkeeperSettingsScreen renders settings menu and red sign out button', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperSettingsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Account & Security'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets('Screen 11: ShopkeeperAccountSecurityScreen renders security options and delete CTA', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperAccountSecurityScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Account & Security'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('Screen 12: ShopkeeperNotificationSettingsScreen renders notification switches', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperNotificationSettingsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Notification Settings'), findsOneWidget);
      expect(find.text('Order Notifications'), findsOneWidget);
    });

    testWidgets('Screen 13: ShopkeeperAppPreferencesScreen renders theme and localization options', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperAppPreferencesScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('App Preferences'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('Screen 14: ShopkeeperPrivacyPermissionsScreen renders privacy choices', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ShopkeeperPrivacyPermissionsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Privacy & Permissions'), findsOneWidget);
    });

    testWidgets('Screen 15: ShopkeeperChangePasswordScreen renders password inputs and update action', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperChangePasswordScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
    });

    testWidgets('Screen 16: ShopkeeperActiveSessionsScreen renders active device sessions', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperActiveSessionsScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Active Sessions'), findsOneWidget);
    });

    testWidgets('Screen 17: ShopkeeperDeleteAccountScreen renders critical warnings and red delete action', (tester) async {
      await tester.pumpWidget(MaterialApp(home: ShopkeeperDeleteAccountScreen(controller: controller)));
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsNWidgets(2));
      expect(find.text('Permanent Account Closure'), findsOneWidget);
    });

    testWidgets('Screen 19: ShopkeeperHelpSupportScreen renders support contacts and FAQs', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ShopkeeperHelpSupportScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
    });

    testWidgets('Screen 20: ShopkeeperAboutScreen renders app version and branding', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ShopkeeperAboutScreen()));
      await tester.pumpAndSettle();

      expect(find.text('About ServiceHub'), findsOneWidget);
      expect(find.text('ServiceHub Shop Partner'), findsOneWidget);
    });

    test('MediaDocumentPickerService Supabase upload pipeline falls back safely to local path if offline or uninitialized', () async {
      final tempFile = File('${tempDir.path}/test_upload.jpg');
      await tempFile.writeAsBytes([1, 2, 3, 4]);

      final result = await MediaDocumentPickerService.instance.uploadImageToSupabase(
        file: tempFile,
        bucket: 'partner_documents',
        path: 'test/test_upload.jpg',
      );

      expect(result, equals(tempFile.path));
    });
  });
}
