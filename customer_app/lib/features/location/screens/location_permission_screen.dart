import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/location_provider.dart';
import '../../../../core/theme/app_theme.dart';

class LocationPermissionScreen extends ConsumerWidget {
  final VoidCallback onPermissionGranted;

  const LocationPermissionScreen({
    super.key,
    required this.onPermissionGranted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              const Spacer(),
              // Icon illustration container
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xffeff6ff),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xffbfdbfe), width: 2),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Enable Location Services',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'ServiceHub uses your precise location to find verified professionals, calculate accurate ETA, and deliver seamless doorstep services.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondaryColor,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              // Feature bullets
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xfff8fafc),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Column(
                  children: [
                    _FeatureRow(icon: Icons.flash_on, text: 'Instant provider matching near you'),
                    SizedBox(height: 10),
                    _FeatureRow(icon: Icons.shield, text: 'Safe & validated doorstep service'),
                    SizedBox(height: 10),
                    _FeatureRow(icon: Icons.map, text: 'Live GPS arrival tracking'),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Allow Location Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () async {
                    await ref.read(locationProvider.notifier).initializeAndDetectLocation();
                    onPermissionGranted();
                  },
                  child: const Text(
                    'Allow Location Access',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  onPermissionGranted();
                },
                child: const Text(
                  'Enter Location Manually',
                  style: TextStyle(color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xfff59e0b), size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
