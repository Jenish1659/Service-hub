import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_admin/features/products/presentation/admin_products_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin Store Products & Catalog Management Tests', () {
    testWidgets('Renders AdminProductsView with header and Add Product action', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminProductsView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Header title and subtitle
      expect(find.text('Store Products & Catalog'), findsOneWidget);
      expect(find.text('Add Product'), findsOneWidget);
    });

    testWidgets('Opens Add Live Store Product dialog on tapping Add Product', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AdminProductsView(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final addBtn = find.text('Add Product');
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify modal opened
      expect(find.text('Add Live Store Product'), findsOneWidget);
      expect(find.text('Product Title *'), findsOneWidget);
      expect(find.text('Selling Price (₹) *'), findsOneWidget);
      expect(find.text('Publish Product'), findsOneWidget);
    });
  });
}
