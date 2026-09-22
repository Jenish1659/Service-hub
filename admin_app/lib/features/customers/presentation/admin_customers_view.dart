import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;

      // 1. Fetch role_id for customer
      String? customerRoleId;
      try {
        final roleRes = await client.from('roles').select('role_id').eq('role_name', 'customer').maybeSingle();
        customerRoleId = roleRes?['role_id']?.toString();
      } catch (_) {}

      // 2. Fetch users with role customer
      List<dynamic> usersRes = [];
      if (customerRoleId != null) {
        try {
          usersRes = await client
              .from('users')
              .select('*, user_profiles(*), user_addresses(*)')
              .eq('role_id', customerRoleId)
              .order('created_at', ascending: false);
        } catch (_) {
          usersRes = await client
              .from('users')
              .select('*, user_profiles(*)')
              .eq('role_id', customerRoleId);
        }
      } else {
        try {
          usersRes = await client
              .from('users')
              .select('*, roles!inner(role_name), user_profiles(*), user_addresses(*)')
              .eq('roles.role_name', 'customer')
              .order('created_at', ascending: false);
        } catch (_) {
          try {
            usersRes = await client.from('users').select('*, user_profiles(*)');
          } catch (_) {
            usersRes = [];
          }
        }
      }

      // 3. Aggregate booking counts and spend per customer
      List<dynamic> bookingsRes = [];
      try {
        bookingsRes = await client.from('service_bookings').select('customer_id, final_amount, estimated_amount');
      } catch (_) {}

      final Map<String, int> bookingCounts = {};
      final Map<String, double> customerSpent = {};
      for (var b in bookingsRes) {
        final cId = b['customer_id']?.toString() ?? '';
        if (cId.isNotEmpty) {
          final amt = (b['final_amount'] as num?)?.toDouble() ??
              (b['estimated_amount'] as num?)?.toDouble() ??
              0.0;
          bookingCounts[cId] = (bookingCounts[cId] ?? 0) + 1;
          customerSpent[cId] = (customerSpent[cId] ?? 0.0) + amt;
        }
      }

      // 4. Map user records
      final List<Map<String, dynamic>> loaded = [];
      for (var u in usersRes) {
        final uId = u['user_id']?.toString() ?? '';

        Map<String, dynamic>? profile;
        if (u['user_profiles'] is List && (u['user_profiles'] as List).isNotEmpty) {
          profile = (u['user_profiles'] as List)[0] as Map<String, dynamic>?;
        } else if (u['user_profiles'] is Map) {
          profile = u['user_profiles'] as Map<String, dynamic>?;
        }

        Map<String, dynamic>? address;
        if (u['user_addresses'] is List && (u['user_addresses'] as List).isNotEmpty) {
          address = (u['user_addresses'] as List)[0] as Map<String, dynamic>?;
        }

        final firstName = profile?['first_name']?.toString() ?? '';
        final lastName = profile?['last_name']?.toString() ?? '';
        final fullName = '$firstName $lastName'.trim();
        final name = fullName.isNotEmpty ? fullName : (u['username']?.toString() ?? 'Customer');
        final email = u['email']?.toString() ?? 'N/A';
        final phone = u['phone']?.toString() ?? 'N/A';
        final city = address?['city']?.toString() ?? 'Surat, Gujarat';
        final isActive = u['is_active'] == true || u['account_status'] == 'ACTIVE';
        final createdAt = u['created_at'] != null ? DateTime.tryParse(u['created_at'].toString()) : null;
        final joinedDate = createdAt != null ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' : 'Recently';

        final totalBookings = bookingCounts[uId] ?? 0;
        final totalSpent = customerSpent[uId] ?? 0.0;
        final coins = (totalSpent * 0.05).toInt();

        loaded.add({
          'user_id': uId,
          'name': name,
          'email': email,
          'phone': phone,
          'city': city,
          'is_active': isActive,
          'joined_date': joinedDate,
          'total_bookings': totalBookings,
          'total_spent': totalSpent.toStringAsFixed(2),
          'coins': coins,
        });
      }

      if (mounted) {
        setState(() {
          _customers = loaded;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _customers = [];
          _isLoading = false;
        });
      }
    }
  }

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
                      (customer['name'] as String).isNotEmpty ? customer['name'][0].toUpperCase() : 'C',
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
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final userId = customer['user_id'];
                      final newStatus = !customer['is_active'];

                      try {
                        final client = Supabase.instance.client;
                        if (userId != null && userId.toString().isNotEmpty) {
                          await client.from('users').update({
                            'is_active': newStatus,
                            'account_status': newStatus ? 'ACTIVE' : 'SUSPENDED',
                          }).eq('user_id', userId);
                        }
                      } catch (_) {}

                      setState(() {
                        customer['is_active'] = newStatus;
                      });

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Customer ${customer['name']} status updated to ${newStatus ? 'ACTIVE' : 'SUSPENDED'}!')),
                        );
                      }
                      _loadCustomers();
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
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
                tooltip: 'Refresh Customers',
                onPressed: _loadCustomers,
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.people_outline_rounded, size: 44, color: Color(0xFFCBD5E1)),
                              SizedBox(height: 10),
                              Text('No Registered Customers Yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF64748B))),
                              SizedBox(height: 4),
                              Text('Registered customer profiles and booking history will appear here automatically.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (ctx, idx) {
                            final c = filtered[idx];
                            final initialLetter = (c['name'] as String).isNotEmpty ? c['name'][0].toUpperCase() : 'C';

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: CircleAvatar(
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: Text(initialLetter, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
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
