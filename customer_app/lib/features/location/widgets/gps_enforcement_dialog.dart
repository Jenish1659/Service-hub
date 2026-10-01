import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/theme/app_theme.dart';
import '../services/location_permission_service.dart';

/// Modal dialog that enforces GPS / Device Location to be turned ON
class GpsEnforcementDialog extends StatefulWidget {
  final VoidCallback? onGpsEnabled;

  const GpsEnforcementDialog({
    super.key,
    this.onGpsEnabled,
  });

  /// Static helper to check and enforce GPS is active.
  /// Returns `true` if GPS is currently active or enabled by the user.
  static Future<bool> ensureGpsActive(BuildContext context) async {
    final service = LocationPermissionService();
    bool isEnabled = await Geolocator.isLocationServiceEnabled();
    if (isEnabled) {
      final perm = await service.checkPermission();
      if (perm == LocationPermissionStatus.granted) {
        return true;
      }
      final req = await service.requestPermission();
      return req == LocationPermissionStatus.granted;
    }

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const GpsEnforcementDialog(),
    );

    return result ?? false;
  }

  @override
  State<GpsEnforcementDialog> createState() => _GpsEnforcementDialogState();
}

class _GpsEnforcementDialogState extends State<GpsEnforcementDialog> with WidgetsBindingObserver {
  final LocationPermissionService _permissionService = LocationPermissionService();
  StreamSubscription<ServiceStatus>? _serviceStatusSub;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Listen for GPS status stream in background
    try {
      _serviceStatusSub = Geolocator.getServiceStatusStream().listen((status) {
        if (status == ServiceStatus.enabled) {
          _onLocationBecameActive();
        }
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _serviceStatusSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyLocationStatus();
    }
  }

  Future<void> _verifyLocationStatus() async {
    if (_isChecking || !mounted) return;
    setState(() => _isChecking = true);

    try {
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (isEnabled) {
        _onLocationBecameActive();
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _onLocationBecameActive() {
    widget.onGpsEnabled?.call();
    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: const Color(0xFFFEF3C7),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFFDE68A), width: 2),
            ),
            child: const Icon(
              Icons.location_off_rounded,
              color: Color(0xFFD97706),
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Device Location is Off',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'To find nearby verified technicians and ensure accurate arrival time, please turn on your device location (GPS).',
            style: TextStyle(
              fontSize: 13.5,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 2,
              ),
              icon: _isChecking
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.settings_suggest_rounded, size: 20),
              label: Text(
                _isChecking ? 'Checking GPS...' : 'Turn On Location',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await _permissionService.openLocationSettings();
              },
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.of(context, rootNavigator: true).pop(false);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
