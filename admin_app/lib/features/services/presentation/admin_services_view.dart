import 'package:flutter/material.dart';

class AdminServicesView extends StatefulWidget {
  const AdminServicesView({super.key});

  @override
  State<AdminServicesView> createState() => _AdminServicesViewState();
}

class _AdminServicesViewState extends State<AdminServicesView> {
  final List<Map<String, dynamic>> _services = [
    {
      'id': 'srv_split_jet',
      'name': 'Split AC Jet Wash & Deep Cleaning',
      'base_price': 499.0,
      'inspection_charge': 449.0,
      'safety_fee': 49.0,
      'warranty': '90 Days',
      'is_active': true,
      'category': 'AC Cleaning',
    },
    {
      'id': 'srv_window_jet',
      'name': 'Window AC Deep Jet Cleaning',
      'base_price': 449.0,
      'inspection_charge': 449.0,
      'safety_fee': 49.0,
      'warranty': '90 Days',
      'is_active': true,
      'category': 'AC Cleaning',
    },
    {
      'id': 'srv_gas_refill',
      'name': 'AC Complete Gas Charging & Leak Check',
      'base_price': 1499.0,
      'inspection_charge': 449.0,
      'safety_fee': 49.0,
      'warranty': '60 Days',
      'is_active': true,
      'category': 'AC Repair',
    },
    {
      'id': 'srv_pcb_repair',
      'name': 'Inverter PCB Circuit Board Diagnostic & Repair',
      'base_price': 899.0,
      'inspection_charge': 449.0,
      'safety_fee': 49.0,
      'warranty': '30 Days',
      'is_active': true,
      'category': 'AC Electronics',
    },
  ];

  void _showEditServiceModal(Map<String, dynamic> srv) {
    final priceController = TextEditingController(text: srv['base_price'].toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Pricing for ${srv['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Base Price (₹):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
            ),
            const SizedBox(height: 14),
            Text('Inspection Fee: ₹${srv['inspection_charge']} (Standard)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            Text('Safety & Protection Fee: ₹${srv['safety_fee']} (Standard)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              final newPrice = double.tryParse(priceController.text) ?? srv['base_price'];
              setState(() {
                srv['base_price'] = newPrice;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${srv['name']} price updated to ₹$newPrice!')),
              );
            },
            child: const Text('Save Pricing'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('Service Catalog & Dynamic Pricing Engine', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 3),
                  Text('Configure master service offerings, inspection charges (₹449), safety fees (₹49), and warranty terms', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                itemCount: _services.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                itemBuilder: (ctx, idx) {
                  final s = _services[idx];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.ac_unit_rounded, color: Color(0xFF2563EB), size: 22),
                    ),
                    title: Row(
                      children: [
                        Text(s['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
                          child: Text(s['warranty'], style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                        ),
                      ],
                    ),
                    subtitle: Text('Inspection Fee: ₹${s['inspection_charge']} • Safety Fee: ₹${s['safety_fee']} • Category: ${s['category']}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('₹${s['base_price']}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
                        const SizedBox(width: 14),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, color: Color(0xFF2563EB), size: 18),
                          onPressed: () => _showEditServiceModal(s),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
