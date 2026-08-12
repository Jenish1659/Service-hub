import 'package:go_router/go_router.dart';
import '../../features/onboarding/presentation/storyboard_animation_screen.dart';
import '../../features/auth/presentation/role_selection_screen.dart';
import '../../features/auth/presentation/service_provider_login_screen.dart';
import '../../features/auth/presentation/shopkeeper_login_screen.dart';
import '../../features/auth/presentation/delivery_agent_login_screen.dart';
import '../../features/registration/presentation/screens/provider_basic_info_registration_screen.dart';
import '../../features/registration/presentation/screens/provider_category_selection_screen.dart';
import '../../features/registration/presentation/screens/provider_service_options_selection_screen.dart';
import '../../features/registration/presentation/screens/provider_experience_registration_screen.dart';
import '../../features/registration/presentation/screens/provider_identity_verification_screen.dart';

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
    // Service Options Routes
    GoRoute(
      path: '/register/service-options/:categoryId',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId'] ?? 'ac_service';
        return ProviderServiceOptionsSelectionScreen(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/register/service-options/ac_service',
      builder: (context, state) => const ProviderServiceOptionsSelectionScreen(categoryId: 'ac_service'),
    ),
    GoRoute(
      path: '/register/service-options/laundry',
      builder: (context, state) => const ProviderServiceOptionsSelectionScreen(categoryId: 'laundry'),
    ),
    GoRoute(
      path: '/register/service-options/cooking',
      builder: (context, state) => const ProviderServiceOptionsSelectionScreen(categoryId: 'cooking'),
    ),
    GoRoute(
      path: '/register/service-options/car_service',
      builder: (context, state) => const ProviderServiceOptionsSelectionScreen(categoryId: 'car_service'),
    ),
    GoRoute(
      path: '/register/service-options/care_taker',
      builder: (context, state) => const ProviderServiceOptionsSelectionScreen(categoryId: 'care_taker'),
    ),
    GoRoute(
      path: '/register/service-options/plumber',
      builder: (context, state) => const ProviderServiceOptionsSelectionScreen(categoryId: 'plumber'),
    ),

    // Professional Experience & Certification Routes
    GoRoute(
      path: '/register/experience/:categoryId',
      builder: (context, state) {
        final categoryId = state.pathParameters['categoryId'] ?? 'ac_service';
        return ProviderExperienceRegistrationScreen(categoryId: categoryId);
      },
    ),
    GoRoute(
      path: '/register/experience/ac_service',
      builder: (context, state) => const ProviderExperienceRegistrationScreen(categoryId: 'ac_service'),
    ),
    GoRoute(
      path: '/register/experience/laundry',
      builder: (context, state) => const ProviderExperienceRegistrationScreen(categoryId: 'laundry'),
    ),
    GoRoute(
      path: '/register/experience/cooking',
      builder: (context, state) => const ProviderExperienceRegistrationScreen(categoryId: 'cooking'),
    ),
    GoRoute(
      path: '/register/experience/car_service',
      builder: (context, state) => const ProviderExperienceRegistrationScreen(categoryId: 'car_service'),
    ),
    GoRoute(
      path: '/register/experience/care_taker',
      builder: (context, state) => const ProviderExperienceRegistrationScreen(categoryId: 'care_taker'),
    ),
    GoRoute(
      path: '/register/experience/plumber',
      builder: (context, state) => const ProviderExperienceRegistrationScreen(categoryId: 'plumber'),
    ),
    // Step 4: Verify Your Identity Route
    GoRoute(
      path: '/register/verify-identity',
      builder: (context, state) => const ProviderIdentityVerificationScreen(),
    ),
  ],
);
