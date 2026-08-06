import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class GujaratComingSoonDialog extends StatelessWidget {
  final String selectedState;
  final VoidCallback onSelectGujarat;

  const GujaratComingSoonDialog({
    super.key,
    required this.selectedState,
    required this.onSelectGujarat,
  });

  static Future<void> show(BuildContext context, String stateName, VoidCallback onSelectGujarat) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GujaratComingSoonDialog(
        selectedState: stateName,
        onSelectGujarat: onSelectGujarat,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 10,
      backgroundColor: Colors.white,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon Badge
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.providerBlueLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: AppColors.providerBluePrimary,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'ServiceHub is Coming Soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.primaryNavy,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Currently, ServiceHub Partner Registration is available only in Gujarat.\n\nWe are expanding to $selectedState very soon. Thank you for your interest!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.borderLight),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close', style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.providerBluePrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop();
                      onSelectGujarat();
                    },
                    child: const Text('Select Gujarat', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
