import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';
import 'package:service_hub_partner/features/dashboard/presentation/ac_provider_dashboard_controller.dart';
import 'package:service_hub_partner/features/dashboard/presentation/provider_dashboard_screen.dart';
import 'package:service_hub_partner/features/dashboard/presentation/provider_live_radar_map_screen.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';

class MockACProviderDashboardNotifier extends ACProviderDashboardNotifier {
  MockACProviderDashboardNotifier([ACProviderDashboardState initial = const ACProviderDashboardState()]) {
    state = initial;
  }

  @override
  Future<void> initDashboard() async {
    // No-op for test isolation
  }

  @override
  Future<Map<String, dynamic>> acceptOffer(Map<String, dynamic> offer) async {
    final activeJobData = {
      ...offer,
      'status': 'CONFIRMED',
      'accepted_at': DateTime.now().toIso8601String(),
    };
    state = state.copyWith(
      activeJob: activeJobData,
    );
    return activeJobData;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final originalOnError = FlutterError.onError;

  setUpAll(() async {
    final tempDir = Directory.systemTemp.createTempSync('hive_osm_test');
    Hive.init(tempDir.path);
    final box = await Hive.openBox('partner_cache');
    await box.clear();

    await LocalRegistrationCache.updateActiveServiceProvider({
      'id': 'test_provider_1',
      'name': 'Rajesh AC Expert',
      'role_name': 'service_provider',
      'phone': '9876543210',
      'verification_status': 'VERIFIED',
      'city': 'Jamnagar',
    });

    FlutterError.onError = (details) {
      final msg = details.exceptionAsString();
      if (msg.contains('tile.openstreetmap.org') || msg.contains('ClientException')) {
        // Safe to ignore remote OSM tile 400s in local test environment
        return;
      }
      originalOnError?.call(details);
    };
  });

  tearDownAll(() {
    FlutterError.onError = originalOnError;
    LiveBookingSyncService.instance.dispose();
  });

  group('Service Provider OpenStreetMap (OSM) Live Radar Screen Tests', () {
    testWidgets('1. ProviderLiveRadarMapScreen mounts OSM FlutterMap with TileLayer, CircleLayer, and technician marker', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      const testState = ACProviderDashboardState(
        isOnline: true,
        incomingOffers: [
          {
            'booking_id': 'AC_TEST_101',
            'id': 'AC_TEST_101',
            'customer_name': 'Kavita Joshi',
            'customer_phone': '+91 98251 11223',
            'customer_address': 'Patel Colony Rd 4, Jamnagar',
            'customer_lat': 22.4735,
            'customer_lng': 70.0630,
            'service_name': 'AC Jet Pump Deep Cleaning',
            'price': 498.0,
            'final_amount': 498.0,
            'status': 'PENDING',
          },
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            acProviderDashboardProvider.overrideWith((ref) => MockACProviderDashboardNotifier(testState)),
          ],
          child: const MaterialApp(
            home: ProviderLiveRadarMapScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify FlutterMap is mounted
      expect(find.byType(FlutterMap), findsOneWidget);

      // Verify TileLayer is configured
      final tileLayerFinder = find.byType(TileLayer);
      expect(tileLayerFinder, findsOneWidget);
      final tileLayer = tester.widget<TileLayer>(tileLayerFinder);
      expect(tileLayer.urlTemplate, equals('https://tile.openstreetmap.org/{z}/{x}/{y}.png'));

      // Verify CircleLayer (5km Jamnagar operational zone)
      final circleLayerFinder = find.byType(CircleLayer);
      expect(circleLayerFinder, findsOneWidget);
      final circleLayer = tester.widget<CircleLayer>(circleLayerFinder);
      expect(circleLayer.circles.first.radius, equals(5000));
      expect(circleLayer.circles.first.useRadiusInMeter, isTrue);

      // Verify Price Tag text is displayed
      expect(find.textContaining('₹498 • Visiting + Protection'), findsWidgets);

      // Verify Top Header Chip
      expect(find.text('AC Service Radar • Live'), findsOneWidget);
      expect(find.text('5 km Jamnagar Zone Coverage'), findsOneWidget);

      // Verify Floating Controls
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      expect(find.byIcon(Icons.crop_free_rounded), findsOneWidget);
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
    });

    testWidgets('2. Tapping customer request pin opens bottom sheet with Accept Job action', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      final testOffer = {
        'booking_id': 'AC_TEST_102',
        'id': 'AC_TEST_102',
        'customer_name': 'Dinesh Mehta',
        'customer_phone': '+91 98251 99887',
        'customer_address': 'Khodiyar Colony, Jamnagar',
        'customer_lat': 22.4632,
        'customer_lng': 70.0495,
        'service_name': 'Split AC Foam Jet Servicing',
        'problem_description': 'Cooling coil clogged, needs foam spray',
        'price': 498.0,
        'final_amount': 498.0,
        'scheduled_time': 'Immediate',
        'status': 'PENDING',
      };

      final testState = ACProviderDashboardState(
        isOnline: true,
        incomingOffers: [testOffer],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            acProviderDashboardProvider.overrideWith((ref) => MockACProviderDashboardNotifier(testState)),
          ],
          child: const MaterialApp(
            home: ProviderLiveRadarMapScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Tap on the price tag widget
      final priceTag = find.textContaining('₹498 • Visiting + Protection').first;
      await tester.tap(priceTag);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Bottom sheet should now be visible with customer name & Accept Job button
      expect(find.text('Dinesh Mehta'), findsOneWidget);
      expect(find.textContaining('Split AC Foam Jet Servicing'), findsOneWidget);
      expect(find.textContaining('Verified 30-day post-service warranty cover'), findsOneWidget);
      expect(find.byKey(const Key('osm_accept_job_button')), findsOneWidget);
    });

    testWidgets('3. Elevated Bottom Nav Center Map button has Royal Blue gradient and opens map directly per P6', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));

      const testState = ACProviderDashboardState(
        isOnline: true,
        providerName: 'Rajesh AC Expert',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            acProviderDashboardProvider.overrideWith((ref) => MockACProviderDashboardNotifier(testState)),
          ],
          child: const MaterialApp(
            home: ProviderDashboardScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Center button finder
      final centerMapBtn = find.byKey(const Key('bottom_nav_center_map_button'));
      expect(centerMapBtn, findsOneWidget);

      // Verify Map label and icon
      expect(find.text('Map'), findsWidgets);
      expect(find.byIcon(Icons.map_rounded), findsWidgets);

      // Verify decoration has Royal Blue gradient
      final containerFinder = find.descendant(
        of: centerMapBtn,
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder.first);
      final boxDec = container.decoration as BoxDecoration;
      final gradient = boxDec.gradient as LinearGradient;
      expect(gradient.colors.first, equals(const Color(0xFF2563EB)));
      expect(gradient.colors.last, equals(const Color(0xFF1D4ED8)));

      // Tap center map button
      await tester.tap(centerMapBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify direct map screen opens without intermediate screen per P6
      expect(find.byType(ProviderLiveRadarMapScreen), findsOneWidget);
      expect(find.byType(FlutterMap), findsWidgets);
      expect(find.byType(TileLayer), findsWidgets);
    });
  });
}
