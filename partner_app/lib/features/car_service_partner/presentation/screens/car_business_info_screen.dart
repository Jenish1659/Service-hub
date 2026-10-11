import 'package:flutter/material.dart';
import '../../../../core/storage/local_registration_cache.dart';

/// Screen 8: Subpage 2 - Business / Garage Information for Car Service Provider
class CarBusinessInfoScreen extends StatefulWidget {
  const CarBusinessInfoScreen({super.key});

  @override
  State<CarBusinessInfoScreen> createState() => _CarBusinessInfoScreenState();
}

class _CarBusinessInfoScreenState extends State<CarBusinessInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _garageNameController;
  late final TextEditingController _addressController;
  late final TextEditingController _descController;
  late final TextEditingController _openSinceController;

  double _radiusKm = 10.0;
  bool _isLoading = true;
  bool _isSaving = false;

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _garageNameController = TextEditingController();
    _addressController = TextEditingController();
    _descController = TextEditingController();
    _openSinceController = TextEditingController();
    _loadBusinessData();
  }

  @override
  void dispose() {
    _garageNameController.dispose();
    _addressController.dispose();
    _descController.dispose();
    _openSinceController.dispose();
    super.dispose();
  }

  Future<void> _loadBusinessData() async {
    final cached = await LocalRegistrationCache.getActiveServiceProvider() ??
        await LocalRegistrationCache.getActivePartner();

    if (mounted) {
      setState(() {
        _garageNameController.text = (cached?['business_name'] ?? cached?['garage_name'] ?? 'Mehta Auto Service').toString();
        _addressController.text = (cached?['address'] ?? cached?['shop_address'] ?? '15, Industrial Area, Jamnagar, Gujarat 361004').toString();
        _descController.text = (cached?['business_description'] ??
            'Professional car service and repair shop specializing in AC service, engine repair, brake service, and general maintenance.').toString();
        _openSinceController.text = (cached?['open_since'] ?? '01 Jan 2022').toString();
        _radiusKm = double.tryParse((cached?['service_radius_km'] ?? '10').toString()) ?? 10.0;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await LocalRegistrationCache.updateActiveServiceProvider({
        'business_name': _garageNameController.text.trim(),
        'garage_name': _garageNameController.text.trim(),
        'address': _addressController.text.trim(),
        'business_description': _descController.text.trim(),
        'open_since': _openSinceController.text.trim(),
        'service_radius_km': _radiusKm.round(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Garage & business profile updated successfully!'),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notice: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Business Information',
          style: TextStyle(
            color: darkSlate,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Garage / Business Name
              _buildFieldLabel('Garage / Business Name *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _garageNameController,
                decoration: _inputDecoration('e.g. Mehta Auto Service'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Garage name is required' : null,
              ),
              const SizedBox(height: 18),

              // 2. Business Address with Location Pin
              _buildFieldLabel('Business Address *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: _inputDecoration(
                  'e.g. 15, Industrial Area, Jamnagar, Gujarat 361004',
                  suffixIcon: const Icon(Icons.location_on_rounded, color: primaryBlue),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: 20),

              // 3. Service Area (Radius) Slider: 1 km to 50 km
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFieldLabel('Service Area (Radius)'),
                  Text(
                    '${_radiusKm.round()} km',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: primaryBlue,
                  inactiveTrackColor: cardBorder,
                  thumbColor: primaryBlue,
                  overlayColor: primaryBlue.withValues(alpha: 0.1),
                ),
                child: Slider(
                  value: _radiusKm,
                  min: 1.0,
                  max: 50.0,
                  divisions: 49,
                  onChanged: (val) {
                    setState(() => _radiusKm = val);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('1 km', style: TextStyle(fontSize: 11, color: textMuted)),
                    Text('50 km', style: TextStyle(fontSize: 11, color: textMuted)),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // 4. Business Description
              _buildFieldLabel('Business Description'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                maxLength: 300,
                decoration: _inputDecoration('Describe your car workshop, equipment & specializations'),
              ),
              const SizedBox(height: 18),

              // 5. Open Since Date
              _buildFieldLabel('Open Since'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _openSinceController,
                readOnly: true,
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2022, 1, 1),
                    firstDate: DateTime(1980),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() {
                      _openSinceController.text =
                          '${picked.day.toString().padLeft(2, '0')} ${_monthName(picked.month)} ${picked.year}';
                    });
                  }
                },
                decoration: _inputDecoration(
                  'e.g. 01 Jan 2022',
                  prefixIcon: const Icon(Icons.calendar_month_outlined, color: primaryBlue, size: 20),
                ),
              ),
              const SizedBox(height: 36),

              // 6. Save Changes Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _saveChanges,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: darkSlate,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: textMuted),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }
}
