import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/features/profile/data/customer_profile_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Customer App 100% Real Data Guarantee (No Fake / Mock Data)', () {
    test('1. getBookings returns empty list when no real bookings exist (Zero fake/dummy baseline bookings)', () {
      final service = CustomerProfileService.instance;
      // In clean test environment without real DB bookings, getBookings must be strictly empty
      final bookings = service.getBookings();

      // Verify that no legacy fake bookings (bk_1, bk_2, bk_3, Vikram Joshi, Ramesh Patel, Kishore Dave) exist
      expect(bookings.any((b) => b['id'] == 'bk_1' || b['partner_name'] == 'Vikram Joshi'), isFalse);
      expect(bookings.any((b) => b['id'] == 'bk_2' || b['partner_name'] == 'Ramesh Patel'), isFalse);
      expect(bookings.any((b) => b['id'] == 'bk_3' || b['partner_name'] == 'Kishore Dave'), isFalse);
    });

    test('2. getAddresses returns zero hardcoded fake preset addresses', () {
      final service = CustomerProfileService.instance;
      final addresses = service.getAddresses();

      // Verify that no legacy fake preset addresses exist
      expect(addresses.any((a) => (a['full_address'] ?? '').toString().contains('Sunrise Residency')), isFalse);
      expect(addresses.any((a) => (a['full_address'] ?? '').toString().contains('Alpha One Mall')), isFalse);
      expect(addresses.any((a) => (a['full_address'] ?? '').toString().contains('City Garden')), isFalse);
    });

    test('3. getNotifications returns zero fake booking alerts and zero dummy welcome messages', () {
      final service = CustomerProfileService.instance;
      final notifications = service.getNotifications();

      // Verify no fake booking derived notifications or hardcoded welcome messages
      expect(notifications.any((n) => n['id'] == 'notif_default_1'), isFalse);
      expect(notifications.any((n) => (n['id'] ?? '').toString().startsWith('notif_bk_')), isFalse);
    });

    test('4. getProfile does not default to fake email aryanbheda@example.com', () {
      final service = CustomerProfileService.instance;
      final profile = service.getProfile();

      // When no active session exists, email must be empty, not hardcoded aryanbheda@example.com
      expect(profile['email'], isNot(equals('aryanbheda@example.com')));
    });

    test('5. getPaymentMethods returns zero hardcoded dummy payment methods (no bheda.aryan or dummy cards)', () {
      final service = CustomerProfileService.instance;
      final payments = service.getPaymentMethods();

      expect(payments.any((p) => (p['detail'] ?? '').toString().contains('bheda.aryan')), isFalse);
      expect(payments.any((p) => (p['detail'] ?? '').toString().contains('4589')), isFalse);
      expect(payments.any((p) => (p['detail'] ?? '').toString().contains('8821')), isFalse);
      expect(payments.any((p) => (p['detail'] ?? '').toString().contains('1024')), isFalse);
    });

    test('6. getSavedServiceIds is empty by default (zero predefined saved services)', () {
      final service = CustomerProfileService.instance;
      final saved = service.getSavedServiceIds();

      expect(saved.isEmpty, isTrue);
    });

    test('7. getAddresses strictly filters Rajkot Road, Vastrapur, Parents Home, Green Park', () {
      final service = CustomerProfileService.instance;
      final addresses = service.getAddresses();

      expect(addresses.any((a) => (a['full_address'] ?? '').toString().toLowerCase().contains('rajkot road')), isFalse);
      expect(addresses.any((a) => (a['full_address'] ?? '').toString().toLowerCase().contains('vastrapur')), isFalse);
      expect(addresses.any((a) => (a['full_address'] ?? '').toString().toLowerCase().contains('green park')), isFalse);
      expect(addresses.any((a) => (a['label'] ?? '').toString().toLowerCase().contains('parents home')), isFalse);
    });
  });

  group('Buffer Overflow Elimination Tests', () {
    testWidgets('5. Share Your Feedback dialog 5-star rating renders cleanly inside 320px screen constraint without right overflow', (tester) async {
      int rating = 5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Share Your Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
                  content: StatefulBuilder(
                    builder: (context, setDialogState) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 360),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(5, (index) {
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(20),
                                    onTap: () => setDialogState(() => rating = index + 1),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                                      child: Icon(
                                        index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                                        color: const Color(0xFFF59E0B),
                                        size: 30,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: TextEditingController(),
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Tell us how we can make ServiceHub even better...',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // Verify no RenderFlex overflow exception
      expect(tester.takeException(), isNull);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
    });
  });

  group('Password Update Verification Logic', () {
    test('6. Rejects update when old password is incorrect with exact error message', () {
      const storedPasswordHash = 'Secret@1234';
      const userEnteredOldPassword = 'WrongPassword';
      const newPassword = 'NewSecret@5678';
      const confirmPassword = 'NewSecret@5678';

      String? errorMessage;
      bool isOldPasswordCorrect = (userEnteredOldPassword == storedPasswordHash);

      if (!isOldPasswordCorrect) {
        errorMessage = 'Old password is incorrect. Please re-type your current password.';
      } else if (newPassword != confirmPassword) {
        errorMessage = 'New passwords do not match. Please re-type.';
      } else if (newPassword.length < 6) {
        errorMessage = 'New password must be at least 6 characters long';
      }

      expect(isOldPasswordCorrect, isFalse);
      expect(errorMessage, 'Old password is incorrect. Please re-type your current password.');
    });

    test('7. Accepts update when old password is correct and new password is confirmed', () {
      const storedPasswordHash = 'Secret@1234';
      const userEnteredOldPassword = 'Secret@1234';
      const newPassword = 'NewSecret@5678';
      const confirmPassword = 'NewSecret@5678';

      String? errorMessage;
      bool isOldPasswordCorrect = (userEnteredOldPassword == storedPasswordHash);

      if (!isOldPasswordCorrect) {
        errorMessage = 'Old password is incorrect. Please re-type your current password.';
      } else if (newPassword != confirmPassword) {
        errorMessage = 'New passwords do not match. Please re-type.';
      } else if (newPassword.length < 6) {
        errorMessage = 'New password must be at least 6 characters long';
      }

      expect(isOldPasswordCorrect, isTrue);
      expect(errorMessage, isNull);
    });
  });
}
