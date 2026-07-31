import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/location_permission_service.dart';

class PermissionDeniedDialog extends StatelessWidget {
  final VoidCallback onManualSelect;

  const PermissionDeniedDialog({
    super.key,
    required this.onManualSelect,
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
                color: Color(0xfffef3c7),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.security, color: Color(0xffd97706), size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Location Permission Required',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'ServiceHub needs location access to match you with nearby verified professionals. Please grant permission in app settings.',
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
                  await permissionService.openAppSettings();
                },
                icon: const Icon(Icons.settings, color: Colors.white, size: 18),
                label: const Text(
                  'Open App Settings',
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
                  'Continue Manually',
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
