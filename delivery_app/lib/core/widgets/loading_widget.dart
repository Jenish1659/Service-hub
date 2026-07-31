import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class ServiceHubLoadingWidget extends StatelessWidget {
  final String message;

  const ServiceHubLoadingWidget({
    super.key,
    this.message = 'Loading ServiceHub...',
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primaryNavy,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.local_shipping, color: AppColors.secondaryGold, size: 36),
          ),
          const SizedBox(height: 16),
          const CircularProgressIndicator(color: AppColors.primaryNavy),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
