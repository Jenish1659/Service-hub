import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../../../../core/theme/app_theme.dart';

class LocationConfirmationSheet extends StatelessWidget {
  final LocationModel location;
  final VoidCallback onConfirm;
  final VoidCallback onEdit;

  const LocationConfirmationSheet({
    super.key,
    required this.location,
    required this.onConfirm,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: AppTheme.successColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Confirm Service Address', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text(location.city, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor)),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 28),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xfff8fafc),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffe2e8f0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pin_drop_outlined, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    location.address,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor, height: 1.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onEdit,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Adjust Map'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
