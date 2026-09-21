import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service_hub_admin/features/dashboard/presentation/admin_provider.dart';
import 'package:hive/hive.dart';

void main() {
  test('test adminUnverifiedPartnersStreamProvider picks up shopkeeper', () async {
    SharedPreferences.setMockInitialValues({});
    final tempDir = Directory.systemTemp.createTempSync();
    Hive.init(tempDir.path);
    await Hive.openBox('admin_cache');
    await Supabase.initialize(
      url: 'https://qnmmonfzjsyeckaihqpg.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFubW1vbmZ6anN5ZWNrYWlocXBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4MjU2NzIsImV4cCI6MjA5OTQwMTY3Mn0.EnLGf4cutTcr8J44Ody5CDtbmL2V9UWOm_iboVFD83k',
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Read the stream
    final stream = container.read(adminUnverifiedPartnersStreamProvider.stream);
    final list = await stream.firstWhere((element) => element.isNotEmpty, orElse: () => []);

    print('Stream returned ${list.length} partners:');
    for (var p in list) {
      print('Partner: name=${p['name']}, role=${p['role_name']}, cat=${p['category']}, business=${p['business_name']}, id=${p['id']}');
    }
  });
}
