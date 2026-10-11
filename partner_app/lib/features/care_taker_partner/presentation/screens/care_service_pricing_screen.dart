import 'package:flutter/material.dart';

/// Screen 9: Dedicated Care Services & Pricing Sub-Screen for Care Taker Specialist
class CareServicePricingScreen extends StatefulWidget {
  const CareServicePricingScreen({super.key});

  @override
  State<CareServicePricingScreen> createState() => _CareServicePricingScreenState();
}

class _CareServicePricingScreenState extends State<CareServicePricingScreen> {
  bool _masterServiceAvailable = true;

  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  // Care Catalog matching reference UI
  final List<Map<String, dynamic>> _carePackages = [
    {
      'title': 'Elderly Companion',
      'price': 699,
      'icon': Icons.volunteer_activism_rounded,
      'enabled': true,
      'desc': 'Daily routine assistance, mobility help & companionship',
    },
    {
      'title': 'Post-Surgery Care',
      'price': 999,
      'icon': Icons.healing_rounded,
      'enabled': true,
      'desc': 'Wound dressing, vitals monitoring & recovery assistance',
    },
    {
      'title': 'Bedridden Patient Care',
      'price': 899,
      'icon': Icons.airline_seat_flat_rounded,
      'enabled': true,
      'desc': 'Complete hygiene, turning, sponge bath & feeding support',
    },
    {
      'title': 'Infant & Babysitting Care',
      'price': 499,
      'icon': Icons.child_care_rounded,
      'enabled': true,
      'desc': 'Newborn care, babysitting & play companionship',
    },
    {
      'title': 'Special Needs Care',
      'price': 649,
      'icon': Icons.accessible_rounded,
      'enabled': true,
      'desc': 'Autism, mobility impairment & specialized support',
    },
    {
      'title': 'Medical Assistance',
      'price': 799,
      'icon': Icons.local_hospital_rounded,
      'enabled': true,
      'desc': 'Injection administration, IV drip monitoring & medicine charting',
    },
  ];

  void _showEditPriceModal(int index) {
    final item = _carePackages[index];
    final controller = TextEditingController(text: item['price'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Price: ${item['title']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter customized package rate in INR (₹):', style: TextStyle(fontSize: 13, color: textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              final newPrice = int.tryParse(controller.text.trim());
              if (newPrice != null && newPrice > 0) {
                setState(() => _carePackages[index]['price'] = newPrice);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddCareTypeModal() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add New Care Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Care Type Title', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
            const SizedBox(height: 6),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                hintText: 'e.g. Dementia & Memory Support',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Starting Price (₹)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
            const SizedBox(height: 6),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'e.g. 749',
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty && priceCtrl.text.trim().isNotEmpty) {
                final price = int.tryParse(priceCtrl.text.trim()) ?? 699;
                setState(() {
                  _carePackages.add({
                    'title': nameCtrl.text.trim(),
                    'price': price,
                    'icon': Icons.health_and_safety_rounded,
                    'enabled': true,
                    'desc': 'Custom home care service package',
                  });
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Package'),
          ),
        ],
      ),
    );
  }

  void _savePricing() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Care services & pricing saved successfully!'),
        backgroundColor: primaryIndigo,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Care Services & Pricing',
          style: TextStyle(color: darkSlate, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master Availability Banner matching reference UI
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.volunteer_activism_rounded, color: Color(0xFF10B981), size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Care Taker & Nursing Service',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkSlate),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Enable or disable your service availability',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _masterServiceAvailable,
                    activeThumbColor: primaryIndigo,
                    onChanged: (val) => setState(() => _masterServiceAvailable = val),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Section Header
            const Text(
              'Care Types and Prices',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: darkSlate),
            ),
            const SizedBox(height: 12),

            // Care packages catalog list
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _carePackages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _carePackages[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryIndigo.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item['icon'] as IconData, color: primaryIndigo, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'].toString(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['desc'].toString(),
                              style: const TextStyle(fontSize: 11, color: textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () => _showEditPriceModal(index),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: cardBorder),
                          ),
                          child: Row(
                            children: [
                              Text(
                                '₹ ${item['price']}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate),
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

            const SizedBox(height: 16),

            // Add New Care Type Button
            Center(
              child: TextButton.icon(
                icon: const Icon(Icons.add_circle_outline_rounded, color: primaryIndigo, size: 18),
                label: const Text('+ Add New Care Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryIndigo)),
                onPressed: _showAddCareTypeModal,
              ),
            ),

            const SizedBox(height: 24),

            // Save Changes Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryIndigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _savePricing,
                child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
