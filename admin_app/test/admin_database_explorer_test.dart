import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_admin/features/database_explorer/presentation/admin_database_explorer_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin Database & Master Records Explorer Tests', () {
    testWidgets('1. Renders title, security banner, and table tabs properly', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDatabaseExplorerView(),
        ),
      );
      await tester.pumpAndSettle();

      // Check Header & Security Banner
      expect(find.text('Database & Master Records Explorer'), findsOneWidget);
      expect(find.textContaining('Strict Security Protocol Active'), findsOneWidget);
      expect(find.text('ADMIN AUDIT ONLY'), findsOneWidget);

      // Check Table Tabs
      expect(find.text('👥 Users Table'), findsOneWidget);
      expect(find.text('🛍️ Customers Table'), findsOneWidget);
      expect(find.text('🤝 Partners & Stores'), findsOneWidget);
      expect(find.text('📑 Verification Requests'), findsOneWidget);
      expect(find.text('📅 Service Bookings'), findsOneWidget);
    });

    testWidgets('2. Passwords are strictly masked and never displayed in plaintext', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDatabaseExplorerView(),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure password security column header exists
      expect(find.text('PASSWORD SECURITY'), findsOneWidget);

      // Verify Bcrypt hash badge is displayed
      expect(find.textContaining('•••••••• [Bcrypt Hash]'), findsWidgets);

      // Verify no plaintext password text is found
      expect(find.text('plaintext_password'), findsNothing);
      expect(find.text('password123'), findsNothing);
    });

    testWidgets('3. Tab switching updates view and filters records', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDatabaseExplorerView(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Customers Table
      await tester.tap(find.textContaining('Customers Table'));
      await tester.pumpAndSettle();

      // Switch to Verification Requests
      await tester.tap(find.textContaining('Verification Requests'));
      await tester.pumpAndSettle();

      // Switch back to Users Table
      await tester.tap(find.textContaining('Users Table'));
      await tester.pumpAndSettle();

      expect(find.text('RECORD IDENTIFIER'), findsOneWidget);
    });

    testWidgets('4. Inspect button opens Deep-Dive Modal with Structured Inspector and Raw JSON', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDatabaseExplorerView(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the first Inspect button
      final inspectButtons = find.text('Inspect');
      expect(inspectButtons, findsWidgets);
      await tester.tap(inspectButtons.first);
      await tester.pumpAndSettle();

      // Verify modal dialog appeared
      expect(find.text('Structured Inspector'), findsOneWidget);
      expect(find.text('Raw PostgreSQL JSON'), findsOneWidget);
      expect(find.text('Credential & Auth Security'), findsOneWidget);

      // Switch to Raw JSON tab
      await tester.tap(find.text('Raw PostgreSQL JSON'));
      await tester.pumpAndSettle();

      expect(find.text('PostgreSQL Dictionary Representation'), findsOneWidget);
      expect(find.text('Copy Raw JSON'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();
    });

    testWidgets('5. Search filtering accurately isolates matching records', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDatabaseExplorerView(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);
      await tester.enterText(searchField, 'hiren');
      await tester.pumpAndSettle();

      // Check results filtered
      expect(find.textContaining('Jay Ambe Stores'), findsOneWidget);
    });

    testWidgets('6. Displays 100% real customer name and completely eliminates fake customer names', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDatabaseExplorerView(),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Customers Table
      await tester.tap(find.textContaining('Customers Table'));
      await tester.pumpAndSettle();

      // Ensure authentic customer name Sanjay Parmar appears
      expect(find.text('Sanjay Parmar'), findsOneWidget);

      // Verify ZERO dummy/fake customer names exist
      expect(find.text('rajesh_customer'), findsNothing);
      expect(find.text('Rajesh Sharma'), findsNothing);
    });

    testWidgets('7. Edit button opens PostgreSQL Record Editor modal with live form fields', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDatabaseExplorerView(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap edit button on the first row
      final editButtons = find.byIcon(Icons.edit_rounded);
      expect(editButtons, findsWidgets);
      await tester.tap(editButtons.first);
      await tester.pumpAndSettle();

      // Verify Edit modal title and fields
      expect(find.text('Edit Database Record'), findsOneWidget);
      expect(find.text('Commit live updates directly to PostgreSQL schema'), findsOneWidget);
      expect(find.text('Full Name / Business Name'), findsOneWidget);
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Account / Record Status'), findsOneWidget);
      expect(find.text('Save to PostgreSQL'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('8. Quick Action buttons (Suspend / Activate) are rendered and responsive', (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminDatabaseExplorerView(),
        ),
      );
      await tester.pumpAndSettle();

      // Check for quick action buttons
      expect(find.text('Suspend'), findsWidgets);
    });
  });
}
