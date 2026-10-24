import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_partner_profile_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_personal_info_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_store_map_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync('hive_laundry_map_test');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('partner_cache')) {
      await Hive.openBox('partner_cache');
    }
  });

  setUp(() {
    LiveBookingSyncService.instance.clearBookingsForTest();
  });

  group('Laundry Partner Dashboard Map, Profile Photo & Bug Fixes Verification', () {
    testWidgets('1. Dashboard renders 5-item bottom navbar with elevated cyan/sapphire center Map FAB', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LaundryPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LaundryPartnerDashboardScreen), findsOneWidget);

      // Verify all 5 navbar labels exist
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Orders'), findsOneWidget);
      expect(find.text('Map'), findsOneWidget);
      expect(find.text('Earnings'), findsWidgets);
      expect(find.text('Profile'), findsOneWidget);

      // Verify elevated center Map FAB key exists
      final centerMapButtonFinder = find.byKey(const Key('laundry_bottom_nav_center_map_button'));
      expect(centerMapButtonFinder, findsOneWidget);
      expect(find.descendant(of: centerMapButtonFinder, matching: find.byIcon(Icons.map_rounded)), findsOneWidget);
    });

    testWidgets('2. Tapping elevated center Map button switches to Map tab and mounts LaundryStoreMapScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LaundryPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap elevated center Map button
      await tester.tap(find.byKey(const Key('laundry_bottom_nav_center_map_button')));
      await tester.pumpAndSettle();

      // Verify LaundryStoreMapScreen is mounted
      expect(find.byType(LaundryStoreMapScreen), findsOneWidget);

      // Verify map controls exist: radius chips, zoom buttons, recenter
      expect(find.text('2 km (Express)'), findsOneWidget);
      expect(find.text('5 km (Standard)'), findsOneWidget);
      expect(find.text('10 km (Extended)'), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    });

    testWidgets('3. Tapping Earnings quick action card in Home tab navigates to Index 3 (Earnings)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LaundryPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap "Earnings" quick action card in Home tab
      await tester.tap(find.byKey(const Key('laundry_quick_action_Earnings')));
      await tester.pumpAndSettle();

      // Verify we arrived at Earnings tab (Index 3)
      expect(find.text('Total Earnings'), findsOneWidget);
      expect(find.text('Completed Orders'), findsOneWidget);
      expect(find.text('Avg. per Order'), findsOneWidget);
      expect(find.text('Earnings Breakdown'), findsOneWidget);
    });

    testWidgets('4. Profile Screen renders interactive avatar with camera badge and opens photo update bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LaundryPartnerProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify interactive avatar key and camera icon
      final avatarFinder = find.byKey(const Key('laundry_profile_avatar_tap'));
      expect(avatarFinder, findsOneWidget);
      expect(find.byIcon(Icons.camera_alt_rounded), findsOneWidget);

      // Tap avatar to open bottom sheet
      await tester.tap(avatarFinder);
      await tester.pumpAndSettle();

      // Verify modal bottom sheet content
      expect(find.text('Update Profile Photo'), findsOneWidget);
      expect(find.text('Choose how you would like to update your profile photo'), findsOneWidget);
      expect(find.text('Take Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);
      expect(find.text('Choose Laundry Avatar'), findsOneWidget);

      // Tap "Take Photo"
      await tester.tap(find.text('Take Photo'));
      await tester.pumpAndSettle();

      // Verify floating bottom SnackBar message
      expect(find.text('Camera opened. Profile photo updated!'), findsOneWidget);
    });

    testWidgets('5. LaundryPersonalInfoScreen supports photo update with bottom sheet and feedback SnackBar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LaundryPersonalInfoScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LaundryPersonalInfoScreen), findsOneWidget);

      // Verify "Change Photo" button
      final changePhotoBtnFinder = find.byKey(const Key('laundry_personal_info_change_photo_btn'));
      expect(changePhotoBtnFinder, findsOneWidget);

      // Tap "Change Photo" button
      await tester.tap(changePhotoBtnFinder);
      await tester.pumpAndSettle();

      // Verify bottom sheet appears
      expect(find.text('Update Profile Photo'), findsOneWidget);
      expect(find.text('Choose from Gallery'), findsOneWidget);

      // Tap "Choose from Gallery"
      await tester.tap(find.text('Choose from Gallery'));
      await tester.pumpAndSettle();

      // Verify feedback SnackBar
      expect(find.text('Photo selected from gallery and updated!'), findsOneWidget);
    });

    testWidgets('6. LaundryStoreMapModal.show opens the OSM map bottom modal sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => Center(
                child: ElevatedButton(
                  onPressed: () => LaundryStoreMapModal.show(ctx),
                  child: const Text('Open Laundry Map Modal'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap open modal button
      await tester.tap(find.text('Open Laundry Map Modal'));
      await tester.pumpAndSettle();

      // Verify modal sheet with LaundryStoreMapScreen rendered
      expect(find.byType(LaundryStoreMapScreen), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}
