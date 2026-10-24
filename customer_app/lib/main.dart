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
  await Supabase.initialize(
    url: 'https://qnmmonfzjsyeckaihqpg.supabase.co',
    // ignore: deprecated_member_use
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFubW1vbmZ6anN5ZWNrYWlocXBnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM4MjU2NzIsImV4cCI6MjA5OTQwMTY3Mn0.EnLGf4cutTcr8J44Ody5CDtbmL2V9UWOm_iboVFD83k',
  );

  // Global Error Widget Builder to prevent red/white crash screens

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const Material(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                color: Color(0xffef4444),
                size: 28,
              ),
              SizedBox(height: 4),
              Text(
                'Notice',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Color(0xff1e293b),
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Rendering refresh in progress',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xff64748b),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };

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
