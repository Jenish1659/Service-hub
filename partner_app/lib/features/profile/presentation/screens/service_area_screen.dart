import 'package:flutter/material.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';

class ServiceAreaScreen extends StatefulWidget {
  final ProfileController controller;

  const ServiceAreaScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ServiceAreaScreen> createState() => _ServiceAreaScreenState();
}

class _ServiceAreaScreenState extends State<ServiceAreaScreen> {
  late TextEditingController _cityController;
  late double _radiusKm;
  late List<String> _areas;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(
      text: widget.controller.serviceCity.isNotEmpty ? widget.controller.serviceCity : 'Jamnagar, Gujarat',
    );
    _radiusKm = widget.controller.serviceRadiusKm;
    _areas = List<String>.from(widget.controller.operationalAreas);
    if (_areas.isEmpty) {
      _areas = ['Digvijay Plot', 'Patel Colony', 'Khodiyar Colony', 'Valkeshwari', 'Ranjit Road'];
    }
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _showAddAreaDialog() {
    final areaCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Service Area', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: areaCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter locality or pincode (e.g. Bedeshwar)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = areaCtrl.text.trim();
              if (val.isNotEmpty && !_areas.contains(val)) {
                setState(() {
                  _areas.add(val);
                });
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final success = await widget.controller.saveServiceAreaSettings(
      city: _cityController.text.trim(),
      radius: _radiusKm,
      areas: _areas,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      TopToast.show(context, 'Service Area updated successfully!', isError: false);
      Navigator.pop(context);
    } else {
      TopToast.show(context, 'Failed to save service area', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Service Area',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Manage your working area and service radius',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Radar Visualizer Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.radar_rounded, color: Color(0xFF2563EB), size: 30),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Coverage Radius: ${_radiusKm.round()} km',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF1E3A8A)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'You will receive customer job requests within ${_radiusKm.round()} km of ${_cityController.text}.',
                                  style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 1: Base Service City
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildCardHeader(
                            icon: Icons.location_city_rounded,
                            iconBg: const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF2563EB),
                            title: 'Primary Operating City',
                            subtitle: 'Your base service location and dispatch center',
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _cityController,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              prefixIcon: const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFF2563EB)),
                              hintText: 'e.g. Jamnagar, Gujarat',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                            ),
                            onChanged: (val) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Interactive Radius Slider
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildCardHeader(
                                  icon: Icons.radar_rounded,
                                  iconBg: const Color(0xFFF0FDF4),
                                  iconColor: const Color(0xFF16A34A),
                                  title: 'Service Radius',
                                  subtitle: 'Set maximum travel distance for home visits',
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_radiusKm.round()} km',
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Slider(
                            value: _radiusKm,
                            min: 1,
                            max: 50,
                            divisions: 49,
                            activeColor: const Color(0xFF2563EB),
                            inactiveColor: const Color(0xFFE2E8F0),
                            onChanged: (val) {
                              setState(() {
                                _radiusKm = val;
                              });
                            },
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('1 km (Local)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                Text('25 km', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                Text('50 km (City-wide)', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Preset Chips
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [5.0, 10.0, 15.0, 25.0, 40.0].map((r) {
                              final isSelected = (_radiusKm.round() == r.round());
                              return InkWell(
                                onTap: () => setState(() => _radiusKm = r),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${r.round()} km',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.white : const Color(0xFF475569),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Operational Localities & Pockets
                    _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildCardHeader(
                                  icon: Icons.my_location_rounded,
                                  iconBg: const Color(0xFFFDF4FF),
                                  iconColor: const Color(0xFFC026D3),
                                  title: 'Preferred Localities',
                                  subtitle: 'Neighborhoods and sectors you actively cover',
                                ),
                              ),
                              TextButton.icon(
                                onPressed: _showAddAreaDialog,
                                icon: const Icon(Icons.add_rounded, size: 16),
                                label: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _areas.map((area) {
                              return Chip(
                                label: Text(area, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                                backgroundColor: const Color(0xFFEFF6FF),
                                side: const BorderSide(color: Color(0xFFBFDBFE)),
                                deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF64748B)),
                                onDeleted: () {
                                  if (_areas.length > 1) {
                                    setState(() => _areas.remove(area));
                                  } else {
                                    TopToast.show(context, 'Keep at least one operational area', isError: true);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Card 4: Fair Dispatch Guarantee Policy
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Fair Dispatch Protection: Requests outside your selected ${_radiusKm.round()} km radius will not affect your acceptance rate or performance score.',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Service Area Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_circle_outline_rounded, size: 20),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Service Area',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildCardHeader({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
