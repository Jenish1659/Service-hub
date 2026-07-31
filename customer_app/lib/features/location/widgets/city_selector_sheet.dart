import 'package:flutter/material.dart';
import '../models/service_area_model.dart';
import '../../../../core/theme/app_theme.dart';

class CitySelectorSheet extends StatelessWidget {
  final List<ServiceAreaModel> activeCities;
  final Function(ServiceAreaModel selectedCity) onCitySelected;

  const CitySelectorSheet({
    super.key,
    required this.activeCities,
    required this.onCitySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
                decoration: const BoxDecoration(
                  color: Color(0xffeff6ff),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_city, color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operational Cities',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  Text(
                    'Select a supported city to view home services',
                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: activeCities.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xfff1f5f9)),
              itemBuilder: (context, index) {
                final city = activeCities[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  leading: const Icon(Icons.check_circle, color: Color(0xff16a34a), size: 20),
                  title: Text(
                    city.city,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xff0f172a)),
                  ),
                  subtitle: Text('${city.state}, ${city.country} • ${city.radiusKm.toInt()} km radius'),
                  trailing: const Icon(Icons.chevron_right, color: Color(0xff94a3b8)),
                  onTap: () {
                    Navigator.pop(context);
                    onCitySelected(city);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
