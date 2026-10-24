import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralized Permission Manager for ServiceHub
class AppPermissionsService {
  static final AppPermissionsService instance = AppPermissionsService._internal();
  AppPermissionsService._internal();

  /// 1. Request Camera Permission (Live FaceRD, Document Scanning, Selfie)
  Future<bool> requestCameraPermission(
    BuildContext context, {
    String title = 'Camera Access Required',
    String rationale = 'ServiceHub requires camera access to capture your live photo and scan physical documents for instant identity verification.',
  }) async {
    PermissionStatus status = await Permission.camera.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      if (!context.mounted) return false;
      final shouldRequest = await _showRationaleDialog(
        context: context,
        title: title,
        description: rationale,
        icon: Icons.camera_alt_rounded,
        actionLabel: 'Allow Camera Access',
      );
      if (!shouldRequest) return false;

      status = await Permission.camera.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      await _showSettingsDialog(
        context: context,
        title: 'Camera Permission Blocked',
        description: 'Camera permission has been permanently denied. Please enable it in Device App Settings to continue.',
      );
      return false;
    }

    return status.isGranted;
  }

  /// 2. Request Media / Photo Gallery Permission (Document uploads, Photo IDs)
  Future<bool> requestMediaPermission(
    BuildContext context, {
    String title = 'Photos & Media Access',
    String rationale = 'ServiceHub requires photo & media access to select and upload your Aadhaar, driving license, and business certificates.',
  }) async {
    PermissionStatus photosStatus = await Permission.photos.status;
    PermissionStatus storageStatus = await Permission.storage.status;

    if (photosStatus.isGranted || storageStatus.isGranted) return true;

    if (!context.mounted) return false;
    final shouldRequest = await _showRationaleDialog(
      context: context,
      title: title,
      description: rationale,
      icon: Icons.photo_library_rounded,
      actionLabel: 'Allow Photo Access',
    );
    if (!shouldRequest) return false;

    photosStatus = await Permission.photos.request();
    if (photosStatus.isGranted) return true;

    storageStatus = await Permission.storage.request();
    if (storageStatus.isGranted) return true;

    if (photosStatus.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {
      if (!context.mounted) return false;
      await _showSettingsDialog(
        context: context,
        title: 'Photos Permission Blocked',
        description: 'Photo library access is disabled. Please enable Photos/Storage permissions in device settings.',
      );
    }

    return photosStatus.isGranted || storageStatus.isGranted;
  }

  /// 3. Request Microphone Permission (Voice instructions, Customer Audio Calls)
  Future<bool> requestMicrophonePermission(
    BuildContext context, {
    String title = 'Microphone Access Required',
    String rationale = 'ServiceHub requires microphone access for voice communication and audio search.',
  }) async {
    PermissionStatus status = await Permission.microphone.status;
    if (status.isGranted) return true;

    if (status.isDenied) {
      if (!context.mounted) return false;
      final shouldRequest = await _showRationaleDialog(
        context: context,
        title: title,
        description: rationale,
        icon: Icons.mic_rounded,
        actionLabel: 'Allow Microphone',
      );
      if (!shouldRequest) return false;

      status = await Permission.microphone.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      await _showSettingsDialog(
        context: context,
        title: 'Microphone Blocked',
        description: 'Microphone permission is blocked. Please enable it in App Settings.',
      );
      return false;
    }

    return status.isGranted;
  }

  /// 4. Request Location Permission (Real-time tracking, 10km radius discovery)
  Future<bool> requestLocationPermission(
    BuildContext context, {
    String title = 'Location Access Required',
    String rationale = 'ServiceHub requires precise location to calculate service radius, live technician tracking, and navigation.',
  }) async {
    PermissionStatus status = await Permission.locationWhenInUse.status;
    if (status.isGranted) return true;

    if (status.isDenied) {
      if (!context.mounted) return false;
      final shouldRequest = await _showRationaleDialog(
        context: context,
        title: title,
        description: rationale,
        icon: Icons.location_on_rounded,
        actionLabel: 'Allow Location',
      );
      if (!shouldRequest) return false;

      status = await Permission.locationWhenInUse.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      if (!context.mounted) return false;
      await _showSettingsDialog(
        context: context,
        title: 'Location Blocked',
        description: 'Location access is required to dispatch jobs. Please enable Location in Device Settings.',
      );
      return false;
    }

    return status.isGranted;
  }

  /// 5. Request Phone Call Permission (Direct partner-to-customer call)
  Future<bool> requestPhoneCallPermission(
    BuildContext context, {
    String title = 'Phone Call Access',
    String rationale = 'ServiceHub requires phone access to connect you directly with customers/technicians.',
  }) async {
    PermissionStatus status = await Permission.phone.status;
    if (status.isGranted) return true;

    status = await Permission.phone.request();
    return status.isGranted;
  }

  /// 6. Request Display Over Other Apps Permission (System Alert Window / Full Screen Dispatch Overlays)
  Future<bool> requestDisplayOverOtherAppsPermission(
    BuildContext context, {
    String title = 'Display Over Other Apps',
    String rationale = 'ServiceHub Partner requires permission to display over other apps so you receive instant full-screen job alerts and customer parcel pickup requests even when using other apps or on the home screen.',
  }) async {
    PermissionStatus status = await Permission.systemAlertWindow.status;
    if (status.isGranted) return true;

    if (!context.mounted) return false;
    final shouldRequest = await _showRationaleDialog(
      context: context,
      title: title,
      description: rationale,
      icon: Icons.layers_rounded,
      actionLabel: 'Allow Overlay Access',
    );
    if (!shouldRequest) return false;

    status = await Permission.systemAlertWindow.request();
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied || status.isDenied) {
      if (!context.mounted) return false;
      await _showSettingsDialog(
        context: context,
        title: 'Overlay Permission Required',
        description: 'To receive dispatch alerts on top of other apps, please enable "Display over other apps" in device settings.',
      );
    }
    return status.isGranted;
  }

  // --- Reusable Modern Permission Dialogue ---
  Future<bool> _showRationaleDialog({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required String actionLabel,
  }) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFF2563EB), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 16),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Your data & privacy are protected by ServiceHub 256-bit encryption.',
                      style: TextStyle(fontSize: 11, color: Color(0xFF334155), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not Now', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  Future<void> _showSettingsDialog({
    required BuildContext context,
    required String title,
    required String description,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.settings_suggest_rounded, color: Color(0xFFEA580C), size: 24),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(
          description,
          style: const TextStyle(fontSize: 13, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
          ),
        ],
      ),
    );
  }
}
