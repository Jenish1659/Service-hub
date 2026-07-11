import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Discover',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose from services for you and your home',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.95,
                children: [
                  _buildDiscoverCard(context, 'Home Cleaning', Icons.cleaning_services, const Color(0xffeff6ff)),
                  _buildDiscoverCard(context, 'Beauty Services', Icons.face, const Color(0xfffff1f2)),
                  _buildDiscoverCard(context, 'Men\'s Grooming', Icons.content_cut, const Color(0xfff0fdfa)),
                  _buildDiscoverCard(context, 'Bathroom Cleaning', Icons.shower, const Color(0xfff8fafc)),
                  _buildDiscoverCard(context, 'Water Purifier Service', Icons.water_drop, const Color(0xfffffbeb)),
                  _buildDiscoverCard(context, 'Plumbing & Repairs', Icons.plumbing, const Color(0xfff5f3ff)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoverCard(
    BuildContext context,
    String name,
    IconData icon,
    Color bg,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image / Icon Container
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppTheme.primaryColor.withOpacity(0.8),
              ),
            ),
          ),
          // Category Label underneath
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
