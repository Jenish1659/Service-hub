import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/sh_logo_widget.dart';

import '../../../core/storage/local_registration_cache.dart';
import '../../../core/utils/service_category_route_helper.dart';

class StoryboardAnimationScreen extends StatefulWidget {
  const StoryboardAnimationScreen({super.key});

  @override
  State<StoryboardAnimationScreen> createState() => _StoryboardAnimationScreenState();
}

class _StoryboardAnimationScreenState extends State<StoryboardAnimationScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isCheckingSession = true;

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  Future<void> _checkActiveSession() async {
    try {
      Map<String, dynamic>? activePartner = await LocalRegistrationCache.getActivePartner();

      // Fallback: If local cache is null, check Supabase auth
      if (activePartner == null) {
        try {
          final client = Supabase.instance.client;
          final user = client.auth.currentUser;
          if (user != null) {
            final uRes = await client
                .from('users')
                .select('user_id, username, email, phone, role_name, partners(partner_id, verification_status, availability_status)')
                .eq('user_id', user.id)
                .maybeSingle();
            if (uRes != null) {
              dynamic pData = uRes['partners'];
              if (pData is List && pData.isNotEmpty) pData = pData.first;
              activePartner = {
                'user_id': uRes['user_id'],
                'username': uRes['username'],
                'email': uRes['email'],
                'phone': uRes['phone'],
                'role_name': uRes['role_name'],
                'partner_id': pData?['partner_id'] ?? uRes['user_id'],
                'verification_status': pData?['verification_status'] ?? 'VERIFIED',
              };
              await LocalRegistrationCache.updateActivePartner(activePartner);
            }
          }
        } catch (_) {}
      }

      if (activePartner == null) {
        if (mounted) {
          setState(() {
            _isCheckingSession = false;
          });
        }
        return;
      }

      if (mounted) {
        final status = (activePartner['verification_status'] ?? activePartner['status'] ?? activePartner['account_status'] ?? '').toString().toUpperCase();

        // If explicitly pending verification, redirect to status tracker
        if (status == 'PENDING' || status == 'IN_REVIEW') {
          final phoneOrUser = activePartner['phone'] ?? activePartner['username'] ?? activePartner['user_id'];
          context.go('/register/status-tracker', extra: phoneOrUser?.toString());
          return;
        }

        // For verified, active, or existing authenticated partners (non-empty role or partner_id)
        final role = (activePartner['role_name'] ?? activePartner['role'] ?? activePartner['partner_type'] ?? '').toString().toLowerCase();
        if (role == 'delivery_agent' || (role.contains('delivery') && !role.contains('shop') && !role.contains('service'))) {
          context.go('/dashboard/delivery');
          return;
        } else if (role == 'shopkeeper' || role.contains('shop') || role.contains('store')) {
          final cat = (activePartner['category'] ?? activePartner['business_type'] ?? '').toString().toLowerCase();
          if (cat.contains('laundry')) {
            context.go('/dashboard/laundry');
          } else {
            context.go('/dashboard/shopkeeper');
          }
          return;
        } else if (role == 'service_provider' || role.contains('provider') || role.contains('expert') || role.contains('technician')) {
          final cat = activePartner['category'] ?? activePartner['service_category_id'];
          final targetRoute = ServiceCategoryRouteHelper.getDashboardRoute(cat?.toString());
          context.go(targetRoute);
          return;
        } else if (role.isNotEmpty) {
          context.go('/role-selection');
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() {
        _isCheckingSession = false;
      });
    }
  }

  // 7 Storyboard slides (6th slide "Everything in One App" REMOVED as per user instructions)
  final List<Map<String, dynamic>> _slides = [
    {
      'step': '1',
      'stepTitle': 'Launch',
      'title': 'Welcome to ServiceHub',
      'subtitle': 'The Next Generation Partner Platform',
      'type': 'launch',
    },
    {
      'step': '2',
      'stepTitle': 'Logo Reveal',
      'title': 'Multiple Services, One Trust',
      'subtitle': 'Engineered for seamless local service operations',
      'type': 'logo',
    },
    {
      'step': '3',
      'stepTitle': 'City Growing',
      'title': 'Building a Better Tomorrow',
      'subtitle': 'for you and your city',
      'icon': Icons.location_city,
      'color': const Color(0xFF2563EB),
    },
    {
      'step': '4',
      'stepTitle': 'Services Rising',
      'title': 'Multiple Services',
      'subtitle': 'Rising Together',
      'icon': Icons.hub,
      'color': const Color(0xFF7C3AED),
    },
    {
      'step': '5',
      'stepTitle': 'Trust & Secure',
      'title': 'Trusted Partners',
      'subtitle': 'Secure & Verified',
      'icon': Icons.verified_user,
      'color': const Color(0xFF059669),
    },
    {
      'step': '7',
      'stepTitle': 'Ready to Start',
      'title': 'Ready to Make',
      'subtitle': 'Life Easier?',
      'icon': Icons.emoji_objects,
      'color': const Color(0xFFD97706),
    },
    {
      'step': '8',
      'stepTitle': "Let's Begin",
      'title': "Let's Get Started",
      'subtitle': 'Your journey begins with Service Hub',
      'type': 'final',
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F172A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShLogoWidget(size: 80, showSubtitle: false),
              SizedBox(height: 24),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.accentGold),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bgLight,
      body: SafeArea(
        child: Column(
          children: [
            // Top Storyboard Header Banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'APP LAUNCH ANIMATION STORYBOARD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryNavy,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/role-selection'),
                    child: const Text(
                      'Skip >',
                      style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // Step Progress Timeline Indicator Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_slides.length, (index) {
                  final isCurrent = _currentIndex == index;
                  final isPassed = _currentIndex > index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.accentGold
                          : isPassed
                              ? AppColors.primaryNavy
                              : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_slides[index]['step']} ${_slides[index]['stepTitle']}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isCurrent
                            ? AppColors.primaryNavy
                            : isPassed
                                ? Colors.white
                                : Colors.black54,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Main Storyboard Page View
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _buildSlideCard(slide);
                },
              ),
            ),

            // Navigation Controls & Get Started Button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)],
              ),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: AppColors.primaryNavy, size: 20),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryNavy,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        if (_currentIndex < _slides.length - 1) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          context.go('/role-selection');
                        }
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentIndex == _slides.length - 1 ? 'Get Started' : 'Next Step',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward, color: AppColors.accentGold, size: 20),
                        ],
                      ),
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

  Widget _buildSlideCard(Map<String, dynamic> slide) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (slide['type'] == 'launch') ...[
            const ShLogoWidget(size: 110),
            const SizedBox(height: 32),
            Container(
              width: 180,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.7,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accentGold,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Loading...',
              style: TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.bold),
            ),
          ] else if (slide['type'] == 'logo') ...[
            const ShLogoWidget(size: 130),
          ] else if (slide['type'] == 'final') ...[
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primaryNavy,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 8)),
                ],
              ),
              child: const Center(
                child: ShLogoWidget(size: 80, showSubtitle: false),
              ),
            ),
          ] else ...[
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: (slide['color'] as Color).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                slide['icon'] as IconData,
                size: 54,
                color: slide['color'] as Color,
              ),
            ),
          ],
          const SizedBox(height: 28),
          Text(
            slide['title'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primaryNavy,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            slide['subtitle'] as String,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
