import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/features/dashboard/presentation/widgets/delivery_recent_and_nav_widget.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/delivery_agent_profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_agent_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_settings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_earnings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_documents_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Delivery Profile Enhancements Tests', () {
    testWidgets('1. Header banner scrolls with content and bottom curved navbar is rendered', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = DeliveryAgentProfileController();
      controller.agentName = 'Rider Vikram';
      controller.isLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryAgentProfileScreen(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Header is inside SingleChildScrollView so it scrolls with page content
      final bannerFinder = find.text('Rider Profile');
      expect(bannerFinder, findsOneWidget);
      expect(
        find.ancestor(of: bannerFinder, matching: find.byType(SingleChildScrollView)),
        findsOneWidget,
      );

      // Bottom curved navigation bar is present
      final navBarFinder = find.byType(DeliveryBottomCurvedNavBar);
      expect(navBarFinder, findsOneWidget);

      final navBarWidget = tester.widget<DeliveryBottomCurvedNavBar>(navBarFinder);
      expect(navBarWidget.currentIndex, equals(4)); // Profile is active

      // Nav bar has Home, Orders, center Map, Earnings, Profile
      expect(find.descendant(of: navBarFinder, matching: find.text('Home')), findsOneWidget);
      expect(find.descendant(of: navBarFinder, matching: find.text('Orders')), findsOneWidget);
      expect(find.descendant(of: navBarFinder, matching: find.text('Map')), findsOneWidget);
      expect(find.descendant(of: navBarFinder, matching: find.text('Earnings')), findsOneWidget);
      expect(find.descendant(of: navBarFinder, matching: find.text('Profile')), findsOneWidget);
    });

    testWidgets('2. Settings -> Security tab renders Change Password and opens bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DeliverySettingsScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Switch to Security Tab
      final securityTabFinder = find.text('Security');
      expect(securityTabFinder, findsOneWidget);
      await tester.tap(securityTabFinder);
      await tester.pumpAndSettle();

      // Change Password tile should be visible
      final changePasswordTile = find.text('Change Password');
      expect(changePasswordTile, findsOneWidget);

      // Tap Change Password tile
      await tester.tap(changePasswordTile);
      await tester.pumpAndSettle();

      // Modal bottom sheet should appear with password fields
      expect(find.text('Update delivery partner portal security credentials'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Update & Synchronize Password'), findsOneWidget);
    });

    testWidgets('3. Earnings Screen has 0 baseline and no active incentives widgets', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryEarningsScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('₹0.00'), findsWidgets);
      expect(find.text('0 Completed Trips'), findsOneWidget);

      // Explicit user instruction: do not add active incentives
      expect(find.text('Active Incentives'), findsNothing);
      expect(find.text('Incentives'), findsNothing);
      expect(find.text('Peak Hour Incentives'), findsNothing);
    });

    testWidgets('4. Documents Screen updates and reactively re-renders', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = DeliveryAgentProfileController();
      controller.drivingLicenseNumber = 'GJ-03-2022-998811';

      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryDocumentsScreen(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Driving Licence'), findsOneWidget);
      expect(find.text('DL No: GJ-03-2022-998811'), findsOneWidget);

      // Tap Driving Licence card to open edit modal
      await tester.tap(find.text('Driving Licence'));
      await tester.pumpAndSettle();

      expect(find.text('Update Driving Licence'), findsOneWidget);
      expect(find.text('Save & Sync to Database'), findsOneWidget);
    });
  });
}
