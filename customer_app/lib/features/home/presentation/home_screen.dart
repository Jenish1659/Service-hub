import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/notification_provider.dart';
import '../../auth/presentation/auth_controller.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedBudget = 'All Budgets';
  bool _outsideRangeWarningShown = false;

  Widget _buildBudgetFilterChip(String label) {
    final isSelected = _selectedBudget == label;
    return InkWell(
      onTap: () {
        setState(() {
          _selectedBudget = label;
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xff0052cc) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xff0052cc) : const Color(0xffcbd5e1),
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xff0052cc).withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xff334155),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  void _showOutsideRangeDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('Location Unavailable'),
            ],
          ),
          content: const Text(
            'Sorry, we are not available at your location. ServiceHub currently only operates within Jamnagar city limits.',
            style: TextStyle(height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
              },
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final notifications = ref.watch(notificationProvider);
    final unreadCount = notifications.where((n) => !n.read).length;

    final authState = ref.watch(authControllerProvider);
    final user = authState.value;
    final String fullName = user?.userMetadata?['name'] as String? ?? user?.email?.split('@').first ?? 'xyz';
    final String firstName = fullName.split(' ').first;

    // Reset warning status if user changes location back into range
    if (!locationState.isOutsideRange) {
      _outsideRangeWarningShown = false;
    }

    // Check outside range on state changes
    if (!locationState.isLoading && locationState.isOutsideRange && !_outsideRangeWarningShown) {
      _outsideRangeWarningShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showOutsideRangeDialog(context);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER & HERO SECTION WITH VIBRANT BLUE BACKGROUND
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xff0052cc), // Vibrant deep blue
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location and Right Header Action Icons (Notifications & Cart)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _showLocationPicker(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on, color: Colors.white, size: 20),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        locationState.isLoading
                                            ? 'Fetching Location...'
                                            : '${locationState.address.isEmpty ? "Digvijay Plot, Jamnagar" : locationState.address} >',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Stack(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                                    onPressed: () => _showNotificationsSheet(context, notifications),
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: 10,
                                      top: 10,
                                      child: Container(
                                        padding: const EdgeInsets.all(3),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: Text(
                                          '$unreadCount',
                                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    )
                                  else
                                    Positioned(
                                      right: 12,
                                      top: 10,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      ),
                                    ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 24),
                                onPressed: () => context.push('/cart'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Hero Banner Left (Text & Pill Button) + Right Graphic
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left side text and CTA
                          Expanded(
                            flex: 6,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome to ServiceHub, $firstName!',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'One App, ',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'All Solutions',
                                        style: TextStyle(
                                          color: Color(0xffffab00), // Vibrant Orange/Yellow
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: "We're here just open app\nand ",
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          height: 1.3,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'book service',
                                        style: TextStyle(
                                          color: Color(0xffffab00),
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Clickable Pill Button: Book Your Service
                                InkWell(
                                  onTap: () => context.go('/discover'),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.indeterminate_check_box_outlined, color: Color(0xff0052cc), size: 18),
                                        SizedBox(width: 6),
                                        Text(
                                          'Book Your Service',
                                          style: TextStyle(
                                            color: Color(0xff0052cc),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.chevron_right_rounded, color: Color(0xff0052cc), size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right side: Hero Technician & ServiceHub Logo Graphic
                          Expanded(
                            flex: 6,
                            child: SizedBox(
                              height: 150,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Image.asset(
                                  'assets/images/hero_technician.png',
                                  fit: BoxFit.contain,
                                  alignment: Alignment.centerRight,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Center(
                                      child: Container(
                                        width: 70,
                                        height: 70,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.engineering_rounded,
                                          size: 45,
                                          color: Color(0xff0052cc),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 1.5. LIVE OPENSTREETMAP HYPERLOCAL GEOLOCATION CARD
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0f000000),
                        blurRadius: 12,
                        offset: Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0xffe2e8f0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Strip
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.map_rounded, color: AppTheme.primaryColor, size: 18),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hyperlocal Service Map',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textPrimaryColor),
                                    ),
                                    Text(
                                      locationState.address.isEmpty ? 'Digvijay Plot, Jamnagar' : locationState.address,
                                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            InkWell(
                              onTap: () => _showLocationPicker(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.my_location_rounded, color: Colors.white, size: 12),
                                    SizedBox(width: 4),
                                    Text(
                                      'Change GPS',
                                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Interactive Live OpenStreetMap Box
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                        child: SizedBox(
                          height: 180,
                          width: double.infinity,
                          child: Stack(
                            children: [
                              FlutterMap(
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    locationState.latitude ?? 22.4725,
                                    locationState.longitude ?? 70.0610,
                                  ),
                                  initialZoom: 14.5,
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName: 'com.servicehub.customer',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      // Customer Live GPS Location Marker
                                      Marker(
                                        point: LatLng(
                                          locationState.latitude ?? 22.4725,
                                          locationState.longitude ?? 70.0610,
                                        ),
                                        width: 48,
                                        height: 48,
                                        child: Column(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.withValues(alpha: 0.2),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(Icons.person_pin_circle_rounded, color: Colors.blueAccent, size: 36),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Nearby Partner Provider 1 (AC Specialist)
                                      Marker(
                                        point: LatLng(
                                          (locationState.latitude ?? 22.4725) + 0.004,
                                          (locationState.longitude ?? 70.0610) + 0.003,
                                        ),
                                        width: 36,
                                        height: 36,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(color: Color(0xff10b981), shape: BoxShape.circle),
                                          child: const Icon(Icons.build_rounded, color: Colors.white, size: 18),
                                        ),
                                      ),
                                      // Nearby Partner Provider 2 (Plumber)
                                      Marker(
                                        point: LatLng(
                                          (locationState.latitude ?? 22.4725) - 0.003,
                                          (locationState.longitude ?? 70.0610) - 0.004,
                                        ),
                                        width: 36,
                                        height: 36,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(color: Color(0xff0d9488), shape: BoxShape.circle),
                                          child: const Icon(Icons.plumbing_rounded, color: Colors.white, size: 18),
                                        ),
                                      ),
                                      // Nearby Delivery Agent
                                      Marker(
                                        point: LatLng(
                                          (locationState.latitude ?? 22.4725) + 0.002,
                                          (locationState.longitude ?? 70.0610) - 0.003,
                                        ),
                                        width: 36,
                                        height: 36,
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: const BoxDecoration(color: Color(0xfff59e0b), shape: BoxShape.circle),
                                          child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 18),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Positioned(
                                bottom: 10,
                                left: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff0f172a).withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.radar_rounded, color: Color(0xff10b981), size: 14),
                                      SizedBox(width: 6),
                                      Text(
                                        '3 Verified Partners Active in 5km Radius',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. FLOATING SEARCH BAR & BUDGET FILTERS
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(
                  children: [
                    // Search Bar Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        onTap: () => _showFilterDialog(context),
                        readOnly: true,
                        decoration: InputDecoration(
                          hintText: 'Search for services or products...',
                          hintStyle: const TextStyle(color: Color(0xff94a3b8), fontSize: 13),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xff64748b)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.tune_rounded, color: Color(0xff0052cc)),
                            onPressed: () => _showFilterDialog(context),
                          ),
                          fillColor: Colors.transparent,
                          filled: true,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Budget Filter Chips (Horizontally Scrollable & Selectable)
                    SizedBox(
                      height: 38,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildBudgetFilterChip('All Budgets'),
                          _buildBudgetFilterChip('Under ₹299'),
                          _buildBudgetFilterChip('₹300-₹999'),
                          _buildBudgetFilterChip('₹1000+'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. PROMO BANNER CARD (AC SERVICE & REPAIR)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  onTap: () => context.go('/discover?category=AC'),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xff0039a6), Color(0xff00247d)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xff00247d).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(18.0),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 6,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffff6b00), // Promo badge orange
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'PROMO',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'AC Service & Repair',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Flat 30% Off on AC Filter cleaning',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    // Book Now Pill Button
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Text(
                                            'Book Now',
                                            style: TextStyle(
                                              color: Color(0xff0039a6),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: const BoxDecoration(
                                              color: Color(0xff0039a6),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // AC Repair Service Image Right (Exact Uploaded Graphic)
                              Expanded(
                                flex: 4,
                                child: Container(
                                  height: 110,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.asset(
                                      'assets/images/ac_promo_banner.png',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.ac_unit_rounded,
                                              color: Colors.white24,
                                              size: 36,
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Icon(
                                                Icons.hvac_rounded,
                                                color: Colors.white,
                                                size: 30,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Bottom Feature Strip of Promo Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          decoration: const BoxDecoration(
                            color: Color(0xff001e6c), // Darker Navy
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(20),
                              bottomRight: Radius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildPromoFeatureItem(Icons.verified_user_outlined, 'Trusted', 'Professionals'),
                              _buildPromoFeatureItem(Icons.timer_outlined, 'Fast &', 'Reliable'),
                              _buildPromoFeatureItem(Icons.verified_outlined, 'Quality', 'Service'),
                              _buildPromoFeatureItem(Icons.monetization_on_outlined, 'Affordable', 'Prices'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. "SERVICES NEAR YOU" SECTION (EXACT AS IMAGE)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Services near you',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff0f172a),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/discover'),
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff0052cc),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Single Row of Clickable Category Icons
              SizedBox(
                height: 105,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildExactServiceItem(
                      context,
                      'AC Repair',
                      Icons.ac_unit_rounded,
                      const Color(0xffebf5ff),
                      const Color(0xff0066ff),
                      'AC',
                    ),
                    _buildExactServiceItem(
                      context,
                      'Plumbing',
                      Icons.plumbing_rounded,
                      const Color(0xffe6f7f0),
                      const Color(0xff00b074),
                      'Plumbing',
                    ),
                    _buildExactServiceItem(
                      context,
                      'Car Service',
                      Icons.directions_car_rounded,
                      const Color(0xffffebeb),
                      const Color(0xffff3b30),
                      'Car',
                    ),
                    _buildExactServiceItem(
                      context,
                      'Cooking',
                      Icons.soup_kitchen_rounded,
                      const Color(0xfffff4e5),
                      const Color(0xffff8800),
                      'Cooking',
                    ),
                    _buildExactServiceItem(
                      context,
                      'More\nServices',
                      Icons.more_horiz_rounded,
                      const Color(0xfff1f5f9),
                      const Color(0xff0066ff),
                      'All',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 5. VALUE PROPOSITION / TRUST GUARANTEED CONTAINER (LIGHT BLUE)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                  onTap: () => _showTrustInfoSheet(context),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xfff0f6ff),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xffdbeafe)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildTrustGridItem(
                            Icons.shield_outlined,
                            const Color(0xff16a34a),
                            'Hygiene\nGuaranteed',
                            'Safe & clean\nservice',
                          ),
                        ),
                        Expanded(
                          child: _buildTrustGridItem(
                            Icons.verified_outlined,
                            const Color(0xff2563eb),
                            'Trusted\nProfessionals',
                            'Verified & skilled\nexperts',
                          ),
                        ),
                        Expanded(
                          child: _buildTrustGridItem(
                            Icons.timer_outlined,
                            const Color(0xffea580c),
                            'Fast &\nReliable',
                            'On-time service\nassured',
                          ),
                        ),
                        Expanded(
                          child: _buildTrustGridItem(
                            Icons.account_balance_wallet_outlined,
                            const Color(0xff7c3aed),
                            'Secure\nPayments',
                            '100% safe\ntransactions',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 6. BOTTOM CALLOUT / HELP STRIP (2 CLICKABLE HALVES)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xffebf3ff),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Left Half Callout
                      Expanded(
                        child: InkWell(
                          onTap: () => context.go('/discover'),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xff0052cc),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.call_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  "We're here just open app and book service",
                                  style: TextStyle(
                                    color: Color(0xff1e293b),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(height: 24, width: 1, color: const Color(0xffcbd5e1)),
                      const SizedBox(width: 8),
                      // Right Half Callout
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push('/profile'),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xff0052cc),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.headset_mic_rounded, color: Colors.white, size: 16),
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  "We're always here to help you",
                                  style: TextStyle(
                                    color: Color(0xff1e293b),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 7. PRODUCTS SECTION (STRICT 5 KM radius geofencing indication)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Products Near You',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff0f172a),
                          ),
                        ),
                        Text(
                          'Strict 5 km zone delivery · 30-45 mins',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xff64748b),
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.go('/products'),
                      child: const Text('See all', style: TextStyle(color: Color(0xff0052cc), fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _getFilteredProducts(),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoFeatureItem(IconData icon, String line1, String line2) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 14),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(line1, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
            Text(line2, style: const TextStyle(color: Colors.white70, fontSize: 8)),
          ],
        ),
      ],
    );
  }

  Widget _buildExactServiceItem(
    BuildContext context,
    String label,
    IconData icon,
    Color circleBg,
    Color iconColor,
    String categoryCode,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          if (categoryCode == 'All') {
            context.go('/discover');
          } else {
            context.go('/discover?category=$categoryCode');
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xfff1f5f9)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: circleBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xff1e293b),
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustGridItem(IconData icon, Color iconColor, String title, String sub) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: iconColor,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 8,
              color: Color(0xff64748b),
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  void _showTrustInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return const Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ServiceHub Safety & Quality Standards',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
              ),
              SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.shield_outlined, color: Colors.green),
                title: Text('Hygiene Guaranteed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Sanitized tools and standard protective gear used during every service call.', style: TextStyle(fontSize: 11)),
              ),
              ListTile(
                leading: Icon(Icons.verified_outlined, color: Colors.blue),
                title: Text('Trusted & Verified Professionals', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('Background checked, skilled local technicians with identity verification.', style: TextStyle(fontSize: 11)),
              ),
              ListTile(
                leading: Icon(Icons.timer_outlined, color: Colors.orange),
                title: Text('Fast & Reliable Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('On-time arrival guarantee within Jamnagar city limits.', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _getFilteredProducts() {
    final List<Map<String, dynamic>> allProducts = [
      {'name': 'AC Dust Filter (Universal)', 'price': 349, 'origPrice': 499, 'disc': '30% OFF'},
      {'name': 'Pipe Repair Tape 5m', 'price': 89, 'origPrice': 120, 'disc': '26% OFF'},
      {'name': 'Car Shampoo 500ml', 'price': 199, 'origPrice': 299, 'disc': '33% OFF'},
      {'name': '3-Tier Tiffin Box', 'price': 449, 'origPrice': 599, 'disc': '25% OFF'},
    ];

    List<Map<String, dynamic>> filtered = [];

    if (_selectedBudget == 'All Budgets') {
      filtered = allProducts;
    } else if (_selectedBudget == 'Under ₹299') {
      filtered = allProducts.where((p) => p['price'] < 299).toList();
    } else if (_selectedBudget == '₹300-₹999') {
      filtered = allProducts.where((p) => p['price'] >= 300 && p['price'] <= 999).toList();
    } else {
      filtered = allProducts.where((p) => p['price'] >= 1000).toList();
    }

    if (filtered.isEmpty) {
      return [
        const SizedBox(
          width: 250,
          child: Center(child: Text('No products in this price range.', style: TextStyle(color: AppTheme.textSecondaryColor))),
        )
      ];
    }

    return filtered.map((p) => Row(
      children: [
        _buildProductCard(context, p['name'], '₹${p['price']}', '₹${p['origPrice']}', p['disc']),
        const SizedBox(width: 12),
      ],
    )).toList();
  }

  Widget _buildProductCard(
    BuildContext context,
    String name,
    String price,
    String originalPrice,
    String discount,
  ) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff1f5f9), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xfff1f5f9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: const Center(
              child: Icon(Icons.shopping_bag_outlined, color: AppTheme.textSecondaryColor, size: 36),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xff0052cc),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      originalPrice,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: AppTheme.textSecondaryColor,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xfff0fdf4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        discount,
                        style: const TextStyle(
                          color: Color(0xff16a34a),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0052cc),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => context.push('/cart'),
                      child: const Text('Add', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker(BuildContext context) {
    final List<Map<String, dynamic>> presets = [
      {'name': 'Digvijay Plot, Jamnagar', 'lat': 22.4725, 'lng': 70.0610},
      {'name': 'Park Colony, Jamnagar', 'lat': 22.4635, 'lng': 70.0768},
      {'name': 'Patel Colony, Jamnagar', 'lat': 22.4795, 'lng': 70.0815},
      {'name': 'Samarpan, Jamnagar', 'lat': 22.4502, 'lng': 70.0505},
      {'name': 'Khodiyar Colony, Jamnagar', 'lat': 22.4831, 'lng': 70.0461},
      {'name': 'Windmill Road, Jamnagar', 'lat': 22.4792, 'lng': 70.0913},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final searchController = TextEditingController();
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Delivery Address',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search for address or area...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward),
                    onPressed: () {
                      final query = searchController.text.trim();
                      if (query.isNotEmpty) {
                        ref.read(locationProvider.notifier).updateCustomLocation(
                          22.4707,
                          70.0577,
                          '$query, Jamnagar',
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Location updated to: $query, Jamnagar')),
                        );
                      }
                    },
                  ),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: const Icon(Icons.my_location, color: Color(0xff0052cc)),
                title: const Text('Detect My Location', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0052cc))),
                subtitle: const Text('Automatically detect your location via GPS'),
                onTap: () async {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Detecting your location...')),
                  );
                  await ref.read(locationProvider.notifier).fetchLocation();
                },
              ),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                'Popular Jamnagar Neighborhoods',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: presets.length,
                  itemBuilder: (c, index) {
                    final preset = presets[index];
                    return ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: Color(0xff0052cc)),
                      title: Text(preset['name']),
                      subtitle: const Text('Popular Area, Jamnagar'),
                      onTap: () {
                        ref.read(locationProvider.notifier).updateCustomLocation(
                          preset['lat'],
                          preset['lng'],
                          preset['name'],
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Address updated to ${preset['name']}'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFilterDialog(BuildContext context) {
    double budgetValue = 450.0;
    int selectedSortIndex = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Services',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textPrimaryColor),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Budget Range',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor),
                      ),
                      Text(
                        '₹${budgetValue.round()}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff0052cc)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('₹100', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                      Text('₹1,500', style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12)),
                    ],
                  ),
                  Slider(
                    value: budgetValue,
                    min: 100,
                    max: 1500,
                    divisions: 14,
                    label: '₹${budgetValue.round()}',
                    activeColor: const Color(0xff0052cc),
                    inactiveColor: Colors.grey.shade200,
                    onChanged: (val) {
                      setModalState(() {
                        budgetValue = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Sort By',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Rating (High to Low)'),
                        selected: selectedSortIndex == 0,
                        selectedColor: const Color(0xff0052cc).withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: selectedSortIndex == 0 ? const Color(0xff0052cc) : AppTheme.textSecondaryColor,
                          fontWeight: selectedSortIndex == 0 ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              selectedSortIndex = 0;
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Price (Low to High)'),
                        selected: selectedSortIndex == 1,
                        selectedColor: const Color(0xff0052cc).withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: selectedSortIndex == 1 ? const Color(0xff0052cc) : AppTheme.textSecondaryColor,
                          fontWeight: selectedSortIndex == 1 ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              selectedSortIndex = 1;
                            });
                          }
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Popularity'),
                        selected: selectedSortIndex == 2,
                        selectedColor: const Color(0xff0052cc).withValues(alpha: 0.1),
                        labelStyle: TextStyle(
                          color: selectedSortIndex == 2 ? const Color(0xff0052cc) : AppTheme.textSecondaryColor,
                          fontWeight: selectedSortIndex == 2 ? FontWeight.bold : FontWeight.normal,
                        ),
                        onSelected: (selected) {
                          if (selected) {
                            setModalState(() {
                              selectedSortIndex = 2;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0052cc),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        final sortText = selectedSortIndex == 0
                            ? 'Rating'
                            : selectedSortIndex == 1
                                ? 'Price'
                                : 'Popularity';
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Applied Filters: Budget <= ₹${budgetValue.round()}, Sorted by $sortText'),
                            backgroundColor: AppTheme.successColor,
                          ),
                        );
                      },
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context, List<AppNotification> list) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Notifications Feed',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(notificationProvider.notifier).markAllAsRead();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Mark all as read'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (list.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text(
                      'No notifications yet.',
                      style: TextStyle(color: AppTheme.textSecondaryColor),
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: list.length,
                    itemBuilder: (c, index) {
                      final item = list[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: item.read ? Colors.grey.shade100 : const Color(0xffeff6ff),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.notifications_active_outlined,
                            color: item.read ? Colors.grey : const Color(0xff0052cc),
                            size: 18,
                          ),
                        ),
                        title: Text(
                          item.title,
                          style: TextStyle(
                            fontWeight: item.read ? FontWeight.normal : FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          item.body,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        trailing: Text(
                          '${item.createdAt.hour.toString().padLeft(2, '0')}:${item.createdAt.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
