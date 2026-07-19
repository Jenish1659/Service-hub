import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white, width: 1.2),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryColor : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
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
          title: Row(
            children: const [
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. CUSTOM HEADER WITH VIBRANT BLUE BACKGROUND
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location and Action Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _showLocationPicker(context),
                            child: Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.white, size: 20),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    locationState.isLoading 
                                        ? 'Fetching Location...' 
                                        : '${locationState.address} >',
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
                        Row(
                          children: [
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.notifications_none, color: Colors.white),
                                  onPressed: () => _showNotificationsSheet(context, notifications),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                      child: Text(
                                        '$unreadCount',
                                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Stack(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                                  onPressed: () => context.push('/cart'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Greeting text
                    Text(
                      'Welcome to ServiceHub, $firstName!',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const Text(
                      'Find your service today',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Search bar with Filter Suffix Icon
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search for services or products...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondaryColor),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.tune_rounded, color: AppTheme.primaryColor),
                          onPressed: () => _showFilterDialog(context),
                        ),
                        fillColor: Colors.white,
                        filled: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Budget filters row directly under search bar
                    SizedBox(
                      height: 36,
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

              // 2. PROMO SLIDER CARD (BLUE GRADIENT)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff2563eb), Color(0xff1d4ed8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white24,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'PROMO',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'AC Service & Repair',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            const Text(
                              'Flat 30% Off on AC Filter cleaning',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppTheme.primaryColor,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => context.go('/discover'),
                              child: const Text(
                                'Book Now',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.ac_unit,
                        size: 80,
                        color: Colors.white24,
                      ),
                    ],
                  ),
                ),
              ),

              // 3. SERVICES SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Services near you',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go('/discover'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Single-line horizontal category selection
              SizedBox(
                height: 86,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    _buildHorizontalServiceCard(context, 'AC Repair', Icons.ac_unit, const Color(0xffeff6ff), const Color(0xff2563eb)),
                    const SizedBox(width: 12),
                    _buildHorizontalServiceCard(context, 'Plumbing', Icons.plumbing, const Color(0xfff0fdfa), const Color(0xff0d9488)),
                    const SizedBox(width: 12),
                    _buildHorizontalServiceCard(context, 'Car Service', Icons.directions_car, const Color(0xfffff1f2), const Color(0xffe11d48)),
                    const SizedBox(width: 12),
                    _buildHorizontalServiceCard(context, 'Cooking', Icons.soup_kitchen, const Color(0xfffffbeb), const Color(0xffd97706)),
                    const SizedBox(width: 12),
                    _buildHorizontalServiceCard(context, 'Laundry', Icons.local_laundry_service, const Color(0xfffaf5ff), const Color(0xff7c3aed)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 4. HYGIENE GUARANTEED BANNER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xfff0fdf4),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffbbf7d0), width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Color(0xff16a34a), size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Hygiene Guaranteed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff16a34a),
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Every provider carries sanitized tools and complies with safety standards.',
                              style: TextStyle(
                                color: Color(0xff15803d),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 5. PRODUCTS SECTION (STRICT 5 KM radius geofencing indication)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Products Near You',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimaryColor,
                          ),
                        ),
                        Text(
                          'Strict 5 km zone delivery · 30-45 mins',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.go('/products'),
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Products list (Rupees ₹ currency symbol) filtered by Budget
              SizedBox(
                height: 200,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _getFilteredProducts(),
                ),
              ),
              const SizedBox(height: 32),

              // 6. QUICK HELP / FAQ SECTION (STUNNING ACCORDION)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Frequently Asked Questions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFaqTile(
                      'How does the 5 km hyperlocal delivery work?',
                      'ServiceHub uses strict geofencing. Products and services are delivered from providers within a 5 km radius of your location to ensure fast delivery and booking verification.',
                    ),
                    const SizedBox(height: 8),
                    _buildFaqTile(
                      'How do I complete a booking / order?',
                      'Your service agent will ask for your unique Completion OTP at the end of the service, or your Delivery PIN at the time of delivery to securely mark it complete.',
                    ),
                    const SizedBox(height: 8),
                    _buildFaqTile(
                      'Can I select a custom delivery address?',
                      'Yes! Tap on the address bar at the top of the Home Screen to search for any neighborhood or choose from popular preset locations.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
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

  Widget _buildHorizontalServiceCard(
    BuildContext context,
    String name,
    IconData icon,
    Color bg,
    Color iconColor,
  ) {
    String dbCategory = name;
    if (name == 'AC Repair') dbCategory = 'AC';
    if (name == 'Car Service') dbCategory = 'Car';

    return InkWell(
      onTap: () => context.go('/discover?category=$dbCategory'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderCol, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
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
                color: bg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(String question, String answer) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderCol, width: 1),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedAlignment: Alignment.topLeft,
        children: [
          Text(
            answer,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
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
        border: Border.all(color: AppTheme.borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image placeholder
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
                        color: AppTheme.primaryColor,
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
                leading: const Icon(Icons.my_location, color: AppTheme.primaryColor),
                title: const Text('Detect My Location', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
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
                      leading: const Icon(Icons.location_on_outlined, color: AppTheme.primaryColor),
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
    int selectedSortIndex = 0; // 0: Rating, 1: Price, 2: Popularity

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
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
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
                    activeColor: AppTheme.primaryColor,
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
                        selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: selectedSortIndex == 0 ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
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
                        selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: selectedSortIndex == 1 ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
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
                        selectedColor: AppTheme.primaryColor.withOpacity(0.1),
                        labelStyle: TextStyle(
                          color: selectedSortIndex == 2 ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
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
                        backgroundColor: AppTheme.primaryColor,
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
                            color: item.read ? Colors.grey : AppTheme.primaryColor,
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
