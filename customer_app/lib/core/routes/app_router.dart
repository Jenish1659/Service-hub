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
import '../../features/services/presentation/laundry_requirement_screen.dart';
import '../../features/services/presentation/car_service_requirement_screen.dart';
import '../../features/services/presentation/care_taker_requirement_screen.dart';
import '../../features/services/presentation/cooking_requirement_screen.dart';
import '../../features/services/presentation/plumbing_requirement_screen.dart';
import '../../features/services/presentation/service_select_date_screen.dart';
import '../../features/services/presentation/service_select_time_screen.dart';
import '../../features/services/presentation/service_address_details_screen.dart';
import '../../features/services/presentation/service_review_confirm_screen.dart';
import '../../features/services/presentation/service_finding_partner_screen.dart';
import '../../features/services/services/multi_service_booking_service.dart';
import '../../features/services/services/ac_availability_service.dart';
import '../../features/products/presentation/products_screen.dart';
import '../../features/cart/presentation/cart_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/support_screen.dart';
import '../../features/profile/presentation/screens/customer_personal_info_screen.dart';
import '../../features/profile/presentation/screens/customer_addresses_screen.dart';
import '../../features/profile/presentation/screens/customer_add_address_screen.dart';
import '../../features/profile/presentation/screens/customer_payment_methods_screen.dart';
import '../../features/profile/presentation/screens/customer_add_payment_method_screen.dart';
import '../../features/profile/presentation/screens/customer_my_bookings_screen.dart';
import '../../features/profile/presentation/screens/customer_booking_details_screen.dart';
import '../../features/profile/presentation/screens/customer_saved_services_screen.dart';
import '../../features/profile/presentation/screens/customer_notifications_screen.dart';
import '../../features/profile/presentation/screens/customer_settings_screen.dart';
import '../../features/profile/presentation/screens/customer_help_support_screen.dart';
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
        GoRoute(
          path: '/profile/personal-info',
          builder: (BuildContext context, GoRouterState state) => const CustomerPersonalInfoScreen(),
        ),
        GoRoute(
          path: '/profile/addresses',
          builder: (BuildContext context, GoRouterState state) => const CustomerAddressesScreen(),
        ),
        GoRoute(
          path: '/profile/addresses/add',
          builder: (BuildContext context, GoRouterState state) => const CustomerAddAddressScreen(),
        ),
        GoRoute(
          path: '/profile/payment-methods',
          builder: (BuildContext context, GoRouterState state) => const CustomerPaymentMethodsScreen(),
        ),
        GoRoute(
          path: '/profile/payment-methods/add',
          builder: (BuildContext context, GoRouterState state) => const CustomerAddPaymentMethodScreen(),
        ),
        GoRoute(
          path: '/profile/my-bookings',
          builder: (BuildContext context, GoRouterState state) => const CustomerMyBookingsScreen(),
        ),
        GoRoute(
          path: '/profile/my-bookings/details',
          builder: (BuildContext context, GoRouterState state) {
            final extra = state.extra as Map<String, dynamic>? ?? {};
            return CustomerBookingDetailsScreen(booking: extra);
          },
        ),
        GoRoute(
          path: '/profile/saved-services',
          builder: (BuildContext context, GoRouterState state) => const CustomerSavedServicesScreen(),
        ),
        GoRoute(
          path: '/profile/notifications',
          builder: (BuildContext context, GoRouterState state) => const CustomerNotificationsScreen(),
        ),
        GoRoute(
          path: '/profile/settings',
          builder: (BuildContext context, GoRouterState state) => const CustomerSettingsScreen(),
        ),
        GoRoute(
          path: '/profile/help-support',
          builder: (BuildContext context, GoRouterState state) => const CustomerHelpSupportScreen(),
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

    // Multi-Service Requirement Routes
    GoRoute(
      path: '/services/laundry/requirements',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => const LaundryRequirementScreen(),
    ),
    GoRoute(
      path: '/services/car/requirements',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => const CarServiceRequirementScreen(),
    ),
    GoRoute(
      path: '/services/care/requirements',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => const CareTakerRequirementScreen(),
    ),
    GoRoute(
      path: '/services/cooking/requirements',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => const CookingRequirementScreen(),
    ),
    GoRoute(
      path: '/services/plumbing/requirements',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) => const PlumbingRequirementScreen(),
    ),

    // Universal Multi-Service Booking Steps
    GoRoute(
      path: '/services/multi/select-date',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ServiceSelectDateScreen(issueDetails: extra);
      },
    ),
    GoRoute(
      path: '/services/multi/select-time',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final selectedDate = extra['selected_date'] as BookingDateOption? ??
            ACAvailabilityService.instance.getNext3BookingDates().first;
        return ServiceSelectTimeScreen(issueDetails: extra, selectedDate: selectedDate);
      },
    ),
    GoRoute(
      path: '/services/multi/address',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final selectedDate = extra['selected_date'] as BookingDateOption? ??
            ACAvailabilityService.instance.getNext3BookingDates().first;
        final selectedTime = extra['selected_time'] as String? ?? '02:00 PM';
        return ServiceAddressDetailsScreen(
          issueDetails: extra,
          selectedDate: selectedDate,
          selectedTime: selectedTime,
        );
      },
    ),
    GoRoute(
      path: '/services/multi/review-confirm',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final selectedDate = extra['selected_date'] as BookingDateOption? ??
            ACAvailabilityService.instance.getNext3BookingDates().first;
        final selectedTime = extra['selected_time'] as String? ?? '02:00 PM';
        return ServiceReviewConfirmScreen(
          issueDetails: extra,
          selectedDate: selectedDate,
          selectedTime: selectedTime,
        );
      },
    ),
    GoRoute(
      path: '/services/multi/finding-partner',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (BuildContext context, GoRouterState state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final bookingData = extra['booking_data'] as Map<String, dynamic>? ?? {};
        final bookingId = (extra['booking_id'] ?? bookingData['id'] ?? bookingData['booking_id'] ?? '').toString();
        final catId = (extra['category_id'] ?? bookingData['category_id'] ?? 'ac_service').toString();
        final config = MultiServiceBookingService.instance.getCategoryConfig(catId);
        return ServiceFindingPartnerScreen(
          bookingId: bookingId,
          serviceTitle: extra['service_title'] as String? ?? 'Service',
          address: extra['address'] as String? ?? '',
          selectedDateFormatted: extra['selected_date_formatted'] as String? ?? 'Tomorrow',
          selectedTime: extra['selected_time'] as String? ?? '02:00 PM',
          categoryConfig: config,
          customerPhone: extra['customer_phone'] as String? ?? '',
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
        final extraData = state.extra as Map<String, dynamic>?;
        return TrackBookingScreen(
          bookingId: bookingId,
          initialBookingData: extraData,
        );
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
