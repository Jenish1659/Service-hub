import 'package:flutter/material.dart';
import '../models/location_model.dart';
import '../../../../core/theme/app_theme.dart';

class LocationCard extends StatelessWidget {
  final LocationModel? location;
  final bool isLoading;
  final VoidCallback onConfirm;
  final VoidCallback onChangeTap;
  final VoidCallback? onBookForSomeoneElseTap;

  const LocationCard({
    super.key,
    required this.location,
    this.isLoading = false,
    required this.onConfirm,
    required this.onChangeTap,
    this.onBookForSomeoneElseTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      elevation: 16,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xffcbd5e1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xffeff6ff),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.my_location, color: AppTheme.primaryColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              location?.area.isNotEmpty == true ? location!.area : 'Select Location',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppTheme.textPrimaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xffdcfce7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Service Available',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xff15803d),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      isLoading
                          ? const Text(
                              'Updating address details...',
                              style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor, fontStyle: FontStyle.italic),
                            )
                          : Text(
                              location?.address ?? 'Move map to select location',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondaryColor,
                                height: 1.3,
                              ),
                            ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onChangeTap,
                  child: const Text(
                    'CHANGE',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (onBookForSomeoneElseTap != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: onBookForSomeoneElseTap,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.person_add_alt_1, color: AppTheme.primaryColor, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'Booking for someone else? Add details',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Spacer(),
                      Icon(Icons.chevron_right, color: AppTheme.primaryColor, size: 18),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                onPressed: isLoading ? null : onConfirm,
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Confirm Service Location',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
