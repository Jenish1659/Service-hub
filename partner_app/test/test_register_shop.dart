import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service_hub_partner/core/services/supabase_auth_service.dart';
import 'package:hive/hive.dart';

void main() {
  test('test registerShopkeeper execution', () async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox('partner_cache');
    await Supabase.initialize(
      url: 'https://qnmmonfzjsyeckaihqpg.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFubW1vbmZ6anN5ZWNrYWlocXBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4MjU2NzIsImV4cCI6MjA5OTQwMTY3Mn0.EnLGf4cutTcr8J44Ody5CDtbmL2V9UWOm_iboVFD83k',
    );

    print('Calling registerShopkeeper...');
    try {
      final res = await SupabaseAuthService.registerShopkeeper(
        username: 'testshop_${DateTime.now().millisecondsSinceEpoch % 10000}',
        firstName: 'Test',
        lastName: 'Shopkeeper',
        phone: '9988776655',
        password: 'Password@123',
        shopName: 'Test Electronics',
        category: 'AC Service Parts',
        shopAddress: '123 Market Road, Jamnagar',
        city: 'Jamnagar',
        state: 'Gujarat',
        pincode: '361001',
        aadhaarNumber: '123456789012',
      );
      print('Success: ${res.isSuccess}, role: ${res.roleName}, user: ${res.userData}');
    } catch (e, st) {
      print('Error calling registerShopkeeper: $e\n$st');
    }
  });
}
