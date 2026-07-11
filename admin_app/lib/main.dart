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
  await Hive.openBox('admin_cache');

  // Initialize Supabase Client
  await Supabase.initialize(
    url: 'https://placeholder-project-id.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.placeholderAnonKeyTextHere',
  );

  runApp(
    const ProviderScope(
      child: ServiceHubAdminApp(),
    ),
  );
}

class ServiceHubAdminApp extends StatelessWidget {
  const ServiceHubAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ServiceHub Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
