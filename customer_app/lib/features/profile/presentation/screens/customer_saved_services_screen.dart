import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/customer_profile_service.dart';

class CustomerSavedServicesScreen extends StatefulWidget {
  const CustomerSavedServicesScreen({super.key});

  @override
  State<CustomerSavedServicesScreen> createState() => _CustomerSavedServicesScreenState();
}

class _CustomerSavedServicesScreenState extends State<CustomerSavedServicesScreen> {
  late List<Map<String, dynamic>> _services;

  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _loadServices() {
    setState(() {
      _services = CustomerProfileService.instance.getAllAvailableServices();
    });
  }

  Future<void> _toggleFavorite(String id) async {
    await CustomerProfileService.instance.toggleSavedService(id);
    _loadServices();
    if (mounted) {
      final item = _services.firstWhere((s) => s['id'] == id);
      final isNowSaved = item['is_saved'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNowSaved ? '✓ Added to Saved Services' : 'Removed from Saved Services'),
          backgroundColor: isNowSaved ? const Color(0xFFE11D48) : textMuted,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: darkSlate),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Saved Services',
          style: TextStyle(color: darkSlate, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: _services.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final s = _services[index];
          final isSaved = s['is_saved'] == true;
          final color = Color(s['color'] as int);

          IconData iconData = Icons.build_rounded;
          final id = s['id'] as String;
          if (id == 'ac_service') iconData = Icons.ac_unit_rounded;
          if (id == 'car_service') iconData = Icons.directions_car_rounded;
          if (id == 'plumbing') iconData = Icons.plumbing_rounded;
          if (id == 'laundry') iconData = Icons.local_laundry_service_rounded;
          if (id == 'care_taker') iconData = Icons.volunteer_activism_rounded;
          if (id == 'cooking') iconData = Icons.soup_kitchen_rounded;

          return GestureDetector(
            onTap: () {
              final route = s['route'] as String?;
              if (route != null) {
                context.push(route);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderGrey),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Icon Container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(iconData, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),

                  // Service Name & Price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: darkSlate,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          s['starting_price'] ?? '',
                          style: const TextStyle(
                            fontSize: 13,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Heart Icon Button
                  IconButton(
                    icon: Icon(
                      isSaved ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                      color: isSaved ? const Color(0xFFE11D48) : textMuted,
                      size: 24,
                    ),
                    onPressed: () => _toggleFavorite(s['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
