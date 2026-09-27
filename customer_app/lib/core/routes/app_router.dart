import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/services/presentation/discover_screen.dart';
import '../../features/services/presentation/ac_service_overview_screen.dart';
import '../../features/services/presentation/ac_issue_details_screen.dart';
import '../../features/services/presentation/ac_select_date_screen.dart';
import '../../features/services/presentation/ac_select_time_screen.dart';
import '../../features/services/presentation/ac_service_details_screen.dart';
import '../../features/services/presentation/ac_review_confirm_screen.dart';
import '../../features/services/presentation/ac_booking_confirmed_screen.dart';
import '../../features/services/presentation/ac_finding_technician_screen.dart';
import '../../features/services/presentation/ac_technician_details_screen.dart';
import '../../features/services/services/ac_availability_service.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/support_screen.dart';
import '../../features/bookings/presentation/track_booking_screen.dart';
import '../../features/bookings/presentation/chat_screen.dart';
import '../../features/orders/presentation/track_order_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/location/screens/map_screen.dart';
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

    // Map route
    GoRoute(
      path: '/map',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => const MapScreen(),
    ),

    // AC Service Overview Route (Screen 1)
    GoRoute(
      path: '/services/ac/overview',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ACServiceOverviewScreen(issueDetails: extra);
      },
    ),

    // AC Service Issue Details Route
    GoRoute(
      path: '/services/ac/issue-details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => const ACIssueDetailsScreen(),
    ),

    // AC Service Select Date Route (Screen 2)
    GoRoute(
      path: '/services/ac/select-date',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ACSelectDateScreen(issueDetails: extra);
      },
    ),

    // AC Service Select Time Route (Screen 3)
    GoRoute(
      path: '/services/ac/select-time',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final selectedDate = extra['selected_date'] as BookingDateOption? ??
            ACAvailabilityService.instance.getNext3BookingDates().first;
        return ACSelectTimeScreen(
          issueDetails: extra,
          selectedDate: selectedDate,
        );
      },
    ),

    // AC Service Details Route (Screen 4)
    GoRoute(
      path: '/services/ac/service-details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final selectedDate = extra['selected_date'] as BookingDateOption? ??
            ACAvailabilityService.instance.getNext3BookingDates().first;
        final selectedTime = extra['selected_time'] as String? ?? '02:00 PM';
        return ACServiceDetailsScreen(
          issueDetails: extra,
          selectedDate: selectedDate,
          selectedTime: selectedTime,
        );
      },
    ),

    // AC Service Review & Confirm Route (Screen 5)
    GoRoute(
      path: '/services/ac/review-confirm',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final selectedDate = extra['selected_date'] as BookingDateOption? ??
            ACAvailabilityService.instance.getNext3BookingDates().first;
        final selectedTime = extra['selected_time'] as String? ?? '02:00 PM';
        return ACReviewConfirmScreen(
          issueDetails: extra,
          selectedDate: selectedDate,
          selectedTime: selectedTime,
        );
      },
    ),

    // AC Service Booking Confirmed Route (Screen 6)
    GoRoute(
      path: '/services/ac/confirmed',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final bookingData = extra['booking_data'] as Map<String, dynamic>? ?? {};
        return ACBookingConfirmedScreen(
          bookingData: bookingData,
          selectedDateFormatted: extra['selected_date_formatted'] as String? ?? 'Tomorrow',
          selectedTime: extra['selected_time'] as String? ?? '02:00 PM',
          serviceTitle: extra['service_title'] as String? ?? 'AC Service',
          address: extra['address'] as String? ?? '',
          partnerCount: extra['partner_count'] as int? ?? 3,
        );
      },
    ),

    // AC Service Finding Technician Route (Screen 7)
    GoRoute(
      path: '/services/ac/finding-technician',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final bookingData = extra['booking_data'] as Map<String, dynamic>? ?? {};
        final bookingId = (extra['booking_id'] ?? bookingData['id'] ?? bookingData['booking_id'] ?? '').toString();
        return ACFindingTechnicianScreen(
          bookingId: bookingId,
          bookingData: bookingData,
          serviceTitle: extra['service_title'] as String? ?? 'AC Service',
          address: extra['address'] as String? ?? '',
          selectedDateFormatted: extra['selected_date_formatted'] as String? ?? 'Tomorrow',
          selectedTime: extra['selected_time'] as String? ?? '02:00 PM',
        );
      },
    ),
    GoRoute(
      path: '/services/ac/technician-details',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final bookingData = extra['booking_data'] as Map<String, dynamic>? ?? {};
        final bookingId = (extra['booking_id'] ?? bookingData['id'] ?? bookingData['booking_id'] ?? '').toString();
        return ACTechnicianDetailsScreen(
          bookingId: bookingId,
          bookingData: bookingData,
          partnerData: extra['partner_data'] as Map<String, dynamic>?,
          serviceTitle: extra['service_title'] as String? ?? 'AC Service',
          address: extra['address'] as String? ?? '',
          selectedDateFormatted: extra['selected_date_formatted'] as String?,
          selectedTime: extra['selected_time'] as String?,
        );
      },
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
    GoRoute(
      path: '/chat/:id',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final bookingId = state.pathParameters['id'] ?? '';
        return ChatScreen(bookingId: bookingId);
      },
    ),
  ],
);
