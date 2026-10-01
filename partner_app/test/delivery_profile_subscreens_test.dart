import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/delivery_agent_profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_agent_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_edit_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_availability_shift_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_area_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_documents_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_earnings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_settings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_help_support_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Delivery Agent Profile 16-Screen System Tests', () {
    testWidgets('1. Main Profile Screen renders all 7 menu items and profile hero', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = DeliveryAgentProfileController();
      controller.agentName = 'Rider Ram';
      controller.isLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryAgentProfileScreen(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      // Brand Header & Profile Hero
      expect(find.text('ServiceHub DELIVERY PARTNER'), findsOneWidget);
      expect(find.text('Rider Profile'), findsOneWidget);
      expect(find.text('Rider Ram'), findsOneWidget);
      expect(find.text('Verified Rider ✓'), findsOneWidget);

      // The 7 Menu Items
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Availability & Shift'), findsOneWidget);
      expect(find.text('Delivery Area'), findsOneWidget);
      expect(find.text('Vehicle & Driving Documents'), findsOneWidget);
      expect(find.text('Earnings & Payouts'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);

      // Sign Out Action
      expect(find.text('Sign Out from Partner Portal'), findsOneWidget);
    });

    testWidgets('2. Edit Profile Screen renders input fields and save button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = DeliveryAgentProfileController();
      controller.agentName = 'Rider Ram';
      controller.phone = '+91 98765 43210';
      controller.email = 'rider.ram@servicehub.in';

      await tester.pumpWidget(
        MaterialApp(
          home: DeliveryEditProfileScreen(controller: controller),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('3. Availability & Shift Screen renders hours and Mon-Sun chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryAvailabilityShiftScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Availability & Shift'), findsOneWidget);
      expect(find.text('Currently Available'), findsOneWidget);
      expect(find.text("Today's Shift"), findsOneWidget);
      expect(find.text('09:00 AM – 08:00 PM'), findsOneWidget);
      expect(find.text('Working Days'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expect(find.text('Sun'), findsOneWidget);
      expect(find.text('Auto Offline After Shift'), findsOneWidget);
    });

    testWidgets('4. Delivery Area Screen renders radius chips and zones', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryAreaScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Delivery Area'), findsOneWidget);
      expect(find.text('Jamnagar, Gujarat'), findsOneWidget);
      expect(find.text('Service Radius'), findsOneWidget);
      expect(find.text('5 km'), findsOneWidget);
      expect(find.text('10 km'), findsNWidgets(2)); // Selected display and chip
      expect(find.text('15 km'), findsOneWidget);
      expect(find.text('40 km'), findsOneWidget);
      expect(find.text('Preferred Areas'), findsOneWidget);
      expect(find.text('Patel Colony'), findsOneWidget);
    });

    testWidgets('5. Documents Screen renders KYC status and document checklist', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryDocumentsScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Documents & Verification'), findsOneWidget);
      expect(find.text('100% KYC Verified'), findsOneWidget);
      expect(find.text('Aadhaar Card'), findsOneWidget);
      expect(find.text('PAN Card'), findsOneWidget);
      expect(find.text('Driving Licence'), findsOneWidget);
      expect(find.text('Vehicle RC'), findsOneWidget);
      expect(find.text('Bank Account'), findsOneWidget);
      expect(find.text('UPI ID'), findsOneWidget);
    });

    testWidgets('6. Earnings Screen strictly starts at 0 and renders tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
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

      expect(find.text('Earnings & Payouts'), findsOneWidget);
      expect(find.text('₹0.00'), findsNWidgets(6)); // Hero, Delivery Fare, Tips, Incentives, Adjustments, Net Settlement
      expect(find.text('0 Completed Trips'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('EARNINGS BREAKDOWN'), findsOneWidget);
      expect(find.text('Net Settlement Balance'), findsOneWidget);
    });

    testWidgets('7. Settings Screen renders General, Security, and Alerts tabs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
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

      expect(find.text('Settings & Security'), findsOneWidget);
      expect(find.text('General'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Alerts'), findsOneWidget);
      expect(find.text('App Language'), findsOneWidget);
      expect(find.text('Clear App Cache'), findsOneWidget);
      expect(find.text('Delete Delivery Account'), findsOneWidget);
    });

    testWidgets('8. Help & Support Screen renders emergency SOS banner and FAQs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: DeliveryHelpSupportScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Emergency Rider SOS'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
      expect(find.text('Rider Helpline'), findsOneWidget);
      expect(find.text('WhatsApp Chat'), findsOneWidget);
      expect(find.text('FREQUENTLY ASKED QUESTIONS'), findsOneWidget);
    });
  });
}
