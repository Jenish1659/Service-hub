import 'package:flutter/material.dart';
import '../../data/customer_profile_service.dart';
import 'customer_add_payment_method_screen.dart';

class CustomerPaymentMethodsScreen extends StatefulWidget {
  const CustomerPaymentMethodsScreen({super.key});

  @override
  State<CustomerPaymentMethodsScreen> createState() => _CustomerPaymentMethodsScreenState();
}

class _CustomerPaymentMethodsScreenState extends State<CustomerPaymentMethodsScreen> {
  late List<Map<String, dynamic>> _methods;

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color verifiedGreen = Color(0xFF10B981);
  static const Color verifiedBg = Color(0xFFECFDF5);

  @override
  void initState() {
    super.initState();
    _loadMethods();
  }

  void _loadMethods() {
    setState(() {
      _methods = CustomerProfileService.instance.getPaymentMethods();
    });
  }

  Future<void> _openAddMethod() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CustomerAddPaymentMethodScreen()),
    );
    if (result == true) {
      _loadMethods();
    }
  }

  Future<void> _removeMethod(String id, String title) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Remove $title?'),
        content: const Text('Are you sure you want to remove this payment method?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CustomerProfileService.instance.removePaymentMethod(id);
      _loadMethods();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $title removed successfully'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _setDefault(String id) async {
    final list = _methods;
    for (final m in list) {
      m['is_default'] = (m['id'] == id);
      await CustomerProfileService.instance.savePaymentMethod(m);
    }
    _loadMethods();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Default payment method updated'),
          backgroundColor: verifiedGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: darkSlate),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Payment Methods',
          style: TextStyle(color: darkSlate, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _openAddMethod,
            child: const Text(
              '+ Add New',
              style: TextStyle(color: primaryBlue, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _methods.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.credit_card_off_rounded, color: primaryBlue, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('No Saved Payment Methods', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkSlate)),
                  const SizedBox(height: 6),
                  const Text('Add UPI or card for instant checkout', style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _openAddMethod,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Payment Method'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _methods.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = _methods[index];
                final isDefault = item['is_default'] == true;
                final type = (item['type'] ?? 'UPI').toString().toUpperCase();

                Widget iconWidget;
                if (type == 'UPI') {
                  iconWidget = Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'UPI',
                        style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  );
                } else if (item['title'] == 'HDFC Bank') {
                  iconWidget = Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.account_balance_rounded, color: Color(0xFF1E40AF), size: 22),
                    ),
                  );
                } else if (item['title'] == 'SBI Bank') {
                  iconWidget = Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.account_balance_rounded, color: Color(0xFF15803D), size: 22),
                    ),
                  );
                } else {
                  iconWidget = Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.credit_card_rounded, color: primaryBlue, size: 22),
                    ),
                  );
                }

                return GestureDetector(
                  onTap: () => _setDefault(item['id']),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDefault ? primaryBlue.withValues(alpha: 0.3) : borderGrey,
                        width: isDefault ? 1.5 : 1,
                      ),
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
                        iconWidget,
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['title'] ?? 'Payment',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: darkSlate,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item['detail'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: verifiedBg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'Default',
                              style: TextStyle(
                                color: verifiedGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: () => _removeMethod(item['id'], item['title'] ?? 'Method'),
                            child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
