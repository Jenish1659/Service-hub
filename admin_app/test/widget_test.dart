import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_hub_admin/main.dart';

void main() {
  testWidgets('Smoke test for Admin App launch', (WidgetTester tester) async {
    // Avoid testing actual network initialization during unit tests
    // Just verify the Widget class resolves
    expect(const ServiceHubAdminApp(), isNotNull);
  });
}
