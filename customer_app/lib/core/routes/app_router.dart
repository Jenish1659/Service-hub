import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/services/presentation/discover_screen.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/support_screen.dart';
import '../../features/bookings/presentation/track_booking_screen.dart';
import '../../features/orders/presentation/track_order_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../shared/layouts/root_navigation_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  navigatorKey: _rootNavigatorKey,
  redirect: (BuildContext context, GoRouterState state) {
    final session = Supabase.instance.client.auth.currentSession;
    bool isLoggedIn = session != null;
    try {
      if (!isLoggedIn) {
        isLoggedIn = Hive.box('customer_cache').get('is_logged_in', defaultValue: false) == true;
      }
    } catch (_) {}
    
    final bool loggingIn = state.matchedLocation == '/login';

    // Route guards: Prompt login only for secure pages
    final secureRoutes = ['/cart', '/profile', '/track-booking', '/track-order', '/support'];
    final isSecureRoute = secureRoutes.any((route) => state.matchedLocation.startsWith(route));

    if (!isLoggedIn && isSecureRoute) {
      return '/login';
    }

    if (isLoggedIn && loggingIn) {
      return '/';
    }

    return null;
  },
  routes: <RouteBase>[
    // Nested Shell Route for Bottom Navigation Bar
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return RootNavigationLayout(child: child);
      },
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (BuildContext context, GoRouterState state) => const HomeScreen(),
        ),
        GoRoute(
          path: '/discover',
          builder: (BuildContext context, GoRouterState state) => const DiscoverScreen(),
        ),
        GoRoute(
          path: '/products',
          builder: (BuildContext context, GoRouterState state) => const ProductsScreen(),
        ),
        GoRoute(
          path: '/orders',
          builder: (BuildContext context, GoRouterState state) => const OrdersScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (BuildContext context, GoRouterState state) => const ProfileScreen(),
        ),
      ],
    ),
    
    // Auth route outside the Shell
    GoRoute(
      path: '/login',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => const LoginScreen(),
    ),

    // Cart route
    GoRoute(
      path: '/cart',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => const CartScreen(),
    ),

    // Dynamic Tracking screens outside the Bottom Nav shell
    GoRoute(
      path: '/track-booking/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final bookingId = state.pathParameters['id'] ?? '';
        return TrackBookingScreen(bookingId: bookingId);
      },
    ),
    GoRoute(
      path: '/track-order/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final orderId = state.pathParameters['id'] ?? '';
        return TrackOrderScreen(orderId: orderId);
      },
    ),
    GoRoute(
      path: '/support',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => const SupportScreen(),
    ),
  ],
);
