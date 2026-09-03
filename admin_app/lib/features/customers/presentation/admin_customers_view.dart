import 'package:flutter/material.dart';

class AdminCustomersView extends StatelessWidget {
  final int customerCount;

  const AdminCustomersView({super.key, required this.customerCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Customer Directory', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  SizedBox(height: 2),
                  Text('Manage verified customers, addresses, and service booking histories', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text('$customerCount Total Customers', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E40AF))),
              ),
            ],
          ),
          const SizedBox(height: 16),

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
                  _buildCustomerRow('Rahul Sharma', '+91 98765 43210', 'rahul.sharma@example.com', 'Jamnagar, Gujarat', 4, '₹4,850'),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildCustomerRow('Priya Patel', '+91 98251 67890', 'priya.patel@example.com', 'Rajkot, Gujarat', 2, '₹2,499'),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildCustomerRow('Vikram Singh', '+91 94280 11223', 'vikram.singh@example.com', 'Ahmedabad, Gujarat', 6, '₹7,920'),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildCustomerRow('Sneha Joshi', '+91 97234 55667', 'sneha.joshi@example.com', 'Surat, Gujarat', 3, '₹3,650'),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),
                  _buildCustomerRow('Amit Kumar', '+91 99090 44332', 'amit.kumar@example.com', 'Vadodara, Gujarat', 1, '₹1,299'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerRow(String name, String phone, String email, String city, int bookings, String spend) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 14)),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                Text(email, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(phone, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
          ),
          Expanded(
            flex: 2,
            child: Text(city, style: const TextStyle(fontSize: 12, color: Color(0xFF334155))),
          ),
          Expanded(
            flex: 2,
            child: Text('$bookings Bookings', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
          ),
          Expanded(
            flex: 2,
            child: Text(spend, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          ),
        ],
      ),
    );
  }
}
