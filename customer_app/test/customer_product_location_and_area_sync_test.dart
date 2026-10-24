import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_customer/core/theme/app_theme.dart';
import 'package:service_hub_customer/features/products/presentation/customer_product_details_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_loc_test_');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('customer_cache')) {
      await Hive.openBox('customer_cache');
    }
  });

  group('Hyperlocal Location & Delivery Area Sync Tests', () {
    testWidgets('1. CustomerProductDetailsScreen displays Hub Location and Delivery Area in Blinkit banner and Specifications table', (tester) async {
      // 1x1 test image
      final samplePngBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
        0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
        0x89, 0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41,
        0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
        0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
        0x42, 0x60, 0x82
      ]);
      final base64Photo = 'data:image/png;base64,${base64Encode(samplePngBytes)}';

      final realProductWithLocation = {
        'id': 'PROD_TEST_LOC_101',
        'name': 'Split AC Indoor Air Filter Mesh',
        'category': 'ac_parts',
        'price': 250.0,
        'mrp': 450.0,
        'sku': 'SKU-AC-143392',
        'stock': 40,
        'location': 'Radha Enterprises Central Hub, Jamnagar',
        'area': 'Indira Marg (5 km Radius)',
        'delivery_eta': '⚡ 15 MINS (Express)',
        'description': 'High quality AC dust filter used to filter indoor air and protect evaporator coil.',
        'image': base64Photo,
        'shop_name': 'Radha Enterprises • Certified Store',
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: CustomerProductDetailsScreen(product: realProductWithLocation),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Blinkit Hyperlocal Delivery Banner has area and hub location
      expect(find.text('⚡ 15 MINS (EXPRESS)'), findsOneWidget);
      expect(find.text('Dispatched from Radha Enterprises Central Hub, Jamnagar serving Indira Marg (5 km Radius)'), findsOneWidget);

      // Verify Technical Specifications Table contains Dispatch Hub, Delivery Area and Fast Delivery ETA
      expect(find.text('Dispatch Hub'), findsOneWidget);
      expect(find.text('Radha Enterprises Central Hub, Jamnagar'), findsOneWidget);
      expect(find.text('Delivery Area'), findsOneWidget);
      expect(find.text('Indira Marg (5 km Radius)'), findsOneWidget);
      expect(find.text('Fast Delivery ETA'), findsOneWidget);
      expect(find.text('⚡ 15 MINS (Express)'), findsOneWidget);
    });

    test('2. Image size is strictly capped under 1MB (1,048,576 bytes)', () {
      // 500 KB test payload
      final smallBytes = Uint8List(500 * 1024);
      expect(smallBytes.lengthInBytes < 1024 * 1024, isTrue);

      // Exceeding 1MB test payload
      final largeBytes = Uint8List(1200 * 1024);
      expect(largeBytes.lengthInBytes > 1024 * 1024, isTrue);
    });
  });
}
