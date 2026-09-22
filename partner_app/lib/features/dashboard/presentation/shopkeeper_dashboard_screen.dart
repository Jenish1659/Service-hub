import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/storage/local_registration_cache.dart';
import '../../../../core/services/live_booking_sync_service.dart';

class ShopkeeperDashboardScreen extends StatefulWidget {
  const ShopkeeperDashboardScreen({super.key});

  @override
  State<ShopkeeperDashboardScreen> createState() => _ShopkeeperDashboardScreenState();
}

class _ShopkeeperDashboardScreenState extends State<ShopkeeperDashboardScreen> {
  bool _isOpen = true;
  String _shopkeeperName = 'Rajesh Kumar';
  String _shopName = 'Rajesh Electronics';
  String _shopAddress = 'Station Road, Jamnagar';
  String _shopCategory = 'AC Service Parts';
  String _todayHours = '9:00 AM - 8:00 PM';
  double _todaySales = 8450.0;
  int _newOrdersCount = 12;
  int _todayOrdersCount = 28;
  final double _shopRating = 4.8;
  final int _ratingReviewsCount = 126;
  int _activeNavIndex = 0;
  bool _isLoading = false;

  // Real stateful orders list matching the design mockup
  late List<Map<String, dynamic>> _orders;

  // Catalog items for the store
  final List<Map<String, dynamic>> _catalogProducts = [
    {'name': 'AC Remote (Universal Multi-brand)', 'category': 'AC Service Parts', 'price': 450.0, 'stock': 8, 'sku': 'SH-AC-901'},
    {'name': 'Water Filter Cartridge (RO 5-Stage)', 'category': 'Water Purifier', 'price': 850.0, 'stock': 3, 'sku': 'SH-RO-412'},
    {'name': 'Washing Machine Belt (Universal)', 'category': 'Appliance Parts', 'price': 350.0, 'stock': 14, 'sku': 'SH-WM-119'},
    {'name': 'Copper Tubing 1/4" (15 Meters Coil)', 'category': 'AC Service Parts', 'price': 1450.0, 'stock': 2, 'sku': 'SH-AC-220'},
    {'name': 'R32 Refrigerant Gas Cylinder (1kg)', 'category': 'AC Service Parts', 'price': 1200.0, 'stock': 0, 'sku': 'SH-AC-032'},
    {'name': 'Drain Pipe 2 Meter Flexible', 'category': 'Plumbing Parts', 'price': 180.0, 'stock': 0, 'sku': 'SH-PL-554'},
  ];

  @override
  void initState() {
    super.initState();
    _initDefaultOrders();
    _loadShopData();
  }

  void _initDefaultOrders() {
    _orders = [
      {
        'order_id': 'SH1024',
        'item_title': 'AC Remote',
        'customer_name': 'Rahul Patel',
        'item_count': 2,
        'location': 'Rajkot (2.3 km)',
        'amount': 450.0,
        'status': 'New',
        'status_color': const Color(0xFF10B981),
        'status_bg': const Color(0xFFDCFCE7),
      },
      {
        'order_id': 'SH1023',
        'item_title': 'Water Filter',
        'customer_name': 'Neha Shah',
        'item_count': 1,
        'location': 'Rajkot (1.8 km)',
        'amount': 850.0,
        'status': 'Preparing',
        'status_color': const Color(0xFFD97706),
        'status_bg': const Color(0xFFFEF3C7),
      },
      {
        'order_id': 'SH1021',
        'item_title': 'Washing Machine Belt',
        'customer_name': 'Amit Joshi',
        'item_count': 2,
        'location': 'Rajkot (3.1 km)',
        'amount': 350.0,
        'status': 'Completed',
        'status_color': const Color(0xFF2563EB),
        'status_bg': const Color(0xFFDBEAFE),
      },
    ];
  }

  Future<void> _loadShopData() async {
    setState(() => _isLoading = true);
    try {
      final activeUser = await LocalRegistrationCache.getActiveShopkeeper();
      if (activeUser != null) {
        final status = (activeUser['verification_status'] ?? '').toString().toUpperCase();
        final accStatus = (activeUser['account_status'] ?? '').toString().toUpperCase();
        
        // Cross-check with LiveBookingSyncService
        final uId = (activeUser['user_id'] ?? '').toString();
        final phone = (activeUser['phone'] ?? '').toString();
        final syncRecord = LiveBookingSyncService.instance.getPartnerVerification(uId) ??
            LiveBookingSyncService.instance.getPartnerVerification(phone);
        final syncStatus = (syncRecord?['status'] ?? syncRecord?['verification_status'] ?? '').toString().toUpperCase();

        var isApproved = status == 'VERIFIED' || status == 'APPROVED' || accStatus == 'ACTIVE' || syncStatus == 'APPROVED' || syncStatus == 'VERIFIED';

        // Real-time fallback against Supabase if local state hasn't synced yet
        if (!isApproved && phone.isNotEmpty) {
          try {
            final client = Supabase.instance.client;
            final uRes = await client.from('users').select('account_status, user_id').eq('phone', phone).maybeSingle();
            if (uRes != null) {
              if (uRes['account_status'] == 'ACTIVE') {
                isApproved = true;
              } else if (uRes['user_id'] != null) {
                final vr = await client
                    .from('verification_requests')
                    .select('status')
                    .eq('user_id', uRes['user_id'])
                    .order('submitted_at', ascending: false)
                    .limit(1)
                    .maybeSingle();
                if (vr != null && (vr['status'] == 'APPROVED' || vr['status'] == 'VERIFIED')) {
                  isApproved = true;
                }
              }
            }
            if (isApproved) {
              await LocalRegistrationCache.updateActiveShopkeeper({
                ...activeUser,
                'verification_status': 'VERIFIED',
                'status': 'APPROVED',
                'account_status': 'ACTIVE',
              });
            }
          } catch (_) {}
        }

        if (!isApproved) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Shopkeeper application is pending Admin approval. Dashboard is locked.'),
                backgroundColor: Color(0xFFD97706),
                behavior: SnackBarBehavior.floating,
              ),
            );
            GoRouter.maybeOf(context)?.go('/login/shopkeeper');
            return;
          }
        }

        setState(() {
          final fullName = (activeUser['name'] ?? activeUser['full_name'] ?? '').toString();
          if (fullName.isNotEmpty) _shopkeeperName = fullName;
          final bName = (activeUser['business_name'] ?? '').toString();
          if (bName.isNotEmpty) _shopName = bName;
          final addr = (activeUser['business_address'] ?? activeUser['address'] ?? '').toString();
          if (addr.isNotEmpty) _shopAddress = addr;
          final cat = (activeUser['category'] ?? '').toString();
          if (cat.isNotEmpty) _shopCategory = cat;
        });
      }

      // Query real store orders from Supabase if connected
      try {
        final client = Supabase.instance.client;
        final ordersRes = await client
            .from('orders')
            .select('*, order_items(*, products(*)), user_addresses(*)')
            .order('created_at', ascending: false)
            .limit(5);

        if (ordersRes.isNotEmpty) {
          final List<Map<String, dynamic>> realOrders = [];
          for (final o in ordersRes) {
            final address = o['user_addresses'] as Map<String, dynamic>?;
            final code = (o['order_code'] ?? 'SH${o['order_id'] ?? 1025}').toString();
            final amt = (o['total_amount'] as num?)?.toDouble() ?? 450.0;
            final st = (o['order_status'] ?? 'New').toString();

            Color stColor = const Color(0xFF10B981);
            Color stBg = const Color(0xFFDCFCE7);
            if (st.toLowerCase().contains('prep') || st.toLowerCase().contains('pack')) {
              stColor = const Color(0xFFD97706);
              stBg = const Color(0xFFFEF3C7);
            } else if (st.toLowerCase().contains('ready') || st.toLowerCase().contains('complete')) {
              stColor = const Color(0xFF2563EB);
              stBg = const Color(0xFFDBEAFE);
            }

            realOrders.add({
              'order_id': code,
              'item_title': o['items_summary'] ?? 'Store Spare Parts',
              'customer_name': 'Customer',
              'item_count': 1,
              'location': address != null ? '${address['city']} (${address['area'] ?? ""})' : 'Rajkot (Local)',
              'amount': amt,
              'status': st,
              'status_color': stColor,
              'status_bg': stBg,
            });
          }
          if (mounted && realOrders.isNotEmpty) {
            setState(() {
              _orders = realOrders;
            });
          }
        }
      } catch (_) {}
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleShopStatus(bool val) {
    setState(() => _isOpen = val);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              val ? Icons.check_circle_rounded : Icons.pause_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            Expanded(
              child: Text(
                val
                    ? 'Shop is now OPEN for new customer orders'
                    : 'Shop is now CLOSED. Incoming orders paused.',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: val ? const Color(0xFF059669) : const Color(0xFF334155),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showOperatingHoursSheet() {
    String selectedHours = _todayHours;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final options = [
            '8:00 AM - 7:00 PM',
            '9:00 AM - 8:00 PM',
            '9:30 AM - 9:00 PM',
            '10:00 AM - 10:00 PM',
            '24 Hours Open',
          ];

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.access_time_filled_rounded, color: Color(0xFFD97706), size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Today\'s Store Operating Hours', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                          Text('Customers can place orders during these working hours', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...options.map((opt) {
                  final isSel = selectedHours == opt;
                  return InkWell(
                    onTap: () => setModalState(() => selectedHours = opt),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSel ? const Color(0xFFECFDF5) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? const Color(0xFF059669) : const Color(0xFFE2E8F0), width: isSel ? 1.5 : 1),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSel ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                            color: isSel ? const Color(0xFF059669) : const Color(0xFF94A3B8),
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(opt, style: TextStyle(fontSize: 14, fontWeight: isSel ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () {
                      setState(() => _todayHours = selectedHours);
                      Navigator.pop(modalCtx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Store operating hours updated to $_todayHours'),
                          backgroundColor: const Color(0xFF059669),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: const Text('Save Operating Hours', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showAddProductModal() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final mrpCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '10');
    final skuCtrl = TextEditingController();
    String selectedCat = 'AC Service Parts';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.add_business_rounded, color: Color(0xFF059669), size: 22),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Add Product to Store Catalog', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                              Text('Make your items discoverable to technicians & customers', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Product Name
                    const Text('Product Title *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        hintText: 'e.g. Copper Pipe 1/4" (15 Meter Coil)',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category Dropdown
                    const Text('Product Category *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: selectedCat,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'AC Service Parts', child: Text('AC Service Parts')),
                        DropdownMenuItem(value: 'Water Purifier', child: Text('Water Purifier / RO Parts')),
                        DropdownMenuItem(value: 'Appliance Parts', child: Text('Washing Machine & Appliance')),
                        DropdownMenuItem(value: 'Plumbing Parts', child: Text('Plumbing Supplies & Taps')),
                        DropdownMenuItem(value: 'Electrical Supplies', child: Text('Electrical & Wiring')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModalState(() => selectedCat = v);
                      },
                    ),
                    const SizedBox(height: 14),

                    // Price & MRP
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Selling Price (₹) *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: priceCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  hintText: '450',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
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
                              const Text('MRP (₹)', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: mrpCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  prefixText: '₹ ',
                                  hintText: '599',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Stock Count & SKU
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Available Stock *', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: stockCtrl,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: '10',
                                  suffixText: 'units',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
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
                              const Text('SKU / Code', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                              const SizedBox(height: 6),
                              TextField(
                                controller: skuCtrl,
                                decoration: InputDecoration(
                                  hintText: 'SH-AC-990',
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF059669),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                        label: const Text('Save & Publish to Store Catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        onPressed: () {
                          final title = nameCtrl.text.trim();
                          final price = double.tryParse(priceCtrl.text.trim()) ?? 350.0;
                          final stock = int.tryParse(stockCtrl.text.trim()) ?? 10;
                          final sku = skuCtrl.text.trim().isNotEmpty ? skuCtrl.text.trim() : 'SH-SKU-${DateTime.now().millisecond}';

                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter a product title'), backgroundColor: Colors.red),
                            );
                            return;
                          }

                          setState(() {
                            _catalogProducts.insert(0, {
                              'name': title,
                              'category': selectedCat,
                              'price': price,
                              'stock': stock,
                              'sku': sku,
                            });
                          });

                          Navigator.pop(modalCtx);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('✓ "$title" added to store inventory successfully!'),
                              backgroundColor: const Color(0xFF059669),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showInventorySheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(ctx).size.height * 0.75,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFF3E8FF), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF7C3AED), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Store Inventory & Catalog', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      Text('Real-time stock quantities and price management', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: _catalogProducts.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (c, i) {
                  final p = _catalogProducts[i];
                  final stock = p['stock'] as int;
                  final isOut = stock == 0;
                  final isLow = stock > 0 && stock <= 5;

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isOut ? const Color(0xFFFEE2E2) : (isLow ? const Color(0xFFFEF3C7) : const Color(0xFFECFDF5)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isOut ? Icons.highlight_off_rounded : (isLow ? Icons.warning_rounded : Icons.check_circle_outline_rounded),
                          color: isOut ? const Color(0xFFEF4444) : (isLow ? const Color(0xFFD97706) : const Color(0xFF059669)),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p['name'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF0F172A))),
                            const SizedBox(height: 2),
                            Text('SKU: ${p['sku']} • ${p['category']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('₹${p['price']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF0F172A))),
                          const SizedBox(height: 2),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isOut ? const Color(0xFFFEE2E2) : (isLow ? const Color(0xFFFEF3C7) : const Color(0xFFDCFCE7)),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isOut ? 'Out of Stock' : (isLow ? '$stock Low' : '$stock in stock'),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isOut ? const Color(0xFFDC2626) : (isLow ? const Color(0xFFB45309) : const Color(0xFF15803D)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Add New Product', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showAddProductModal();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOffersDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.local_offer_rounded, color: Color(0xFFEA580C), size: 24),
            SizedBox(width: 10),
            Text('Active Store Offers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFEDD5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.discount_rounded, color: Color(0xFFEA580C), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FLAT10 • 10% Off on AC Spares', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF9A3412))),
                        Text('Valid for registered technicians on orders > ₹1000', style: TextStyle(fontSize: 11, color: Color(0xFFC2410C))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFDBEAFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.local_shipping_rounded, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('FREESHIP • Free 2km Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF))),
                        Text('Free store runner delivery for urgent service bookings', style: TextStyle(fontSize: 11, color: Color(0xFF3B82F6))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Offer banner activated on customer catalog!'), backgroundColor: Color(0xFF059669)),
              );
            },
            child: const Text('Create New Offer'),
          ),
        ],
      ),
    );
  }

  void _showEarningsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF16A34A), size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Store Earnings & Payouts', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                      Text('Settlements credited directly to registered bank account', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Settled Balance', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                      const SizedBox(height: 4),
                      Text('₹${_todaySales.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF059669),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Instant payout initiated to your verified bank account!'), backgroundColor: Color(0xFF059669)),
                      );
                    },
                    child: const Text('Withdraw Now'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Recent Payouts: Yesterday ₹14,200 (HDFC Bank • Complete)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  void _handleOrderAction(int index, String newStatus) {
    setState(() {
      final ord = _orders[index];
      ord['status'] = newStatus;
      if (newStatus == 'Preparing') {
        ord['status_color'] = const Color(0xFFD97706);
        ord['status_bg'] = const Color(0xFFFEF3C7);
        if (_newOrdersCount > 0) _newOrdersCount--;
      } else if (newStatus == 'Ready for Pickup') {
        ord['status_color'] = const Color(0xFF2563EB);
        ord['status_bg'] = const Color(0xFFDBEAFE);
      } else if (newStatus == 'Completed') {
        ord['status_color'] = const Color(0xFF059669);
        ord['status_bg'] = const Color(0xFFDCFCE7);
        _todaySales += (ord['amount'] as num?)?.toDouble() ?? 350.0;
        _todayOrdersCount++;
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order #${_orders[index]['order_id']} marked as $newStatus!'),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: _isLoading && _orders.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF059669)))
          : RefreshIndicator(
              onRefresh: _loadShopData,
              color: const Color(0xFF059669),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Greeting & Storefront Hero Card
                    _buildHeroStoreCard(),
                    const SizedBox(height: 14),

                    // 2. Shop Status & Today's Hours Split Bar
                    _buildStatusAndHoursBar(),
                    const SizedBox(height: 16),

                    // 3. Key Metrics 4-Card Row
                    _buildMetricsRow(),
                    const SizedBox(height: 20),

                    // 4. Quick Actions
                    _buildQuickActionsRow(),
                    const SizedBox(height: 20),

                    // 5. Stock Up Banner & Inventory Alerts
                    _buildBannerAndAlerts(),
                    const SizedBox(height: 22),

                    // 6. Recent Orders Section
                    _buildRecentOrdersHeader(),
                    const SizedBox(height: 12),
                    ..._orders.asMap().entries.map((entry) => _buildOrderCard(entry.key, entry.value)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // -------------------------------------------------------------
  // App Bar matching the Design Mockup
  // -------------------------------------------------------------
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      scrolledUnderElevation: 1,
      leading: Builder(
        builder: (ctx) => IconButton(
          icon: const Icon(Icons.menu_rounded, color: Color(0xFF0F172A), size: 24),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF059669),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SERVICEHUB',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                'SHOP PARTNER',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Notification bell with badge 4
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Color(0xFF0F172A), size: 24),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('4 New Notifications: 2 new orders received, 2 items low on stock.'),
                    backgroundColor: Color(0xFF0F172A),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            Positioned(
              right: 8,
              top: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Text(
                  '4',
                  style: TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),

        // Shopkeeper Avatar with green online indicator
        Padding(
          padding: const EdgeInsets.only(right: 14, left: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => context.push('/profile/shopkeeper'),
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 17,
                  backgroundColor: const Color(0xFFDCFCE7),
                  child: Text(
                    _shopkeeperName.isNotEmpty ? _shopkeeperName[0].toUpperCase() : 'R',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF059669), fontSize: 14),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _isOpen ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // Store Navigation Drawer
  // -------------------------------------------------------------
  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0F766E), Color(0xFF064E3B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Text(
                    _shopkeeperName.isNotEmpty ? _shopkeeperName[0].toUpperCase() : 'R',
                    style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF065F46), fontSize: 22),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _shopName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 2),
                Text(
                  _shopkeeperName,
                  style: const TextStyle(color: Color(0xFFCCFBF1), fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '📍 $_shopAddress • $_shopCategory',
                  style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF34D399)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_rounded, color: Color(0xFF34D399), size: 13),
                      SizedBox(width: 4),
                      Text('Verified Store Vendor', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.storefront_rounded, color: Color(0xFF059669)),
            title: const Text('Storefront Dashboard', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.inventory_2_outlined, color: Color(0xFF334155)),
            title: const Text('Inventory & Catalog', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _showInventorySheet();
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF334155)),
            title: const Text('Add New Product', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _showAddProductModal();
            },
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF334155)),
            title: const Text('Earnings & Settlements', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _showEarningsModal();
            },
          ),
          ListTile(
            leading: const Icon(Icons.local_offer_outlined, color: Color(0xFF334155)),
            title: const Text('Promotions & Offers', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              _showOffersDialog();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.help_outline_rounded, color: Color(0xFF334155)),
            title: const Text('Help & Support', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              context.push('/profile/shopkeeper');
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings_outlined, color: Color(0xFF334155)),
            title: const Text('Settings & Security', style: TextStyle(fontWeight: FontWeight.w600)),
            onTap: () {
              Navigator.pop(context);
              context.push('/profile/shopkeeper');
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
            onTap: () async {
              await LocalRegistrationCache.logoutShopkeeper();
              if (mounted) context.go('/login/shopkeeper');
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. Hero Store Greeting Banner (Pixel-Perfect from Mockup)
  // -------------------------------------------------------------
  Widget _buildHeroStoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D5B56), Color(0xFF064E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF064E3B).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left details
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning, $_shopkeeperName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('🏪 ', style: TextStyle(fontSize: 14)),
                    Flexible(
                      child: Text(
                        _shopName,
                        style: const TextStyle(
                          color: Color(0xFFCCFBF1),
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Verified Shop badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF34D399), width: 1.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 14),
                      SizedBox(width: 5),
                      Text(
                        'Verified Shop',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  '"Quality Products Happier Homes!"',
                  style: TextStyle(
                    color: Color(0xFFA7F3D0),
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Right illustration (Storefront representation)
          Expanded(
            flex: 4,
            child: Container(
              height: 115,
              alignment: Alignment.center,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Circular background glow
                  Container(
                    width: 95,
                    height: 95,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                  ),
                  // Stylized store front graphic
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF34D399), width: 1.5),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Awning canopy
                        Container(
                          width: 56,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34D399),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(
                              4,
                              (i) => Container(width: 6, color: i.isEven ? Colors.white : const Color(0xFF059669)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Icon(Icons.storefront_rounded, color: Colors.white, size: 30),
                        const SizedBox(height: 2),
                        const Text('PARTS', style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. Shop Status & Operating Hours Bar (Two equal cards)
  // -------------------------------------------------------------
  Widget _buildStatusAndHoursBar() {
    return Row(
      children: [
        // Left: Shop Status toggle
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _isOpen ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0)),
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.store_rounded,
                    color: _isOpen ? const Color(0xFF16A34A) : const Color(0xFF64748B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shop Status',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      Text(
                        _isOpen ? 'You are open for orders' : 'Store is closed',
                        style: TextStyle(fontSize: 10.5, color: _isOpen ? const Color(0xFF059669) : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: _isOpen,
                    activeThumbColor: Colors.white,
                    activeTrackColor: const Color(0xFF16A34A),
                    inactiveTrackColor: const Color(0xFFCBD5E1),
                    onChanged: _toggleShopStatus,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),

        // Right: Today's Hours
        Expanded(
          child: InkWell(
            onTap: _showOperatingHoursSheet,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      color: Color(0xFFD97706),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Today\'s Hours',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '$_todayHours >',
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 3. Metrics 4-Card Row (Pixel-Perfect from Mockup)
  // -------------------------------------------------------------
  Widget _buildMetricsRow() {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final cardWidth = (constraints.maxWidth - 10 * 3) / 4;
        final isNarrow = constraints.maxWidth < 650;

        if (isNarrow) {
          // 2x2 grid for standard mobile
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildMetricCard(title: 'New Orders', value: '$_newOrdersCount', pillText: '↑ 20%', icon: Icons.shopping_bag_outlined, pillColor: const Color(0xFF10B981), pillBg: const Color(0xFFDCFCE7), iconColor: const Color(0xFF0284C7), iconBg: const Color(0xFFE0F2FE))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard(title: 'Today\'s Orders', value: '$_todayOrdersCount', pillText: '↑ 12%', icon: Icons.local_shipping_outlined, pillColor: const Color(0xFFEA580C), pillBg: const Color(0xFFFFEDD5), iconColor: const Color(0xFFEA580C), iconBg: const Color(0xFFFFF7ED))),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _buildMetricCard(title: 'Today\'s Sales', value: '₹${_todaySales.toStringAsFixed(0)}', pillText: '↑ 18%', icon: Icons.currency_rupee_rounded, pillColor: const Color(0xFF7C3AED), pillBg: const Color(0xFFF3E8FF), iconColor: const Color(0xFF7C3AED), iconBg: const Color(0xFFFAF5FF))),
                  const SizedBox(width: 10),
                  Expanded(child: _buildMetricCard(title: 'Shop Rating', value: '$_shopRating', pillText: '★★★★★ ($_ratingReviewsCount)', icon: Icons.star_rounded, pillColor: const Color(0xFFCA8A04), pillBg: const Color(0xFFFEF9C3), iconColor: const Color(0xFFEAB308), iconBg: const Color(0xFFFEFCE8))),
                ],
              ),
            ],
          );
        }

        // Full 4-card row on larger views
        return Row(
          children: [
            SizedBox(width: cardWidth, child: _buildMetricCard(title: 'New Orders', value: '$_newOrdersCount', pillText: '↑ 20%', icon: Icons.shopping_bag_outlined, pillColor: const Color(0xFF10B981), pillBg: const Color(0xFFDCFCE7), iconColor: const Color(0xFF0284C7), iconBg: const Color(0xFFE0F2FE))),
            const SizedBox(width: 10),
            SizedBox(width: cardWidth, child: _buildMetricCard(title: 'Today\'s Orders', value: '$_todayOrdersCount', pillText: '↑ 12%', icon: Icons.local_shipping_outlined, pillColor: const Color(0xFFEA580C), pillBg: const Color(0xFFFFEDD5), iconColor: const Color(0xFFEA580C), iconBg: const Color(0xFFFFF7ED))),
            const SizedBox(width: 10),
            SizedBox(width: cardWidth, child: _buildMetricCard(title: 'Today\'s Sales', value: '₹${_todaySales.toStringAsFixed(0)}', pillText: '↑ 18%', icon: Icons.currency_rupee_rounded, pillColor: const Color(0xFF7C3AED), pillBg: const Color(0xFFF3E8FF), iconColor: const Color(0xFF7C3AED), iconBg: const Color(0xFFFAF5FF))),
            const SizedBox(width: 10),
            SizedBox(width: cardWidth, child: _buildMetricCard(title: 'Shop Rating', value: '$_shopRating', pillText: '★★★★★ ($_ratingReviewsCount)', icon: Icons.star_rounded, pillColor: const Color(0xFFCA8A04), pillBg: const Color(0xFFFEF9C3), iconColor: const Color(0xFFEAB308), iconBg: const Color(0xFFFEFCE8))),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String pillText,
    required IconData icon,
    required Color pillColor,
    required Color pillBg,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  pillText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: pillColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 4. Quick Actions Row (5 Rounded Icon Buttons)
  // -------------------------------------------------------------
  Widget _buildQuickActionsRow() {
    final actions = [
      {'title': 'Add Product', 'icon': Icons.add_rounded, 'color': const Color(0xFF059669), 'bg': const Color(0xFF059669), 'onTap': _showAddProductModal},
      {'title': 'Manage Products', 'icon': Icons.category_outlined, 'color': Colors.white, 'bg': const Color(0xFF3B82F6), 'onTap': _showInventorySheet},
      {'title': 'Inventory', 'icon': Icons.inventory_2_outlined, 'color': Colors.white, 'bg': const Color(0xFF8B5CF6), 'onTap': _showInventorySheet},
      {'title': 'Offers', 'icon': Icons.local_offer_outlined, 'color': Colors.white, 'bg': const Color(0xFFF97316), 'onTap': _showOffersDialog},
      {'title': 'View Earnings', 'icon': Icons.account_balance_wallet_outlined, 'color': Colors.white, 'bg': const Color(0xFF10B981), 'onTap': _showEarningsModal},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: actions.map((act) {
          final isAdd = act['title'] == 'Add Product';
          return Padding(
            padding: const EdgeInsets.only(right: 18),
            child: InkWell(
              onTap: act['onTap'] as VoidCallback,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: act['bg'] as Color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (act['bg'] as Color).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      act['icon'] as IconData,
                      color: isAdd ? Colors.white : Colors.white,
                      size: isAdd ? 28 : 22,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    act['title'] as String,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // -------------------------------------------------------------
  // 5. Stock Up Banner & Inventory Alerts
  // -------------------------------------------------------------
  Widget _buildBannerAndAlerts() {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isNarrow = constraints.maxWidth < 650;

        final banner = Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Stock Up. Sell More.',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Keep your inventory updated to get more orders from technicians & customers.',
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF059669),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _showAddProductModal,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Add Product', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Parts box representation
              Container(
                width: 75,
                height: 75,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.inventory_2_rounded, color: Color(0xFF34D399), size: 32),
                    SizedBox(height: 4),
                    Text('PARTS BOX', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 8, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        );

        final alerts = Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 8),
                  const Text('Inventory Alerts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const Spacer(),
                  InkWell(
                    onTap: _showInventorySheet,
                    child: const Text('Restock Now >', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.trending_down_rounded, color: Color(0xFFB45309), size: 14),
                        SizedBox(width: 6),
                        Text('4 Low Stock Items', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.remove_circle_outline_rounded, color: Color(0xFFDC2626), size: 14),
                        SizedBox(width: 6),
                        Text('2 Out of Stock', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFB91C1C))),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        if (isNarrow) {
          return Column(
            children: [
              banner,
              const SizedBox(height: 12),
              alerts,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 6, child: banner),
            const SizedBox(width: 14),
            Expanded(flex: 5, child: alerts),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------
  // 6. Recent Orders Section
  // -------------------------------------------------------------
  Widget _buildRecentOrdersHeader() {
    return Row(
      children: [
        const Text(
          'Recent Orders',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        const Spacer(),
        InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Viewing all 18 past customer and technician orders'),
                backgroundColor: Color(0xFF059669),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
          child: const Text(
            'View All (18) >',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
          ),
        ),
      ],
    );
  }

  Widget _buildOrderCard(int index, Map<String, dynamic> order) {
    final status = order['status'] as String;
    final isNew = status == 'New';
    final isPreparing = status == 'Preparing';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${order['order_id']} ${order['item_title']}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF0F172A)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: order['status_bg'] as Color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: order['status_color'] as Color),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${order['customer_name']} • ${order['item_count']} item(s) • ${order['location']}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                '₹${order['amount']}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
              ),
              const Spacer(),
              if (isNew) ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Order #${order['order_id']} details: 2x Universal AC Remote'), backgroundColor: const Color(0xFF0F172A)),
                    );
                  },
                  child: const Text('Details', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleOrderAction(index, 'Preparing'),
                  child: const Text('Accept Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ] else if (isPreparing) ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.call_rounded, size: 14, color: Color(0xFF2563EB)),
                  label: const Text('Call', style: TextStyle(fontSize: 11.5, color: Color(0xFF2563EB))),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Calling customer: +91 98980 22334'), backgroundColor: Color(0xFF2563EB)),
                    );
                  },
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleOrderAction(index, 'Completed'),
                  child: const Text('Ready for Pickup', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ] else ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invoice downloaded for Order #${order['order_id']}'), backgroundColor: const Color(0xFF059669)),
                    );
                  },
                  child: const Text('Receipt', style: TextStyle(fontSize: 12, color: Color(0xFF334155))),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 7. Bottom Navigation Bar (5 tabs)
  // -------------------------------------------------------------
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _activeNavIndex,
        onTap: (idx) {
          setState(() => _activeNavIndex = idx);
          if (idx == 1) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Navigating to Live Orders Queue'), backgroundColor: Color(0xFF059669)),
            );
          } else if (idx == 2) {
            _showInventorySheet();
          } else if (idx == 3) {
            _showEarningsModal();
          } else if (idx == 4) {
            context.push('/profile/shopkeeper');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF059669),
        unselectedItemColor: const Color(0xFF64748B),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        elevation: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text('3'),
              backgroundColor: Color(0xFFEF4444),
              child: Icon(Icons.shopping_bag_outlined),
            ),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category_outlined),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_rupee_rounded),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
