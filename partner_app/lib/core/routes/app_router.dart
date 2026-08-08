import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/storyboard_animation_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/service_provider_login_screen.dart';
import '../../features/auth/presentation/shopkeeper_login_screen.dart';
import '../../features/auth/presentation/delivery_agent_login_screen.dart';
import '../../features/registration/presentation/screens/provider_basic_info_registration_screen.dart';
import '../../features/registration/presentation/screens/provider_category_selection_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const StoryboardAnimationScreen(),
    ),
    GoRoute(
      path: '/role-selection',
      builder: (context, state) => const RoleSelectionScreen(),
    ),
    GoRoute(
      path: '/login/service-provider',
      builder: (context, state) => const ServiceProviderLoginScreen(),
    ),
    GoRoute(
      path: '/login/shopkeeper',
      builder: (context, state) => const ShopkeeperLoginScreen(),
    ),
    GoRoute(
      path: '/login/delivery-agent',
      builder: (context, state) => const DeliveryAgentLoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const ProviderBasicInfoRegistrationScreen(),
    ),
    GoRoute(
      path: '/register/service-category',
      builder: (context, state) => const ProviderCategorySelectionScreen(),
    ),
  ],
);
