import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/location_permission_service.dart';

class GpsDisabledDialog extends StatelessWidget {
  final VoidCallback onManualSelect;
  final VoidCallback onRetry;

  const GpsDisabledDialog({
    super.key,
    required this.onManualSelect,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final permissionService = LocationPermissionService();

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
                color: Color(0xfffee2e2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_off, color: Color(0xffdc2626), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'GPS / Location Disabled',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Your device location services are turned off. Please turn on GPS or enter your city manually to view local home services.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  await permissionService.openLocationSettings();
                  onRetry();
                },
                icon: const Icon(Icons.settings, color: Colors.white, size: 18),
                label: const Text(
                  'Enable Location in Settings',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: onManualSelect,
                child: const Text(
                  'Select Location Manually',
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
