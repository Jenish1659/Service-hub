import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_personal_info_screen.dart';
import 'package:service_hub_partner/features/laundry_partner/presentation/screens/laundry_personal_info_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_personal_info_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_personal_info_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_personal_info_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_edit_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_edit_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'active_service_provider': '{"id":"test-1","name":"John Doe","phone":"9876543210","role":"care_taker"}',
      'active_delivery_agent': '{"id":"del-1","name":"Rider One","phone":"9876543210"}',
      'active_shopkeeper': '{"id":"shop-1","store_name":"Super Shop","phone":"9876543210"}',
    });
  });

  testWidgets('CarePersonalInfoScreen has Save Changes pinned in bottomNavigationBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CarePersonalInfoScreen()));
    await tester.pumpAndSettle();

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.bottomNavigationBar, isNotNull);

    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('LaundryPersonalInfoScreen has Save Changes pinned in bottomNavigationBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LaundryPersonalInfoScreen()));
    await tester.pumpAndSettle();

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.bottomNavigationBar, isNotNull);

    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('CookingPersonalInfoScreen has Save Changes pinned in bottomNavigationBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CookingPersonalInfoScreen()));
    await tester.pumpAndSettle();

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.bottomNavigationBar, isNotNull);

    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('CarPersonalInfoScreen has Save Changes pinned in bottomNavigationBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: CarPersonalInfoScreen()));
    await tester.pumpAndSettle();

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.bottomNavigationBar, isNotNull);

    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('PlumbingPersonalInfoScreen has Save Changes pinned in bottomNavigationBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: PlumbingPersonalInfoScreen()));
    await tester.pumpAndSettle();

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.bottomNavigationBar, isNotNull);

    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('DeliveryEditProfileScreen has Save Changes pinned in bottomNavigationBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: DeliveryEditProfileScreen()));
    await tester.pumpAndSettle();

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.bottomNavigationBar, isNotNull);

    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('ShopkeeperEditProfileScreen has Save Changes pinned in bottomNavigationBar', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ShopkeeperEditProfileScreen()));
    await tester.pumpAndSettle();

    final scaffoldFinder = find.byType(Scaffold);
    expect(scaffoldFinder, findsOneWidget);
    final scaffold = tester.widget<Scaffold>(scaffoldFinder);
    expect(scaffold.bottomNavigationBar, isNotNull);

    expect(find.text('Save Changes'), findsOneWidget);
  });
}
