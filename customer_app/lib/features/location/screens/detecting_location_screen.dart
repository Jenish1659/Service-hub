import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/location_provider.dart';
import '../controllers/location_controller.dart';
import '../widgets/gps_disabled_dialog.dart';
import '../widgets/permission_denied_dialog.dart';
import 'map_screen.dart';
import 'location_search_screen.dart';
import '../../../../core/theme/app_theme.dart';

class DetectingLocationScreen extends ConsumerStatefulWidget {
  const DetectingLocationScreen({super.key});

  @override
  ConsumerState<DetectingLocationScreen> createState() => _DetectingLocationScreenState();
}

class _DetectingLocationScreenState extends ConsumerState<DetectingLocationScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _hasStartedDetection = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startDetection();
    });
  }

  Future<void> _startDetection() async {
    if (_hasStartedDetection) return;
    _hasStartedDetection = true;

    final locationNotifier = ref.read(locationProvider.notifier);
    await locationNotifier.initializeAndDetectLocation();

    if (!mounted) return;
    final state = ref.read(locationProvider);

    if (state.status == LocationStatus.success && state.currentLocation != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MapScreen()),
      );
    } else if (state.status == LocationStatus.error) {
      if (state.errorMessage?.contains('disabled') == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => GpsDisabledDialog(
            onRetry: () {
              Navigator.pop(context);
              _hasStartedDetection = false;
              _startDetection();
            },
            onManualSelect: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
              );
            },
          ),
        );
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => PermissionDeniedDialog(
            onManualSelect: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LocationSearchScreen()),
              );
            },
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: const Color(0xffeff6ff),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          blurRadius: 24,
                          spreadRadius: 12 * _pulseAnimation.value,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.gps_fixed,
                      size: 52,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 36),
            const Text(
              'Detecting Your Location...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Acquiring GPS coordinates & reverse geocoding address',
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 28),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
