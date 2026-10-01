import 'package:flutter/material.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/storage/local_registration_cache.dart';
import '../controllers/delivery_agent_profile_controller.dart';

class DeliveryAreaScreen extends StatefulWidget {
  final DeliveryAgentProfileController? controller;
  const DeliveryAreaScreen({super.key, this.controller});

  @override
  State<DeliveryAreaScreen> createState() => _DeliveryAreaScreenState();
}

class _DeliveryAreaScreenState extends State<DeliveryAreaScreen> {
  String _selectedRadius = '10 km';
  final List<String> _radiusOptions = ['5 km', '10 km', '15 km', '25 km', '40 km'];
  List<String> _preferredAreas = ['Patel Colony'];
  List<String> _blockedAreas = [];
  String _operatingCity = 'Jamnagar, Gujarat';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSavedPreferences();
  }

  Future<void> _loadSavedPreferences() async {
    try {
      final data = widget.controller?.agentData ?? await LocalRegistrationCache.getActiveDeliveryAgent();
      if (data != null && mounted) {
        setState(() {
          if (data['preferred_areas'] is List && (data['preferred_areas'] as List).isNotEmpty) {
            _preferredAreas = List<String>.from(data['preferred_areas']);
          }
          if (data['blocked_areas'] is List) {
            _blockedAreas = List<String>.from(data['blocked_areas']);
          }
          if (data['service_radius'] != null && _radiusOptions.contains(data['service_radius'].toString())) {
            _selectedRadius = data['service_radius'].toString();
          }
          final c = data['city']?.toString().trim();
          final s = data['state']?.toString().trim();
          if (c != null && c.isNotEmpty) {
            _operatingCity = (s != null && s.isNotEmpty) ? '$c, $s' : c;
          }
        });
      }
    } catch (_) {}
  }

  void _removePreferred(String area) {
    setState(() => _preferredAreas.remove(area));
  }

  void _removeBlocked(String area) {
    setState(() => _blockedAreas.remove(area));
  }

  void _showAddAreaDialog(bool isPreferred) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isPreferred ? 'Add Preferred Area' : 'Add Blocked Area', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter area or locality name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white),
            onPressed: () {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                setState(() {
                  if (isPreferred) {
                    if (!_preferredAreas.contains(text)) _preferredAreas.add(text);
                  } else {
                    if (!_blockedAreas.contains(text)) _blockedAreas.add(text);
                  }
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final radiusNum = double.tryParse(_selectedRadius.replaceAll(RegExp(r'[^\d.]'), '')) ?? 10.0;
    widget.controller?.updateRadius(radiusNum);
    await LocalRegistrationCache.updateActiveDeliveryAgent({
      'preferred_areas': _preferredAreas,
      'blocked_areas': _blockedAreas,
      'service_radius': _selectedRadius,
    });
    await SupabaseAuthService.updateDeliveryAgentInDatabase(
      operatingRadius: radiusNum,
      preferredAreas: _preferredAreas,
      blockedAreas: _blockedAreas,
    );
    if (mounted) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Delivery operating area & radius updated successfully!'),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = Color(0xFFEA580C);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Delivery Area',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card 1: Primary Operating City
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.location_on_rounded, color: Color(0xFF2563EB), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Primary Operating City', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(_operatingCity, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 2: Service Radius
            Container(
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
                        decoration: BoxDecoration(color: const Color(0xFFFFF7ED), borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.radar_rounded, color: orangeColor, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Service Radius', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Text('Distance within which you receive orders', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      Text(
                        _selectedRadius,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: orangeColor),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: _radiusOptions.map((opt) {
                      final isSelected = _selectedRadius == opt;
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: InkWell(
                            onTap: () => setState(() => _selectedRadius = opt),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? orangeColor : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                opt,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : const Color(0xFF475569),
                                ),
                              ),
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

            // Card 3: Preferred Areas
            Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFFFAF5FF), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.favorite_rounded, color: Color(0xFF9333EA), size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text('Preferred Areas', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                      InkWell(
                        onTap: () => _showAddAreaDialog(true),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            children: [
                              Icon(Icons.add_rounded, size: 14, color: Color(0xFF334155)),
                              SizedBox(width: 2),
                              Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_preferredAreas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No preferred areas added yet. Tap "Add" to specify high-priority delivery hubs.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _preferredAreas.map((area) {
                        return Chip(
                          label: Text(area, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          backgroundColor: const Color(0xFFF8FAFC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF64748B)),
                          onDeleted: () => _removePreferred(area),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Card 4: Blocked Areas (Optional)
            Container(
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.block_rounded, color: Color(0xFFEF4444), size: 18),
                          ),
                          const SizedBox(width: 10),
                          const Text('Blocked Areas (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                      InkWell(
                        onTap: () => _showAddAreaDialog(false),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                          child: const Row(
                            children: [
                              Icon(Icons.add_rounded, size: 14, color: Color(0xFF334155)),
                              SizedBox(width: 2),
                              Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_blockedAreas.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'No blocked areas configured. Tap "Add" to exclude congested routes.',
                        style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _blockedAreas.map((area) {
                        return Chip(
                          label: Text(area, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155))),
                          backgroundColor: const Color(0xFFF8FAFC),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          deleteIcon: const Icon(Icons.close_rounded, size: 14, color: Color(0xFF64748B)),
                          onDeleted: () => _removeBlocked(area),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Save Settings Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: orangeColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Operating Area', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
