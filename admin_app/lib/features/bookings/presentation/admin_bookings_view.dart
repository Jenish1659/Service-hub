import 'package:flutter/material.dart';
import '../../dashboard/presentation/widgets/booking_details_modal.dart';

class AdminBookingsView extends StatefulWidget {
  final List<Map<String, dynamic>> allBookings;
  final String initialFilter;

  const AdminBookingsView({
    super.key,
    required this.allBookings,
    this.initialFilter = 'All Bookings',
  });

  @override
  State<AdminBookingsView> createState() => _AdminBookingsViewState();
}

class _AdminBookingsViewState extends State<AdminBookingsView> {
  late String _activeFilter;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(covariant AdminBookingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter) {
      setState(() {
        _activeFilter = widget.initialFilter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.allBookings.where((b) {
      final status = (b['status'] ?? '').toString().toUpperCase();
      final service = (b['service_name'] ?? '').toString().toLowerCase();
      final customer = (b['customer_name'] ?? b['name'] ?? '').toString().toLowerCase();
      final id = (b['id'] ?? b['booking_id'] ?? '').toString().toLowerCase();

      // Search match
      if (_searchQuery.isNotEmpty) {
        final matches = customer.contains(_searchQuery.toLowerCase()) ||
            service.contains(_searchQuery.toLowerCase()) ||
            id.contains(_searchQuery.toLowerCase());
        if (!matches) return false;
      }

      // Filter match
      switch (_activeFilter) {
        case 'AC Service Bookings':
          return service.contains('ac') || service.contains('air');
        case 'Booking Requests':
          return status == 'PENDING' || status == 'SEARCHING_PROVIDER';
        case 'Assigned Bookings':
          return status == 'ASSIGNED';
        case 'Ongoing Services':
          return status == 'ONGOING' || status == 'SERVICE_STARTED';
        case 'Completed Services':
          return status == 'COMPLETED';
        case 'Cancelled Bookings':
          return status == 'CANCELLED';
        default:
          return true;
      }
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Tabs Bar
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Bookings', widget.allBookings.length),
                const SizedBox(width: 8),
                _buildFilterChip('AC Service Bookings', widget.allBookings.where((b) => (b['service_name'] ?? '').toString().toLowerCase().contains('ac')).length),
                const SizedBox(width: 8),
                _buildFilterChip('Booking Requests', widget.allBookings.where((b) => (b['status'] ?? '').toString().toUpperCase() == 'PENDING').length),
                const SizedBox(width: 8),
                _buildFilterChip('Assigned Bookings', widget.allBookings.where((b) => (b['status'] ?? '').toString().toUpperCase() == 'ASSIGNED').length),
                const SizedBox(width: 8),
                _buildFilterChip('Ongoing Services', widget.allBookings.where((b) => (b['status'] ?? '').toString().toUpperCase() == 'ONGOING').length),
                const SizedBox(width: 8),
                _buildFilterChip('Completed Services', widget.allBookings.where((b) => (b['status'] ?? '').toString().toUpperCase() == 'COMPLETED').length),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled Bookings', widget.allBookings.where((b) => (b['status'] ?? '').toString().toUpperCase() == 'CANCELLED').length),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search & Action Header
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 18, color: Color(0xFF94A3B8)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (val) => setState(() => _searchQuery = val),
                          decoration: const InputDecoration(
                            hintText: 'Search by Customer, Service, Booking ID...',
                            hintStyle: TextStyle(fontSize: 12.5, color: Color(0xFF94A3B8)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Refresh Bookings', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                onPressed: () => setState(() {}),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Table Content Container
          Expanded(
            child: Container(
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
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_month_outlined, size: 48, color: Color(0xFFCBD5E1)),
                          const SizedBox(height: 10),
                          Text('No bookings found for "$_activeFilter"', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      child: DataTable(
                        columnSpacing: 18,
                        horizontalMargin: 20,
                        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                        columns: const [
                          DataColumn(label: Text('Booking ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                          DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                          DataColumn(label: Text('Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                          DataColumn(label: Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                          DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                          DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                          DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF475569)))),
                        ],
                        rows: filtered.map((b) {
                          final id = b['id'] ?? b['booking_id'] ?? 'BK1250';
                          final customer = b['customer_name'] ?? b['name'] ?? 'Rahul Sharma';
                          final service = b['service_name'] ?? 'AC Service (Split AC)';
                          final date = b['service_date'] ?? '31 May 2025';
                          final time = b['service_time'] ?? '10:30 AM';
                          final amount = b['estimated_amount'] ?? '499.00';
                          final status = (b['status'] ?? 'CONFIRMED').toString().toUpperCase();

                          return DataRow(
                            cells: [
                              DataCell(Text('#$id', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF2563EB)))),
                              DataCell(Text(customer, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: Color(0xFF0F172A)))),
                              DataCell(Text(service, style: const TextStyle(fontSize: 12, color: Color(0xFF334155)))),
                              DataCell(Text('$date • $time', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B)))),
                              DataCell(Text('₹$amount', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)))),
                              DataCell(_buildStatusBadge(status)),
                              DataCell(
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFEFF6FF),
                                    foregroundColor: const Color(0xFF2563EB),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => BookingDetailsModal.show(context, b),
                                  child: const Text('Inspect', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _activeFilter == label;
    return InkWell(
      onTap: () => setState(() => _activeFilter = label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF334155)),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF64748B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;

    switch (status) {
      case 'CONFIRMED':
      case 'ACCEPTED':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF10B981);
        break;
      case 'ONGOING':
      case 'SERVICE_STARTED':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFF59E0B);
        break;
      case 'ASSIGNED':
      case 'SEARCHING_PROVIDER':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF0284C7);
        break;
      case 'COMPLETED':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        break;
      case 'CANCELLED':
      case 'REJECTED':
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFEF4444);
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
