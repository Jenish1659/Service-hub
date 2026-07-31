import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class AvailabilityPopup extends StatelessWidget {
  final String cityName;
  final VoidCallback onSelectOtherCity;

  const AvailabilityPopup({
    super.key,
    required this.cityName,
    required this.onSelectOtherCity,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xfffef3c7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rocket_launch, color: Color(0xffd97706), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              'ServiceHub is Coming Soon to $cityName!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 10),
            const Text(
              'We are expanding rapidly and will launch in your location very soon. In the meantime, you can explore services in our operational cities.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor, height: 1.4),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: onSelectOtherCity,
                child: const Text(
                  'Select Supported City',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
