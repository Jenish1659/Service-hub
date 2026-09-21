import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  test('check all verification_requests and users', () async {
    final client = SupabaseClient(
      'https://qnmmonfzjsyeckaihqpg.supabase.co',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFubW1vbmZ6anN5ZWNrYWlocXBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4MjU2NzIsImV4cCI6MjA5OTQwMTY3Mn0.EnLGf4cutTcr8J44Ody5CDtbmL2V9UWOm_iboVFD83k',
    );

    print('Listing all verification_requests...');
    final vrs = await client.from('verification_requests').select().order('submitted_at', ascending: false);
    print('Total verification_requests: ${vrs.length}');
    for (var v in vrs) {
      print('VR: ${v['verification_id']} | status: ${v['status']} | user_id: ${v['user_id']} | remarks: ${v['remarks']}');
    }

    print('\nListing all users with role shopkeeper...');
    final users = await client.from('users').select('*, roles(*)').order('created_at', ascending: false).limit(10);
    for (var u in users) {
      print('User: ${u['username']} | phone: ${u['phone']} | role: ${u['roles']} | status: ${u['account_status']}');
    }

    print('\nListing roles table...');
    final roles = await client.from('roles').select();
    for (var r in roles) {
      print('Role: ${r['role_id']} -> ${r['role_name']}');
    }
  });
}
