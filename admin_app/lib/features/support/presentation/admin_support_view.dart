import 'package:flutter/material.dart';

class AdminSupportView extends StatelessWidget {
  final Function(String id) onResolve;

  const AdminSupportView({super.key, required this.onResolve});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Complaints & Support Tickets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('Realtime dispute resolution and service quality complaints management', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView(
                children: [
                  _buildTicketRow('TCK-901', 'Rahul Sharma', 'AC Cooling issue persisted after service', 'HIGH PRIORITY', false),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildTicketRow('TCK-902', 'Priya Patel', 'Technician arrived 15 minutes late', 'MEDIUM', true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketRow(String id, String user, String desc, String priority, bool resolved) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(id, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 12))),
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text(desc, style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: const Color(0xFFFEF2F2), borderRadius: BorderRadius.circular(6)),
            child: Text(priority, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
          ),
          const SizedBox(width: 14),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: resolved ? const Color(0xFFF1F5F9) : const Color(0xFF2563EB),
              foregroundColor: resolved ? const Color(0xFF64748B) : Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: resolved ? null : () => onResolve(id),
            child: Text(resolved ? 'Resolved ✓' : 'Mark Resolved', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
