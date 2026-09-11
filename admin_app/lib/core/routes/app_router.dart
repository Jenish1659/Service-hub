import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/dashboard/presentation/admin_dashboard.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

// Global flag to allow administrative desktop session bypass
bool adminBypassLoggedIn = false;

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  navigatorKey: _rootNavigatorKey,
  redirect: (BuildContext context, GoRouterState state) {
    final session = Supabase.instance.client.auth.currentSession;
    final bool loggingIn = state.matchedLocation == '/login';

    if (session == null && !adminBypassLoggedIn && !loggingIn) {
      return '/login';
    }

    if ((session != null || adminBypassLoggedIn) && loggingIn) {
      return '/';
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/',
      builder: (BuildContext context, GoRouterState state) => const AdminDashboardScreen(),
    ),
  ],
);
