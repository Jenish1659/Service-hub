// ignore_for_file: avoid_print
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  const anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFubW1vbmZ6anN5ZWNrYWlocXBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4MjU2NzIsImV4cCI6MjA5OTQwMTY3Mn0.EnLGf4cutTcr8J44Ody5CDtbmL2V9UWOm_iboVFD83k';
  final headers = {
    'apikey': anonKey,
    'Authorization': 'Bearer $anonKey',
    'Content-Type': 'application/json',
    'Prefer': 'return=representation',
  };

  print('=== CHECKING USERS AND ROLES IN SUPABASE ===');
  final usersRes = await http.get(
    Uri.parse('https://qnmmonfzjsyeckaihqpg.supabase.co/rest/v1/users?select=*'),
    headers: headers,
  );
  print('Users: ${usersRes.body}');

  final servicesRes = await http.get(
    Uri.parse('https://qnmmonfzjsyeckaihqpg.supabase.co/rest/v1/services?select=service_id,name&limit=1'),
    headers: headers,
  );
  final realServiceId = (jsonDecode(servicesRes.body) as List).first['service_id'];
  print('Real Service UUID: $realServiceId');

  // Let's test insert with admin user_id and real service_id
  final adminUserId = (jsonDecode(usersRes.body) as List).first['user_id'];
  final testPayload = {
    'customer_id': adminUserId,
    'service_id': realServiceId,
    'status': 'SEARCHING_PROVIDER',
    'scheduled_time': '10:00 AM',
    'estimated_amount': 499.0,
  };
  final insertRes = await http.post(
    Uri.parse('https://qnmmonfzjsyeckaihqpg.supabase.co/rest/v1/service_bookings'),
    headers: headers,
    body: jsonEncode(testPayload),
  );
  print('\nInsert with real user_id and service_id:');
  print('Status: ${insertRes.statusCode}');
  print('Body: ${insertRes.body}');
}
