import 'package:go_router/go_router.dart';
import '../../features/chat/presentation/partner_chat_screen.dart';
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
import '../../features/dashboard/presentation/delivery_dashboard_screen.dart';
import '../../features/dashboard/presentation/shopkeeper_dashboard_screen.dart';
import '../../features/dashboard/presentation/ac_active_job_navigation_screen.dart';
import '../../features/dashboard/presentation/delivery_live_map_screen.dart';
import '../../features/dashboard/presentation/shopkeeper_store_map_screen.dart';
import '../../features/dashboard/presentation/provider_live_radar_map_screen.dart';
import '../../features/registration/presentation/screens/delivery_partner_registration_flow_screen.dart';
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
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_info_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_business_hours_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_service_area_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_photos_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_documents_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_contact_details_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_bank_details_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/shopkeeper_profile_controller.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_settings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_account_security_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_notification_settings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_app_preferences_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_privacy_permissions_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_change_password_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_active_sessions_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_delete_account_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_help_support_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/shopkeeper_about_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_agent_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_edit_profile_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_availability_shift_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_area_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_documents_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_earnings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_settings_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/screens/delivery_help_support_screen.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/delivery_agent_profile_controller.dart';
import '../../features/ac_service_partner/presentation/screens/ac_partner_dashboard_screen.dart';
import '../../features/ac_service_partner/presentation/screens/ac_partner_profile_screen.dart';
import '../../features/care_taker_partner/presentation/screens/care_partner_dashboard_screen.dart';
import '../../features/care_taker_partner/presentation/screens/care_partner_profile_screen.dart';
import '../../features/care_taker_partner/presentation/screens/care_live_map_screen.dart';
import '../../features/care_taker_partner/presentation/screens/care_request_details_screen.dart';
import '../../features/care_taker_partner/presentation/screens/care_personal_info_screen.dart';
import '../../features/care_taker_partner/presentation/screens/care_business_info_screen.dart';
import '../../features/care_taker_partner/presentation/screens/care_service_pricing_screen.dart';
import '../../features/care_taker_partner/presentation/screens/care_working_hours_screen.dart';
import '../../features/care_taker_partner/presentation/screens/care_documents_screen.dart';
import '../../features/care_taker_partner/presentation/screens/care_bank_details_screen.dart';
import '../../features/care_taker_partner/presentation/screens/care_settings_screen.dart';
import '../../features/cooking_partner/presentation/screens/cooking_partner_dashboard_screen.dart';
import '../../features/cooking_partner/presentation/screens/cooking_partner_profile_screen.dart';
import '../../features/laundry_partner/presentation/screens/laundry_partner_dashboard_screen.dart';
import '../../features/laundry_partner/presentation/screens/laundry_partner_profile_screen.dart';
import '../../features/laundry_partner/presentation/screens/laundry_store_map_screen.dart';
import '../../features/car_service_partner/presentation/screens/car_partner_dashboard_screen.dart';
import '../../features/car_service_partner/presentation/screens/car_partner_profile_screen.dart';
import '../../features/car_service_partner/presentation/screens/car_live_map_screen.dart';
import '../../features/car_service_partner/presentation/screens/car_request_details_screen.dart';
import '../../features/car_service_partner/presentation/screens/car_personal_info_screen.dart';
import '../../features/car_service_partner/presentation/screens/car_business_info_screen.dart';
import '../../features/car_service_partner/presentation/screens/car_service_pricing_screen.dart';
import '../../features/car_service_partner/presentation/screens/car_working_hours_screen.dart';
import '../../features/car_service_partner/presentation/screens/car_documents_screen.dart';
import '../../features/car_service_partner/presentation/screens/car_bank_details_screen.dart';
import '../../features/car_service_partner/presentation/screens/car_settings_screen.dart';
import '../../features/plumbing_partner/presentation/screens/plumbing_partner_dashboard_screen.dart';
import '../../features/plumbing_partner/presentation/screens/plumbing_partner_profile_screen.dart';
import '../../features/plumbing_partner/presentation/screens/plumbing_live_map_screen.dart';
import '../../features/plumbing_partner/presentation/screens/plumbing_request_details_screen.dart';
import '../../features/plumbing_partner/presentation/screens/plumbing_personal_info_screen.dart';
import '../../features/plumbing_partner/presentation/screens/plumbing_business_info_screen.dart';
import '../../features/plumbing_partner/presentation/screens/plumbing_service_pricing_screen.dart';
import '../../features/plumbing_partner/presentation/screens/plumbing_working_hours_screen.dart';
import '../../features/plumbing_partner/presentation/screens/plumbing_documents_screen.dart';
import '../../features/plumbing_partner/presentation/screens/plumbing_settings_screen.dart';
import '../utils/service_category_route_helper.dart';

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
      path: '/login/delivery',
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

    // Provider Main Dashboard Route (AC & Services fallback with dynamic category resolution)
    GoRoute(
      path: '/dashboard',
      redirect: (context, state) async {
        final cat = await ServiceCategoryRouteHelper.resolveActivePartnerCategory();
        return ServiceCategoryRouteHelper.getDashboardRoute(cat);
      },
      builder: (context, state) => const ACPartnerDashboardScreen(),
    ),

    // Service-Wise Dedicated Partner Dashboards
    GoRoute(
      path: '/dashboard/ac',
      builder: (context, state) => const ACPartnerDashboardScreen(),
    ),
    GoRoute(
      path: '/dashboard/care-taker',
      builder: (context, state) => const CarePartnerDashboardScreen(),
    ),
    GoRoute(
      path: '/dashboard/cooking',
      builder: (context, state) => const CookingPartnerDashboardScreen(),
    ),
    GoRoute(
      path: '/dashboard/laundry',
      builder: (context, state) => const LaundryPartnerDashboardScreen(),
    ),
    GoRoute(
      path: '/dashboard/car-service',
      builder: (context, state) => const CarPartnerDashboardScreen(),
    ),
    GoRoute(
      path: '/dashboard/plumbing',
      builder: (context, state) => const PlumbingPartnerDashboardScreen(),
    ),

    // Service-Wise Dedicated Partner Profiles
    GoRoute(
      path: '/profile/ac',
      builder: (context, state) => const ACPartnerProfileScreen(),
    ),
    GoRoute(
      path: '/profile/care-taker',
      builder: (context, state) => const CarePartnerProfileScreen(),
    ),
    GoRoute(
      path: '/dashboard/care-taker/map',
      builder: (context, state) => const CareLiveMapScreen(),
    ),
    GoRoute(
      path: '/dashboard/care-taker/request-details',
      builder: (context, state) {
        final b = state.extra as Map<String, dynamic>? ?? {};
        return CareRequestDetailsScreen(booking: b);
      },
    ),
    GoRoute(
      path: '/profile/care-taker/personal',
      builder: (context, state) => const CarePersonalInfoScreen(),
    ),
    GoRoute(
      path: '/profile/care-taker/personal-info',
      builder: (context, state) => const CarePersonalInfoScreen(),
    ),
    GoRoute(
      path: '/profile/care-taker/business',
      builder: (context, state) => const CareBusinessInfoScreen(),
    ),
    GoRoute(
      path: '/profile/care-taker/business-info',
      builder: (context, state) => const CareBusinessInfoScreen(),
    ),
    GoRoute(
      path: '/profile/care-taker/pricing',
      builder: (context, state) => const CareServicePricingScreen(),
    ),
    GoRoute(
      path: '/profile/care-taker/service-pricing',
      builder: (context, state) => const CareServicePricingScreen(),
    ),
    GoRoute(
      path: '/profile/care-taker/hours',
      builder: (context, state) => const CareWorkingHoursScreen(),
    ),
    GoRoute(
      path: '/profile/care-taker/working-hours',
      builder: (context, state) => const CareWorkingHoursScreen(),
    ),
    GoRoute(
      path: '/profile/care-taker/documents',
      builder: (context, state) => const CareDocumentsScreen(),
    ),
    GoRoute(
      path: '/profile/care-taker/bank',
      builder: (context, state) => const CareBankDetailsScreen(),
    ),
    GoRoute(
      path: '/profile/care-taker/settings',
      builder: (context, state) => const CareSettingsScreen(),
    ),
    GoRoute(
      path: '/profile/cooking',
      builder: (context, state) => const CookingPartnerProfileScreen(),
    ),
    GoRoute(
      path: '/profile/laundry',
      builder: (context, state) => const LaundryPartnerProfileScreen(),
    ),
    GoRoute(
      path: '/dashboard/laundry/map',
      builder: (context, state) => const LaundryStoreMapScreen(),
    ),
    GoRoute(
      path: '/profile/car-service',
      builder: (context, state) => const CarPartnerProfileScreen(),
    ),
    GoRoute(
      path: '/dashboard/car-service/map',
      builder: (context, state) => const CarLiveMapScreen(),
    ),
    GoRoute(
      path: '/dashboard/car-service/request-details',
      builder: (context, state) {
        final b = state.extra as Map<String, dynamic>? ?? {};
        return CarRequestDetailsScreen(booking: b);
      },
    ),
    GoRoute(
      path: '/profile/car-service/personal',
      builder: (context, state) => const CarPersonalInfoScreen(),
    ),
    GoRoute(
      path: '/profile/car-service/personal-info',
      builder: (context, state) => const CarPersonalInfoScreen(),
    ),
    GoRoute(
      path: '/profile/car-service/business',
      builder: (context, state) => const CarBusinessInfoScreen(),
    ),
    GoRoute(
      path: '/profile/car-service/business-info',
      builder: (context, state) => const CarBusinessInfoScreen(),
    ),
    GoRoute(
      path: '/profile/car-service/pricing',
      builder: (context, state) => const CarServicePricingScreen(),
    ),
    GoRoute(
      path: '/profile/car-service/service-pricing',
      builder: (context, state) => const CarServicePricingScreen(),
    ),
    GoRoute(
      path: '/profile/car-service/hours',
      builder: (context, state) => const CarWorkingHoursScreen(),
    ),
    GoRoute(
      path: '/profile/car-service/working-hours',
      builder: (context, state) => const CarWorkingHoursScreen(),
    ),
    GoRoute(
      path: '/profile/car-service/documents',
      builder: (context, state) => const CarDocumentsScreen(),
    ),
    GoRoute(
      path: '/profile/car-service/bank',
      builder: (context, state) => const CarBankDetailsScreen(),
    ),
    GoRoute(
      path: '/profile/car-service/settings',
      builder: (context, state) => const CarSettingsScreen(),
    ),
    GoRoute(
      path: '/profile/plumbing',
      builder: (context, state) => const PlumbingPartnerProfileScreen(),
    ),
    GoRoute(
      path: '/dashboard/plumbing/map',
      builder: (context, state) => const PlumbingLiveMapScreen(),
    ),
    GoRoute(
      path: '/dashboard/plumbing/request-details',
      builder: (context, state) {
        final b = state.extra as Map<String, dynamic>? ?? {};
        return PlumbingRequestDetailsScreen(booking: b);
      },
    ),
    GoRoute(
      path: '/profile/plumbing/personal-info',
      builder: (context, state) => const PlumbingPersonalInfoScreen(),
    ),
    GoRoute(
      path: '/profile/plumbing/business-info',
      builder: (context, state) => const PlumbingBusinessInfoScreen(),
    ),
    GoRoute(
      path: '/profile/plumbing/service-pricing',
      builder: (context, state) => const PlumbingServicePricingScreen(),
    ),
    GoRoute(
      path: '/profile/plumbing/working-hours',
      builder: (context, state) => const PlumbingWorkingHoursScreen(),
    ),
    GoRoute(
      path: '/profile/plumbing/documents',
      builder: (context, state) => const PlumbingDocumentsScreen(),
    ),
    GoRoute(
      path: '/profile/plumbing/settings',
      builder: (context, state) => const PlumbingSettingsScreen(),
    ),

    // Provider Live Radar Map Route
    GoRoute(
      path: '/dashboard/provider/map',
      builder: (context, state) => const ProviderLiveRadarMapScreen(),
    ),

    // Delivery Agent Main Dashboard Route
    GoRoute(
      path: '/dashboard/delivery',
      builder: (context, state) => const DeliveryDashboardScreen(),
    ),

    // Delivery Agent Live Navigation Map Route
    GoRoute(
      path: '/delivery/map',
      builder: (context, state) {
        final task = state.extra as Map<String, dynamic>? ?? <String, dynamic>{};
        return DeliveryLiveMapScreen(task: task);
      },
    ),

    // Shopkeeper Store Main Dashboard Route
    GoRoute(
      path: '/dashboard/shopkeeper',
      builder: (context, state) => const ShopkeeperDashboardScreen(),
    ),

    // Shopkeeper Store Live Map Route
    GoRoute(
      path: '/dashboard/shopkeeper/map',
      builder: (context, state) => const ShopkeeperStoreMapScreen(),
    ),

    // Dedicated Shopkeeper Profile Routes (Strictly for Shopkeeper Only)
    GoRoute(
      path: '/profile/shopkeeper',
      builder: (context, state) => const ShopkeeperProfileScreen(),
    ),
    GoRoute(
      path: '/profile/shopkeeper/info',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController? ?? ShopkeeperProfileController();
        return ShopkeeperInfoScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/edit',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController? ?? ShopkeeperProfileController();
        return ShopkeeperEditProfileScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/hours',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController? ?? ShopkeeperProfileController();
        return ShopkeeperBusinessHoursScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/service-area',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController? ?? ShopkeeperProfileController();
        return ShopkeeperServiceAreaScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/photos',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController? ?? ShopkeeperProfileController();
        return ShopkeeperPhotosScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/documents',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController? ?? ShopkeeperProfileController();
        return ShopkeeperDocumentsScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/contact',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController? ?? ShopkeeperProfileController();
        return ShopkeeperContactDetailsScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/bank',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController? ?? ShopkeeperProfileController();
        return ShopkeeperBankDetailsScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/settings',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController?;
        return ShopkeeperSettingsScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/settings/security',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController?;
        return ShopkeeperAccountSecurityScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/settings/notifications',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController?;
        return ShopkeeperNotificationSettingsScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/settings/preferences',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController?;
        return ShopkeeperAppPreferencesScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/settings/privacy-permissions',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController?;
        return ShopkeeperPrivacyPermissionsScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/settings/change-password',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController?;
        return ShopkeeperChangePasswordScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/settings/active-sessions',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController?;
        return ShopkeeperActiveSessionsScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/settings/delete-account',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController?;
        return ShopkeeperDeleteAccountScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/settings/help',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController?;
        return ShopkeeperHelpSupportScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/shopkeeper/settings/about',
      builder: (context, state) {
        final ctrl = state.extra as ShopkeeperProfileController?;
        return ShopkeeperAboutScreen(controller: ctrl);
      },
    ),

    // Dedicated Delivery Agent Profile Route (Strictly for Delivery Agent Only)
    GoRoute(
      path: '/profile/delivery',
      builder: (context, state) => const DeliveryAgentProfileScreen(),
    ),
    GoRoute(
      path: '/profile/delivery/edit',
      builder: (context, state) {
        final ctrl = state.extra as DeliveryAgentProfileController?;
        return DeliveryEditProfileScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/delivery/shift',
      builder: (context, state) {
        final ctrl = state.extra as DeliveryAgentProfileController?;
        return DeliveryAvailabilityShiftScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/delivery/area',
      builder: (context, state) {
        final ctrl = state.extra as DeliveryAgentProfileController?;
        return DeliveryAreaScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/delivery/documents',
      builder: (context, state) {
        final ctrl = state.extra as DeliveryAgentProfileController?;
        return DeliveryDocumentsScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/delivery/earnings',
      builder: (context, state) {
        final ctrl = state.extra as DeliveryAgentProfileController?;
        return DeliveryEarningsScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/delivery/settings',
      builder: (context, state) {
        final ctrl = state.extra as DeliveryAgentProfileController?;
        return DeliverySettingsScreen(controller: ctrl);
      },
    ),
    GoRoute(
      path: '/profile/delivery/help',
      builder: (context, state) {
        final ctrl = state.extra as DeliveryAgentProfileController?;
        return DeliveryHelpSupportScreen(controller: ctrl);
      },
    ),

    // Service Provider Profile Routes (Strictly for Service Provider Only, with dynamic category redirect)
    GoRoute(
      path: '/profile',
      redirect: (context, state) async {
        final cat = await ServiceCategoryRouteHelper.resolveActivePartnerCategory();
        return ServiceCategoryRouteHelper.getProfileRoute(cat);
      },
      builder: (context, state) => const ACPartnerProfileScreen(),
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
    GoRoute(
      path: '/chat/:id',
      builder: (context, state) {
        final bookingId = state.pathParameters['id'] ?? '';
        final extra = state.extra as Map<String, dynamic>?;
        return PartnerChatScreen(
          bookingId: bookingId,
          initialCustomerName: extra?['customer_name'] as String?,
          initialCustomerPhone: extra?['customer_phone'] as String?,
          initialServiceName: extra?['service_name'] as String?,
        );
      },
    ),
    GoRoute(
      path: '/chat',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final bookingId = (extra?['booking_id'] ?? extra?['id'] ?? '').toString();
        return PartnerChatScreen(
          bookingId: bookingId,
          initialCustomerName: extra?['customer_name'] as String?,
          initialCustomerPhone: extra?['customer_phone'] as String?,
          initialServiceName: extra?['service_name'] as String?,
        );
      },
    ),
  ],
);
