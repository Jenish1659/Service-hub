import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/provider/presentation/provider_dashboard.dart';
import '../../features/seller/presentation/seller_dashboard.dart';
import '../../features/delivery/presentation/delivery_dashboard.dart';
import '../../features/profile/presentation/profile_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  navigatorKey: _rootNavigatorKey,
  redirect: (BuildContext context, GoRouterState state) {
    final session = Supabase.instance.client.auth.currentSession;
    final bool loggingIn = state.matchedLocation == '/login';

    if (session == null && !loggingIn) {
      return '/login';
    }

    if (session != null && loggingIn) {
      return '/role-select';
    }

    return null;
  },
  routes: <RouteBase>[
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/role-select',
      builder: (BuildContext context, GoRouterState state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/provider-dashboard',
      builder: (BuildContext context, GoRouterState state) => const ProviderDashboard(),
    ),
    GoRoute(
      path: '/seller-dashboard',
      builder: (BuildContext context, GoRouterState state) => const SellerDashboard(),
    ),
    GoRoute(
      path: '/delivery-dashboard',
      builder: (BuildContext context, GoRouterState state) => const DeliveryDashboard(),
    ),
    GoRoute(
      path: '/profile',
      builder: (BuildContext context, GoRouterState state) => const ProfileScreen(),
    ),
  ],
);
