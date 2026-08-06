import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Pure Flutter Vector Illustrations for Provider Roles
class ServiceProviderAvatar extends StatelessWidget {
  final double size;
  const ServiceProviderAvatar({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            AppColors.providerBlueLight,
            AppColors.providerBlueBorder,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.providerBluePrimary.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 10,
            child: Icon(
              Icons.location_city,
              size: size * 0.5,
              color: AppColors.providerBluePrimary.withOpacity(0.15),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: size * 0.38,
                    height: size * 0.16,
                    decoration: const BoxDecoration(
                      color: AppColors.providerBluePrimary,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: size * 0.32,
                    height: size * 0.32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD1B3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                width: size * 0.55,
                height: size * 0.32,
                decoration: const BoxDecoration(
                  color: AppColors.providerBlueDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(
                  child: Icon(Icons.build, color: AppColors.accentGold, size: 22),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: const Icon(Icons.handyman, color: AppColors.providerBlueDark, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class ShopkeeperAvatar extends StatelessWidget {
  final double size;
  const ShopkeeperAvatar({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            AppColors.shopkeeperGreenLight,
            AppColors.shopkeeperGreenBorder,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shopkeeperGreenPrimary.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: 16,
            child: Row(
              children: List.generate(
                5,
                (i) => Container(
                  width: size * 0.12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: i % 2 == 0 ? AppColors.shopkeeperGreenPrimary : Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
                  ),
                ),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 14),
              Container(
                width: size * 0.32,
                height: size * 0.32,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFD1B3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                    ],
                  ),
                ),
              ),
              Container(
                width: size * 0.55,
                height: size * 0.30,
                decoration: const BoxDecoration(
                  color: AppColors.shopkeeperGreenDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: const Center(
                  child: Icon(Icons.storefront, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: const Icon(Icons.shopping_basket, color: AppColors.shopkeeperGreenDark, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class DeliveryAgentAvatar extends StatelessWidget {
  final double size;
  const DeliveryAgentAvatar({super.key, this.size = 140});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            AppColors.deliveryOrangeLight,
            AppColors.deliveryOrangeBorder,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.deliveryOrangePrimary.withOpacity(0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    width: size * 0.38,
                    height: size * 0.18,
                    decoration: const BoxDecoration(
                      color: AppColors.deliveryOrangePrimary,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    width: size * 0.30,
                    height: size * 0.30,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFD1B3),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                width: size * 0.52,
                height: size * 0.28,
                decoration: const BoxDecoration(
                  color: AppColors.deliveryOrangeDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const Center(
                  child: Icon(Icons.two_wheeler, color: Colors.white, size: 22),
                ),
              ),
            ],
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              child: const Icon(Icons.electric_scooter, color: AppColors.deliveryOrangeDark, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
