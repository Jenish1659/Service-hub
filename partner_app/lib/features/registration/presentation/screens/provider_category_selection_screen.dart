import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/sh_logo_widget.dart';
import '../../../../core/widgets/vector_avatar_widgets.dart';

class ServiceCategoryModel {
  final String id;
  final String title;
  final String subtitle;
  final IconData mainIcon;
  final IconData subIcon;
  final List<Color> gradientColors;
  final Color accentColor;

  const ServiceCategoryModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.mainIcon,
    required this.subIcon,
    required this.gradientColors,
    required this.accentColor,
  });
}

class ProviderCategorySelectionScreen extends StatefulWidget {
  const ProviderCategorySelectionScreen({super.key});

  @override
  State<ProviderCategorySelectionScreen> createState() => _ProviderCategorySelectionScreenState();
}

class _ProviderCategorySelectionScreenState extends State<ProviderCategorySelectionScreen> {
  String? _selectedCategoryId;

  static const List<ServiceCategoryModel> _categories = [
    ServiceCategoryModel(
      id: 'ac_service',
      title: 'AC Service Provider',
      subtitle: 'Installation, Repairing\n& Maintenance',
      mainIcon: Icons.hvac_rounded,
      subIcon: Icons.ac_unit_rounded,
      gradientColors: [Color(0xFF1E40AF), Color(0xFF3B82F6)],
      accentColor: Color(0xFF2563EB),
    ),
    ServiceCategoryModel(
      id: 'laundry',
      title: 'Laundry Provider',
      subtitle: 'Washing, Ironing\n& Dry Cleaning',
      mainIcon: Icons.local_laundry_service_rounded,
      subIcon: Icons.dry_cleaning_rounded,
      gradientColors: [Color(0xFF4338CA), Color(0xFF6366F1)],
      accentColor: Color(0xFF4F46E5),
    ),
    ServiceCategoryModel(
      id: 'cooking',
      title: 'Cooking Provider',
      subtitle: 'Home Cooking, Chef\n& Meal Preparation',
      mainIcon: Icons.soup_kitchen_rounded,
      subIcon: Icons.restaurant_menu_rounded,
      gradientColors: [Color(0xFFD97706), Color(0xFFF59E0B)],
      accentColor: Color(0xFFEAB308),
    ),
    ServiceCategoryModel(
      id: 'car_service',
      title: 'Car Service Provider',
      subtitle: 'Repairing, Washing\n& Maintenance',
      mainIcon: Icons.directions_car_rounded,
      subIcon: Icons.car_repair_rounded,
      gradientColors: [Color(0xFFDC2626), Color(0xFFEF4444)],
      accentColor: Color(0xFFE11D48),
    ),
    ServiceCategoryModel(
      id: 'care_taker',
      title: 'Care Taker Provider',
      subtitle: 'Elderly Care, Baby Care\n& Home Care',
      mainIcon: Icons.medical_services_rounded,
      subIcon: Icons.favorite_rounded,
      gradientColors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
      accentColor: Color(0xFF0F766E),
    ),
    ServiceCategoryModel(
      id: 'plumber',
      title: 'Plumber Provider',
      subtitle: 'Plumbing, Pipe Fitting\n& Repairs',
      mainIcon: Icons.plumbing_rounded,
      subIcon: Icons.build_rounded,
      gradientColors: [Color(0xFF0284C7), Color(0xFF38BDF8)],
      accentColor: Color(0xFF0369A1),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.bgLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderLight),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: AppColors.primaryNavy, size: 14),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/register');
            }
          },
        ),
        title: const ShLogoWidget(size: 32, showSubtitle: true),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    // Hero Vector Banner Header Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: Flex(
                        direction: isDesktop ? Axis.horizontal : Axis.vertical,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: isDesktop ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                            children: const [
                              Text(
                                'Which type of\nprovider are you?',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryNavy,
                                  height: 1.2,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Select the service category that\nbest describes your business',
                                textAlign: TextAlign.left,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textMuted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isDesktop ? 0 : 16),
                          // Service Provider Avatar & Vector Floating Badges
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              const ServiceProviderAvatar(size: 100),
                              Positioned(
                                top: 0,
                                right: 10,
                                child: _buildFloatingIconBadge(Icons.hvac_rounded, const Color(0xFF0284C7)),
                              ),
                              Positioned(
                                top: 12,
                                left: 0,
                                child: _buildFloatingIconBadge(Icons.local_laundry_service_rounded, const Color(0xFFEC4899)),
                              ),
                              Positioned(
                                bottom: 12,
                                right: 0,
                                child: _buildFloatingIconBadge(Icons.soup_kitchen_rounded, const Color(0xFFF59E0B)),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 10,
                                child: _buildFloatingIconBadge(Icons.directions_car_rounded, const Color(0xFF8B5CF6)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Service Provider Category Options List Container
                    Container(
                      constraints: const BoxConstraints(maxWidth: 580),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: _categories.map((category) {
                          final isSelected = _selectedCategoryId == category.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedCategoryId = category.id;
                                });
                              },
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected ? AppColors.providerBluePrimary : AppColors.borderLight,
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isSelected
                                          ? AppColors.providerBluePrimary.withValues(alpha: 0.15)
                                          : Colors.black.withValues(alpha: 0.03),
                                      blurRadius: isSelected ? 12 : 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    // Custom Vector Illustration Container (No bitmap images per request)
                                    _buildVectorCategoryThumbnail(category),

                                    const SizedBox(width: 16),

                                    // Title and Description Text
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category.title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              color: isSelected ? AppColors.providerBluePrimary : AppColors.primaryNavy,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            category.subtitle,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted,
                                              height: 1.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(width: 8),

                                    // Selection Chevron / Active Indicator Badge
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: isSelected ? AppColors.providerBluePrimary : const Color(0xFFF8FAFC),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? AppColors.providerBluePrimary : AppColors.borderLight,
                                        ),
                                      ),
                                      child: Icon(
                                        isSelected ? Icons.check_rounded : Icons.chevron_right_rounded,
                                        color: isSelected ? Colors.white : AppColors.textMuted,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Sticky Navigation CTA Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 540),
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedCategoryId != null
                            ? AppColors.providerBluePrimary
                            : Colors.grey.shade400,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: _selectedCategoryId != null ? 4 : 0,
                      ),
                      onPressed: _selectedCategoryId != null
                          ? () {
                              context.push('/register/service-options/$_selectedCategoryId');
                            }
                          : null,
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pure Code Vector Illustration Thumbnail Box
  Widget _buildVectorCategoryThumbnail(ServiceCategoryModel category) {
    return Container(
      width: 100,
      height: 76,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: category.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        children: [
          // Decorative background vector circles
          Positioned(
            right: -10,
            bottom: -10,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -8,
            top: -8,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Main Vector Icons Center
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(category.mainIcon, color: Colors.white, size: 30),
                const SizedBox(width: 4),
                Icon(category.subIcon, color: Colors.white.withValues(alpha: 0.85), size: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingIconBadge(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Icon(icon, color: Colors.white, size: 12),
    );
  }
}
