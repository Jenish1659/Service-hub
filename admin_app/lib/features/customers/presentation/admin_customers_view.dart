import 'package:flutter/material.dart';

class AdminCustomersView extends StatefulWidget {
  final int customerCount;
  const AdminCustomersView({super.key, this.customerCount = 0});

  @override
  State<AdminCustomersView> createState() => _AdminCustomersViewState();
}

class _AdminCustomersViewState extends State<AdminCustomersView> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _activeFilterIndex = 0; // 0: All, 1: Active, 2: Suspended/Blocked

  final List<Map<String, dynamic>> _customers = [
    {
      'id': 'cust_101',
      'name': 'Meera Trivedi',
      'phone': '+91 98980 11223',
      'email': 'meera.trivedi@gmail.com',
      'city': 'Jamnagar (Patel Colony)',
      'total_bookings': 4,
      'total_spent': 2490.0,
      'coins': 480,
      'is_active': true,
      'joined_date': '12 Aug 2026',
    },
    {
      'id': 'cust_102',
      'name': 'Hardik Bhatt',
      'phone': '+91 98790 44332',
      'email': 'hardik.bhatt@yahoo.com',
      'city': 'Jamnagar (Digvijay Plot)',
      'total_bookings': 2,
      'total_spent': 998.0,
      'coins': 300,
      'is_active': true,
      'joined_date': '18 Aug 2026',
    },
    {
      'id': 'cust_103',
      'name': 'Pooja Vaghela',
      'phone': '+91 97241 88990',
      'email': 'pooja.v@outlook.com',
      'city': 'Jamnagar (Ranjit Nagar)',
      'total_bookings': 6,
      'total_spent': 3780.0,
      'coins': 620,
      'is_active': true,
      'joined_date': '02 Jul 2026',
    },
    {
      'id': 'cust_104',
      'name': 'Sanjay Mehta',
      'phone': '+91 99099 22114',
      'email': 'sanjay.mehta@gmail.com',
      'city': 'Jamnagar (Khodiyar Colony)',
      'total_bookings': 1,
      'total_spent': 499.0,
      'coins': 300,
      'is_active': false,
      'joined_date': '28 Aug 2026',
    },
  ];

  void _showCustomerDetailsModal(Map<String, dynamic> customer) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 550,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFEFF6FF),
                    child: Text(
                      customer['name'][0],
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 20),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(customer['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text('${customer['phone']} • ${customer['email']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 20),
              const Divider(color: Color(0xFFE2E8F0)),
              const SizedBox(height: 14),

              // KPI Row
              Row(
                children: [
                  _buildCustomerStatBox('Total Bookings', '${customer['total_bookings']}', Icons.calendar_month_rounded, const Color(0xFF2563EB)),
                  const SizedBox(width: 10),
                  _buildCustomerStatBox('Total Spent', '₹${customer['total_spent']}', Icons.payments_rounded, const Color(0xFF059669)),
                  const SizedBox(width: 10),
                  _buildCustomerStatBox('ServiceCoins', '${customer['coins']}', Icons.monetization_on_rounded, const Color(0xFFD97706)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Location: ${customer['city']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
              const SizedBox(height: 6),
              Text('Member Since: ${customer['joined_date']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: customer['is_active'] ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      side: BorderSide(color: customer['is_active'] ? const Color(0xFFFCA5A5) : const Color(0xFF6EE7B7)),
                    ),
                    icon: Icon(customer['is_active'] ? Icons.block_rounded : Icons.check_circle_rounded, size: 16),
                    label: Text(customer['is_active'] ? 'Suspend Customer' : 'Reactivate Account'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        customer['is_active'] = !customer['is_active'];
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Customer ${customer['name']} status updated!')),
                      );
                    },
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                    icon: const Icon(Icons.send_rounded, size: 16),
                    label: const Text('Send Notification'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Push notification sent to ${customer['name']}')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerStatBox(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _customers.where((c) {
      if (_activeFilterIndex == 1 && !c['is_active']) return false;
      if (_activeFilterIndex == 2 && c['is_active']) return false;
      if (_searchQuery.isEmpty) return true;
      final name = (c['name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString().toLowerCase();
      final email = (c['email'] ?? '').toString().toLowerCase();
      return name.contains(_searchQuery) || phone.contains(_searchQuery) || email.contains(_searchQuery);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Customer Relationship Management (CRM)', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 3),
                  Text('Directory of verified customer profiles, booking history, wallet points, and communications', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBFDBFE))),
                child: Text('Total Customers: ${_customers.length}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF))),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Search and Filters
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(10)),
                child: Row(
                  children: [
                    _buildFilterPill(0, 'All (${_customers.length})'),
                    _buildFilterPill(1, 'Active (${_customers.where((c) => c['is_active']).length})'),
                    _buildFilterPill(2, 'Suspended (${_customers.where((c) => !c['is_active']).length})'),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 320,
                height: 40,
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                  decoration: InputDecoration(
                    hintText: 'Search customer name or phone...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.zero,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (ctx, idx) {
                  final c = filtered[idx];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: Text(c['name'][0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                    ),
                    title: Row(
                      children: [
                        Text(c['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: c['is_active'] ? const Color(0xFFECFDF5) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            c['is_active'] ? 'Active' : 'Suspended',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: c['is_active'] ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text('${c['phone']} • ${c['email']} • ${c['city']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹${c['total_spent']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A))),
                            Text('${c['total_bookings']} Bookings', style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
                      ],
                    ),
                    onTap: () => _showCustomerDetailsModal(c),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(int index, String label) {
    final isSelected = _activeFilterIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeFilterIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected ? [const BoxShadow(color: Colors.black12, blurRadius: 4)] : null,
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF64748B)),
        ),
      ),
    );
  }
}
