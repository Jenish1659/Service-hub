import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:service_hub_partner/core/services/supabase_auth_service.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Hive.init('./test_hive_login');
    if (!Hive.isBoxOpen('partner_cache')) {
      await Hive.openBox('partner_cache');
    }
  });

  tearDownAll(() async {
    try {
      if (Hive.isBoxOpen('partner_cache')) {
        await Hive.box('partner_cache').clear();
        await Hive.box('partner_cache').close();
      }
    } catch (_) {}
  });

  group('Partner Multi-Identifier Login & Credential Verification Tests', () {
    test('1. Empty identifier or password returns prompt message', () async {
      final resEmpty = await SupabaseAuthService.loginWithUsernameOrPhone(
        identifier: '',
        password: '',
        expectedRole: 'service_provider',
      );
      expect(resEmpty.isSuccess, isFalse);
      expect(resEmpty.errorMessage, contains('Please enter your username or mobile number and password.'));
    });

    test('2. Non-existent account returns Account not found message', () async {
      final resNotFound = await SupabaseAuthService.loginWithUsernameOrPhone(
        identifier: 'non_existent_partner_999999',
        password: 'ValidPassword@123',
        expectedRole: 'service_provider',
      );
      expect(resNotFound.isSuccess, isFalse);
      expect(resNotFound.errorMessage, anyOf(contains('Account not found'), contains('Invalid username/mobile')));
    });

    test('3. Saved account in Hive credential store logs in successfully by Username', () async {
      final box = Hive.box('partner_cache');
      final creds = Map<String, dynamic>.from(box.get('user_credentials', defaultValue: {}) as Map);
      creds['test_provider_jamnagar'] = 'SecurePass@2026';
      creds['9876543210'] = 'SecurePass@2026';
      await box.put('user_credentials', creds);

      final userSession = {
        'user_id': 'usr_test_123',
        'username': 'test_provider_jamnagar',
        'phone': '9876543210',
        'email': 'test_provider@servicehub.com',
        'password': 'SecurePass@2026',
        'role_name': 'service_provider',
        'category': 'ac_service',
        'name': 'Test AC Provider',
        'verification_status': 'VERIFIED',
      };
      await box.put('registered_users_list', [userSession]);

      // Login by Username
      final resUser = await SupabaseAuthService.loginWithUsernameOrPhone(
        identifier: 'test_provider_jamnagar',
        password: 'SecurePass@2026',
        expectedRole: 'service_provider',
      );
      expect(resUser.isSuccess, isTrue);
      expect(resUser.roleName, 'service_provider');
      expect(resUser.userData?['username'], 'test_provider_jamnagar');

      // Login with wrong password
      final resWrong = await SupabaseAuthService.loginWithUsernameOrPhone(
        identifier: 'test_provider_jamnagar',
        password: 'WrongPassword',
        expectedRole: 'service_provider',
      );
      expect(resWrong.isSuccess, isFalse);
    });

    test('4. Saved account logs in successfully by 10-digit Phone Number', () async {
      final resPhone = await SupabaseAuthService.loginWithUsernameOrPhone(
        identifier: '9876543210',
        password: 'SecurePass@2026',
        expectedRole: 'service_provider',
      );
      expect(resPhone.isSuccess, isTrue);
      expect(resPhone.userData?['username'], 'test_provider_jamnagar');
    });

    test('5. Cross-role login does not crash and preserves authentic role', () async {
      final box = Hive.box('partner_cache');
      final creds = Map<String, dynamic>.from(box.get('user_credentials', defaultValue: {}) as Map);
      creds['delivery_agent_jamnagar'] = 'RiderPass@2026';
      await box.put('user_credentials', creds);

      final delivSession = {
        'user_id': 'deliv_test_456',
        'username': 'delivery_agent_jamnagar',
        'phone': '9988776655',
        'email': 'rider@servicehub.com',
        'password': 'RiderPass@2026',
        'role_name': 'delivery_agent',
        'category': 'delivery_agent',
        'name': 'Jamnagar Express Rider',
        'verification_status': 'VERIFIED',
      };
      final rawList = box.get('registered_users_list', defaultValue: []) as List;
      await box.put('registered_users_list', [...rawList, delivSession]);

      // Login on service provider screen with delivery credentials
      final resCross = await SupabaseAuthService.loginWithUsernameOrPhone(
        identifier: 'delivery_agent_jamnagar',
        password: 'RiderPass@2026',
        expectedRole: 'service_provider',
      );
      expect(resCross.isSuccess, isTrue);
      expect(resCross.roleName, 'delivery_agent');
    });
  });
}
