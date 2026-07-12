import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  String selectedCategory = 'All';

  final List<String> categories = ['All', 'AC', 'Plumbing', 'Car', 'Cooking', 'Laundry'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () => context.push('/cart'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. GEOFENCING ZONE INDICATOR
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xffeff6ff),
            child: Row(
              children: const [
                Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 18),
                SizedBox(width: 8),
                Text(
                  'Delivering within 5 km zone only · 30-45 mins delivery',
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. CATEGORY PILLS
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                    selectedColor: AppTheme.primaryColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textPrimaryColor,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: const BorderSide(color: AppTheme.borderCol),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 3. PRODUCT GRID
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.78,
              children: [
                _buildGridProductCard(context, 'AC Dust Filter (Universal)', '₹349', '₹499', '30% OFF'),
                _buildGridProductCard(context, 'Pipe Repair Tape 5m', '₹89', '₹120', '26% OFF'),
                _buildGridProductCard(context, 'Car Shampoo 500ml', '₹199', '₹299', '33% OFF'),
                _buildGridProductCard(context, '3-Tier Tiffin Box', '₹449', '₹599', '25% OFF'),
                _buildGridProductCard(context, 'Laundry Detergent 1kg', '₹249', '₹349', '29% OFF'),
                _buildGridProductCard(context, 'Microfiber Cloths (5pc)', '₹299', '₹399', '25% OFF'),
                _buildGridProductCard(context, 'Drain Cleaner 500ml', '₹149', '₹199', '25% OFF'),
                _buildGridProductCard(context, 'Mesh Laundry Bag Set', '₹179', '₹249', '28% OFF'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridProductCard(
    BuildContext context,
    String name,
    String price,
    String originalPrice,
    String discount,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderCol, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Space
          Container(
            height: 110,
            decoration: const BoxDecoration(
              color: Color(0xfff1f5f9),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: const Center(
              child: Icon(Icons.shopping_bag_outlined, color: AppTheme.textSecondaryColor, size: 40),
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
                    fontSize: 13,
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
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      originalPrice,
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: AppTheme.textSecondaryColor,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => context.push('/cart'),
                      child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
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
}
