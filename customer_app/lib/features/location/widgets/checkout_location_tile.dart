import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location_model.dart';
import '../providers/location_provider.dart';
import '../screens/saved_locations_screen.dart';
import '../../../../core/theme/app_theme.dart';

class CheckoutLocationTile extends ConsumerWidget {
  final VoidCallback? onChangeLocation;

  const CheckoutLocationTile({
    super.key,
    this.onChangeLocation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locationState = ref.watch(locationProvider);
    final LocationModel? selectedLoc = locationState.selectedLocation ?? locationState.currentLocation;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Service & Delivery Location',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0f172a),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: onChangeLocation ??
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SavedLocationsScreen()),
                        );
                      },
                  child: const Text(
                    'CHANGE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              selectedLoc != null && selectedLoc.address.isNotEmpty
                  ? selectedLoc.address
                  : 'No service address selected',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xff334155),
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xffdcfce7),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Verified Operational Area',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff15803d),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  selectedLoc != null ? '${selectedLoc.area}, ${selectedLoc.city}' : '',
                  style: const TextStyle(fontSize: 11, color: Color(0xff64748b)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
