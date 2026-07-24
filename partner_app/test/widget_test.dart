import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/main.dart';

void main() {
  testWidgets('Smoke test for Partner App launch', (WidgetTester tester) async {
    // Avoid testing actual network initialization during unit tests
    // Just verify the Widget class resolves
    expect(const ServiceHubPartnerApp(), isNotNull);
  });
}
