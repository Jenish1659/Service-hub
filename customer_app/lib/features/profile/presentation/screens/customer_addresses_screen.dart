import 'package:flutter/material.dart';
import '../../data/customer_profile_service.dart';
import 'customer_add_address_screen.dart';

class CustomerAddressesScreen extends StatefulWidget {
  const CustomerAddressesScreen({super.key});

  @override
  State<CustomerAddressesScreen> createState() => _CustomerAddressesScreenState();
}

class _CustomerAddressesScreenState extends State<CustomerAddressesScreen> {
  late List<Map<String, dynamic>> _addresses;

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);
  static const Color verifiedGreen = Color(0xFF10B981);
  static const Color verifiedBg = Color(0xFFECFDF5);

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  void _loadAddresses() {
    setState(() {
      _addresses = CustomerProfileService.instance.getAddresses();
    });
  }

  Future<void> _openAddAddress([Map<String, dynamic>? existing]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomerAddAddressScreen(existingAddress: existing),
      ),
    );
    if (result == true) {
      _loadAddresses();
    }
  }

  Future<void> _deleteAddress(String id, String label) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete $label?'),
        content: const Text('Are you sure you want to remove this address?'),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CustomerProfileService.instance.deleteAddress(id);
      _loadAddresses();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ $label removed successfully'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _setDefault(String id) async {
    await CustomerProfileService.instance.setDefaultAddress(id);
    _loadAddresses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Set as default address'),
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
          'Addresses',
          style: TextStyle(color: darkSlate, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => _openAddAddress(),
            child: const Text(
              '+ Add New',
              style: TextStyle(color: primaryBlue, fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: _addresses.isEmpty
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
                    child: const Icon(Icons.location_off_rounded, color: primaryBlue, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text('No Saved Addresses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkSlate)),
                  const SizedBox(height: 6),
                  const Text('Add your home or office address for quicker booking', style: TextStyle(color: textMuted, fontSize: 13)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _openAddAddress(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Address'),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              itemCount: _addresses.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final addr = _addresses[index];
                final isDefault = addr['is_default'] == true;
                final type = (addr['type'] ?? 'Home').toString().toLowerCase();

                // Distinct colors matching design
                Color iconBg = const Color(0xFFEFF6FF);
                Color iconColor = primaryBlue;
                IconData iconData = Icons.home_rounded;

                if (type.contains('office') || type.contains('work')) {
                  iconBg = const Color(0xFFFAF5FF);
                  iconColor = const Color(0xFF9333EA);
                  iconData = Icons.apartment_rounded;
                } else if (type.contains('parent') || type.contains('other')) {
                  iconBg = const Color(0xFFFFF1F2);
                  iconColor = const Color(0xFFE11D48);
                  iconData = Icons.favorite_rounded;
                }

                return GestureDetector(
                  onTap: () => _setDefault(addr['id']),
                  child: Container(
                    padding: const EdgeInsets.all(16),
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon Container
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(iconData, color: iconColor, size: 22),
                        ),
                        const SizedBox(width: 14),

                        // Address Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    addr['label'] ?? 'Address',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: darkSlate,
                                    ),
                                  ),
                                  if (isDefault) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: verifiedBg,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Default',
                                        style: TextStyle(
                                          color: verifiedGreen,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                addr['full_address'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: textMuted,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Action Icons: Edit & Delete
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              icon: const Icon(Icons.edit_outlined, size: 18, color: textMuted),
                              onPressed: () => _openAddAddress(addr),
                            ),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(6),
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFEF4444)),
                              onPressed: () => _deleteAddress(addr['id'], addr['label'] ?? 'Address'),
                            ),
                          ],
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
