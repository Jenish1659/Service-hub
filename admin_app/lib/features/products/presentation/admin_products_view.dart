import 'dart:ui' as ui;
import 'package:file_picker/file_picker.dart';
import 'dart:math';
import 'package:flutter/foundation.dart';
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


Future<Uint8List> _compressImageUnder1MB(Uint8List rawBytes) async {
  // If already under 350 KB, return directly
  if (rawBytes.lengthInBytes <= 350 * 1024) {
    return rawBytes;
  }
  try {
    final codec = await ui.instantiateImageCodec(
      rawBytes,
      targetWidth: 800,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final compressed = byteData.buffer.asUint8List();
      if (compressed.lengthInBytes <= 1024 * 1024) {
        return compressed;
      }
    }
  } catch (e) {
    debugPrint('[AdminProducts] Image compression note: $e');
  }

  try {
    final codec = await ui.instantiateImageCodec(
      rawBytes,
      targetWidth: 500,
    );
    final frame = await codec.getNextFrame();
    final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData != null) {
      final compressed = byteData.buffer.asUint8List();
      if (compressed.lengthInBytes <= 1024 * 1024) {
        return compressed;
      }
    }
  } catch (_) {}

  // Strict 1MB limit check
  if (rawBytes.lengthInBytes > 1024 * 1024) {
    throw Exception('Selected image exceeds 1MB limit. Please choose a photo under 1MB.');
  }
  return rawBytes;
}

class _AdminProductsViewState extends State<AdminProductsView> {
  Widget _buildProductImage(String? imageSource, {double size = 36}) {
    if (imageSource == null || imageSource.trim().isEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFDBEAFE)),
        ),
        child: Icon(Icons.inventory_2_rounded, color: const Color(0xFF2563EB), size: size * 0.5),
      );
    }
    final src = imageSource.trim();
    if (src.startsWith('data:image/') || src.startsWith('base64,')) {
      try {
        final base64String = src.contains(',') ? src.split(',').last : src;
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            base64Decode(base64String),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_rounded, color: const Color(0xFF2563EB), size: size * 0.5),
          ),
        );
      } catch (_) {}
    } else if (src.startsWith('http://') || src.startsWith('https://')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          src,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.inventory_2_rounded, color: const Color(0xFF2563EB), size: size * 0.5),
        ),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFDBEAFE)),
      ),
      child: Icon(Icons.inventory_2_rounded, color: const Color(0xFF2563EB), size: size * 0.5),
    );
  }

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
    final Map<String, Map<String, dynamic>> combined = {};

    // 1. Supabase Cloud Database (Universal Master Catalog)
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('products')
          .select('*, shops(shop_name, shop_type)')
          .order('created_at', ascending: false)
          .timeout(const Duration(seconds: 12));
      for (final r in res) {
        final m = Map<String, dynamic>.from(r as Map);
        final id = (m['product_id'] ?? m['id'] ?? '').toString();
        m['id'] = id;
        m['product_id'] = id;
        m['name'] = m['product_name'] ?? m['name'] ?? m['title'] ?? 'Product';
        m['title'] = m['name'];
        m['image_url'] = m['image'] ?? m['image_url'];
        final shop = m['shops'] is Map ? m['shops'] as Map<String, dynamic> : null;
        m['shop_name'] = shop?['shop_name'] ?? 'ServiceHub Store';
        m['category_name'] = shop?['shop_type'] ?? m['category'] ?? 'AC Spare Parts';
        m['category'] = (m['category'] ?? m['category_name'] ?? 'ac_parts').toString().toLowerCase().replaceAll(' ', '_');
        final rawDesc = (m['description'] ?? '').toString();
        final tagRegex = RegExp(r'\[Area:\s*(.*?)\s*\|\s*Hub:\s*(.*?)\s*\|\s*ETA:\s*(.*?)\]\s*');
        final match = tagRegex.firstMatch(rawDesc);
        if (match != null) {
          m['area'] = match.group(1);
          m['location'] = match.group(2);
          m['delivery_eta'] = match.group(3);
          m['clean_description'] = rawDesc.replaceFirst(tagRegex, '').trim();
        } else {
          m['area'] = m['area'] ?? 'Indira Marg (5 km Radius)';
          m['location'] = m['location'] ?? (shop?['shop_name'] ?? 'Radha Enterprises Central Hub');
          m['delivery_eta'] = m['delivery_eta'] ?? '⚡ 15 MINS (Express)';
          m['clean_description'] = rawDesc;
        }
        if (id.isNotEmpty) combined[id] = m;
      }
    } catch (e) {
      debugPrint('[AdminProducts] Supabase products load: $e');
    }

    // 2. Python Sync Bridge API (Host-aware for Android vs Web/Windows)
    try {
      final host = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : '127.0.0.1';
      final res = await http
          .get(Uri.parse('http://$host:8088/api/products'))
          .timeout(const Duration(milliseconds: 1500));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List) {
          for (final item in decoded) {
            final m = Map<String, dynamic>.from(item as Map);
            final id = (m['product_id'] ?? m['id'] ?? '').toString();
            m['name'] = m['product_name'] ?? m['name'] ?? m['title'] ?? 'Product';
            m['title'] = m['name'];
            if (id.isNotEmpty && !combined.containsKey(id)) {
              combined[id] = m;
            }
          }
        }
      }
    } catch (_) {}

    // 3. Direct File IPC Fallback (Windows Desktop Only)
    if (!kIsWeb && Platform.isWindows) {
      try {
        const publicPath = r'C:\Users\Public\ServiceHub\service_hub_store_products.json';
        final file = File(publicPath);
        if (await file.exists()) {
          final content = await file.readAsString();
          final data = jsonDecode(content);
          if (data is Map) {
            for (final entry in data.entries) {
              final m = Map<String, dynamic>.from(entry.value as Map);
              final id = (m['product_id'] ?? m['id'] ?? entry.key).toString();
              m['name'] = m['product_name'] ?? m['name'] ?? m['title'] ?? 'Product';
              m['title'] = m['name'];
              if (id.isNotEmpty && !combined.containsKey(id)) {
                combined[id] = m;
              }
            }
          } else if (data is List) {
            for (final item in data) {
              final m = Map<String, dynamic>.from(item as Map);
              final id = (m['product_id'] ?? m['id'] ?? '').toString();
              m['name'] = m['product_name'] ?? m['name'] ?? m['title'] ?? 'Product';
              m['title'] = m['name'];
              if (id.isNotEmpty && !combined.containsKey(id)) {
                combined[id] = m;
              }
            }
          }
        }
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _products = combined.values.toList();
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
      await client.from('products').delete().or('product_id.eq.$productId,sku.eq.$productId');
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
    final locationController = TextEditingController(text: 'Radha Enterprises Central Hub, Jamnagar');
    final areaController = TextEditingController(text: 'Indira Marg (5 km Radius)');
    String selectedDeliveryEta = '⚡ 15 MINS (Express)';

    String selectedCategory = 'AC Spare Parts';
    Uint8List? pickedImageBytes;
    String? pickedImageName;
    bool isPublishing = false;

    // Auto-generate guaranteed collision-proof SKU on modal open
    skuController.text = 'SKU-AC-${Random().nextInt(900000) + 100000}';

    showDialog(
      context: context,
      barrierDismissible: !isPublishing,
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
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
                                    final catPrefix = val.length >= 2 ? val.substring(0, 2).toUpperCase() : 'PR';
                                    skuController.text = 'SKU-$catPrefix-${Random().nextInt(900000) + 100000}';
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
                                hintText: 'Auto-generated SKU',
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

                  // Real Image from File Explorer Section
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Product Photo (From Computer / Files) *',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF334155)),
                        ),
                        const SizedBox(height: 8),
                        if (pickedImageBytes != null) ...[
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  pickedImageBytes!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pickedImageName ?? 'selected_image.jpg',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${(pickedImageBytes!.lengthInBytes / 1024).toStringAsFixed(1)} KB • Real photo (< 1MB guaranteed)',
                                      style: const TextStyle(color: Color(0xFF16A34A), fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                                tooltip: 'Remove Image',
                                onPressed: () {
                                  setModalState(() {
                                    pickedImageBytes = null;
                                    pickedImageName = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ] else ...[
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    side: const BorderSide(color: Color(0xFF2563EB)),
                                  ),
                                  icon: const Icon(Icons.photo_library_rounded, color: Color(0xFF2563EB), size: 20),
                                  label: const Text('Browse Files & Select Real Photo', style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                                  onPressed: () async {
                                    try {
                                      final result = await FilePicker.platform.pickFiles(
                                        type: FileType.image,
                                        withData: true,
                                      );
                                      if (result != null && result.files.isNotEmpty) {
                                        final file = result.files.first;
                                        Uint8List? bytes = file.bytes;
                                        if (bytes == null && file.path != null) {
                                          bytes = await File(file.path!).readAsBytes();
                                        }
                                        if (bytes != null) {
                                          try {
                                            final optimized = await _compressImageUnder1MB(bytes);
                                            if (optimized.lengthInBytes > 1024 * 1024) {
                                              if (ctx.mounted) {
                                                ScaffoldMessenger.of(ctx).showSnackBar(
                                                  const SnackBar(
                                                    content: Text('⚠️ Selected photo exceeds 1MB. Please choose an image under 1MB.'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                              return;
                                            }
                                            setModalState(() {
                                              pickedImageBytes = optimized;
                                              pickedImageName = file.name;
                                            });
                                          } catch (err) {
                                            if (ctx.mounted) {
                                              ScaffoldMessenger.of(ctx).showSnackBar(
                                                SnackBar(
                                                  content: Text('Image Error: $err'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      }
                                    } catch (e) {
                                      debugPrint('Error picking file: $e');
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
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
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Detailed specifications, warranty information, and compatibility details...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Location & Delivery Area Section for Fast Hyperlocal Delivery
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFFB45309)),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Hyperlocal Delivery Area & Store Hub *',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Store / Hub Location *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: locationController,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Radha Enterprises Central Hub, Jamnagar',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      prefixIcon: const Icon(Icons.store_rounded, size: 18, color: Color(0xFF2563EB)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Delivery Area / Serving Zone *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF334155))),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: areaController,
                                    decoration: InputDecoration(
                                      hintText: 'e.g. Indira Marg (5 km Radius)',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                      prefixIcon: const Icon(Icons.location_on_rounded, size: 18, color: Color(0xFF16A34A)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: ['Indira Marg', 'Patel Colony', 'GIDC Zone', '5 km Radius'].map((preset) {
                            return ActionChip(
                              label: Text(preset, style: const TextStyle(fontSize: 11)),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              onPressed: () {
                                setModalState(() {
                                  areaController.text = '$preset (5 km Radius)';
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Text('Delivery Guarantee: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                            const SizedBox(width: 8),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: selectedDeliveryEta,
                                items: const [
                                  DropdownMenuItem(value: '⚡ 15 MINS (Express)', child: Text('⚡ 15 MINS (Instant Hyperlocal)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                  DropdownMenuItem(value: '⚡ 30 MINS (Priority)', child: Text('⚡ 30 MINS (Priority Express)', style: TextStyle(fontSize: 12))),
                                  DropdownMenuItem(value: 'Same-Day Fast Delivery', child: Text('Same-Day Fast Delivery', style: TextStyle(fontSize: 12))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => selectedDeliveryEta = val);
                                },
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                ),
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
          ),
          actions: [
            TextButton(
              onPressed: isPublishing ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: isPublishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                isPublishing ? 'Publishing...' : 'Publish Product',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: isPublishing
                  ? null
                  : () async {
                      final title = titleController.text.trim();
                      final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                      final mrp = double.tryParse(mrpController.text.trim()) ?? (price * 1.3);
                      final rawSku = skuController.text.trim().isNotEmpty
                          ? skuController.text.trim()
                          : 'SKU-${Random().nextInt(900000) + 100000}';
                      final stock = int.tryParse(stockController.text.trim()) ?? 10;
                      final desc = descController.text.trim().isNotEmpty
                          ? descController.text.trim()
                          : 'Genuine store certified item with manufacturer warranty.';
                      final location = locationController.text.trim().isNotEmpty
                          ? locationController.text.trim()
                          : 'Radha Enterprises Central Hub, Jamnagar';
                      final area = areaController.text.trim().isNotEmpty
                          ? areaController.text.trim()
                          : 'Indira Marg (5 km Radius)';
                      final deliveryEta = selectedDeliveryEta;

                      // Encode structured delivery metadata tags for 100% database compatibility
                      final fullDesc = '[Area: $area | Hub: $location | ETA: $deliveryEta] $desc';

                      if (title.isEmpty || price <= 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter a valid title and price'), backgroundColor: Colors.red),
                        );
                        return;
                      }

                      // Convert picked real photo to Base64 data URI
                      String finalImage;
                      if (pickedImageBytes != null) {
                        final isPng = pickedImageName?.toLowerCase().endsWith('.png') ?? false;
                        final mime = isPng ? 'image/png' : 'image/jpeg';
                        finalImage = 'data:$mime;base64,${base64Encode(pickedImageBytes!)}';
                      } else if (imageUrlController.text.trim().isNotEmpty) {
                        finalImage = imageUrlController.text.trim();
                      } else {
                        // Fallback authentic image
                        finalImage = 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&w=600&q=80';
                      }

                      setModalState(() => isPublishing = true);

                      const validShopId = '8644497a-8c8a-4ff1-8912-c4e7048176c8';
                      final client = Supabase.instance.client;
                      String? createdProductId;
                      String finalSku = rawSku;

                      // Insert into Supabase products table with automatic collision retry
                      for (int attempt = 0; attempt < 3; attempt++) {
                        try {
                          final inserted = await client.from('products').insert({
                            'shop_id': validShopId,
                            'product_name': title,
                            'price': price,
                            'description': fullDesc,
                            'sku': finalSku,
                            'image': finalImage,
                            'status': 'ACTIVE',
                          }).select().single().timeout(const Duration(seconds: 12));
                          createdProductId = inserted['product_id']?.toString();
                          break;
                        } catch (e) {
                          if (e.toString().contains('products_sku_key') ||
                              e.toString().contains('409') ||
                              e.toString().contains('duplicate key')) {
                            finalSku = '$rawSku-${Random().nextInt(9000) + 1000}';
                            continue;
                          }
                          debugPrint('[AdminProducts] Supabase insert note: $e');
                          break;
                        }
                      }

                      if (createdProductId == null) {
                        setModalState(() => isPublishing = false);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to publish product to live store. Please check connection and retry.'),
                            backgroundColor: Color(0xFFDC2626),
                          ),
                        );
                        return;
                      }

                      final effectiveId = createdProductId;

                      final newProd = {
                        'id': effectiveId,
                        'product_id': effectiveId,
                        'shop_id': validShopId,
                        'name': title,
                        'product_name': title,
                        'title': title,
                        'category': selectedCategory.toLowerCase().replaceAll(' ', '_'),
                        'category_name': selectedCategory,
                        'price': price,
                        'mrp': mrp,
                        'sku': finalSku,
                        'stock': stock,
                        'description': fullDesc,
                        'clean_description': desc,
                        'area': area,
                        'location': location,
                        'delivery_eta': deliveryEta,
                        'icon': 'inventory_2_rounded',
                        'image_url': finalImage,
                        'image': finalImage,
                        'created_at': DateTime.now().toIso8601String(),
                      };

                      // 1. Optimistic instant UI update
                      if (mounted) {
                        setState(() {
                          _products.insert(0, newProd);
                        });
                        if (ctx.mounted) Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('✓ Product "${newProd['title']}" published to store with real photo!'),
                            backgroundColor: const Color(0xFF16A34A),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }

                      // 2. Background non-blocking secondary syncs
                      Future.microtask(() async {
                        try {
                          final host = (!kIsWeb && Platform.isAndroid) ? '10.0.2.2' : '127.0.0.1';
                          await http.post(
                            Uri.parse('http://$host:8088/api/products'),
                            headers: {'Content-Type': 'application/json'},
                            body: jsonEncode(newProd),
                          ).timeout(const Duration(seconds: 2));
                        } catch (_) {}

                        if (!kIsWeb && Platform.isWindows) {
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
                        }
                      });
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
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.vertical,
                              physics: const ClampingScrollPhysics(),
                              child: DataTable(
                              headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                              columnSpacing: 24,
                              horizontalMargin: 20,
                              columns: const [
                                DataColumn(label: Text('PRODUCT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                                DataColumn(label: Text('CATEGORY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                                DataColumn(label: Text('LOCATION & AREA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                                DataColumn(label: Text('SKU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                                DataColumn(label: Text('SELLING PRICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                                DataColumn(label: Text('MRP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                                DataColumn(label: Text('STOCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                                DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                              ],
                              rows: filtered.map((prod) {
                                final pId = (prod['id'] ?? prod['product_id'] ?? '').toString();
                                final title = (prod['product_name'] ?? prod['name'] ?? prod['title'] ?? 'Product').toString();
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
                                          _buildProductImage(prod['image'] ?? prod['image_url'], size: 36),
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
                                    DataCell(
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            (prod['area'] ?? '5 km Radius').toString(),
                                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                          ),
                                          Text(
                                            (prod['location'] ?? 'Central Hub').toString(),
                                            style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
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
          ),
        ],
      ),
    );
  }
}
