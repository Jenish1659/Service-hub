import 'package:flutter/material.dart';

class AdminServicesView extends StatelessWidget {
  const AdminServicesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Services & Pricing Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
          const SizedBox(height: 2),
          const Text('Manage categories, AC service models, visiting inspection fee (₹449), and safety fees (₹49)', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 20),

          Expanded(
            child: GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.5,
              children: [
                _buildServiceConfigCard('AC Service (Split AC)', 'Deep clean & gas check', '₹499.00', '₹449 Visiting', true),
                _buildServiceConfigCard('AC Service (Window AC)', 'Filter clean & coil wash', '₹449.00', '₹449 Visiting', true),
                _buildServiceConfigCard('AC Service (Cassette AC)', 'Commercial 360 airflow', '₹999.00', '₹449 Visiting', true),
                _buildServiceConfigCard('AC Installation / Uninstallation', 'Wall mounting & piping', '₹1,199.00', '₹449 Visiting', true),
                _buildServiceConfigCard('Washing Machine Repair', 'Front load / Top load motor', '₹399.00', '₹349 Visiting', true),
                _buildServiceConfigCard('RO Water Purifier Service', 'Membrane & sediment filter', '₹299.00', '₹249 Visiting', true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceConfigCard(String name, String desc, String price, String visiting, bool active) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.ac_unit_rounded, color: Color(0xFF2563EB), size: 20),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
              ),
            ],
          ),
          const Spacer(),
          Text(name, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
          Text(desc, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(price, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF2563EB))),
              Text(visiting, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }
}
