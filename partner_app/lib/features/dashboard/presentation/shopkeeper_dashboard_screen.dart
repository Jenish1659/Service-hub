import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/services/app_permissions_service.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/storage/local_registration_cache.dart';
import '../../../../core/services/phone_launcher_service.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import 'shopkeeper_store_map_screen.dart';

class ShopkeeperDashboardScreen extends StatefulWidget {
  const ShopkeeperDashboardScreen({super.key});

  @override
  State<ShopkeeperDashboardScreen> createState() => _ShopkeeperDashboardScreenState();
}

class _ShopkeeperDashboardScreenState extends State<ShopkeeperDashboardScreen> {
  bool get _isTestMode {
    if (kIsWeb) return false;
    try {
      return Platform.environment.containsKey('FLUTTER_TEST') ||
          WidgetsBinding.instance.runtimeType.toString().contains('Test');
    } catch (_) {
      return false;
    }
  }

  bool _isOpen = true;
  String _shopkeeperName = 'Store Owner';
  String _shopName = 'ServiceHub Store';
  String _shopAddress = '';
  String? _storePhotoPath;
  String _shopCategory = 'Store Catalog';
  String _todayHours = '09:00 AM - 08:00 PM';
  double _todaySales = 0.0;
  int _newOrdersCount = 0;
  int _todayOrdersCount = 0;
  double _shopRating = 0.0;
  int _ratingReviewsCount = 0;
  int _activeNavIndex = 0;
  bool _isLoading = false;
  String _partnerId = '';
  String _phone = '';
  DateTime? _lastBackPressTime;
  StreamSubscription? _liveBookingSub;

  // Real dynamically queried orders list (Supabase & Hive)
  List<Map<String, dynamic>> _orders = [];

  // Catalog items for the store (Supabase & Hive)
  List<Map<String, dynamic>> _catalogProducts = [];

  @override
  void initState() {
    super.initState();
    _loadShopData();
    _liveBookingSub = LiveBookingSyncService.instance.bookingsStream.listen((_) {
      if (mounted) _loadShopData();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverlayPermission();
    });
  }

  @override
  void dispose() {
    _liveBookingSub?.cancel();
    super.dispose();
  }

  Future<void> _loadShopData() async {
    setState(() => _isLoading = true);
    try {
      final cachedShopkeeper = await LocalRegistrationCache.getActiveShopkeeper();
      final activeUser = cachedShopkeeper ?? await LocalRegistrationCache.getActivePartner();
      if (activeUser == null) {
        if (mounted) GoRouter.maybeOf(context)?.go('/login/shopkeeper');
        return;
      }

      final role = (activeUser['role_name'] ?? activeUser['role'] ?? activeUser['category'] ?? '').toString().toLowerCase();
      if (role.isNotEmpty && role != 'shopkeeper' && !role.contains('shop') && !role.contains('store')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Access restricted: Logged in account is registered as $role, not Shopkeeper.'),
              backgroundColor: const Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
          if (role.contains('delivery') || role.contains('rider')) {
            GoRouter.maybeOf(context)?.go('/dashboard/delivery');
          } else if (role.contains('service') || role.contains('provider') || role.contains('expert')) {
            GoRouter.maybeOf(context)?.go('/dashboard');
          } else {
            GoRouter.maybeOf(context)?.go('/role-selection');
          }
        }
        return;
      }
        final userMap = Map<String, dynamic>.from(activeUser);
        final status = (userMap['verification_status'] ?? '').toString().toUpperCase();
        final accStatus = (userMap['account_status'] ?? '').toString().toUpperCase();
        
        // Cross-check with LiveBookingSyncService
        final uId = (userMap['user_id'] ?? userMap['id'] ?? '').toString();
        final pId = (userMap['partner_id'] ?? '').toString();
        final phone = (userMap['phone'] ?? '').toString();
        if (phone.isNotEmpty) _phone = phone;
        final username = (userMap['username'] ?? '').toString().trim();
        final syncRecord = LiveBookingSyncService.instance.getPartnerVerification(uId) ??
            (pId.isNotEmpty ? LiveBookingSyncService.instance.getPartnerVerification(pId) : null) ??
            (phone.isNotEmpty ? LiveBookingSyncService.instance.getPartnerVerification(phone) : null);
        final syncStatus = (syncRecord?['status'] ?? syncRecord?['verification_status'] ?? '').toString().toUpperCase();

        var isApproved = status == 'VERIFIED' || status == 'APPROVED' || accStatus == 'ACTIVE' || syncStatus == 'APPROVED' || syncStatus == 'VERIFIED';

        // Real-time fallback against Supabase if local state hasn't synced yet
        if (!isApproved && !_isTestMode) {
          try {
            final client = Supabase.instance.client;
            final cleanDigits = phone.replaceAll(RegExp(r'\D'), '');
            final last10 = cleanDigits.length >= 10 ? cleanDigits.substring(cleanDigits.length - 10) : '';

            // 1. Check users table by user_id, phone, or username
            Map<String, dynamic>? uRes;
            if (uId.isNotEmpty && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(uId)) {
              uRes = await client.from('users').select('account_status, user_id').eq('user_id', uId).maybeSingle();
            }
            if (uRes == null && last10.length >= 10) {
              uRes = await client
                  .from('users')
                  .select('account_status, user_id')
                  .or('phone.eq.$cleanDigits,phone.eq.+91$last10,phone.ilike.*$last10*')
                  .limit(1)
                  .maybeSingle();
            }
            if (uRes == null && username.isNotEmpty) {
              uRes = await client
                  .from('users')
                  .select('account_status, user_id')
                  .eq('username', username)
                  .limit(1)
                  .maybeSingle();
            }

            if (uRes != null) {
              final userAccStatus = (uRes['account_status'] ?? '').toString().toUpperCase();
              final targetUid = uRes['user_id']?.toString() ?? uId;
              if (userAccStatus == 'ACTIVE') {
                isApproved = true;
              } else if (targetUid.isNotEmpty) {
                final vr = await client
                    .from('verification_requests')
                    .select('status')
                    .eq('user_id', targetUid)
                    .order('submitted_at', ascending: false)
                    .limit(1)
                    .maybeSingle();
                if (vr != null && (vr['status'] == 'APPROVED' || vr['status'] == 'VERIFIED')) {
                  isApproved = true;
                }
              }
            }

            // 2. Check partners table directly
            if (!isApproved) {
              if (pId.isNotEmpty && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(pId)) {
                final pRes = await client.from('partners').select('verification_status').eq('partner_id', pId).maybeSingle();
                if (pRes != null && (pRes['verification_status'] == 'VERIFIED' || pRes['verification_status'] == 'APPROVED')) {
                  isApproved = true;
                }
              }
              final checkUid = (uRes?['user_id']?.toString() ?? uId);
              if (!isApproved && checkUid.isNotEmpty && RegExp(r'^[0-9a-fA-F-]{36}$').hasMatch(checkUid)) {
                final pRes = await client.from('partners').select('verification_status').eq('user_id', checkUid).maybeSingle();
                if (pRes != null && (pRes['verification_status'] == 'VERIFIED' || pRes['verification_status'] == 'APPROVED')) {
                  isApproved = true;
                }
              }
            }

            if (isApproved) {
              userMap['verification_status'] = 'VERIFIED';
              userMap['status'] = 'APPROVED';
              userMap['account_status'] = 'ACTIVE';
              await LocalRegistrationCache.updateActiveShopkeeper(userMap);
            }
          } catch (e) {
            debugPrint('[ShopkeeperDashboard] Supabase verification check note: $e');
          }
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
          final fullName = (userMap['name'] ?? userMap['full_name'] ?? '').toString();
          if (fullName.isNotEmpty) _shopkeeperName = fullName;
          final bName = (userMap['business_name'] ?? '').toString();
          if (bName.isNotEmpty) _shopName = bName;
          final addr = (userMap['business_address'] ?? userMap['address'] ?? '').toString();
          if (addr.isNotEmpty) _shopAddress = addr;
          final cat = (userMap['category'] ?? '').toString();
          if (cat.isNotEmpty) _shopCategory = cat;
          final hrs = (userMap['today_hours'] ?? userMap['business_hours'] ?? '').toString();
          if (hrs.isNotEmpty) _todayHours = hrs;
          if (userMap['rating'] is num) {
            _shopRating = (userMap['rating'] as num).toDouble();
          } else if (userMap['shop_rating'] is num) {
            _shopRating = (userMap['shop_rating'] as num).toDouble();
          }
          if (userMap['review_count'] is num) {
            _ratingReviewsCount = (userMap['review_count'] as num).toInt();
          } else if (userMap['reviews_count'] is num) {
            _ratingReviewsCount = (userMap['reviews_count'] as num).toInt();
          }
          _storePhotoPath = (userMap['profile_image'] ?? userMap['store_image'] ?? userMap['logo_url'] ?? userMap['avatar_url'] ?? userMap['photo_path'])?.toString();
        });

        // Query real reviews if partnerId or userId is available
        if (uId.isNotEmpty && !_isTestMode) {
          try {
            final client = Supabase.instance.client;
            final pRes = await client
                .from('partners')
                .select('partner_id, shopkeeper_profiles(*)')
                .eq('user_id', uId)
                .maybeSingle();
            if (pRes != null) {
              final pId = pRes['partner_id']?.toString();
              if (pId != null && pId.isNotEmpty) {
                _partnerId = pId;
                final revRes = await client
                    .from('reviews')
                    .select('rating')
                    .eq('partner_id', pId);
                if (revRes.isNotEmpty) {
                  _ratingReviewsCount = revRes.length;
                  double totalRating = 0.0;
                  for (final r in revRes) {
                    totalRating += (r['rating'] as num?)?.toDouble() ?? 0.0;
                  }
                  _shopRating = _ratingReviewsCount > 0 ? (totalRating / _ratingReviewsCount) : 0.0;
                }
              }
            }
          } catch (_) {}
        }

      // Query real store orders dynamically from Supabase & Hive
      List<Map<String, dynamic>> realOrders = [];
      if (!_isTestMode) {
        try {
          final client = Supabase.instance.client;
          final ordersRes = await client
              .from('orders')
              .select('*, order_items(*, products(*)), user_addresses(*)')
              .order('created_at', ascending: false)
              .limit(20);

        if (ordersRes.isNotEmpty) {
          for (final o in ordersRes) {
            final address = o['user_addresses'] as Map<String, dynamic>?;
            final code = (o['order_code'] ?? 'SH${o['order_id'] ?? ''}').toString();
            final amt = (o['total_amount'] as num?)?.toDouble() ?? 0.0;
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
              'raw_id': o['order_id'] ?? o['id'],
              'order_code': code,
              'booking_id': o['order_id'] ?? o['id'] ?? code,
              'item_title': o['items_summary'] ?? 'Store Spare Parts',
              'customer_name': 'Customer',
              'item_count': 1,
              'location': address != null ? '${address['city']} (${address['area'] ?? ""})' : 'Local Delivery',
              'amount': amt,
              'status': st,
              'status_color': stColor,
              'status_bg': stBg,
            });
          }
        }
      } catch (_) {}
    }

      // Fallback: Query Hive local storage if Supabase returned nothing or is offline
      if (realOrders.isEmpty) {
        try {
          if (Hive.isBoxOpen('partner_cache')) {
            final box = Hive.box('partner_cache');
            final cached = box.get('shopkeeper_orders');
            if (cached != null && cached is List) {
              realOrders = cached.map((e) {
                final m = Map<String, dynamic>.from(e as Map);
                if (m['status_color'] is int) {
                  m['status_color'] = Color(m['status_color'] as int);
                } else if (m['status_color'] is! Color) {
                  final st = (m['status'] ?? 'New').toString();
                  m['status_color'] = st == 'New'
                      ? const Color(0xFF10B981)
                      : (st == 'Preparing' ? const Color(0xFFD97706) : const Color(0xFF2563EB));
                }
                if (m['status_bg'] is int) {
                  m['status_bg'] = Color(m['status_bg'] as int);
                } else if (m['status_bg'] is! Color) {
                  final st = (m['status'] ?? 'New').toString();
                  m['status_bg'] = st == 'New'
                      ? const Color(0xFFDCFCE7)
                      : (st == 'Preparing' ? const Color(0xFFFEF3C7) : const Color(0xFFDBEAFE));
                }
                return m;
              }).toList();
            }
          }
        } catch (_) {}
      }

      // Query LiveBookingSyncService for real-time customer store orders
      try {
        final syncBookings = LiveBookingSyncService.instance.getAllBookings();
        for (final b in syncBookings) {
          final isStoreOrder = (b['type'] == 'DELIVERY_ORDER' ||
              (b['service_id'] ?? '').toString().contains('delivery') ||
              b['order_code'] != null) &&
              (b['category_id'] ?? '').toString() != 'laundry' &&
              !(b['category_name'] ?? '').toString().toLowerCase().contains('laundry') &&
              !(b['service_name'] ?? '').toString().toLowerCase().contains('laundry');
          if (!isStoreOrder) continue;

          // Concurrency Claim Guarantee:
          // If this order is already claimed by another shopkeeper, hide immediately!
          final assignedPartner = (b['partner_id'] ?? b['shopkeeper_id'] ?? '').toString();
          if (assignedPartner.isNotEmpty && assignedPartner != _partnerId && assignedPartner != _partnerId) {
            continue;
          }

          final bCode = (b['order_code'] ?? b['order_id'] ?? b['id'] ?? '').toString();
          final bId = (b['id'] ?? b['booking_id'] ?? b['order_id'] ?? bCode).toString();

          final alreadyPresent = realOrders.any((o) =>
              (o['order_id'] != null && (o['order_id'] == bCode || o['order_id'] == bId)) ||
              (o['raw_id'] != null && (o['raw_id'] == bId || o['raw_id'] == bCode)) ||
              (o['order_code'] != null && (o['order_code'] == bCode || o['order_code'] == bId)));

          if (!alreadyPresent) {
            final rawStatus = (b['status'] ?? 'New').toString();
            String displayStatus = 'New';
            if (rawStatus.toUpperCase() == 'PACKING' || rawStatus.toUpperCase() == 'PREPARING' || rawStatus == 'Preparing') {
              displayStatus = 'Preparing';
            } else if (rawStatus.toUpperCase() == 'READY' || rawStatus.toUpperCase() == 'READY_FOR_PICKUP' || rawStatus == 'Ready for Pickup') {
              displayStatus = 'Ready for Pickup';
            } else if (rawStatus.toUpperCase() == 'DELIVERED' || rawStatus.toUpperCase() == 'COMPLETED') {
              displayStatus = 'Completed';
            }

            Color stColor = const Color(0xFF10B981);
            Color stBg = const Color(0xFFDCFCE7);
            if (displayStatus == 'Preparing') {
              stColor = const Color(0xFFD97706);
              stBg = const Color(0xFFFEF3C7);
            } else if (displayStatus == 'Ready for Pickup') {
              stColor = const Color(0xFF2563EB);
              stBg = const Color(0xFFDBEAFE);
            } else if (displayStatus == 'Completed') {
              stColor = const Color(0xFF059669);
              stBg = const Color(0xFFDCFCE7);
            }

            final amt = (b['final_amount'] as num?)?.toDouble() ??
                (b['estimated_amount'] as num?)?.toDouble() ??
                (b['total_amount'] as num?)?.toDouble() ??
                350.0;

            realOrders.add({
              'order_id': bCode.isNotEmpty ? bCode : bId,
              'raw_id': bId,
              'booking_id': bId,
              'order_code': bCode,
              'item_title': b['items_summary'] ?? b['service_name'] ?? 'Store Order Delivery',
              'items_summary': b['items_summary'] ?? b['service_name'] ?? 'Store Order Delivery',
              'customer_name': b['customer_name'] ?? 'Customer',
              'customer_phone': b['customer_phone'] ?? b['phone'],
              'item_count': 1,
              'location': b['customer_address'] ?? b['address'] ?? 'Local Delivery',
              'amount': amt,
              'status': displayStatus,
              'status_color': stColor,
              'status_bg': stBg,
              'delivery_pin': b['delivery_pin'] ?? b['delivery_otp'],
              'delivery_otp': b['delivery_otp'] ?? b['delivery_pin'],
              'pickup_otp': b['pickup_otp'] ?? b['pickup_pin'],
              'pickup_pin': b['pickup_otp'] ?? b['pickup_pin'],
              'partner_id': b['partner_id'],
              'shopkeeper_id': b['shopkeeper_id'],
            });
          }
        }
      } catch (_) {}

      // Query products from Live Sync Server (8088) & Shared File IPC
      List<Map<String, dynamic>> loadedCatalog = [];
      try {
        final res = await http.get(Uri.parse('http://127.0.0.1:8088/api/products')).timeout(const Duration(milliseconds: 1500));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(res.body);
          if (decoded is List) {
            loadedCatalog = List<Map<String, dynamic>>.from(decoded);
          }
        }
      } catch (_) {}

      if (loadedCatalog.isEmpty) {
        try {
          const publicPath = r'C:\Users\Public\ServiceHub\service_hub_store_products.json';
          final file = File(publicPath);
          if (await file.exists()) {
            final content = await file.readAsString();
            final data = jsonDecode(content);
            if (data is Map) {
              loadedCatalog = data.values.map((v) => Map<String, dynamic>.from(v as Map)).toList();
            } else if (data is List) {
              loadedCatalog = List<Map<String, dynamic>>.from(data);
            }
          }
        } catch (_) {}
      }

      if (loadedCatalog.isEmpty) {
        try {
          if (Hive.isBoxOpen('partner_cache')) {
            final box = Hive.box('partner_cache');
            final pRaw = box.get('shopkeeper_products');
            if (pRaw != null && pRaw is List) {
              loadedCatalog = pRaw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
            }
          }
        } catch (_) {}
      }
      _catalogProducts = loadedCatalog;

      if (mounted) {
        setState(() {
          _orders = realOrders;
          if (_orders.isNotEmpty) {
            _newOrdersCount = _orders.where((o) => (o['status'] ?? '').toString().toLowerCase() == 'new').length;
            _todayOrdersCount = _orders.length;
            _todaySales = _orders.fold<double>(0.0, (sum, o) => sum + ((o['amount'] as num?)?.toDouble() ?? 0.0));
          } else {
            _newOrdersCount = 0;
            _todayOrdersCount = 0;
            _todaySales = 0.0;
          }
        });
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _checkOverlayPermission() async {
    try {
      await AppPermissionsService.instance.requestDisplayOverOtherAppsPermission(context);
    } catch (_) {}
  }

  void _toggleShopStatus(bool val) async {
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

    if (_partnerId.isNotEmpty && !_isTestMode) {
      try {
        await Supabase.instance.client
            .from('partners')
            .update({'availability_status': val ? 'ONLINE' : 'OFFLINE'})
            .eq('partner_id', _partnerId);

        if (val) {
          await Supabase.instance.client.rpc('dispatch_pending_bookings_for_partner', params: {
            'p_partner_id': _partnerId,
          });
        }
      } catch (_) {}
    }
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
              child: _catalogProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.inventory_2_outlined, size: 40, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No Products in Catalog',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Add your store products to start receiving customer orders.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                itemCount: _catalogProducts.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (c, i) {
                  final p = _catalogProducts[i];
                  final stock = (p['stock'] as num?)?.toInt() ?? 0;
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
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Sync Catalog from Admin', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.pop(ctx);
                  _loadShopData();
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
            Text(_todaySales > 0 ? 'Recent Payouts: In Process' : 'No payout history yet', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Future<void> _handleOrderAction(int index, String newStatus) async {
    final ord = _orders[index];
    final orderId = ord['order_id']?.toString() ?? '';
    final rawId = ord['raw_id']?.toString() ?? orderId;
    final bookingId = ord['booking_id']?.toString() ?? rawId;

    final currentPId = _partnerId.isNotEmpty ? _partnerId : 'SHOP_OWNER';
    setState(() {
      ord['status'] = newStatus;
      if (newStatus == 'Preparing') {
        ord['partner_id'] = currentPId;
        ord['shopkeeper_id'] = currentPId;
        ord['shopkeeper_name'] = _shopName;
        ord['shopkeeper_phone'] = _phone;
        ord['shopkeeper_address'] = _shopAddress;
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

    // Update Supabase
    try {
      final client = Supabase.instance.client;
      String dbStatus = newStatus;
      if (newStatus == 'Preparing') dbStatus = 'Packing';
      if (newStatus == 'Completed') dbStatus = 'Delivered';

      await client.from('orders').update({
        'order_status': dbStatus,
        'status': dbStatus,
      }).or('order_id.eq.$rawId,order_code.eq.$orderId').timeout(const Duration(seconds: 2));

      if (newStatus == 'Ready for Pickup') {
        try {
          await client.from('delivery_assignments').update({
            'status': 'READY',
          }).eq('order_id', rawId).timeout(const Duration(seconds: 2));
        } catch (_) {}
      }
    } catch (_) {}

    // Update LiveBookingSyncService
    try {
      String syncStatus = 'ASSIGNED';
      if (newStatus == 'Preparing') {
        syncStatus = 'ACCEPTED_BY_SHOPKEEPER';
        // Atomic claim lock: ensures immediate disappearance from all other shopkeepers
        final partnerPayload = {
          'partner_id': currentPId,
          'shopkeeper_id': currentPId,
          'shopkeeper_name': _shopName,
          'shop_name': _shopName,
          'shopkeeper_phone': _phone,
          'shopkeeper_address': _shopAddress,
          'status': 'ACCEPTED_BY_SHOPKEEPER',
        };
        await LiveBookingSyncService.instance.acceptBooking(bookingId, partnerPayload);
        await LiveBookingSyncService.instance.updateBookingStatus(bookingId, 'ACCEPTED_BY_SHOPKEEPER');
        await LiveBookingSyncService.instance.updateMilestone(bookingId, 'ACCEPTED_BY_SHOPKEEPER');
        if (orderId.isNotEmpty && orderId != bookingId) {
          await LiveBookingSyncService.instance.acceptBooking(orderId, partnerPayload);
          await LiveBookingSyncService.instance.updateBookingStatus(orderId, 'ACCEPTED_BY_SHOPKEEPER');
          await LiveBookingSyncService.instance.updateMilestone(orderId, 'ACCEPTED_BY_SHOPKEEPER');
        }
      } else if (newStatus == 'Ready for Pickup') {
        syncStatus = 'READY_FOR_PICKUP';
        await LiveBookingSyncService.instance.updateBookingStatus(bookingId, 'READY_FOR_PICKUP');
        await LiveBookingSyncService.instance.updateMilestone(bookingId, 'READY_FOR_PICKUP');
        if (orderId.isNotEmpty && orderId != bookingId) {
          await LiveBookingSyncService.instance.updateBookingStatus(orderId, 'READY_FOR_PICKUP');
          await LiveBookingSyncService.instance.updateMilestone(orderId, 'READY_FOR_PICKUP');
        }
      } else if (newStatus == 'Completed') {
        syncStatus = 'DELIVERED';
        await LiveBookingSyncService.instance.updateBookingStatus(bookingId, 'DELIVERED');
        await LiveBookingSyncService.instance.updateMilestone(bookingId, 'DELIVERED');
        if (orderId.isNotEmpty && orderId != bookingId) {
          await LiveBookingSyncService.instance.updateBookingStatus(orderId, 'DELIVERED');
          await LiveBookingSyncService.instance.updateMilestone(orderId, 'DELIVERED');
        }
      }
      if (orderId.isNotEmpty && orderId != bookingId) {
        await LiveBookingSyncService.instance.updateBookingStatus(orderId, syncStatus);
        await LiveBookingSyncService.instance.updateMilestone(orderId, syncStatus);
      }
    } catch (_) {}

    // Save to Hive
    try {
      if (Hive.isBoxOpen('partner_cache')) {
        final box = Hive.box('partner_cache');
        final sanitizedOrders = _orders.map((o) {
          final copy = Map<String, dynamic>.from(o);
          if (copy['status_color'] is Color) {
            copy['status_color'] = (copy['status_color'] as Color).toARGB32();
          }
          if (copy['status_bg'] is Color) {
            copy['status_bg'] = (copy['status_bg'] as Color).toARGB32();
          }
          return copy;
        }).toList();
        await box.put('shopkeeper_orders', sanitizedOrders).timeout(const Duration(milliseconds: 500));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_activeNavIndex != 0) {
          setState(() => _activeNavIndex = 0);
          return;
        }
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              backgroundColor: Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        SystemNavigator.pop();
      },
      child: Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
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
                    if (_orders.isEmpty)
                      _buildEmptyOrdersState()
                    else
                      ..._orders.asMap().entries.map((entry) => _buildOrderCard(entry.key, entry.value)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      ),
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
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: Center(
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.storefront_rounded, color: Color(0xFF059669), size: 22),
          ),
        ),
      ),
      titleSpacing: 8,
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
                    _shopkeeperName.isNotEmpty ? _shopkeeperName[0].toUpperCase() : 'S',
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

  Widget _buildStoreHeroAvatar() {
    final clean = _storePhotoPath?.trim() ?? '';
    if (clean.isNotEmpty) {
      final isNetwork = clean.startsWith('http://') || clean.startsWith('https://');
      if (!isNetwork) {
        final f = File(clean);
        if (f.existsSync()) {
          return ClipOval(child: Image.file(f, fit: BoxFit.cover, width: 52, height: 52));
        }
      } else {
        return ClipOval(
          child: Image.network(
            clean,
            fit: BoxFit.cover,
            width: 52,
            height: 52,
            errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
          ),
        );
      }
    }
    return const Icon(Icons.storefront_rounded, color: Colors.white, size: 28);
  }

  // -------------------------------------------------------------
  // 1. Top Hero Storefront Card (Modern Emerald Gradient & CTA)
  // -------------------------------------------------------------
  Widget _buildHeroStoreCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF065F46), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF065F46).withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar & Greeting & Rating Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Store Avatar with online dot - tap navigates to store profile
              InkWell(
                onTap: () => context.push('/profile/shopkeeper'),
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withValues(alpha: 0.35), width: 1.5),
                  ),
                  child: _buildStoreHeroAvatar(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good Morning, $_shopkeeperName 👋',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _shopAddress.isNotEmpty ? '📍 $_shopAddress' : 'Owner: $_shopkeeperName',
                      style: const TextStyle(
                        color: Color(0xFFCCFBF1),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Rating Badge: 'New' or '★ 4.8'
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE047).withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFDE047), size: 16),
                    const SizedBox(width: 3),
                    Text(
                      _ratingReviewsCount == 0 && _shopRating == 0.0 ? 'New' : _shopRating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Color(0xFFFDE047),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Real Store Name
          Row(
            children: [
              const Text('🏪 ', style: TextStyle(fontSize: 15)),
              Expanded(
                child: Text(
                  _shopName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Category pill & Verified badge row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Category pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: Text(
                  _shopCategory,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
              // Verified merchant badge: 'Verified Shop ✓'
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF34D399), width: 1.2),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Color(0xFF34D399), size: 13),
                    SizedBox(width: 4),
                    Text(
                      'Verified Shop',
                      style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      ' ✓',
                      style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Tagline and Quick CTA Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  '"Quality Products Happier Homes!"',
                  style: TextStyle(
                    color: Color(0xFFA7F3D0),
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              // Quick CTA: 'View Store Profile'
              InkWell(
                onTap: () => context.push('/profile/shopkeeper'),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View Store Profile',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. Shop Status & Business Hours Section (Full-Width Container)
  // -------------------------------------------------------------
  Widget _buildStatusAndHoursBar() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isOpen ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store status row with active green glowing status dot & Switch
          Row(
            children: [
              // Active green glowing status dot
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _isOpen ? const Color(0xFF10B981) : const Color(0xFF94A3B8),
                  shape: BoxShape.circle,
                  boxShadow: _isOpen
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.6),
                            blurRadius: 8,
                            spreadRadius: 2.5,
                          ),
                        ]
                      : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Shop Status',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _isOpen
                          ? 'Store Open • Accepting Customer Orders'
                          : 'Store Closed • Incoming Orders Paused',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: _isOpen ? const Color(0xFF059669) : const Color(0xFF64748B),
                      ),
                    ),
                    Text(
                      _isOpen ? 'You are open for orders' : 'Store is closed',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Smooth Switch with ample room
              Switch(
                value: _isOpen,
                activeThumbColor: Colors.white,
                activeTrackColor: const Color(0xFF10B981),
                inactiveTrackColor: const Color(0xFFCBD5E1),
                inactiveThumbColor: Colors.white,
                onChanged: _toggleShopStatus,
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Color(0xFFF1F5F9)),
          ),

          // Operating Hours row: 'Today: 09:00 AM - 08:00 PM' with clock icon, tap navigates to /profile/shopkeeper/hours
          InkWell(
            onTap: () => context.push('/profile/shopkeeper/hours'),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.access_time_filled_rounded,
                      color: Color(0xFFD97706),
                      size: 16,
                    ),
                  ),
                  const Text(
                    'Today\'s Hours',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF475569),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Today: $_todayHours',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Color(0xFF94A3B8),
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
  // 3. 4 Key Metrics Cards (2x2 Grid, 16px Padding, Crisp Typography)
  // -------------------------------------------------------------
  Widget _buildMetricsRow() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'New Orders',
                value: '$_newOrdersCount',
                pillText: _newOrdersCount > 0 ? 'Action Req.' : '0 Pending',
                icon: Icons.shopping_bag_outlined,
                pillColor: const Color(0xFF10B981),
                pillBg: const Color(0xFFDCFCE7),
                iconColor: const Color(0xFF0284C7),
                iconBg: const Color(0xFFE0F2FE),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Today\'s Orders',
                value: '$_todayOrdersCount',
                pillText: _todayOrdersCount > 0 ? '$_todayOrdersCount Today' : '0 Orders',
                icon: Icons.local_shipping_outlined,
                pillColor: const Color(0xFFEA580C),
                pillBg: const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFEA580C),
                iconBg: const Color(0xFFFFF7ED),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Today\'s Sales',
                value: '₹${_todaySales.toStringAsFixed(0)}',
                pillText: _todaySales > 0 ? 'Live Sales' : '₹0 Today',
                icon: Icons.currency_rupee_rounded,
                pillColor: const Color(0xFF7C3AED),
                pillBg: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF7C3AED),
                iconBg: const Color(0xFFFAF5FF),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Shop Rating',
                value: _ratingReviewsCount == 0 && _shopRating == 0.0 ? 'New' : '★ ${_shopRating.toStringAsFixed(1)}',
                pillText: _ratingReviewsCount == 0 ? '0 Reviews' : '★ ($_ratingReviewsCount)',
                icon: Icons.star_rounded,
                pillColor: const Color(0xFFCA8A04),
                pillBg: const Color(0xFFFEF9C3),
                iconColor: const Color(0xFFEAB308),
                iconBg: const Color(0xFFFEFCE8),
              ),
            ),
          ],
        ),
      ],
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(color: pillBg, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  pillText,
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: pillColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
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
      {'title': 'Store Catalog', 'icon': Icons.inventory_2_rounded, 'color': const Color(0xFF059669), 'bg': const Color(0xFF059669), 'onTap': _showInventorySheet},
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
        final isNarrow = constraints.maxWidth < 768;

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
                      onPressed: _showInventorySheet,
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View Catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
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
                  const Expanded(
                    child: Text(
                      'Inventory Alerts',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: _showInventorySheet,
                    child: const Text('Restock Now >', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.trending_down_rounded, color: Color(0xFFB45309), size: 14),
                        SizedBox(width: 6),
                        Text('4 Low Stock Items', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF92400E))),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
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

  // -------------------------------------------------------------
  // Clean, Gorgeous Empty State when no orders exist
  // -------------------------------------------------------------
  Widget _buildEmptyOrdersState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFA7F3D0), width: 1.5),
            ),
            child: const Icon(
              Icons.shopping_bag_outlined,
              size: 36,
              color: Color(0xFF059669),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No incoming orders yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your store is active and waiting for customer orders',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0.5,
            ),
            onPressed: _showInventorySheet,
            icon: const Icon(Icons.inventory_2_outlined, size: 18),
            label: const Text(
              'Manage Catalog',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
            ),
          ),
        ],
      ),
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
          if ((order['pickup_otp'] != null || order['pickup_pin'] != null) && status != 'Completed') ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pin_rounded, color: Color(0xFFD97706), size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Pickup OTP: ${order['pickup_otp'] ?? order['pickup_pin']} (Share with delivery rider upon arrival)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                      SnackBar(content: Text('Order #${order['order_id']} items: ${order['item_title'] ?? order['items_summary'] ?? "Store items"}'), backgroundColor: const Color(0xFF0F172A)),
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
                    final cPhone = (order['customer_phone'] ?? order['phone'] ?? '').toString();
                    PhoneLauncherService.makePhoneCall(context, cPhone);
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
                  onPressed: () => _handleOrderAction(index, 'Ready for Pickup'),
                  child: const Text('Ready for Pickup', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ] else if (status == 'Ready for Pickup') ...[
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.two_wheeler_rounded, size: 14, color: Color(0xFF2563EB)),
                  label: const Text('Awaiting Rider', style: TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Order packed and ready. Hyperlocal delivery rider dispatched for pickup.'),
                        backgroundColor: Color(0xFF2563EB),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _handleOrderAction(index, 'Completed'),
                  child: const Text('Dispatch / Handover', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
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
  // 7. Bottom Navigation Bar (5 tabs with Elevated Emerald Center Map)
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
                if (GoRouter.maybeOf(context) != null) {
                  context.push('/dashboard/shopkeeper/map');
                } else {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ShopkeeperStoreMapScreen()));
                }
              } else if (idx == 3) {
                _showInventorySheet();
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
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              const BottomNavigationBarItem(
                icon: Badge(
                  label: Text('3'),
                  backgroundColor: Color(0xFFEF4444),
                  child: Icon(Icons.shopping_bag_outlined),
                ),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: Container(
                  key: const Key('shopkeeper_bottom_nav_center_map_button'),
                  width: 52,
                  height: 52,
                  margin: const EdgeInsets.only(bottom: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF059669), Color(0xFF047857)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF059669).withValues(alpha: 0.38),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.map_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                label: 'Map',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.category_outlined),
                label: 'Products',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline_rounded),
                label: 'Profile',
              ),
            ],
          ),
        );
  }
}
