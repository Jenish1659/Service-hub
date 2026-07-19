import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:service_hub_customer/main.dart';

void main() {
  testWidgets('Smoke test for Customer App launch', (WidgetTester tester) async {
    expect(const ServiceHubCustomerApp(), isNotNull);
  });
}
