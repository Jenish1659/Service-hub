import 'package:flutter/material.dart';

class BookingDetailsModal {
  static void show(BuildContext context, Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 580,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.ac_unit_rounded, color: Color(0xFF2563EB), size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking Details #${booking['id'] ?? booking['booking_id'] ?? 'BK1250'}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                          ),
                          Text(
                            booking['service_name'] ?? 'AC Service (Split AC)',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F5F9)),
                const SizedBox(height: 12),

                // Customer Info
                const Text('Customer Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.person_outline, 'Name', booking['customer_name'] ?? 'Not specified'),
                _buildInfoRow(Icons.phone_outlined, 'Phone', booking['customer_phone'] ?? 'Not provided'),
                _buildInfoRow(Icons.location_on_outlined, 'Address', booking['customer_address'] ?? booking['address'] ?? 'Not provided'),
                const SizedBox(height: 14),

                // AC Issue Info
                const Text('AC Appliance & Problem', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.mode_fan_off_outlined, 'AC Type', booking['ac_type'] ?? 'N/A'),
                _buildInfoRow(Icons.branding_watermark_outlined, 'Brand', booking['ac_brand'] ?? 'N/A'),
                _buildInfoRow(Icons.history_outlined, 'AC Age', booking['ac_age'] ?? 'N/A'),
                _buildInfoRow(Icons.description_outlined, 'Problem', booking['problem_description'] ?? 'No description provided'),
                const SizedBox(height: 14),

                // Schedule & Slot
                const Text('Service Schedule', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.calendar_month_outlined, 'Date', booking['scheduled_date'] ?? booking['service_date'] ?? booking['booking_date_formatted'] ?? 'N/A'),
                _buildInfoRow(Icons.schedule_outlined, 'Time Slot', booking['scheduled_time_slot'] ?? booking['service_time'] ?? booking['scheduled_time'] ?? 'N/A'),
                _buildInfoRow(Icons.currency_rupee_rounded, 'Estimated Price', '₹${booking['estimated_amount'] ?? booking['price'] ?? booking['final_amount'] ?? '0'}'),
                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Confirm Assignment'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Booking assignment confirmed!'), backgroundColor: Color(0xFF10B981)),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12, color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
