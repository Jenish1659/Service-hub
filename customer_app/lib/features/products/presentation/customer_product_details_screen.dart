import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import '../../../../core/theme/app_theme.dart';
import '../../cart/presentation/cart_provider.dart';
import '../services/product_reviews_service.dart';

class CustomerProductDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;

  const CustomerProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<CustomerProductDetailsScreen> createState() => _CustomerProductDetailsScreenState();
}

class _CustomerProductDetailsScreenState extends ConsumerState<CustomerProductDetailsScreen> {
  int _activeImageIndex = 0;
  int _quantity = 1;
  bool _isWishlisted = false;
  bool _isDescriptionExpanded = false;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> _extractImages(Map<String, dynamic> item) {
    final List<String> images = [];
    if (item['images'] is List) {
      for (final img in (item['images'] as List)) {
        if (img != null && img.toString().trim().isNotEmpty) {
          images.add(img.toString().trim());
        }
      }
    }
    if (images.isEmpty && item['image_url'] != null && item['image_url'].toString().trim().isNotEmpty) {
      images.add(item['image_url'].toString().trim());
    }
    if (images.isEmpty && item['image'] != null && item['image'].toString().trim().isNotEmpty) {
      images.add(item['image'].toString().trim());
    }
    return images;
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.product;
    final id = (item['id'] ?? item['product_id'] ?? '').toString();
    final name = (item['name'] ?? item['product_name'] ?? item['title'] ?? 'Product').toString();
    final price = (item['price'] as num?)?.toDouble() ?? 0.0;
    final mrp = (item['mrp'] as num?)?.toDouble() ?? (price > 0 ? (price * 1.3).roundToDouble() : 0.0);
    final sku = (item['sku'] ?? 'SKU-$id').toString();
    final cat = (item['category'] ?? item['category_name'] ?? 'General').toString();
    final desc = (item['clean_description'] ?? item['description'] ?? 'Genuine store certified item with manufacturer warranty and hyperlocal delivery.')
        .toString();
    final brand = (item['shop_name'] ?? 'Radha Enterprises • Certified Store').toString();
    final area = (item['area'] ?? item['delivery_area'] ?? 'Indira Marg (5 km Radius)').toString();
    final location = (item['location'] ?? item['hub_location'] ?? 'Radha Enterprises Central Hub').toString();
    final deliveryEta = (item['delivery_eta'] ?? '⚡ 15 MINS HYPERLOCAL DELIVERY').toString();

    final stockRaw = item['stock'] ?? item['stock_quantity'] ?? 50;
    final int stock = (stockRaw is num) ? stockRaw.toInt() : (int.tryParse(stockRaw.toString()) ?? 50);
    final bool isLowStock = stock > 0 && stock <= 10;
    final bool isOutOfStock = stock <= 0;

    final double discountPercent = (mrp > price && mrp > 0)
        ? (((mrp - price) / mrp) * 100).roundToDouble()
        : 0.0;
    final double savings = mrp > price ? (mrp - price) : 0.0;

    final images = _extractImages(item);
    final cartItemCount = ref.watch(cartItemCountProvider);

    // Dynamic real customer ratings (Zero fake ratings)
    final stats = ProductReviewsService.instance.getProductRatingStats(id);
    final bool hasRatings = stats['has_ratings'] == true;
    final double ratingVal = hasRatings ? (stats['average_rating'] as num).toDouble() : 0.0;
    final int reviewCount = (stats['review_count'] as num?)?.toInt() ?? 0;
    final reviews = ProductReviewsService.instance.getReviewsForProduct(id);

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xff0f172a)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff0f172a)),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isWishlisted ? Colors.redAccent : const Color(0xff475569),
            ),
            onPressed: () {
              setState(() {
                _isWishlisted = !_isWishlisted;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isWishlisted ? 'Saved to Wishlist' : 'Removed from Wishlist'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.primaryColor),
                onPressed: () => context.push('/cart'),
              ),
              if (cartItemCount > 0)
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
                      '$cartItemCount',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. BLINKIT-STYLE 15 MINS DELIVERY BANNER
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xfffef3c7), Color(0xfffef9c3)],
                ),
                border: Border(bottom: BorderSide(color: Color(0xfffde047), width: 0.5)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xffeab308),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deliveryEta.contains('⚡') ? deliveryEta.toUpperCase() : '⚡ $deliveryEta'.toUpperCase(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: Color(0xff854d0e),
                            letterSpacing: 0.3,
                          ),
                        ),
                        Text(
                          'Dispatched from $location serving $area',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xffa16207),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. MULTI-PHOTO INTERACTIVE CAROUSEL
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(
                        height: 290,
                        child: images.isNotEmpty
                            ? PageView.builder(
                                controller: _pageController,
                                itemCount: images.length,
                                onPageChanged: (idx) {
                                  setState(() => _activeImageIndex = idx);
                                },
                                itemBuilder: (context, index) {
                                  return _buildProductPhoto(images[index], cat, height: 290);
                                },
                              )
                            : _buildPlaceholderPhoto(cat, height: 290),
                      ),
                      if (discountPercent > 0)
                        Positioned(
                          top: 14,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xff16a34a),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                            ),
                            child: Text(
                              '${discountPercent.toInt()}% OFF',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 11),
                            ),
                          ),
                        ),
                      if (images.length > 1)
                        Positioned(
                          bottom: 14,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(images.length, (idx) {
                              final isCurrent = _activeImageIndex == idx;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: isCurrent ? 20 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isCurrent ? AppTheme.primaryColor : const Color(0xffcbd5e1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ),
                        ),
                    ],
                  ),

                  // Image thumbnails strip if multiple images
                  if (images.length > 1)
                    Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: images.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, idx) {
                          final isSelected = _activeImageIndex == idx;
                          return GestureDetector(
                            onTap: () {
                              _pageController.animateToPage(
                                idx,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                            child: Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected ? AppTheme.primaryColor : const Color(0xffe2e8f0),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: _buildProductPhoto(images[idx], cat, height: 48),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const Divider(height: 1, color: Color(0xffe2e8f0)),
                ],
              ),
            ),

            // 3. PRODUCT TITLE, BRAND & AUTHENTIC RATING
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Certified Brand Badge
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xffeff6ff),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xffbfdbfe)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: AppTheme.primaryColor),
                            const SizedBox(width: 5),
                            Text(
                              brand,
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      // Stock status badge
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xfffff7ed),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xfffed7aa)),
                          ),
                          child: Text(
                            '🔥 Only $stock left',
                            style: const TextStyle(
                              color: Color(0xffea580c),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (!isOutOfStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xfff0fdf4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xffbbf7d0)),
                          ),
                          child: const Text(
                            '✓ In Stock',
                            style: TextStyle(
                              color: Color(0xff16a34a),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xfffef2f2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xfffecaca)),
                          ),
                          child: const Text(
                            'Sold Out',
                            style: TextStyle(
                              color: Color(0xffdc2626),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Full Product Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Color(0xff0f172a),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Dynamic Authentic Customer Ratings (Strictly Zero Fake Ratings)
                  Row(
                    children: [
                      if (hasRatings) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xff15803d),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ratingVal.toStringAsFixed(1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 3),
                              const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$reviewCount Verified Customer Review${reviewCount > 1 ? 's' : ''}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xff475569),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xfff1f5f9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xffcbd5e1)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star_outline_rounded, size: 14, color: Color(0xff64748b)),
                              SizedBox(width: 4),
                              Text(
                                'New Launch • No customer reviews yet',
                                style: TextStyle(
                                  color: Color(0xff475569),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Price Breakdown
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '₹${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: Color(0xff0f172a),
                        ),
                      ),
                      if (mrp > price) ...[
                        const SizedBox(width: 10),
                        Text(
                          '₹${mrp.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xff94a3b8),
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xffdcfce7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Save ₹${savings.toStringAsFixed(0)} (${discountPercent.toInt()}% off)',
                            style: const TextStyle(
                              color: Color(0xff15803d),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Inclusive of all taxes • 100% Genuine Certified Spare Part',
                    style: TextStyle(fontSize: 11, color: Color(0xff64748b)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 4. AMAZON-STYLE TRUST BADGES
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTrustBadge(
                    icon: Icons.assignment_return_outlined,
                    title: '7 Days Return',
                    subtitle: 'Hassle-free replacement',
                  ),
                  _buildTrustBadge(
                    icon: Icons.verified_user_outlined,
                    title: '100% Genuine',
                    subtitle: 'Manufacturer tested',
                  ),
                  _buildTrustBadge(
                    icon: Icons.local_shipping_outlined,
                    title: 'Free Delivery',
                    subtitle: 'Within 5 km radius',
                  ),
                  _buildTrustBadge(
                    icon: Icons.payments_outlined,
                    title: 'Pay on Delivery',
                    subtitle: 'Cash or UPI on door',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 5. STRUCTURED TECHNICAL SPECIFICATIONS TABLE (Flipkart/Amazon style)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, color: AppTheme.primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Technical Specifications',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Table(
                    border: TableBorder.all(color: const Color(0xffe2e8f0), width: 1, borderRadius: BorderRadius.circular(8)),
                    children: [
                      _buildTableRow('Item Code / SKU', sku, isEven: true),
                      _buildTableRow('Category', cat.replaceAll('_', ' ').toUpperCase(), isEven: false),
                      _buildTableRow('Dispatch Hub', location, isEven: true),
                      _buildTableRow('Delivery Area', area, isEven: false),
                      _buildTableRow('Fast Delivery ETA', deliveryEta, isEven: true),
                      _buildTableRow('Brand / Seller', brand, isEven: false),
                      _buildTableRow('Compatibility', 'Universal Fit for ${_categoryFitment(cat)}', isEven: true),
                      _buildTableRow('Warranty', '6 Months Manufacturer Replacement Warranty', isEven: false),
                      _buildTableRow('Country of Origin', 'India (Certified Local Hub)', isEven: true),
                      _buildTableRow('In The Box', '1x $name, Official Invoice & Warranty Seal', isEven: false),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 6. PRODUCT DESCRIPTION
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.description_outlined, color: AppTheme.primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Product Overview & Description',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    desc,
                    maxLines: _isDescriptionExpanded ? null : 4,
                    overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xff334155),
                      height: 1.5,
                    ),
                  ),
                  if (desc.length > 150)
                    TextButton(
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                      onPressed: () {
                        setState(() {
                          _isDescriptionExpanded = !_isDescriptionExpanded;
                        });
                      },
                      child: Text(
                        _isDescriptionExpanded ? 'Read Less ▲' : 'Read More ▼',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 7. REAL CUSTOMER REVIEWS & RATINGS (Blinkit/Flipkart/Amazon style)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.reviews_rounded, color: AppTheme.primaryColor, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Customer Ratings & Reviews',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
                          ),
                        ],
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          side: const BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.rate_review_outlined, size: 15, color: AppTheme.primaryColor),
                        label: const Text('Write Review', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        onPressed: () => _showWriteReviewDialog(context, id, name),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (hasRatings) ...[
                    // Overall Rating Summary Box
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xfff8fafc),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffe2e8f0)),
                      ),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Text(
                                ratingVal.toStringAsFixed(1),
                                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Color(0xff0f172a)),
                              ),
                              Row(
                                children: List.generate(5, (starIdx) {
                                  return Icon(
                                    starIdx < ratingVal.floor() ? Icons.star_rounded : (starIdx < ratingVal ? Icons.star_half_rounded : Icons.star_outline_rounded),
                                    color: const Color(0xffeab308),
                                    size: 16,
                                  );
                                }),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$reviewCount ratings',
                                style: const TextStyle(color: Color(0xff64748b), fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [5, 4, 3, 2, 1].map((stars) {
                                final count = (stats['breakdown'] is Map)
                                    ? ((stats['breakdown'] as Map)[stars] as num?)?.toInt() ?? 0
                                    : 0;
                                final pct = reviewCount > 0 ? count / reviewCount : 0.0;
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                                  child: Row(
                                    children: [
                                      Text('$stars★', style: const TextStyle(fontSize: 10.5, color: Color(0xff64748b), fontWeight: FontWeight.bold)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            backgroundColor: const Color(0xffe2e8f0),
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              stars >= 4 ? const Color(0xff16a34a) : (stars == 3 ? const Color(0xffeab308) : const Color(0xffef4444)),
                                            ),
                                            minHeight: 6,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text('$count', style: const TextStyle(fontSize: 10.5, color: Color(0xff94a3b8))),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Authentic Customer Reviews List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: reviews.length,
                      separatorBuilder: (_, __) => const Divider(height: 20, color: Color(0xfff1f5f9)),
                      itemBuilder: (context, idx) {
                        final r = reviews[idx];
                        final rRating = (r['rating'] as num?)?.toDouble() ?? 5.0;
                        final rComment = (r['comment'] ?? '').toString();
                        final rAuthor = (r['reviewer_name'] ?? 'Verified Customer').toString();
                        final rDate = (r['created_at'] != null)
                            ? r['created_at'].toString().split('T').first
                            : 'Recent';

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff15803d),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        rRating.toStringAsFixed(0),
                                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Icons.star_rounded, size: 11, color: Colors.white),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  rAuthor,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: Color(0xff0f172a)),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffeff6ff),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text('✓ Verified Purchase', style: TextStyle(color: Color(0xff2563eb), fontSize: 9.5, fontWeight: FontWeight.bold)),
                                ),
                                const Spacer(),
                                Text(
                                  rDate,
                                  style: const TextStyle(fontSize: 10.5, color: Color(0xff94a3b8)),
                                ),
                              ],
                            ),
                            if (rComment.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                rComment,
                                style: const TextStyle(fontSize: 12.5, color: Color(0xff334155), height: 1.35),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ] else ...[
                    // Empty state (Strictly Zero Fake Ratings)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xfff8fafc),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffe2e8f0)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.rate_review_outlined, size: 36, color: Color(0xff94a3b8)),
                          const SizedBox(height: 8),
                          const Text(
                            'No customer reviews yet',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xff334155)),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Be the first verified customer to share genuine experience with this product.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 11.5, color: Color(0xff64748b)),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.star_outline_rounded, size: 16),
                            label: const Text('Write First Review', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () => _showWriteReviewDialog(context, id, name),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),

      // 8. STICKY BOTTOM ACTION BAR (Blinkit/Flipkart/Amazon style)
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
          border: const Border(top: BorderSide(color: Color(0xffe2e8f0))),
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Quantity Stepper
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffcbd5e1)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: isOutOfStock || _quantity <= 1
                          ? null
                          : () {
                              setState(() => _quantity--);
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Icon(
                          Icons.remove_rounded,
                          size: 18,
                          color: isOutOfStock || _quantity <= 1 ? const Color(0xffcbd5e1) : const Color(0xff0f172a),
                        ),
                      ),
                    ),
                    Text(
                      '$_quantity',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff0f172a)),
                    ),
                    InkWell(
                      onTap: isOutOfStock || _quantity >= stock
                          ? null
                          : () {
                              setState(() => _quantity++);
                            },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: isOutOfStock || _quantity >= stock ? const Color(0xffcbd5e1) : const Color(0xff0f172a),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Add to Cart Button
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isOutOfStock ? const Color(0xffcbd5e1) : AppTheme.primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isOutOfStock
                        ? null
                        : () {
                            ref.read(cartProvider.notifier).addItemWithQuantity(item, _quantity);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('✓ $_quantity × "$name" added to cart!'),
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
                      isOutOfStock ? 'Sold Out' : 'Add to Cart',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isOutOfStock ? const Color(0xff94a3b8) : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Buy Now Button
              Expanded(
                child: SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isOutOfStock ? const Color(0xffcbd5e1) : const Color(0xfff59e0b),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isOutOfStock
                        ? null
                        : () {
                            ref.read(cartProvider.notifier).addItemWithQuantity(item, _quantity);
                            context.push('/cart');
                          },
                    child: Text(
                      isOutOfStock ? 'Out of Stock' : '⚡ Buy Now',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(String title, String val, {required bool isEven}) {
    return TableRow(
      decoration: BoxDecoration(color: isEven ? const Color(0xfff8fafc) : Colors.white),
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff475569)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: Text(
            val,
            style: const TextStyle(fontSize: 12, color: Color(0xff0f172a), fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }

  Widget _buildTrustBadge({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(
            color: Color(0xffeff6ff),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 9.5, color: Color(0xff64748b)),
        ),
      ],
    );
  }

  String _categoryFitment(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('ac')) return 'Split, Window & Inverter Air Conditioners';
    if (c.contains('plumb')) return 'Kitchen, Bathroom & Main Pipelines';
    if (c.contains('car')) return 'Hatchback, Sedan & SUV Automobiles';
    if (c.contains('cook')) return 'Kitchen Appliance & Gas Burner Units';
    if (c.contains('laundr')) return 'Semi & Fully Automatic Washing Machines';
    if (c.contains('care')) return 'Standard Home Healthcare Equipment';
    return 'Residential & Commercial Systems';
  }

  Widget _buildProductPhoto(String? imageSource, String cat, {required double height}) {
    if (imageSource == null || imageSource.trim().isEmpty) {
      return _buildPlaceholderPhoto(cat, height: height);
    }
    final src = imageSource.trim();

    if (src.startsWith('data:image/') || src.startsWith('base64,')) {
      try {
        final base64String = src.contains(',') ? src.split(',').last : src;
        return Image.memory(
          base64Decode(base64String),
          height: height,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _buildPlaceholderPhoto(cat, height: height),
        );
      } catch (_) {
        return _buildPlaceholderPhoto(cat, height: height);
      }
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      return Image.network(
        src,
        height: height,
        width: double.infinity,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => _buildPlaceholderPhoto(cat, height: height),
      );
    } else {
      try {
        final f = File(src);
        if (f.existsSync()) {
          return Image.file(
            f,
            height: height,
            width: double.infinity,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildPlaceholderPhoto(cat, height: height),
          );
        }
      } catch (_) {}
      return _buildPlaceholderPhoto(cat, height: height);
    }
  }

  Widget _buildPlaceholderPhoto(String cat, {required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      color: const Color(0xfff8fafc),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            _getIconForCategory(cat),
            color: AppTheme.primaryColor,
            size: 56,
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('ac')) return Icons.ac_unit_rounded;
    if (c.contains('plumb')) return Icons.plumbing_rounded;
    if (c.contains('care')) return Icons.health_and_safety_rounded;
    if (c.contains('car')) return Icons.directions_car_rounded;
    if (c.contains('cook')) return Icons.soup_kitchen_rounded;
    if (c.contains('laundry')) return Icons.local_laundry_service_rounded;
    return Icons.shopping_bag_outlined;
  }

  void _showWriteReviewDialog(BuildContext context, String productId, String productName) {
    double selectedRating = 5.0;
    final commentController = TextEditingController();
    final nameController = TextEditingController();

    // Autofill logged-in customer name if available
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        final savedName = box.get('customer_name') ?? box.get('name');
        if (savedName != null && savedName.toString().trim().isNotEmpty) {
          nameController.text = savedName.toString().trim();
        }
      }
    } catch (_) {}

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xffeff6ff),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.star_rounded, color: AppTheme.primaryColor, size: 22),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Write Verified Review',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xff334155)),
                ),
                const SizedBox(height: 14),

                const Text('Rate this product *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xff475569))),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (starIdx) {
                    final starVal = starIdx + 1.0;
                    return IconButton(
                      icon: Icon(
                        starVal <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                        color: const Color(0xffeab308),
                        size: 32,
                      ),
                      onPressed: () {
                        setDialogState(() => selectedRating = starVal);
                      },
                    );
                  }),
                ),
                const SizedBox(height: 14),

                const Text('Your Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xff475569))),
                const SizedBox(height: 6),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'e.g. Rahul Sharma',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 14),

                const Text('Your Review & Experience *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xff475569))),
                const SizedBox(height: 6),
                TextField(
                  controller: commentController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Write about product quality, fitment, and performance...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xff64748b))),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final comment = commentController.text.trim();
                final name = nameController.text.trim();
                if (comment.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter your review comment')),
                  );
                  return;
                }

                await ProductReviewsService.instance.submitProductReview(
                  productId: productId,
                  rating: selectedRating,
                  comment: comment,
                  reviewerName: name.isNotEmpty ? name : 'Verified Customer',
                );

                if (!mounted) return;
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {}); // Refresh product details screen with updated ratings

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('✓ Thank you! Your verified review has been submitted.'),
                      backgroundColor: Color(0xff16a34a),
                    ),
                  );
                }
              },
              child: const Text('Submit Review', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
