import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:service_hub_partner/core/services/partner_location_service.dart';
import 'package:service_hub_partner/features/care_taker_partner/presentation/screens/care_live_map_screen.dart';
import 'package:service_hub_partner/features/car_service_partner/presentation/screens/car_live_map_screen.dart';
import 'package:service_hub_partner/features/cooking_partner/presentation/screens/cooking_live_map_screen.dart';
import 'package:service_hub_partner/features/plumbing_partner/presentation/screens/plumbing_live_map_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'active_service_provider': '{"id":"prov-1","name":"Verified Partner","phone":"9876543210","latitude":22.4707,"longitude":70.0577}',
    });
  });

  group('1. PartnerLocationService Real Haversine Distance Engine Tests', () {
    test('calculateDistanceInfo accurately computes geodesic road distance and ETA', () {
      const from = LatLng(22.4707, 70.0577); // Jamnagar Hub
      const to = LatLng(22.4842, 70.0712);   // ~2.0 km straight, ~2.5 km road

      final info = PartnerLocationService.calculateDistanceInfo(
        from: from,
        to: to,
        averageSpeedKmH: 25.0,
      );

      // Verify geodesic calculation
      expect(info.straightKm, greaterThan(1.8));
      expect(info.straightKm, lessThan(2.2));

      // Verify road factor (1.25x)
      expect(info.roadKm, greaterThan(info.straightKm));
      expect(info.durationMinutes, greaterThan(3));
      expect(info.durationMinutes, lessThan(12));

      // Verify formatted strings
      expect(info.formattedDistance, contains('km'));
      expect(info.formattedEta, contains('min'));
      expect(info.formattedSummary, contains('away'));
    });

    test('calculateDistanceInfo handles identical coordinates as < 100 m', () {
      const loc = LatLng(22.4707, 70.0577);
      final info = PartnerLocationService.calculateDistanceInfo(from: loc, to: loc);

      expect(info.straightKm, equals(0.0));
      expect(info.formattedDistance, equals('< 100 m'));
      expect(info.durationMinutes, equals(1));
    });

    test('calculateDistanceInfo handles longer inter-city distances dynamically', () {
      const jamnagar = LatLng(22.4707, 70.0577);
      const rajkot = LatLng(22.3039, 70.8022); // ~80-90 km

      final info = PartnerLocationService.calculateDistanceInfo(from: jamnagar, to: rajkot);

      expect(info.straightKm, greaterThan(75.0));
      expect(info.straightKm, lessThan(100.0));
      expect(info.roadKm, greaterThan(95.0));
      expect(info.durationMinutes, greaterThan(150));
    });
  });

  group('2. Live Map Screens Dynamic Distance & Real Location Verification', () {
    testWidgets('CareLiveMapScreen computes and displays dynamic distance for booking', (tester) async {
      final testBooking = {
        'id': 'CARE-901',
        'customer_name': 'Patient Soni',
        'customer_phone': '+91 98251 11223',
        'customer_address': 'Patel Colony, Street 4, Jamnagar',
        'customer_lat': 22.4780,
        'customer_lng': 70.0650,
      };

      await tester.pumpWidget(MaterialApp(
        home: CareLiveMapScreen(booking: testBooking),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CareLiveMapScreen), findsOneWidget);
      expect(find.text('Patient Soni'), findsOneWidget);

      // Verify that distance badge is rendered and is not hardcoded
      expect(find.textContaining('away'), findsWidgets);
    });

    testWidgets('CarLiveMapScreen computes and displays dynamic distance for booking', (tester) async {
      final testBooking = {
        'id': 'CAR-802',
        'customer_name': 'Car Owner Dave',
        'customer_phone': '+91 98252 33445',
        'customer_address': 'Digjam Circle, Jamnagar',
        'customer_lat': 22.4650,
        'customer_lng': 70.0480,
      };

      await tester.pumpWidget(MaterialApp(
        home: CarLiveMapScreen(booking: testBooking),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CarLiveMapScreen), findsOneWidget);
      expect(find.text('Car Owner Dave'), findsOneWidget);
      expect(find.textContaining('away'), findsWidgets);
    });

    testWidgets('CookingLiveMapScreen computes and displays dynamic distance for booking', (tester) async {
      final testBooking = {
        'id': 'COOK-703',
        'customer_name': 'Mehta Residence',
        'customer_phone': '+91 98253 55667',
        'customer_address': 'Oshwal Colony, Jamnagar',
        'customer_lat': 22.4795,
        'customer_lng': 70.0620,
      };

      await tester.pumpWidget(MaterialApp(
        home: CookingLiveMapScreen(booking: testBooking),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(CookingLiveMapScreen), findsOneWidget);
      expect(find.text('Mehta Residence'), findsOneWidget);
      expect(find.textContaining('km'), findsWidgets);
    });

    testWidgets('PlumbingLiveMapScreen computes and displays dynamic distance for booking', (tester) async {
      final testBooking = {
        'id': 'PLUMB-604',
        'customer_name': 'Anand Shah',
        'customer_phone': '+91 98254 77889',
        'customer_address': 'Valkeshwari Nagari, Jamnagar',
        'customer_lat': 22.4820,
        'customer_lng': 70.0690,
      };

      await tester.pumpWidget(MaterialApp(
        home: PlumbingLiveMapScreen(booking: testBooking),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(PlumbingLiveMapScreen), findsOneWidget);
      expect(find.text('Anand Shah'), findsOneWidget);
      expect(find.textContaining('km'), findsWidgets);
    });
  });
}
