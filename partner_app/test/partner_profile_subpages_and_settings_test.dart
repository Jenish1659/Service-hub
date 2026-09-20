import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/availability_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/documents_and_verification_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/help_and_support_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/my_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/service_area_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileController controller;

  setUp(() {
    controller = ProfileController();
    controller.partnerName = 'Test Partner';
    controller.phoneNumber = '+91 98765 43210';
    controller.serviceCity = 'Jamnagar, Gujarat';
  });

  group('Partner Profile Subpages, Settings & Disambiguation Tests', () {
    testWidgets('1. SettingsScreen renders all 6 sections matching uploaded design', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      // Top Bar
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Manage your app preferences'), findsOneWidget);
      expect(find.text('4'), findsOneWidget); // Notification badge

      // Section 1: ACCOUNT
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('Login & Security'), findsOneWidget);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Phone & Email'), findsOneWidget);
      expect(find.text('Active Sessions'), findsOneWidget);

      // Section 2: NOTIFICATIONS
      expect(find.text('NOTIFICATIONS'), findsOneWidget);
      expect(find.text('Push Notifications'), findsOneWidget);
      expect(find.text('Booking Requests'), findsOneWidget);
      expect(find.text('Payment Updates'), findsOneWidget);
      expect(find.text('Service Reminders'), findsOneWidget);

      // Section 3: APP PREFERENCES
      expect(find.text('APP PREFERENCES'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('Light'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Location Services'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);

      // Section 4: PRIVACY & SECURITY
      expect(find.text('PRIVACY & SECURITY'), findsOneWidget);
      expect(find.text('Privacy Controls'), findsOneWidget);
      expect(find.text('Data & Permissions'), findsOneWidget);
      expect(find.text('Document Security'), findsOneWidget);

      // Section 5: SUPPORT
      expect(find.text('SUPPORT'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Report a Problem'), findsOneWidget);
      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('About ServiceHub'), findsOneWidget);

      // Section 6: ACCOUNT ACTIONS
      expect(find.text('ACCOUNT ACTIONS'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);

      // Footer
      expect(find.textContaining('ServiceHub'), findsWidgets);
      expect(find.text('Better Services, Brighter Tomorrows'), findsOneWidget);
    });

    testWidgets('2. ServiceAreaScreen is distinct from AvailabilityScreen and renders radius & area tools', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ServiceAreaScreen(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Service Area'), findsOneWidget);
      expect(find.text('Manage your working area and service radius'), findsOneWidget);
      expect(find.text('Primary Operating City'), findsOneWidget);
      expect(find.text('Service Radius'), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Preferred Localities'), findsOneWidget);
      expect(find.text('Save Service Area'), findsOneWidget);

      // Availability specifics must NOT exist here
      expect(find.text('Working Hours'), findsNothing);
      expect(find.text('Working Days'), findsNothing);
      expect(find.text('Break Time (Optional)'), findsNothing);
    });

    testWidgets('3. AvailabilityScreen is purely focused on working hours and days without service area card', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AvailabilityScreen(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Availability'), findsOneWidget);
      expect(find.text('Set your working hours and days'), findsOneWidget);
      expect(find.text('Working Hours'), findsOneWidget);
      expect(find.text('Working Days'), findsOneWidget);
      expect(find.text('Break Time (Optional)'), findsOneWidget);
      expect(find.text('Instant & Emergency Bookings'), findsOneWidget);

      // Service Area specifics must NOT exist in AvailabilityScreen
      expect(find.text('Primary Operating City'), findsNothing);
      expect(find.text('Preferred Localities'), findsNothing);
      expect(find.text('Save Service Area'), findsNothing);
    });

    testWidgets('4. DocumentsAndVerificationScreen renders verified KYC documents', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DocumentsAndVerificationScreen(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Documents & Verification'), findsOneWidget);
      expect(find.text('100% KYC Verified Partner'), findsOneWidget);
      expect(find.text('Aadhaar Card'), findsOneWidget);
      expect(find.text('PAN Card'), findsOneWidget);
      expect(find.text('Trade Skill Certification'), findsOneWidget);
      expect(find.text('Police & Background Clearance'), findsOneWidget);
      expect(find.text('PAYOUT BANKING INFORMATION'), findsOneWidget);
    });

    testWidgets('5. HelpAndSupportScreen renders 24/7 hotline, FAQs and query submission', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HelpAndSupportScreen(controller: controller),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Toll-Free Call'), findsOneWidget);
      expect(find.text('1800-123-SERVICE'), findsOneWidget);
      expect(find.text('WhatsApp Chat'), findsOneWidget);
      expect(find.text('Email Support'), findsOneWidget);
      expect(find.text('FREQUENTLY ASKED QUESTIONS'), findsOneWidget);
      expect(find.text('Submit Support Ticket'), findsOneWidget);
    });

    testWidgets('6. MyProfileScreen has separate navigation entries for all profile sub-pages', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MyProfileScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // All menu items must be present
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('My Services'), findsOneWidget);
      expect(find.text('Availability'), findsOneWidget);
      expect(find.text('Service Area'), findsOneWidget);
      expect(find.text('Documents & Verification'), findsOneWidget);
      expect(find.text('Earnings'), findsWidgets); // Present in menu & bottom bar
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });
  });
}
