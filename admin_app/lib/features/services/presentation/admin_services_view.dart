import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminServicesView extends StatefulWidget {
  const AdminServicesView({super.key});

  @override
  State<AdminServicesView> createState() => _AdminServicesViewState();
}

class _AdminServicesViewState extends State<AdminServicesView> {
  List<Map<String, dynamic>> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  Future<void> _loadServices() async {
    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final List<dynamic> res = await client.from('services').select().order('name', ascending: true);
      if (mounted) {
        setState(() {
          _services = List<Map<String, dynamic>>.from(res);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _services = [];
          _isLoading = false;
        });
      }
    }
  }

  void _showAddServiceModal() {
    final nameController = TextEditingController();
    final priceController = TextEditingController(text: '499');
    final durationController = TextEditingController(text: '60');
    final descController = TextEditingController();
    String selectedCategory = 'ac_service';

    final categories = [
      {'id': 'ac_service', 'label': 'AC Service'},
      {'id': 'plumbing', 'label': 'Plumbing'},
      {'id': 'laundry', 'label': 'Laundry'},
      {'id': 'car_service', 'label': 'Car Service'},
      {'id': 'cooking', 'label': 'Cooking'},
      {'id': 'care_taker', 'label': 'Care Taker'},
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Service', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Service Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Split AC Jet Wash & Deep Cleaning',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    items: categories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['id'],
                        child: Text(cat['label']!),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => selectedCategory = val);
                      }
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Base Price (₹)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: priceController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Duration (mins)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 6),
                            TextField(
                              controller: durationController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Detailed description of the service offering...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final price = double.tryParse(priceController.text.trim()) ?? 0.0;
                final duration = int.tryParse(durationController.text.trim()) ?? 60;
                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a service name.')),
                  );
                  return;
                }

                Navigator.pop(ctx);
                try {
                  final client = Supabase.instance.client;
                  await client.from('services').insert({
                    'name': name,
                    'category_id': selectedCategory,
                    'base_price': price,
                    'duration_minutes': duration,
                    'status': 'ACTIVE',
                    'description': descController.text.trim(),
                  });
                  await _loadServices();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Service "$name" created successfully!'),
                        backgroundColor: const Color(0xFF10B981),
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to add service: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Add Service'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditServiceModal(Map<String, dynamic> srv) {
    final serviceId = srv['service_id'] ?? srv['id'];
    final basePrice = (srv['base_price'] as num?)?.toDouble() ?? (srv['price'] as num?)?.toDouble() ?? 0.0;
    final priceController = TextEditingController(text: basePrice.toStringAsFixed(0));
    final nameController = TextEditingController(text: srv['name'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Pricing for ${srv['name']}'),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Service Name:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: nameController,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 14),
              const Text('Base Price (₹):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
              ),
              const SizedBox(height: 14),
              Text('Inspection Fee: ₹${srv['inspection_charge'] ?? 449.0} (Standard)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              Text('Safety & Protection Fee: ₹${srv['safety_fee'] ?? 49.0} (Standard)', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              final newPrice = double.tryParse(priceController.text) ?? basePrice;
              final newName = nameController.text.trim();

              try {
                final client = Supabase.instance.client;
                if (serviceId != null) {
                  await client.from('services').update({
                    'base_price': newPrice,
                    if (newName.isNotEmpty) 'name': newName,
                  }).eq('service_id', serviceId);
                }
                await _loadServices();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${srv['name']} price updated to ₹$newPrice!'),
                      backgroundColor: const Color(0xFF10B981),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to update service: $e'), backgroundColor: Colors.red),
                  );
                }
              }
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
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2563EB)),
                tooltip: 'Refresh Services',
                onPressed: _loadServices,
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: _showAddServiceModal,
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
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _services.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.cleaning_services_rounded, size: 48, color: Color(0xFF2563EB)),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No services configured yet',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'No services configured yet • Click Add Service to create one',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add Service'),
                                onPressed: _showAddServiceModal,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _services.length,
                          separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          itemBuilder: (ctx, idx) {
                            final s = _services[idx];
                            final name = s['name'] ?? 'Service';
                            final warranty = s['warranty'] ?? '90 Days';
                            final inspectionCharge = s['inspection_charge'] ?? 449.0;
                            final safetyFee = s['safety_fee'] ?? 49.0;
                            final category = s['category_id'] ?? s['category'] ?? 'General';
                            final basePrice = s['base_price'] ?? s['price'] ?? 0.0;

                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.ac_unit_rounded, color: Color(0xFF2563EB), size: 22),
                              ),
                              title: Row(
                                children: [
                                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(4)),
                                    child: Text(warranty, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                  ),
                                ],
                              ),
                              subtitle: Text('Inspection Fee: ₹$inspectionCharge • Safety Fee: ₹$safetyFee • Category: $category', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('₹$basePrice', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A))),
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
