import 'package:flutter/material.dart';
import '../../../../core/storage/local_registration_cache.dart';

/// Screen 9: Subpage 3 - Services & Pricing for Car Service Provider
class CarServicePricingScreen extends StatefulWidget {
  const CarServicePricingScreen({super.key});

  @override
  State<CarServicePricingScreen> createState() => _CarServicePricingScreenState();
}

class _CarServicePricingScreenState extends State<CarServicePricingScreen> {
  bool _masterServiceAvailable = true;
  bool _isSaving = false;

  // Car Service Catalog Items matching reference design
  final List<Map<String, dynamic>> _serviceCatalog = [
    {
      'title': 'Periodic Standard Service',
      'price': 1499,
      'icon': Icons.car_repair_rounded,
      'enabled': true,
    },
    {
      'title': 'Comprehensive Service',
      'price': 2499,
      'icon': Icons.precision_manufacturing_rounded,
      'enabled': true,
    },
    {
      'title': 'AC Service & Gas Refill',
      'price': 1199,
      'icon': Icons.ac_unit_rounded,
      'enabled': true,
    },
    {
      'title': 'Full Foam Wash & Detailing',
      'price': 899,
      'icon': Icons.local_car_wash_rounded,
      'enabled': true,
    },
    {
      'title': 'Wheel Alignment & Balancing',
      'price': 599,
      'icon': Icons.tire_repair_rounded,
      'enabled': true,
    },
    {
      'title': '360° Safety Inspection',
      'price': 499,
      'icon': Icons.security_rounded,
      'enabled': true,
    },
  ];

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadPricingConfig();
  }

  Future<void> _loadPricingConfig() async {
    final cached = await LocalRegistrationCache.getActiveServiceProvider() ??
        await LocalRegistrationCache.getActivePartner();
    if (mounted && cached != null) {
      setState(() {
        _masterServiceAvailable = cached['is_online'] ?? true;
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      await LocalRegistrationCache.updateActiveServiceProvider({
        'car_services_pricing': _serviceCatalog,
        'master_service_available': _masterServiceAvailable,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Car service packages & pricing updated!'),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notice: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddServiceDialog() {
    final titleController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: primaryBlue, size: 22),
            SizedBox(width: 8),
            Text('Add Custom Service', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                labelText: 'Service Name',
                hintText: 'e.g. Engine Oil Flush',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Price (₹)',
                hintText: 'e.g. 799',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final title = titleController.text.trim();
              final price = int.tryParse(priceController.text.trim()) ?? 0;
              if (title.isNotEmpty && price > 0) {
                setState(() {
                  _serviceCatalog.add({
                    'title': title,
                    'price': price,
                    'icon': Icons.build_rounded,
                    'enabled': true,
                  });
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add Service'),
          ),
        ],
      ),
    );
  }

  void _editPriceDialog(int index) {
    final priceController = TextEditingController(text: _serviceCatalog[index]['price'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        title: Text('Edit Price: ${_serviceCatalog[index]['title']}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: priceController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'New Price (₹)',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final newPrice = int.tryParse(priceController.text.trim());
              if (newPrice != null && newPrice > 0) {
                setState(() {
                  _serviceCatalog[index]['price'] = newPrice;
                });
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Services & Pricing',
          style: TextStyle(
            color: darkSlate,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Master Service Availability Card
            Material(
              color: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                side: BorderSide(color: cardBorder),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.directions_car_rounded, color: Color(0xFF10B981), size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Car Service',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: darkSlate,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Enable or disable car service availability',
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _masterServiceAvailable,
                      activeThumbColor: primaryBlue,
                      onChanged: (val) {
                        setState(() => _masterServiceAvailable = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 2. Service Packages & Prices Header
            const Text(
              'Service Packages & Prices',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: darkSlate,
              ),
            ),
            const SizedBox(height: 12),

            // 3. Service Packages List
            Material(
              color: Colors.white,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
                side: BorderSide(color: cardBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _serviceCatalog.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: cardBorder),
                itemBuilder: (context, index) {
                  final item = _serviceCatalog[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item['icon'] as IconData, color: primaryBlue, size: 20),
                    ),
                    title: Text(
                      item['title'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _editPriceDialog(index),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '₹ ${item['price']}',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue),
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.edit_outlined, size: 14, color: textMuted),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            // 4. "+ Add New Service" Outlined Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.add_rounded, color: primaryBlue, size: 20),
                label: const Text(
                  '+ Add New Service',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryBlue),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryBlue),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _showAddServiceDialog,
              ),
            ),
            const SizedBox(height: 28),

            // 5. Save Changes Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _saveChanges,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
