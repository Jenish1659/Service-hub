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

import '../../features/registration/presentation/screens/provider_review_application_screen.dart';
import '../../features/registration/presentation/screens/provider_registration_success_screen.dart';
import '../../features/registration/presentation/screens/provider_application_status_screen.dart';
import '../../features/registration/presentation/screens/shopkeeper_registration_flow_screen.dart';
import '../../features/dashboard/presentation/provider_dashboard_screen.dart';
import '../../features/dashboard/presentation/delivery_dashboard_screen.dart';
import '../../features/dashboard/presentation/shopkeeper_dashboard_screen.dart';
import '../../features/dashboard/presentation/ac_active_job_navigation_screen.dart';
import '../../features/registration/presentation/screens/delivery_partner_registration_flow_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/my_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/my_services_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/availability_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/earnings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/service_area_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/settings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/documents_and_verification_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/help_and_support_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/report_a_problem_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delete_account_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/login_and_security_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/terms_and_conditions_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/privacy_policy_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/about_service_hub_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_edit_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_documents_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/shopkeeper_profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_agent_profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/dashboard/ac-job-navigation',
      builder: (context, state) {
        final job = state.extra as Map<String, dynamic>? ?? <String, dynamic>{};
        return ACActiveJobNavigationScreen(job: job);
      },
    ),
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
      path: '/register/shopkeeper',
      builder: (context, state) => const ShopkeeperRegistrationFlowScreen(),
    ),
    GoRoute(
      path: '/register/delivery-partner',
      builder: (context, state) => const DeliveryPartnerRegistrationFlowScreen(),
    ),
    GoRoute(
      path: '/register/delivery-agent',
      builder: (context, state) => const DeliveryPartnerRegistrationFlowScreen(),
    ),
    GoRoute(
      path: '/register/delivery_agent',
      builder: (context, state) => const DeliveryPartnerRegistrationFlowScreen(),
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

    // Step 5: Verify Your Identity Route
    GoRoute(
      path: '/register/verify-identity',
      builder: (context, state) => const ProviderIdentityVerificationScreen(),
    ),

    // Step 6: Review & Final Submit Route
    GoRoute(
      path: '/register/review',
      builder: (context, state) => const ProviderReviewApplicationScreen(),
    ),

    // Step 7: Submission Success Route
    GoRoute(
      path: '/register/success',
      builder: (context, state) => const ProviderRegistrationSuccessScreen(),
    ),

    // Application Status Tracker Route
    GoRoute(
      path: '/register/status-tracker',
      builder: (context, state) => ProviderApplicationStatusScreen(
        initialIdentifier: state.extra as String?,
      ),
    ),

    // Provider Main Dashboard Route (AC & Services)
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const ProviderDashboardScreen(),
    ),

    // Delivery Agent Main Dashboard Route
    GoRoute(
      path: '/dashboard/delivery',
      builder: (context, state) => const DeliveryDashboardScreen(),
    ),

    // Shopkeeper Store Main Dashboard Route
    GoRoute(
      path: '/dashboard/shopkeeper',
      builder: (context, state) => const ShopkeeperDashboardScreen(),
    ),

    // Dedicated Shopkeeper Profile Routes (Strictly for Shopkeeper Only)
    GoRoute(
      path: '/profile/shopkeeper',
      builder: (context, state) => const ShopkeeperProfileScreen(),
    ),
    GoRoute(
      path: '/profile/shopkeeper/edit',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController? ?? ShopkeeperProfileController();
        return ShopkeeperEditProfileScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/documents',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController? ?? ShopkeeperProfileController();
        return ShopkeeperDocumentsScreen(controller: ctrl);
      },
    ),

    // Dedicated Delivery Agent Profile Route (Strictly for Delivery Agent Only)
    GoRoute(
      path: '/profile/delivery',
      builder: (context, state) => const DeliveryAgentProfileScreen(),
    ),

    // Service Provider Profile Routes (Strictly for Service Provider Only)
    GoRoute(
      path: '/profile',
      builder: (context, state) => const MyProfileScreen(),
    ),
    GoRoute(
      path: '/profile/edit',
      builder: (context, state) {
        final ctrl = state.extra as ProfileController? ?? ProfileController();
        return EditProfileScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/services',
      builder: (context, state) {
        final ctrl = state.extra as ProfileController? ?? ProfileController();
        return MyServicesScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/availability',
      builder: (context, state) {
        final ctrl = state.extra as ProfileController? ?? ProfileController();
        return AvailabilityScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/earnings',
      builder: (context, state) {
        final ctrl = state.extra as ProfileController? ?? ProfileController();
        return EarningsScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/service-area',
      builder: (context, state) {
        final ctrl = state.extra as ProfileController? ?? ProfileController();
        return ServiceAreaScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/settings',
      builder: (context, state) {
        final ctrl = state.extra as ProfileController? ?? ProfileController();
        return SettingsScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/documents',
      builder: (context, state) {
        final ctrl = state.extra as ProfileController? ?? ProfileController();
        return DocumentsAndVerificationScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/help',
      builder: (context, state) {
        final ctrl = state.extra as ProfileController? ?? ProfileController();
        return HelpAndSupportScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/report-problem',
      builder: (context, state) {
        final ctrl = state.extra as ProfileController? ?? ProfileController();
        return ReportAProblemScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/delete-account',
      builder: (context, state) {
        final ctrl = state.extra as ProfileController? ?? ProfileController();
        return DeleteAccountScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/login-security',
      builder: (context, state) {
        final ctrl = state.extra as ProfileController? ?? ProfileController();
        return LoginAndSecurityScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/terms',
      builder: (context, state) => const TermsAndConditionsScreen(),
    ),
    GoRoute(
      path: '/profile/privacy',
      builder: (context, state) => const PrivacyPolicyScreen(),
    ),
    GoRoute(
      path: '/profile/about',
      builder: (context, state) => const AboutServiceHubScreen(),
    ),
  ],
);
