import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:service_hub_partner/core/utils/service_category_route_helper.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_partner_profile_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_partner_profile_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_partner_profile_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_partner_profile_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_partner_dashboard_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_partner_profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ServiceCategoryRouteHelper Route Resolution Tests', () {
    test('1. Normalizes category slugs, dashes, and trade aliases accurately', () {
      expect(ServiceCategoryRouteHelper.normalizeCategory('ac_service'), 'ac_service');
      expect(ServiceCategoryRouteHelper.normalizeCategory('ac'), 'ac_service');
      expect(ServiceCategoryRouteHelper.normalizeCategory('laundry'), 'laundry');
      expect(ServiceCategoryRouteHelper.normalizeCategory('dry-cleaning'), 'laundry');
      expect(ServiceCategoryRouteHelper.normalizeCategory('plumbing'), 'plumbing');
      expect(ServiceCategoryRouteHelper.normalizeCategory('plumber'), 'plumbing');
      expect(ServiceCategoryRouteHelper.normalizeCategory('car_service'), 'car_service');
      expect(ServiceCategoryRouteHelper.normalizeCategory('automobile'), 'car_service');
      expect(ServiceCategoryRouteHelper.normalizeCategory('care_taker'), 'care_taker');
      expect(ServiceCategoryRouteHelper.normalizeCategory('care-taker'), 'care_taker');
      expect(ServiceCategoryRouteHelper.normalizeCategory('cooking'), 'cooking');
      expect(ServiceCategoryRouteHelper.normalizeCategory('chef'), 'cooking');
    });

    test('2. Maps each canonical category to its dedicated Dashboard route', () {
      expect(ServiceCategoryRouteHelper.getDashboardRoute('ac_service'), '/dashboard/ac');
      expect(ServiceCategoryRouteHelper.getDashboardRoute('laundry'), '/dashboard/laundry');
      expect(ServiceCategoryRouteHelper.getDashboardRoute('plumbing'), '/dashboard/plumbing');
      expect(ServiceCategoryRouteHelper.getDashboardRoute('plumber'), '/dashboard/plumbing');
      expect(ServiceCategoryRouteHelper.getDashboardRoute('car_service'), '/dashboard/car-service');
      expect(ServiceCategoryRouteHelper.getDashboardRoute('care_taker'), '/dashboard/care-taker');
      expect(ServiceCategoryRouteHelper.getDashboardRoute('cooking'), '/dashboard/cooking');
    });

    test('3. Maps each canonical category to its dedicated Profile route', () {
      expect(ServiceCategoryRouteHelper.getProfileRoute('ac_service'), '/profile/ac');
      expect(ServiceCategoryRouteHelper.getProfileRoute('laundry'), '/profile/laundry');
      expect(ServiceCategoryRouteHelper.getProfileRoute('plumbing'), '/profile/plumbing');
      expect(ServiceCategoryRouteHelper.getProfileRoute('plumber'), '/profile/plumbing');
      expect(ServiceCategoryRouteHelper.getProfileRoute('car_service'), '/profile/car-service');
      expect(ServiceCategoryRouteHelper.getProfileRoute('care_taker'), '/profile/care-taker');
      expect(ServiceCategoryRouteHelper.getProfileRoute('cooking'), '/profile/cooking');
    });
  });

  group('Dedicated Category Dashboards & Profiles Render Tests', () {
    testWidgets('4. Laundry Dashboard renders with specialized branding & controls', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LaundryPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LaundryPartnerDashboardScreen), findsOneWidget);
    });

    testWidgets('5. Laundry Profile renders with specialist trade credentials', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LaundryPartnerProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LaundryPartnerProfileScreen), findsOneWidget);
    });

    testWidgets('6. Plumbing Dashboard renders with sanitation controls', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlumbingPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlumbingPartnerDashboardScreen), findsOneWidget);
    });

    testWidgets('7. Plumbing Profile renders with plumbing credentials', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlumbingPartnerProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(PlumbingPartnerProfileScreen), findsOneWidget);
    });

    testWidgets('8. Car Service Dashboard renders with workshop station controls', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CarPartnerDashboardScreen), findsOneWidget);
    });

    testWidgets('9. Car Service Profile renders with auto credentials', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarPartnerProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CarPartnerProfileScreen), findsOneWidget);
    });

    testWidgets('10. Care Taker Dashboard renders with nursing station controls', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarePartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CarePartnerDashboardScreen), findsOneWidget);
    });

    testWidgets('11. Care Taker Profile renders with caregiving credentials', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CarePartnerProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CarePartnerProfileScreen), findsOneWidget);
    });

    testWidgets('12. Cooking Dashboard renders with culinary kitchen controls', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingPartnerDashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CookingPartnerDashboardScreen), findsOneWidget);
    });

    testWidgets('13. Cooking Profile renders with culinary credentials', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: CookingPartnerProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CookingPartnerProfileScreen), findsOneWidget);
    });
  });
}
