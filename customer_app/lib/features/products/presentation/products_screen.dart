import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../cart/presentation/cart_provider.dart';
import 'products_provider.dart';

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> categories = [
    {'name': 'All', 'icon': Icons.apps_rounded},
    {'name': 'AC Repair', 'icon': Icons.ac_unit_rounded},
    {'name': 'Car Service', 'icon': Icons.directions_car_rounded},
    {'name': 'Plumbing', 'icon': Icons.plumbing_rounded},
    {'name': 'Cooking', 'icon': Icons.soup_kitchen_rounded},
    {'name': 'Laundry', 'icon': Icons.local_laundry_service_rounded},
    {'name': 'Care Taker', 'icon': Icons.health_and_safety_rounded},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final itemCount = ref.watch(cartItemCountProvider);
    final subtotal = ref.watch(cartSubtotalProvider);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ServiceHub Marketplace',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: Color(0xff0f172a)),
            ),
            Text(
              'Hyperlocal Spare Parts & Genuine Products (5 km Radius)',
              style: TextStyle(fontSize: 11, color: Color(0xff64748b), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryColor),
                onPressed: () => context.push('/cart'),
              ),
              if (itemCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xffef4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$itemCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // 1. SEARCH BAR
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val.trim();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products, parts, or service tools...',
                    hintStyle: const TextStyle(color: Color(0xff94a3b8), fontSize: 13.5),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryColor, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xff64748b)),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xfff1f5f9),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                    ),
                  ),
                ),
              ),

              // 2. CATEGORY FILTERS
              Container(
                height: 52,
                color: Colors.white,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: categories.length,
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final String catName = cat['name'];
                    final isSelected = catName == selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        avatar: Icon(
                          cat['icon'],
                          size: 16,
                          color: isSelected ? Colors.white : AppTheme.primaryColor,
                        ),
                        label: Text(
                          catName,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xff334155),
                          ),
                        ),
                        backgroundColor: const Color(0xfff1f5f9),
                        selectedColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? AppTheme.primaryColor : const Color(0xffe2e8f0),
                          ),
                        ),
                        onSelected: (val) {
                          setState(() {
                            selectedCategory = catName;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1, color: Color(0xffe2e8f0)),

              // 3. PRODUCT GRID
              Expanded(
                child: productsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                  error: (err, stack) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text('Error loading products: $err', style: const TextStyle(color: Color(0xffef4444))),
                    ),
                  ),
                  data: (products) {
                    final filteredProducts = products.where((p) {
                      final cat = p['category']?.toString() ?? '';
                      final name = p['name']?.toString().toLowerCase() ?? '';
                      final desc = p['description']?.toString().toLowerCase() ?? '';

                      bool matchesCategory = (selectedCategory == 'All') || (cat.toLowerCase() == selectedCategory.toLowerCase());
                      bool matchesSearch = _searchQuery.isEmpty ||
                          name.contains(_searchQuery.toLowerCase()) ||
                          desc.contains(_searchQuery.toLowerCase()) ||
                          cat.toLowerCase().contains(_searchQuery.toLowerCase());

                      return matchesCategory && matchesSearch;
                    }).toList();

                    if (filteredProducts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off_rounded, size: 54, color: Color(0xff94a3b8)),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No products matching "$_searchQuery"'
                                  : 'No products available under $selectedCategory',
                              style: const TextStyle(color: Color(0xff64748b), fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return GridView.builder(
                      padding: EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                        bottom: itemCount > 0 ? 90 : 20,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final item = filteredProducts[index];
                        return _buildGridProductCard(context, item);
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // 4. FLOATING VIEW CART BAR
          if (itemCount > 0)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: InkWell(
                onTap: () => context.push('/cart'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.35),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$itemCount Item${itemCount > 1 ? 's' : ''} in Cart',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Subtotal: ₹$subtotal',
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                      const Row(
                        children: [
                          Text(
                            'View Cart',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridProductCard(BuildContext context, Map<String, dynamic> item) {
    final name = item['name'] ?? 'Product';
    final price = '₹${item['price'] ?? 349}';
    final originalPrice = item['original_price'] != null ? '₹${item['original_price']}' : '';
    final discount = item['discount'] ?? '';
    final String cat = item['category'] ?? '';

    // Extract real photos
    final List<String> images = (item['images'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
        [
          if (item['image_url'] != null) item['image_url'].toString(),
          ..._getDefaultImagesForCategory(cat),
        ];

    final int stock = (item['stock'] ?? item['stock_quantity'] ?? 100) as int;
    final bool isLowStock = stock > 0 && stock <= 10;
    final bool isOutOfStock = stock <= 0;

    return GestureDetector(
      onTap: () => _showProductDetailsModal(context, item, images),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isLowStock ? const Color(0xfff97316) : const Color(0xffe2e8f0),
            width: isLowStock ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Real Image Container with Photo Count Tag
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(17),
                    topRight: Radius.circular(17),
                  ),
                  child: Image.network(
                    images.first,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 120,
                      color: const Color(0xffeff6ff),
                      child: Center(
                        child: Icon(_getIconForCategory(cat), color: AppTheme.primaryColor, size: 40),
                      ),
                    ),
                  ),
                ),

                // Multi-Photo Count Badge
                if (images.length > 1)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.collections_rounded, color: Colors.white, size: 10),
                          const SizedBox(width: 3),
                          Text(
                            '${images.length}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Stock Urgency Alert Badge
                if (isLowStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xffea580c),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_fire_department_rounded, color: Colors.white, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            'Only $stock left!',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (isOutOfStock)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xffdc2626),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Out of Stock',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xff0f172a),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        price,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                          fontSize: 14.5,
                        ),
                      ),
                      if (originalPrice.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          originalPrice,
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
                      if (!isLowStock && !isOutOfStock && discount.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xfff0fdf4),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xffbbf7d0)),
                          ),
                          child: Text(
                            discount,
                            style: const TextStyle(
                              color: Color(0xff16a34a),
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (!isLowStock && !isOutOfStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xfff0fdf4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'In Stock',
                            style: TextStyle(
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: isOutOfStock ? const Color(0xffcbd5e1) : AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: isOutOfStock
                            ? null
                            : () {
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
                        child: Text(
                          isOutOfStock ? 'Sold Out' : 'Add',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Multi-Photo Detail Modal
  void _showProductDetailsModal(BuildContext context, Map<String, dynamic> item, List<String> images) {
    int activePage = 0;
    final name = item['name'] ?? 'Product';
    final price = '₹${item['price'] ?? 349}';
    final originalPrice = item['original_price'] != null ? '₹${item['original_price']}' : '';
    final discount = item['discount'] ?? '';
    final String cat = item['category'] ?? '';
    final String desc = item['description'] ?? 'High quality genuine spare part & product verified for 5 km hyperlocal home delivery.';
    final int stock = (item['stock'] ?? item['stock_quantity'] ?? 100) as int;
    final bool isLowStock = stock > 0 && stock <= 10;
    final bool isOutOfStock = stock <= 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: Column(
                children: [
                  // Modal Header handle
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xffcbd5e1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Carousel Header (PageView with dots)
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(
                        height: 220,
                        child: PageView.builder(
                          itemCount: images.length,
                          onPageChanged: (idx) {
                            setModalState(() => activePage = idx);
                          },
                          itemBuilder: (context, imgIdx) {
                            return Image.network(
                              images[imgIdx],
                              width: double.infinity,
                              height: 220,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: const Color(0xffeff6ff),
                                child: Center(
                                  child: Icon(_getIconForCategory(cat), color: AppTheme.primaryColor, size: 60),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Carousel Dots Indicator
                      if (images.length > 1)
                        Positioned(
                          bottom: 10,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (idx) {
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: activePage == idx ? 16 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: activePage == idx ? AppTheme.primaryColor : Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),

                  // Product Specs & Details
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xffeff6ff),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: const Color(0xffbfdbfe)),
                                ),
                                child: Text(
                                  cat,
                                  style: const TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const Spacer(),
                              if (isLowStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffea580c),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '🔥 Only $stock left in stock!',
                                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                )
                              else if (!isOutOfStock)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffdcfce7),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'In Stock (Fast Delivery)',
                                    style: TextStyle(color: Color(0xff15803d), fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xff0f172a))),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Text(price, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
                              if (originalPrice.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(originalPrice, style: const TextStyle(fontSize: 14, color: Color(0xff94a3b8), decoration: TextDecoration.lineThrough)),
                              ],
                              if (discount.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xfff0fdf4), borderRadius: BorderRadius.circular(4)),
                                  child: Text(discount, style: const TextStyle(color: Color(0xff16a34a), fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Product Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xff0f172a))),
                          const SizedBox(height: 6),
                          Text(desc, style: const TextStyle(fontSize: 13, color: Color(0xff64748b), height: 1.4)),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Action Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: Color(0xffe2e8f0))),
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isOutOfStock ? const Color(0xffcbd5e1) : AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: isOutOfStock
                            ? null
                            : () {
                                ref.read(cartProvider.notifier).addItem(item);
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('$name added to cart!'),
                                    backgroundColor: AppTheme.successColor,
                                  ),
                                );
                              },
                        child: Text(
                          isOutOfStock ? 'Sold Out' : 'Add to Cart • $price',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
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

  List<String> _getDefaultImagesForCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('ac')) {
      return [
        'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1581094288338-2314dddb7ece?auto=format&fit=crop&w=600&q=80',
      ];
    }
    if (c.contains('plumb')) {
      return [
        'https://images.unsplash.com/photo-1585704032915-c3400ca199e7?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1607472586893-edb57bdc0e39?auto=format&fit=crop&w=600&q=80',
      ];
    }
    if (c.contains('car')) {
      return [
        'https://images.unsplash.com/photo-1486006920555-c77dce18193b?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1619642751034-765dfdf7c58e?auto=format&fit=crop&w=600&q=80',
      ];
    }
    if (c.contains('cook')) {
      return [
        'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?auto=format&fit=crop&w=600&q=80',
        'https://images.unsplash.com/photo-1556910103-1c02745aae4d?auto=format&fit=crop&w=600&q=80',
      ];
    }
    if (c.contains('laundry')) {
      return [
        'https://images.unsplash.com/photo-1582735689369-4fe89db7114c?auto=format&fit=crop&w=600&q=80',
      ];
    }
    return [
      'https://images.unsplash.com/photo-1584308666744-24d5c474f2ae?auto=format&fit=crop&w=600&q=80',
      'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?auto=format&fit=crop&w=600&q=80',
    ];
  }

  IconData _getIconForCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('ac')) return Icons.ac_unit_rounded;
    if (c.contains('plumb')) return Icons.plumbing_rounded;
    if (c.contains('car')) return Icons.directions_car_rounded;
    if (c.contains('cook')) return Icons.soup_kitchen_rounded;
    if (c.contains('laundry')) return Icons.local_laundry_service_rounded;
    if (c.contains('care')) return Icons.health_and_safety_rounded;
    return Icons.shopping_bag_outlined;
  }
}
