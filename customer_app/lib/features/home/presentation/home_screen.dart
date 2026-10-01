import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../shared/providers/location_provider.dart';
import '../../../shared/providers/notification_provider.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../cart/presentation/cart_provider.dart';
import '../../location/screens/saved_locations_screen.dart';
import '../../location/screens/map_screen.dart';
import '../../location/services/location_permission_service.dart';
import '../../location/widgets/gps_enforcement_dialog.dart';
import '../../products/presentation/products_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _outsideRangeWarningShown = false;
  final Set<String> _wishlistProducts = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkLocationOnAppEntry();
    });
  }

  Future<void> _checkLocationOnAppEntry() async {
    try {
      final service = LocationPermissionService();
      final status = await service.checkPermission();
      if (status == LocationPermissionStatus.serviceDisabled) {
        if (mounted) {
          await GpsEnforcementDialog.ensureGpsActive(context);
        }
      } else if (status == LocationPermissionStatus.denied) {
        await service.requestPermission();
      }
    } catch (_) {}
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
    final String fullName = user?.userMetadata?['name'] as String? ?? user?.email?.split('@').first ?? 'Guest';
    final String firstName = fullName.split(' ').first;
    final productsAsync = ref.watch(productsProvider);

    if (!locationState.isOutsideRange) {
      _outsideRangeWarningShown = false;
    }

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
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. REDESIGNED LUXURY BLUE HEADER BANNER (SEARCH BAR REMOVED)
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xff002b99),
                      Color(0xff0043c7),
                      Color(0xff0052cc),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                child: Column(
                  children: [
                    // Header Row: Location Chip & Action Buttons
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Location Picker Button
                          Expanded(
                            child: InkWell(
                              onTap: () => _showLocationPicker(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.location_on_rounded, color: Colors.white, size: 20),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        locationState.isLoading
                                            ? 'Fetching Location...'
                                            : (locationState.address.isEmpty ? 'Kaushal Nagar, Jamnagar' : locationState.address),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Notification Bell & Cart Icons
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
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.redAccent,
                                          shape: BoxShape.circle,
                                        ),
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



                    // Hero Banner Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 22),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi $firstName! 👋',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                RichText(
                                  text: const TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'One App,\n',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          height: 1.15,
                                        ),
                                      ),
                                      TextSpan(
                                        text: 'All Solutions',
                                        style: TextStyle(
                                          color: Color(0xffffb800),
                                          fontSize: 26,
                                          fontWeight: FontWeight.w900,
                                          height: 1.15,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Reliable services. Trusted professionals.\nRight at your doorstep.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: () => context.go('/discover'),
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.15),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: const FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.calendar_month_outlined, color: Color(0xff0052cc), size: 16),
                                          SizedBox(width: 8),
                                          Text(
                                            'Book Your Service',
                                            style: TextStyle(
                                              color: Color(0xff0052cc),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          Icon(Icons.chevron_right_rounded, color: Color(0xff0052cc), size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right Pro Badge Graphic
                          Expanded(
                            flex: 5,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 90,
                                  height: 90,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.2),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.engineering_rounded,
                                      size: 56,
                                      color: Color(0xff0052cc),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffffb800),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    '★ Verified Experts',
                                    style: TextStyle(
                                      color: Color(0xff0f172a),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 2. SERVICES NEAR YOU SECTION HEADER
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Services near you',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff0f172a),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 3. EXACT 4 SERVICE CARDS + MORE OPTION TILE (COMPACT & SLIGHTLY SMALLER)
              SizedBox(
                height: 125,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Card 1: AC Repair
                    _buildPillServiceCard(
                      context: context,
                      title: 'AC Repair',
                      badgeColor: const Color(0xff0066ff),
                      badgeBg: const Color(0xffe6f0ff),
                      badgeIcon: Icons.ac_unit_rounded,
                      categoryCode: 'AC',
                    ),
                    const SizedBox(width: 14),

                    // Card 2: Car Service
                    _buildPillServiceCard(
                      context: context,
                      title: 'Car Service',
                      badgeColor: const Color(0xffe11d48),
                      badgeBg: const Color(0xffffe4e6),
                      badgeIcon: Icons.directions_car_rounded,
                      categoryCode: 'Car',
                    ),
                    const SizedBox(width: 14),

                    // Card 3: Cooking
                    _buildPillServiceCard(
                      context: context,
                      title: 'Cooking',
                      badgeColor: const Color(0xffd97706),
                      badgeBg: const Color(0xfffef3c7),
                      badgeIcon: Icons.soup_kitchen_rounded,
                      categoryCode: 'Cooking',
                    ),
                    const SizedBox(width: 14),

                    // Card 4: Care Taker
                    _buildPillServiceCard(
                      context: context,
                      title: 'Care Taker',
                      badgeColor: const Color(0xff9333ea),
                      badgeBg: const Color(0xfff3e8ff),
                      badgeIcon: Icons.volunteer_activism_rounded,
                      categoryCode: 'CareTaker',
                    ),
                    const SizedBox(width: 14),

                    // Card 5: More Services (Redirects to Services)
                    _buildPillMoreCard(context: context),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 4. 4-COLUMN TRUST GUARANTEE CARD
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xfff0f7ff),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xffdbeafe)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildTrustItem(
                          icon: Icons.shield_outlined,
                          iconColor: const Color(0xff16a34a),
                          title: 'Hygiene\nGuaranteed',
                          sub: 'Safe & clean\nservice',
                        ),
                      ),
                      Container(height: 36, width: 1, color: const Color(0xffcbd5e1)),
                      Expanded(
                        child: _buildTrustItem(
                          icon: Icons.verified_user_outlined,
                          iconColor: const Color(0xff0052cc),
                          title: 'Trusted\nProfessionals',
                          sub: 'Verified & skilled\nexperts',
                        ),
                      ),
                      Container(height: 36, width: 1, color: const Color(0xffcbd5e1)),
                      Expanded(
                        child: _buildTrustItem(
                          icon: Icons.access_time_rounded,
                          iconColor: const Color(0xffea580c),
                          title: 'Fast &\nReliable',
                          sub: 'On-time service\nassured',
                        ),
                      ),
                      Container(height: 36, width: 1, color: const Color(0xffcbd5e1)),
                      Expanded(
                        child: _buildTrustItem(
                          icon: Icons.account_balance_wallet_outlined,
                          iconColor: const Color(0xff7c3aed),
                          title: 'Secure\nPayments',
                          sub: '100% safe\ntransactions',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. HELP & SUPPORT STRIP
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => context.push('/support'),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xffeff6ff),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xffdbeafe)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xff0052cc),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.support_agent, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "24/7 Help & AI Support",
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xff0f172a),
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  "Instant AI diagnostics & ticket assistance",
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xff64748b),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(height: 24, width: 1, color: const Color(0xffcbd5e1)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: Color(0xff0052cc),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.headset_mic_outlined, color: Colors.white, size: 20),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // 6. POPULAR PRODUCTS NEAR YOU SECTION (REAL PRODUCT PHOTOS & NO OVERFLOW ERROR)
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
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff0f172a),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Strict 5 km zone delivery · 30-45 mins',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xff64748b),
                          ),
                        ),
                      ],
                    ),
                    InkWell(
                      onTap: () => context.go('/products'),
                      child: const Row(
                        children: [
                          Text(
                            'See all',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xff0052cc),
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, color: Color(0xff0052cc), size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Products Horizontal Scroll (Dynamic from productsProvider or Zero-state card)
              productsAsync.when(
                loading: () => const SizedBox(
                  height: 140,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xff0052cc)),
                  ),
                ),
                error: (err, _) => _buildZeroStateProductsCard(context),
                data: (products) {
                  if (products.isEmpty) {
                    return _buildZeroStateProductsCard(context);
                  }
                  return SizedBox(
                    height: 240,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return Padding(
                          padding: EdgeInsets.only(right: index == products.length - 1 ? 0 : 14),
                          child: _buildRealProductCard(context, product),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPillServiceCard({
    required BuildContext context,
    required String title,
    required Color badgeColor,
    required Color badgeBg,
    required IconData badgeIcon,
    required String categoryCode,
  }) {
    return InkWell(
      onTap: () => context.go('/discover?category=$categoryCode'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 92,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffe2e8f0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeBg,
                shape: BoxShape.circle,
              ),
              child: Icon(badgeIcon, color: badgeColor, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                color: Color(0xff0f172a),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillMoreCard({required BuildContext context}) {
    return InkWell(
      onTap: () => context.go('/discover'),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 92,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xff0052cc), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Color(0xffeff6ff),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.grid_view_rounded, color: Color(0xff0052cc), size: 22),
            ),
            const SizedBox(height: 6),
            const Text(
              'More',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                color: Color(0xff0052cc),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String sub,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          title,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Color(0xff0f172a),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          sub,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(
            fontSize: 9,
            color: Color(0xff64748b),
            height: 1.1,
          ),
        ),
      ],
    );
  }

  Widget _buildZeroStateProductsCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffe2e8f0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffeff6ff),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xffdbeafe)),
              ),
              child: const Icon(
                Icons.storefront_outlined,
                color: Color(0xff0052cc),
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No products in your area yet • Check back soon',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: Color(0xff0f172a),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Local genuine spare parts delivered within 5 km',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xff64748b),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRealProductCard(BuildContext context, Map<String, dynamic> item) {
    final id = item['id']?.toString() ?? '';
    final name = item['name']?.toString() ?? 'Product';
    final priceVal = item['price'] ?? 0;
    final priceStr = '₹$priceVal';
    final origPriceVal = item['original_price'];
    final origPriceStr = origPriceVal != null ? '₹$origPriceVal' : '';
    final disc = item['discount']?.toString() ?? '';
    final cat = item['category']?.toString() ?? '';

    // Extract real image URL if available
    String? imageUrl;
    if (item['images'] is List && (item['images'] as List).isNotEmpty) {
      final first = (item['images'] as List).first?.toString();
      if (first != null && first.trim().isNotEmpty) {
        imageUrl = first.trim();
      }
    } else if (item['image_url'] != null && item['image_url'].toString().trim().isNotEmpty) {
      imageUrl = item['image_url'].toString().trim();
    }

    final bool isWishlisted = _wishlistProducts.contains(id);

    return Container(
      width: 165,
      height: 236, // Explicit fixed outer height to prevent layout overflow
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe2e8f0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Photo Container with Heart Wishlist Icon
          Stack(
            children: [
              Container(
                height: 105,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Color(0xfff8fafc),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(17),
                    topRight: Radius.circular(17),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(17),
                    topRight: Radius.circular(17),
                  ),
                  child: imageUrl != null && imageUrl.startsWith('http')
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return _buildProductCategoryPlaceholder(cat);
                          },
                        )
                      : _buildProductCategoryPlaceholder(cat),
                ),
              ),

              Positioned(
                right: 6,
                top: 6,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (isWishlisted) {
                        _wishlistProducts.remove(id);
                      } else {
                        _wishlistProducts.add(id);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(15),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: isWishlisted ? Colors.redAccent : const Color(0xff94a3b8),
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Content Box with FittedBox to guarantee ZERO overflow
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 32,
                  child: Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xff0f172a),
                      height: 1.2,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text(
                      priceStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: Color(0xff0f172a),
                        fontSize: 14,
                      ),
                    ),
                    if (origPriceStr.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      Text(
                        origPriceStr,
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Color(0xff94a3b8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (disc.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xffdcfce7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          disc,
                          style: const TextStyle(
                            color: Color(0xff16a34a),
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      const SizedBox(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff0052cc),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        minimumSize: const Size(44, 26),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        ref.read(cartProvider.notifier).addItem(item);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$name added to cart!'),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'View Cart',
                              textColor: Colors.amber,
                              onPressed: () => context.push('/cart'),
                            ),
                          ),
                        );
                      },
                      child: const Text('Add', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
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

  Widget _buildProductCategoryPlaceholder(String cat) {
    return Container(
      color: const Color(0xfff1f5f9),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xff0052cc).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getProductCategoryIcon(cat),
            color: const Color(0xff0052cc),
            size: 28,
          ),
        ),
      ),
    );
  }

  IconData _getProductCategoryIcon(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('ac')) return Icons.ac_unit_rounded;
    if (c.contains('plumb')) return Icons.plumbing_rounded;
    if (c.contains('car')) return Icons.directions_car_rounded;
    if (c.contains('cook')) return Icons.soup_kitchen_rounded;
    if (c.contains('laundry')) return Icons.local_laundry_service_rounded;
    if (c.contains('care')) return Icons.health_and_safety_rounded;
    return Icons.shopping_bag_outlined;
  }

  void _showLocationPicker(BuildContext context) {
    final List<Map<String, dynamic>> presets = [
      {'name': 'Kaushal Nagar, Jamnagar', 'lat': 22.4725, 'lng': 70.0610},
      {'name': 'Digvijay Plot, Jamnagar', 'lat': 22.4725, 'lng': 70.0610},
      {'name': 'Park Colony, Jamnagar', 'lat': 22.4635, 'lng': 70.0768},
      {'name': 'Patel Colony, Jamnagar', 'lat': 22.4795, 'lng': 70.0815},
      {'name': 'Samarpan, Jamnagar', 'lat': 22.4502, 'lng': 70.0505},
      {'name': 'Khodiyar Colony, Jamnagar', 'lat': 22.4831, 'lng': 70.0461},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
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
                const Text(
                  'Select Delivery Address',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xff0f172a)),
                ),
                const SizedBox(height: 14),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xffeff6ff),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.my_location, color: Color(0xff0052cc), size: 22),
                  ),
                  title: const Text('Detect My Location', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0052cc))),
                  subtitle: const Text('Automatically detect your live GPS location', style: TextStyle(fontSize: 12)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            ),
                            SizedBox(width: 12),
                            Text('Detecting GPS location...'),
                          ],
                        ),
                        backgroundColor: Color(0xff0052cc),
                        duration: Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    await ref.read(locationProvider.notifier).fetchLocation();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xffeff6ff),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.map_outlined, color: Color(0xff0052cc), size: 22),
                  ),
                  title: const Text('Pick on OpenStreetMap', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0052cc))),
                  subtitle: const Text('Select exact pinpoint on map', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapScreen()),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xffeff6ff),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark_outline, color: Color(0xff0052cc), size: 22),
                  ),
                  title: const Text('Manage Saved Addresses', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xff0052cc))),
                  subtitle: const Text('Choose from saved home or work addresses', style: TextStyle(fontSize: 12)),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SavedLocationsScreen()),
                    );
                  },
                ),
                const Divider(),
                const SizedBox(height: 8),
                const Text(
                  'Quick Area Presets',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff64748b)),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: ListView.builder(
                    itemCount: presets.length,
                    itemBuilder: (c, index) {
                      final preset = presets[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.location_on_outlined, color: Color(0xff0052cc)),
                        title: Text(preset['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Jamnagar, Gujarat', style: TextStyle(fontSize: 12)),
                        onTap: () {
                          ref.read(locationProvider.notifier).updateCustomLocation(
                            preset['lat'],
                            preset['lng'],
                            preset['name'],
                          );
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context, List<AppNotification> notifications) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 12),
              if (notifications.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text('No new notifications', style: TextStyle(color: Color(0xff64748b)))),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: notifications.length,
                    itemBuilder: (c, i) {
                      final notif = notifications[i];
                      return ListTile(
                        leading: const Icon(Icons.notifications_active_outlined, color: Color(0xff0052cc)),
                        title: Text(notif.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(notif.body, style: const TextStyle(fontSize: 11)),
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


