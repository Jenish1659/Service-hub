import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Hive Cache
  await Hive.initFlutter();
  await Hive.openBox('customer_cache');

  // Initialize Supabase Client
  // Note: Replace these URL and Anon Key strings with your own Supabase project credentials.
  await Supabase.initialize(
    url: 'https://placeholder-project-id.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.placeholderAnonKeyTextHere',
  );

  runApp(
    const ProviderScope(
      child: ServiceHubCustomerApp(),
    ),
  );
}

class ServiceHubCustomerApp extends StatelessWidget {
  const ServiceHubCustomerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ServiceHub Customer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
