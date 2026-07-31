import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/delivery_requests/presentation/screens/delivery_dashboard_screen.dart';
import '../../features/authentication/presentation/screens/delivery_login_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const DeliveryLoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DeliveryDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri.path}'),
      ),
    ),
  );
}
