import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminProductsView extends StatefulWidget {
  const AdminProductsView({super.key});

  @override
  State<AdminProductsView> createState() => _AdminProductsViewState();
}

class _AdminProductsViewState extends State<AdminProductsView> {
  List<Map<String, dynamic>> _products = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'AC Spare Parts',
    'Electronics & Tools',
    'Plumbing & Hardware',
    'Automotive Supplies',
    'Household Essentials',
  ];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    List<Map<String, dynamic>> loaded = [];

    // 1. Try fetching from Python sync bridge API
    try {
      final res = await http
          .get(Uri.parse('http://127.0.0.1:8088/api/products'))
          .timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          loaded = List<Map<String, dynamic>>.from(decoded);
        }
      }
    } catch (_) {}

    // 2. Direct File IPC Fallback
    if (loaded.isEmpty) {
      try {
        const publicPath = r'C:\Users\Public\ServiceHub\service_hub_store_products.json';
        final file = File(publicPath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final data = jsonDecode(content);
          if (data is Map) {
            loaded = data.values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
          } else if (data is List) {
            loaded = List<Map<String, dynamic>>.from(data);
          }
        }
      } catch (_) {}
    }

    // 3. Supabase Fallback
    if (loaded.isEmpty) {
      try {
        final client = Supabase.instance.client;
        final res = await client.from('products').select().order('created_at', ascending: false);
        if (res.isNotEmpty) {
          loaded = List<Map<String, dynamic>>.from(res);
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _products = loaded;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Product', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove product #$productId from the live catalog?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await http.delete(Uri.parse('http://127.0.0.1:8088/api/products/$productId')).timeout(const Duration(seconds: 2));
    } catch (_) {}

    // File IPC delete
    try {
      const publicPath = r'C:\Users\Public\ServiceHub\service_hub_store_products.json';
      final file = File(publicPath);
      if (await file.exists()) {
        final content = await file.readAsString();
        final data = jsonDecode(content);
        if (data is Map && data.containsKey(productId)) {
          data.remove(productId);
          await file.writeAsString(jsonEncode(data));
        }
      }
    } catch (_) {}

    // Supabase delete
    try {
      final client = Supabase.instance.client;
      await client.from('products').delete().eq('id', productId);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Product #$productId removed from catalog.'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadProducts();
    }
  }

  void _showAddProductModal() {
    final titleController = TextEditingController();
    final categoryController = TextEditingController(text: 'AC Spare Parts');
    final priceController = TextEditingController();
    final mrpController = TextEditingController();
    final skuController = TextEditingController();
    final stockController = TextEditingController(text: '50');
    final descController = TextEditingController();
    final imageUrlController = TextEditingController();

    String selectedCategory = 'AC Spare Parts';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_shopping_cart_rounded, color: Color(0xFF2563EB), size: 22),
              ),
              const SizedBox(width: 12),
              const Text(
                'Add Live Store Product',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Product Title *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Split AC Universal Remote Controller',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Category *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            DropdownButtonFormField<String>(
                              initialValue: selectedCategory,
                              items: _categories.where((c) => c != 'All').map((cat) {
                                return DropdownMenuItem<String>(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13)));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setModalState(() {
                                    selectedCategory = val;
                                    categoryController.text = val;
                                  });
                                }
                              },
                              decoration: InputDecoration(
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('SKU / Code *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: skuController,
                              decoration: InputDecoration(
                                hintText: 'e.g. SKU-AC-REM-01',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Selling Price (₹) *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                hintText: '349',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('MRP / Original (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: mrpController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                prefixText: '₹ ',
                                hintText: '599',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Stock Units *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                            const SizedBox(height: 6),
                            TextField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '50',
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  const Text('Product Description *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Detailed specifications, warranty information, and compatibility details...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  const Text('Image URL (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155))),
                  const SizedBox(height: 6),
                  TextField(
                    controller: imageUrlController,
                    decoration: InputDecoration(
                      hintText: 'https://images.unsplash.com/... or asset path',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.check_circle_rounded, size: 18),
              label: const Text('Publish Product', style: TextStyle(fontWeight: FontWeight.bold)),
              onPressed: () async {
                final title = titleController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                final mrp = double.tryParse(mrpController.text.trim()) ?? (price * 1.3);
                final sku = skuController.text.trim().isNotEmpty
                    ? skuController.text.trim()
                    : 'SKU-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                final stock = int.tryParse(stockController.text.trim()) ?? 10;
                final desc = descController.text.trim().isNotEmpty
                    ? descController.text.trim()
                    : 'Authentic store certified product with manufacturer warranty.';
                final img = imageUrlController.text.trim().isNotEmpty
                    ? imageUrlController.text.trim()
                    : 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=300&q=80';

                if (title.isEmpty || price <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a valid title and price'), backgroundColor: Colors.red),
                  );
                  return;
                }

                Navigator.pop(ctx);

                final newProd = {
                  'id': 'PROD_${DateTime.now().millisecondsSinceEpoch}',
                  'product_id': 'PROD_${DateTime.now().millisecondsSinceEpoch}',
                  'name': title,
                  'title': title,
                  'category': selectedCategory.toLowerCase().replaceAll(' ', '_'),
                  'category_name': selectedCategory,
                  'price': price,
                  'mrp': mrp,
                  'sku': sku,
                  'stock': stock,
                  'description': desc,
                  'icon': 'inventory_2_rounded',
                  'image_url': img,
                  'created_at': DateTime.now().toIso8601String(),
                };

                // 1. Post to Python server
                try {
                  await http.post(
                    Uri.parse('http://127.0.0.1:8088/api/products'),
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode(newProd),
                  ).timeout(const Duration(seconds: 2));
                } catch (_) {}

                // 2. Direct File IPC Save
                try {
                  const publicPath = r'C:\Users\Public\ServiceHub\service_hub_store_products.json';
                  final file = File(publicPath);
                  Map<String, dynamic> current = {};
                  if (await file.exists()) {
                    final content = await file.readAsString();
                    final parsed = jsonDecode(content);
                    if (parsed is Map) current = Map<String, dynamic>.from(parsed);
                  }
                  current[newProd['id'] as String] = newProd;
                  await file.writeAsString(jsonEncode(current));
                } catch (_) {}

                // 3. Supabase insert
                try {
                  final client = Supabase.instance.client;
                  await client.from('products').insert({
                    'id': newProd['id'],
                    'name': newProd['name'],
                    'category': newProd['category'],
                    'price': newProd['price'],
                    'stock': newProd['stock'],
                    'description': newProd['description'],
                    'image_url': newProd['image_url'],
                  });
                } catch (_) {}

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Product "${newProd['title']}" added to live catalog successfully!'),
                      backgroundColor: const Color(0xFF16A34A),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  _loadProducts();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _products.where((p) {
      final name = (p['name'] ?? p['title'] ?? '').toString().toLowerCase();
      final cat = (p['category_name'] ?? p['category'] ?? '').toString().toLowerCase();
      final sku = (p['sku'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();

      final matchesQuery = q.isEmpty || name.contains(q) || cat.contains(q) || sku.contains(q);
      final matchesCategory = _selectedCategory == 'All' ||
          cat.contains(_selectedCategory.toLowerCase()) ||
          (p['category'] ?? '').toString().toLowerCase().contains(_selectedCategory.toLowerCase().replaceAll(' ', '_'));

      return matchesQuery && matchesCategory;
    }).toList();

    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Store Products & Catalog',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage official products displayed to customers and fulfilled by shopkeepers (${_products.length} live products)',
                      style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: _loadProducts,
                    icon: const Icon(Icons.refresh_rounded, color: Color(0xFF475569)),
                    tooltip: 'Refresh Products',
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    onPressed: _showAddProductModal,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search and Filters Bar
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val),
                  decoration: InputDecoration(
                    hintText: 'Search products by title, SKU, or category...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)))).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Main Products Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                              child: const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF2563EB)),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No Products Found',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Click "Add Product" above to publish products to the customer marketplace.',
                              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 4))],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SingleChildScrollView(
                            physics: const ClampingScrollPhysics(),
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              columnSpacing: 24,
                              horizontalMargin: 20,
                              columns: const [
                                DataColumn(label: Text('PRODUCT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                                DataColumn(label: Text('CATEGORY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                                DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                                DataColumn(label: Text('SELLING PRICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                                DataColumn(label: Text('MRP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                                DataColumn(label: Text('STOCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                                DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                              ],
                              rows: filtered.map((prod) {
                                final pId = (prod['id'] ?? prod['product_id'] ?? '').toString();
                                final title = (prod['name'] ?? prod['title'] ?? 'Product').toString();
                                final cat = (prod['category_name'] ?? prod['category'] ?? 'Store').toString();
                                final sku = (prod['sku'] ?? 'N/A').toString();
                                final price = (prod['price'] as num?)?.toDouble() ?? 0.0;
                                final mrp = (prod['mrp'] as num?)?.toDouble() ?? (price * 1.3);
                                final stock = (prod['stock'] as num?)?.toInt() ?? 0;
                                final inStock = stock > 0;

                                return DataRow(
                                  cells: [
                                    DataCell(
                                      Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFEFF6FF),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(color: const Color(0xFFDBEAFE)),
                                            ),
                                            child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF2563EB), size: 18),
                                          ),
                                          const SizedBox(width: 12),
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 220),
                                            child: Text(
                                              title,
                                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1F5F9),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(cat, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                                      ),
                                    ),
                                    DataCell(Text(sku, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontFamily: 'monospace'))),
                                    DataCell(Text('₹${price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)))),
                                    DataCell(Text('₹${mrp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12.5, decoration: TextDecoration.lineThrough, color: Color(0xFF94A3B8)))),
                                    DataCell(
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: inStock ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          inStock ? '$stock units' : 'Out of Stock',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: inStock ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                                        tooltip: 'Delete Product',
                                        onPressed: () => _deleteProduct(pId),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
