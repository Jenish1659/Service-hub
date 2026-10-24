import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:service_hub_customer/core/theme/app_theme.dart';
import 'package:service_hub_customer/features/cart/presentation/cart_provider.dart';
import 'package:service_hub_customer/features/products/presentation/customer_product_details_screen.dart';
import 'package:service_hub_customer/features/products/services/product_reviews_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('hive_ecommerce_test_');
    Hive.init(tempDir.path);
    if (!Hive.isBoxOpen('customer_cache')) {
      await Hive.openBox('customer_cache');
    }
  });

  group('E-Commerce Architecture & Real Customer Ratings Tests', () {
    test('1. Freshly listed product has ZERO fake ratings (Strict 100% Real Data Guarantee)', () {
      final service = ProductReviewsService.instance;
      const testProductId = 'prod_test_fresh_launch_123';

      final stats = service.getProductRatingStats(testProductId);
      expect(stats['has_ratings'], isFalse, reason: 'Fresh product must not have fake ratings');
      expect(stats['average_rating'], 0.0);
      expect(stats['review_count'], 0);
      expect(service.getReviewsForProduct(testProductId), isEmpty);
    });

    test('2. Real verified customer reviews compute accurate dynamic ratings & star breakdown', () async {
      final service = ProductReviewsService.instance;
      const testProductId = 'prod_test_real_reviews_456';

      // Customer 1 submits 5-star review
      await service.submitProductReview(
        productId: testProductId,
        rating: 5.0,
        comment: 'Excellent genuine AC remote, worked instantly with my Daikin unit!',
        reviewerName: 'Amit Patel',
      );

      var stats = service.getProductRatingStats(testProductId);
      expect(stats['has_ratings'], isTrue);
      expect(stats['average_rating'], 5.0);
      expect(stats['review_count'], 1);

      // Customer 2 submits 4-star review
      await service.submitProductReview(
        productId: testProductId,
        rating: 4.0,
        comment: 'Good build quality and fast 15-min delivery.',
        reviewerName: 'Priya Sharma',
      );

      stats = service.getProductRatingStats(testProductId);
      expect(stats['has_ratings'], isTrue);
      // Average of 5.0 and 4.0 is 4.5
      expect(stats['average_rating'], 4.5);
      expect(stats['review_count'], 2);

      final breakdown = stats['breakdown'] as Map<int, int>;
      expect(breakdown[5], 1);
      expect(breakdown[4], 1);
      expect(breakdown[3], 0);

      final reviews = service.getReviewsForProduct(testProductId);
      expect(reviews.length, 2);
      expect(reviews.first['reviewer_name'], 'Priya Sharma');
      expect(reviews.first['is_verified_purchase'], isTrue);
    });

    test('3. CartProvider handles addItemWithQuantity and calculates accurate pricing', () {
      final container = ProviderContainer();
      final sampleProduct = {
        'id': 'prod_remote_001',
        'name': 'Split AC Universal Remote',
        'price': 450,
        'category': 'ac_parts',
      };

      final notifier = container.read(cartProvider.notifier);
      notifier.clearCart();
      expect(container.read(cartItemCountProvider), 0);
      expect(container.read(cartSubtotalProvider), 0);

      // Add 3 units
      notifier.addItemWithQuantity(sampleProduct, 3);
      expect(container.read(cartItemCountProvider), 3);
      expect(container.read(cartSubtotalProvider), 1350);

      // Add 2 more units of same product
      notifier.addItemWithQuantity(sampleProduct, 2);
      expect(container.read(cartItemCountProvider), 5);
      expect(container.read(cartSubtotalProvider), 2250);

      notifier.clearCart();
    });

    testWidgets('4. CustomerProductDetailsScreen renders full Blinkit/Flipkart/Amazon structured UI', (tester) async {
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

      final realProductData = {
        'id': 'PROD_TEST_UI_999',
        'name': 'Split AC High-Pressure Copper Valve 1/4 inch',
        'category': 'ac_parts',
        'price': 499.0,
        'mrp': 799.0,
        'sku': 'SKU-AC-998877',
        'stock': 25,
        'description': 'Heavy duty 100% pure copper service valve designed for R32 and R410A inverter AC systems.',
        'image': base64Photo,
        'shop_name': 'Radha Enterprises • Certified Store',
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: CustomerProductDetailsScreen(product: realProductData),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Blinkit 15 Mins Delivery Banner & Specs Table Fast ETA
      expect(find.text('⚡ 15 MINS HYPERLOCAL DELIVERY'), findsNWidgets(2));
      expect(find.textContaining('Dispatched from Radha Enterprises'), findsOneWidget);

      // 2. Brand & Certified Store Badge (in certified header and specifications table)
      expect(find.text('Radha Enterprises • Certified Store'), findsNWidgets(2));
      expect(find.text('✓ In Stock'), findsOneWidget);

      // 3. Price & Discount Savings
      expect(find.text('₹499'), findsOneWidget);
      expect(find.text('₹799'), findsOneWidget);
      expect(find.textContaining('Save ₹300 (38% off)'), findsOneWidget);

      // 4. Amazon-Style Trust Badges
      expect(find.text('7 Days Return'), findsOneWidget);
      expect(find.text('100% Genuine'), findsOneWidget);
      expect(find.text('Free Delivery'), findsOneWidget);
      expect(find.text('Pay on Delivery'), findsOneWidget);

      // 5. Technical Specifications Table
      expect(find.text('Technical Specifications'), findsOneWidget);
      expect(find.text('Item Code / SKU'), findsOneWidget);
      expect(find.text('SKU-AC-998877'), findsOneWidget);
      expect(find.text('AC PARTS'), findsOneWidget);
      expect(find.text('Universal Fit for Split, Window & Inverter Air Conditioners'), findsOneWidget);

      // 6. Zero Fake Rating Display (Shows New Launch because it's brand new)
      expect(find.text('New Launch • No customer reviews yet'), findsOneWidget);
      expect(find.text('Write First Review'), findsOneWidget);

      // 7. Sticky Bottom Action Buttons
      expect(find.text('Add to Cart'), findsOneWidget);
      expect(find.text('⚡ Buy Now'), findsOneWidget);
    });

    testWidgets('5. Adding product to cart from details screen triggers SnackBar and updates cart state', (tester) async {
      final realProductData = {
        'id': 'PROD_TEST_CART_888',
        'name': 'Universal Washing Machine Inlet Pipe',
        'category': 'laundry',
        'price': 299.0,
        'mrp': 499.0,
        'sku': 'SKU-LA-112233',
        'stock': 15,
        'description': 'High pressure braided water inlet hose.',
      };

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: CustomerProductDetailsScreen(product: realProductData),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap '+' to increase quantity to 2
      final plusFinder = find.byIcon(Icons.add_rounded);
      expect(plusFinder, findsOneWidget);
      await tester.tap(plusFinder);
      await tester.pumpAndSettle();

      // Quantity should now show 2
      expect(find.text('2'), findsOneWidget);

      // Tap 'Add to Cart'
      final addToCartFinder = find.widgetWithText(OutlinedButton, 'Add to Cart');
      expect(addToCartFinder, findsOneWidget);
      await tester.tap(addToCartFinder);
      await tester.pump();

      // Verify SnackBar message appears
      expect(find.textContaining('2 × "Universal Washing Machine Inlet Pipe" added to cart!'), findsOneWidget);
    });
  });
}
