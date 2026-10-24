import 'package:flutter/material.dart';
import '../../dashboard/presentation/widgets/booking_details_modal.dart';

class AdminBookingsView extends StatefulWidget {
  final List<Map<String, dynamic>> allBookings;
  final String initialFilter;
  final String? serviceCategory;
  final String title;

  const AdminBookingsView({
    super.key,
    required this.allBookings,
    this.initialFilter = 'All Bookings',
    this.serviceCategory,
    this.title = 'All Bookings',
  });

  @override
  State<AdminBookingsView> createState() => _AdminBookingsViewState();
}

class _AdminBookingsViewState extends State<AdminBookingsView> {
  late String _activeFilter;
  String _searchQuery = '';

  static bool _matchesCategory(Map<String, dynamic> b, String targetCategory) {
    final catId = (b['category_id'] ?? '').toString().toLowerCase().trim();
    final catName = (b['category'] ?? b['category_name'] ?? '').toString().toLowerCase().trim();
    final sName = (b['service_name'] ?? b['problem_description'] ?? '').toString().toLowerCase();

    final target = targetCategory.toLowerCase().trim();

    if (catId.isNotEmpty && catId == target) return true;

    switch (target) {
      case 'ac_service':
        return catId == 'ac_service' ||
            catName.contains('ac') ||
            sName.contains('ac') ||
            sName.contains('air condition');
      case 'care_taker':
        return catId == 'care_taker' ||
            catName.contains('care') ||
            sName.contains('care') ||
            sName.contains('elderly') ||
            sName.contains('patient') ||
            sName.contains('babysitt');
      case 'laundry':
        return catId == 'laundry' ||
            catName.contains('laundry') ||
            sName.contains('laundry') ||
            sName.contains('wash') ||
            sName.contains('iron') ||
            sName.contains('dry clean');
      case 'car_service':
        return catId == 'car_service' ||
            (catName.contains('car') && !catName.contains('care')) ||
            (sName.contains('car') && !sName.contains('care')) ||
            sName.contains('vehicle') ||
            sName.contains('automobile');
      case 'plumbing':
        return catId == 'plumbing' ||
            catName.contains('plumb') ||
            sName.contains('plumb') ||
            sName.contains('pipe') ||
            sName.contains('tap') ||
            sName.contains('leak');
      case 'cooking':
        return catId == 'cooking' ||
            catName.contains('cook') ||
            sName.contains('cook') ||
            sName.contains('chef');
      default:
        return catId == target || catName.contains(target) || sName.contains(target);
    }
  }

  @override
  void initState() {
    super.initState();
    _activeFilter = widget.initialFilter;
  }

  @override
  void didUpdateWidget(covariant AdminBookingsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialFilter != widget.initialFilter || oldWidget.serviceCategory != widget.serviceCategory) {
      setState(() {
        _activeFilter = widget.initialFilter;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final baseBookings = widget.serviceCategory == null
        ? widget.allBookings
        : widget.allBookings.where((b) => _matchesCategory(b, widget.serviceCategory!)).toList();

    final filtered = baseBookings.where((b) {
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
          return _matchesCategory(b, 'ac_service');
        case 'Care Taker Bookings':
          return _matchesCategory(b, 'care_taker');
        case 'Laundry Bookings':
          return _matchesCategory(b, 'laundry');
        case 'Car Service Bookings':
          return _matchesCategory(b, 'car_service');
        case 'Plumbing Bookings':
          return _matchesCategory(b, 'plumbing');
        case 'Cooking Bookings':
          return _matchesCategory(b, 'cooking');
        case 'Booking Requests':
          return status == 'PENDING' || status == 'SEARCHING_PROVIDER';
        case 'Assigned Bookings':
          return status == 'ASSIGNED' || status == 'CONFIRMED' || status == 'ACCEPTED';
        case 'Ongoing Services':
          return status == 'ONGOING' || status == 'SERVICE_STARTED' || status == 'ARRIVED' || status == 'ON_THE_WAY' || status == 'IN_TRANSIT';
        case 'Completed Services':
          return status == 'COMPLETED' || status == 'SERVICE_COMPLETED';
        case 'Cancelled Bookings':
          return status == 'CANCELLED' || status == 'REJECTED';
        default:
          return true;
      }
    }).toList();

    final isDedicatedService = widget.serviceCategory != null;

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
                _buildFilterChip('All Bookings', baseBookings.length),
                if (!isDedicatedService) ...[
                  const SizedBox(width: 8),
                  _buildFilterChip('AC Service Bookings', baseBookings.where((b) => _matchesCategory(b, 'ac_service')).length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Care Taker Bookings', baseBookings.where((b) => _matchesCategory(b, 'care_taker')).length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Laundry Bookings', baseBookings.where((b) => _matchesCategory(b, 'laundry')).length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Car Service Bookings', baseBookings.where((b) => _matchesCategory(b, 'car_service')).length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Plumbing Bookings', baseBookings.where((b) => _matchesCategory(b, 'plumbing')).length),
                  const SizedBox(width: 8),
                  _buildFilterChip('Cooking Bookings', baseBookings.where((b) => _matchesCategory(b, 'cooking')).length),
                ],
                const SizedBox(width: 8),
                _buildFilterChip('Booking Requests', baseBookings.where((b) {
                  final s = (b['status'] ?? '').toString().toUpperCase();
                  return s == 'PENDING' || s == 'SEARCHING_PROVIDER';
                }).length),
                const SizedBox(width: 8),
                _buildFilterChip('Assigned Bookings', baseBookings.where((b) {
                  final s = (b['status'] ?? '').toString().toUpperCase();
                  return s == 'ASSIGNED' || s == 'CONFIRMED' || s == 'ACCEPTED';
                }).length),
                const SizedBox(width: 8),
                _buildFilterChip('Ongoing Services', baseBookings.where((b) {
                  final s = (b['status'] ?? '').toString().toUpperCase();
                  return s == 'ONGOING' || s == 'SERVICE_STARTED' || s == 'ARRIVED' || s == 'ON_THE_WAY' || s == 'IN_TRANSIT';
                }).length),
                const SizedBox(width: 8),
                _buildFilterChip('Completed Services', baseBookings.where((b) {
                  final s = (b['status'] ?? '').toString().toUpperCase();
                  return s == 'COMPLETED' || s == 'SERVICE_COMPLETED';
                }).length),
                const SizedBox(width: 8),
                _buildFilterChip('Cancelled Bookings', baseBookings.where((b) {
                  final s = (b['status'] ?? '').toString().toUpperCase();
                  return s == 'CANCELLED' || s == 'REJECTED';
                }).length),
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
                          Text(
                            baseBookings.isEmpty
                                ? 'No bookings found for "${widget.title}"'
                                : 'No bookings found for "$_activeFilter"',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        physics: const ClampingScrollPhysics(),
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
                          final rawId = b['id'] ?? b['booking_id'];
                          final id = rawId != null ? (rawId.toString().length > 8 ? rawId.toString().substring(0, 8) : rawId.toString()) : 'N/A';
                          final customer = (b['customer_name'] ?? b['name'] ?? (b['customer_id'] != null ? 'Customer #${b['customer_id'].toString().substring(0, b['customer_id'].toString().length.clamp(0, 6))}' : 'Customer')).toString();
                          final service = (b['service_name'] ?? b['category_name'] ?? b['problem_description'] ?? 'AC Service').toString();
                          final date = (b['service_date'] ?? b['scheduled_date'] ?? (b['created_at'] != null ? b['created_at'].toString().split('T').first : 'Today')).toString();
                          final time = (b['service_time'] ?? b['scheduled_time_slot'] ?? 'Scheduled').toString();
                          final amount = (b['final_amount'] ?? b['estimated_amount'] ?? '0.00').toString();
                          final status = (b['status'] ?? 'PENDING').toString().toUpperCase();

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
      case 'ARRIVED':
      case 'ON_THE_WAY':
      case 'IN_TRANSIT':
        bg = const Color(0xFFFFFBEB);
        fg = const Color(0xFFF59E0B);
        break;
      case 'ASSIGNED':
      case 'SEARCHING_PROVIDER':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF0284C7);
        break;
      case 'COMPLETED':
      case 'SERVICE_COMPLETED':
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
