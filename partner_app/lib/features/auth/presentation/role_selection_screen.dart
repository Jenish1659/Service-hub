import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/vector_avatar_widgets.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Dark Navy Header Card (matching Image 2)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              decoration: const BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Welcome to',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentGold,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'SERVICEHUB ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        TextSpan(
                          text: 'PARTNER',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accentGold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 24, height: 2, color: AppColors.accentGold),
                      const SizedBox(width: 8),
                      Container(width: 12, height: 2, color: Colors.white54),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Title & Subtitle ("Who are you? Choose your role to continue")
            const Text(
              'Who are you?',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose your role to continue',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            // Role Options List (Unlimited time to select)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // 1. Service Provider Card
                    _buildRoleCard(
                      context,
                      title: 'Service Provider',
                      subtitle: 'Provide professional services to customers',
                      avatar: const ServiceProviderAvatar(size: 76),
                      bgColor: AppColors.providerBlueLight,
                      borderColor: AppColors.providerBlueBorder,
                      accentColor: AppColors.providerBluePrimary,
                      route: '/login/service-provider',
                    ),
                    const SizedBox(height: 16),

                    // 2. Shopkeeper Card
                    _buildRoleCard(
                      context,
                      title: 'Shopkeeper',
                      subtitle: 'Manage your store and sell products',
                      avatar: const ShopkeeperAvatar(size: 76),
                      bgColor: AppColors.shopkeeperGreenLight,
                      borderColor: AppColors.shopkeeperGreenBorder,
                      accentColor: AppColors.shopkeeperGreenPrimary,
                      route: '/login/shopkeeper',
                    ),
                    const SizedBox(height: 16),

                    // 3. Delivery Agent Card
                    _buildRoleCard(
                      context,
                      title: 'Delivery Agent',
                      subtitle: 'Deliver orders quickly & safely',
                      avatar: const DeliveryAgentAvatar(size: 76),
                      bgColor: AppColors.deliveryOrangeLight,
                      borderColor: AppColors.deliveryOrangeBorder,
                      accentColor: AppColors.deliveryOrangePrimary,
                      route: '/login/delivery-agent',
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom City Skyline Vector Footer Graphic
            Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, size: 16, color: AppColors.primaryNavy),
                  const SizedBox(width: 6),
                  Text(
                    'ServiceHub Secured Role Gateway',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryNavy.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget avatar,
    required Color bgColor,
    required Color borderColor,
    required Color accentColor,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.go(route),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: accentColor.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Character Avatar Illustration
            avatar,
            const SizedBox(width: 16),

            // Title & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),

            // Action Arrow Circle Button
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryNavy.withOpacity(0.2),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
