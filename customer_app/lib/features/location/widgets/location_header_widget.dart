import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/location_provider.dart';
import '../screens/saved_locations_screen.dart';
import '../../../../core/theme/app_theme.dart';

class LocationHeaderWidget extends ConsumerWidget {
  const LocationHeaderWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final activeLoc = locationState.selectedLocation ?? locationState.currentLocation;

    final String displayTitle = activeLoc != null && activeLoc.area.isNotEmpty
        ? activeLoc.area
        : (activeLoc?.city.isNotEmpty == true ? activeLoc!.city : 'Select Location');

    final String displaySubtitle = activeLoc != null && activeLoc.city.isNotEmpty
        ? activeLoc.city
        : 'Set delivery area';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SavedLocationsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Color(0xffeff6ff),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 18),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff0f172a),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down, color: Color(0xff64748b), size: 18),
                  ],
                ),
                Text(
                  displaySubtitle,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff64748b),
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
