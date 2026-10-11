import 'package:flutter/material.dart';
import '../../../../core/storage/local_registration_cache.dart';

/// Screen 8: Dedicated Business Information Sub-Screen for Care Taker Specialist
class CareBusinessInfoScreen extends StatefulWidget {
  const CareBusinessInfoScreen({super.key});

  @override
  State<CareBusinessInfoScreen> createState() => _CareBusinessInfoScreenState();
}

class _CareBusinessInfoScreenState extends State<CareBusinessInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _addressController;
  late TextEditingController _descController;
  double _serviceRadius = 10.0;
  String _openSince = '01 Jan 2022';
  bool _isLoading = true;

  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _businessNameController = TextEditingController();
    _addressController = TextEditingController();
    _descController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _addressController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final cached = await LocalRegistrationCache.getActiveServiceProvider() ??
        await LocalRegistrationCache.getActivePartner();
    if (mounted) {
      setState(() {
        _businessNameController.text = (cached?['business_name'] ?? 'Neha Care Services').toString();
        _addressController.text = (cached?['business_address'] ??
            cached?['address'] ??
            '12, Sunrise Residency, Jamnagar, Gujarat 361001').toString();
        _descController.text = (cached?['business_description'] ??
            'Professional home care and nursing services with compassion and trust. Elderly care, patient care, babysitting and special needs support.').toString();
        _serviceRadius = double.tryParse((cached?['service_radius'] ?? 10).toString()) ?? 10.0;
        _openSince = (cached?['open_since'] ?? '01 Jan 2022').toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    await LocalRegistrationCache.updateActiveServiceProvider({
      'business_name': _businessNameController.text.trim(),
      'business_address': _addressController.text.trim(),
      'address': _addressController.text.trim(),
      'business_description': _descController.text.trim(),
      'service_radius': _serviceRadius.round(),
      'open_since': _openSince,
      'role': 'care_taker',
      'category': 'care_taker',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business information saved successfully!'),
          backgroundColor: primaryIndigo,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(child: CircularProgressIndicator(color: primaryIndigo)),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Business Information',
          style: TextStyle(color: darkSlate, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Care Service Name
              const Text('Care Service Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _businessNameController,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Care service name is required' : null,
              ),

              const SizedBox(height: 16),

              // Business Address
              const Text('Business Address *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  suffixIcon: const Icon(Icons.location_on_rounded, color: primaryIndigo),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Address is required' : null,
              ),

              const SizedBox(height: 20),

              // Service Area (Radius) Slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Service Area (Radius)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
                  Text('${_serviceRadius.round()} km', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: primaryIndigo)),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: primaryIndigo,
                  inactiveTrackColor: primaryIndigo.withValues(alpha: 0.15),
                  thumbColor: primaryIndigo,
                ),
                child: Slider(
                  value: _serviceRadius,
                  min: 1,
                  max: 50,
                  divisions: 49,
                  onChanged: (val) => setState(() => _serviceRadius = val),
                ),
              ),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1 km', style: TextStyle(fontSize: 11, color: textMuted)),
                  Text('50 km', style: TextStyle(fontSize: 11, color: textMuted)),
                ],
              ),

              const SizedBox(height: 20),

              // Business Description
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Business Description', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
                  Text('${_descController.text.length}/300', style: const TextStyle(fontSize: 11, color: textMuted)),
                ],
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 4,
                maxLength: 300,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  counterText: '',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const SizedBox(height: 16),

              // Open Since
              const Text('Open Since', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2022, 1, 1),
                    firstDate: DateTime(1990),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _openSince = '${picked.day.toString().padLeft(2, '0')} ${_getMonthName(picked.month)} ${picked.year}';
                    });
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, size: 18, color: primaryIndigo),
                      const SizedBox(width: 12),
                      Text(_openSince, style: const TextStyle(fontSize: 14, color: darkSlate)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Save Changes Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryIndigo,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveChanges,
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}
