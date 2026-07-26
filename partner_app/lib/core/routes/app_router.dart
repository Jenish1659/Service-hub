import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/onboarding/presentation/partner_onboarding_screen.dart';
import '../../features/provider/presentation/provider_dashboard.dart';
import '../../features/seller/presentation/seller_dashboard.dart';
import '../../features/delivery/presentation/delivery_dashboard.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/shared/presentation/partner_map_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

// Global flag to bypass Auth check for mock accounts & local testing
bool partnerBypassLoggedIn = false;

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  navigatorKey: _rootNavigatorKey,
  redirect: (BuildContext context, GoRouterState state) {
    final session = Supabase.instance.client.auth.currentSession;
    final bool loggingIn = state.matchedLocation == '/login';

    if (session == null && !partnerBypassLoggedIn && !loggingIn) {
      return '/login';
    }

    if ((session != null || partnerBypassLoggedIn) && loggingIn) {
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
      path: '/onboarding',
      builder: (BuildContext context, GoRouterState state) => const PartnerOnboardingScreen(),
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
    GoRoute(
      path: '/navigation',
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return PartnerMapScreen(
          taskId: extra['taskId'] ?? 'mock_task_1',
          customerName: extra['customerName'] ?? 'Jenish Bheda',
          address: extra['address'] ?? 'Digvijay Plot, Jamnagar',
          serviceName: extra['serviceName'] ?? 'AC Service & Repair',
          price: extra['price'] ?? '₹1,100',
          type: extra['type'] ?? 'service',
          deliveryPin: extra['deliveryPin'] ?? '2842',
        );
      },
    ),
  ],
);
