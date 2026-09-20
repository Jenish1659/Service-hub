import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/about_service_hub_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/active_sessions_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/change_password_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/data_and_permissions_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delete_account_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/help_and_support_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/login_and_security_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/phone_and_email_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/privacy_controls_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/report_a_problem_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/settings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/terms_and_conditions_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProfileController controller;

  setUp(() {
    controller = ProfileController();
    controller.partnerName = 'Test Partner';
    controller.phoneNumber = '+91 98765 43210';
    controller.emailAddress = 'testpartner@servicehub.in';
    controller.serviceCity = 'Jamnagar, Gujarat';
  });

  group('Partner Settings Dedicated Sub-Pages Verification', () {
    testWidgets('1. LoginAndSecurityScreen renders 2FA, biometrics, credentials & session log', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginAndSecurityScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Login & Security'), findsOneWidget);
      expect(find.text('Two-Factor Authentication'), findsOneWidget);
      expect(find.text('Biometric Authentication'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Mobile Number'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('RECENT SECURITY ACTIVITY'), findsOneWidget);
    });

    testWidgets('2. ChangePasswordScreen renders inputs and live strength indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangePasswordScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('CURRENT PASSWORD'), findsOneWidget);
      expect(find.text('NEW PASSWORD'), findsOneWidget);
      expect(find.text('CONFIRM NEW PASSWORD'), findsOneWidget);
      expect(find.text('Save New Password'), findsOneWidget);
      expect(find.text('Minimum 8 characters long'), findsOneWidget);
    });

    testWidgets('3. PhoneAndEmailScreen renders primary phone, email and emergency contact', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PhoneAndEmailScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Phone & Email'), findsOneWidget);
      expect(find.text('Primary Mobile Number'), findsOneWidget);
      expect(find.text('Primary Email Address'), findsOneWidget);
      expect(find.text('Emergency Backup Contact'), findsOneWidget);
      expect(find.text('Save Contact Details'), findsOneWidget);
    });

    testWidgets('4. ActiveSessionsScreen renders current active session and logout options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ActiveSessionsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Active Sessions'), findsOneWidget);
      expect(find.text('CURRENT ACTIVE DEVICE'), findsOneWidget);
      expect(find.text('Active Now'), findsOneWidget);
      expect(find.text('Log Out All Other Devices'), findsOneWidget);
    });

    testWidgets('5. PrivacyControlsScreen renders phone masking and privacy toggles', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PrivacyControlsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy Controls'), findsOneWidget);
      expect(find.text('Phone Number Masking'), findsOneWidget);
      expect(find.text('Precise Location Protection'), findsOneWidget);
      expect(find.text('Completed Job Privacy'), findsOneWidget);
    });

    testWidgets('6. DataAndPermissionsScreen renders permission items and cache clearer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DataAndPermissionsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Data & Permissions'), findsOneWidget);
      expect(find.text('DEVICE PERMISSIONS STATUS'), findsOneWidget);
      expect(find.text('Clear Cache & Temp Files'), findsOneWidget);
      expect(find.text('Request Data Archive'), findsOneWidget);
    });

    testWidgets('7. ReportAProblemScreen is distinct from HelpAndSupportScreen and captures bug tickets', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ReportAProblemScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Report a Problem'), findsOneWidget);
      expect(find.text('PROBLEM CATEGORY'), findsOneWidget);
      expect(find.text('App Glitch / Crash'), findsOneWidget);
      expect(find.text('SEVERITY LEVEL'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('Critical'), findsOneWidget);
      expect(find.text('Submit Problem Ticket'), findsOneWidget);

      // Help & Support specifics must NOT appear in ReportAProblemScreen
      expect(find.text('Toll-Free Call'), findsNothing);
      expect(find.text('1800-123-SERVICE'), findsNothing);
      expect(find.text('FREQUENTLY ASKED QUESTIONS'), findsNothing);
    });

    testWidgets('8. TermsAndConditionsScreen renders comprehensive legal clauses', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TermsAndConditionsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('ServiceHub Partner Agreement • Version 2026.1'), findsOneWidget);
      expect(find.text('Partner Relationship & Eligibility'), findsOneWidget);
      expect(find.text('Service Standards & Safety Conduct'), findsOneWidget);
      expect(find.text('Transparent Pricing & Direct Payouts'), findsOneWidget);
    });

    testWidgets('9. PrivacyPolicyScreen renders data privacy and 256-bit encryption disclosures', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: PrivacyPolicyScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Your Privacy is Sacred'), findsOneWidget);
      expect(find.text('Information We Collect'), findsOneWidget);
      expect(find.text('Financial Data & AES-256 Encryption'), findsOneWidget);
      expect(find.text('ISO 27001 Certified & RBI Compliant Storage'), findsOneWidget);
    });

    testWidgets('10. AboutServiceHubScreen renders version 1.0.0, build metrics and licenses', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: AboutServiceHubScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('About ServiceHub'), findsOneWidget);
      expect(find.text('ServiceHub Partner'), findsOneWidget);
      expect(find.text('v1.0.0 (Build 100) • Production'), findsOneWidget);
      expect(find.text('SYSTEM & BUILD METRICS'), findsOneWidget);
      expect(find.text('Our Mission'), findsOneWidget);
      expect(find.text('Open Source Software Licenses'), findsOneWidget);
    });

    testWidgets('11. DeleteAccountScreen renders questionnaire with exit reasons and deletion challenge', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DeleteAccountScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsOneWidget);
      expect(find.text('This action is irreversible'), findsOneWidget);
      expect(find.text('PLEASE TELL US WHY YOU ARE LEAVING'), findsOneWidget);
      expect(find.text('Not getting enough booking requests in my area'), findsOneWidget);
      expect(find.text('Payouts or earnings are lower than expected'), findsOneWidget);
      expect(find.text('Moving to another city or changing profession'), findsOneWidget);
      expect(find.text('REQUIRED CONFIRMATIONS'), findsOneWidget);
      expect(find.text('CONFIRMATION CHALLENGE'), findsOneWidget);
      expect(find.text('Permanently Delete My Account'), findsOneWidget);

      // Verify selecting a different reason
      await tester.tap(find.text('Moving to another city or changing profession'));
      await tester.pumpAndSettle();
    });

    testWidgets('12. SettingsScreen navigation opens dedicated sub-pages instead of placeholder dialogs', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: SettingsScreen(controller: controller),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure Report a Problem is visible and tap it
      await tester.ensureVisible(find.text('Report a Problem'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Report a Problem'));
      await tester.pumpAndSettle();

      // Verify ReportAProblemScreen opened (not HelpAndSupportScreen)
      expect(find.text('Submit Problem Ticket'), findsOneWidget);
      expect(find.text('PROBLEM CATEGORY'), findsOneWidget);

      // Pop back using the back icon
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      // Ensure Delete Account is visible and tap it
      await tester.ensureVisible(find.text('Delete Account'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Verify DeleteAccountScreen opened with exit survey (not a fake popup dialog)
      expect(find.text('PLEASE TELL US WHY YOU ARE LEAVING'), findsOneWidget);
      expect(find.text('Permanently Delete My Account'), findsOneWidget);
    });
  });
}
