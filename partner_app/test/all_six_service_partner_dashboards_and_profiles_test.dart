import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:service_hub_partner/core/routes/app_router.dart';
import 'package:service_hub_partner/features/ac_service_partner/presentation/screens/ac_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/ac_service_partner/presentation/screens/ac_partner_profile_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_partner_profile_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_partner_profile_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_partner_profile_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_partner_profile_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_partner_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync('hive_six_services_test');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('partner_cache')) {
      await Hive.openBox('partner_cache');
    }
  });

  group('All 6 Service Partner Dedicated Dashboards & Profiles Verification', () {
    testWidgets('1. ACPartnerDashboardScreen and ACPartnerProfileScreen render valid widget trees', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ACPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ACPartnerDashboardScreen), findsOneWidget);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ACPartnerProfileScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ACPartnerProfileScreen), findsOneWidget);
    });

    testWidgets('2. CarePartnerDashboardScreen and CarePartnerProfileScreen render valid widget trees', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarePartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CarePartnerDashboardScreen), findsOneWidget);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarePartnerProfileScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CarePartnerProfileScreen), findsOneWidget);
    });

    testWidgets('3. CookingPartnerDashboardScreen and CookingPartnerProfileScreen render valid widget trees', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CookingPartnerDashboardScreen), findsOneWidget);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingPartnerProfileScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CookingPartnerProfileScreen), findsOneWidget);
    });

    testWidgets('4. LaundryPartnerDashboardScreen and LaundryPartnerProfileScreen render valid widget trees', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LaundryPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(LaundryPartnerDashboardScreen), findsOneWidget);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LaundryPartnerProfileScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(LaundryPartnerProfileScreen), findsOneWidget);
    });

    testWidgets('5. CarPartnerDashboardScreen and CarPartnerProfileScreen render valid widget trees', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CarPartnerDashboardScreen), findsOneWidget);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarPartnerProfileScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CarPartnerProfileScreen), findsOneWidget);
    });

    testWidgets('6. PlumbingPartnerDashboardScreen and PlumbingPartnerProfileScreen render valid widget trees', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlumbingPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PlumbingPartnerDashboardScreen), findsOneWidget);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlumbingPartnerProfileScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(PlumbingPartnerProfileScreen), findsOneWidget);
    });

    test('7. AppRouter registers all 12 dedicated service routes without electrical', () {
      final routes = appRouter.configuration.routes;
      final paths = routes.whereType<GoRoute>().map((r) => r.path).toSet();

      expect(paths.contains('/dashboard/ac'), isTrue);
      expect(paths.contains('/dashboard/care-taker'), isTrue);
      expect(paths.contains('/dashboard/cooking'), isTrue);
      expect(paths.contains('/dashboard/laundry'), isTrue);
      expect(paths.contains('/dashboard/car-service'), isTrue);
      expect(paths.contains('/dashboard/plumbing'), isTrue);

      expect(paths.contains('/profile/ac'), isTrue);
      expect(paths.contains('/profile/care-taker'), isTrue);
      expect(paths.contains('/profile/cooking'), isTrue);
      expect(paths.contains('/profile/laundry'), isTrue);
      expect(paths.contains('/profile/car-service'), isTrue);
      expect(paths.contains('/profile/plumbing'), isTrue);

      // Verify zero electrical routes
      expect(paths.any((p) => p.contains('electrical')), isFalse);
    });
  });
}
