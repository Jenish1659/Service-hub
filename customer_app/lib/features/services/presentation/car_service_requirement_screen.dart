import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../services/multi_service_booking_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';
import 'service_select_date_screen.dart';

/// Screen 1 for Car Service & Repair:
/// Captures vehicle type, brand & model, fuel type, package selection,
/// symptom checklist, photos, and problem description (min 10 chars).
class CarServiceRequirementScreen extends ConsumerStatefulWidget {
  final String? serviceName;
  final double? servicePrice;

  const CarServiceRequirementScreen({
    super.key,
    this.serviceName,
    this.servicePrice,
  });

  @override
  ConsumerState<CarServiceRequirementScreen> createState() => _CarServiceRequirementScreenState();
}

class _CarServiceRequirementScreenState extends ConsumerState<CarServiceRequirementScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _problemController = TextEditingController();

  String _selectedVehicleType = 'Hatchback';
  String _selectedBrand = 'Maruti Suzuki';
  String _selectedFuelType = 'Petrol';
  String _selectedPackage = 'Periodic Standard Service';

  final List<String> _vehicleTypes = ['Hatchback', 'Sedan', 'Compact SUV', 'Full SUV / Luxury'];
  final List<String> _brands = [
    'Maruti Suzuki',
    'Hyundai',
    'Tata Motors',
    'Mahindra',
    'Honda',
    'Toyota',
    'Kia',
    'Volkswagen',
    'Other'
  ];
  final List<String> _fuelTypes = ['Petrol', 'Diesel', 'CNG', 'Electric'];

  final Map<String, double> _packageBasePrices = {
    'Periodic Standard Service': 1499.0,
    'Comprehensive Car Service': 2499.0,
    'AC Servicing & Gas Refill': 1199.0,
    'Full Foam Wash & Interior Detailing': 899.0,
    'Wheel Alignment & Dynamic Balancing': 599.0,
    'Complete 360° Safety Inspection': 499.0,
  };

  final Map<String, double> _vehicleMultipliers = {
    'Hatchback': 1.0,
    'Sedan': 1.15,
    'Compact SUV': 1.25,
    'Full SUV / Luxury': 1.4,
  };

  final Set<String> _selectedSymptoms = {};
  final List<String> _symptomOptions = [
    'Unusual engine or exhaust noise',
    'Brake squealing or low braking bite',
    'AC blowing warm / low cooling airflow',
    'Check engine or dashboard warning light',
    'Fluid / oil leakage under car',
    'Steering wobble or vibration at speed',
    'Hard clutch pedal or rough gear shift',
  ];

  final List<File> _uploadedPhotos = [];
  int _charCount = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _problemController.addListener(_onTextChanged);
    _loadDraft();
  }

  void _onTextChanged() {
    setState(() {
      _charCount = _problemController.text.length;
      if (_hasError && _charCount >= 10) {
        _hasError = false;
      }
    });
    _saveDraft();
  }

  void _loadDraft() {
    final draft = MultiServiceBookingService.instance.loadDraft('car_service');
    if (draft != null) {
      setState(() {
        if (draft['vehicle_type'] != null) _selectedVehicleType = draft['vehicle_type'] as String;
        if (draft['brand'] != null) _selectedBrand = draft['brand'] as String;
        if (draft['model'] != null) _modelController.text = draft['model'] as String;
        if (draft['fuel_type'] != null) _selectedFuelType = draft['fuel_type'] as String;
        if (draft['package_name'] != null) _selectedPackage = draft['package_name'] as String;
        if (draft['symptoms'] is List) {
          _selectedSymptoms.clear();
          _selectedSymptoms.addAll(List<String>.from(draft['symptoms'] as List));
        }
        if (draft['problem_description'] != null) {
          _problemController.text = draft['problem_description'] as String;
          _charCount = _problemController.text.length;
        }
      });
    }
  }

  void _saveDraft() {
    final draft = {
      'category_id': 'car_service',
      'service_name': _selectedPackage,
      'vehicle_type': _selectedVehicleType,
      'brand': _selectedBrand,
      'model': _modelController.text.trim(),
      'fuel_type': _selectedFuelType,
      'package_name': _selectedPackage,
      'service_price': _calculatedPrice,
      'symptoms': _selectedSymptoms.toList(),
      'problem_description': _problemController.text.trim(),
      'status': 'DRAFT_REQUIREMENTS',
      'updated_at': DateTime.now().toIso8601String(),
    };
    MultiServiceBookingService.instance.saveDraft('car_service', draft);
  }

  double get _calculatedPrice {
    final base = _packageBasePrices[_selectedPackage] ?? (widget.servicePrice ?? 799.0);
    final mult = _vehicleMultipliers[_selectedVehicleType] ?? 1.0;
    return (base * mult).roundToDouble();
  }

  @override
  void dispose() {
    _problemController.removeListener(_onTextChanged);
    _problemController.dispose();
    _modelController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_uploadedPhotos.length >= 4) {
      _showWarningSnackBar('Maximum 4 photos allowed.');
      return;
    }
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.camera, imageQuality: 80);
      if (image != null) {
        setState(() => _uploadedPhotos.add(File(image.path)));
      }
    } catch (_) {}
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleContinue() async {
    final problemDesc = _problemController.text.trim();
    if (problemDesc.isNotEmpty && problemDesc.length < 10) {
      setState(() => _hasError = true);
      _showWarningSnackBar('Problem description must be at least 10 characters.');
      return;
    }

    if (_uploadedPhotos.isEmpty) {
      _showWarningSnackBar('Please upload at least one image of the vehicle/issue.');
      return;
    }

    final photoUrls = await MultiServiceBookingService.instance.uploadPhotos(
      _uploadedPhotos,
      prefix: 'car_service',
    );

    final autoDesc = problemDesc.isNotEmpty
        ? problemDesc
        : '$_selectedBrand ${_modelController.text.trim().isNotEmpty ? _modelController.text.trim() : _selectedVehicleType} - $_selectedPackage';

    final payload = {
      'category_id': 'car_service',
      'service_name': _selectedPackage,
      'package_name': _selectedPackage,
      'service_price': _calculatedPrice,
      'estimated_amount': _calculatedPrice,
      'vehicle_type': _selectedVehicleType,
      'brand': _selectedBrand,
      'model': _modelController.text.trim(),
      'fuel_type': _selectedFuelType,
      'symptoms': _selectedSymptoms.toList(),
      'photo_urls': photoUrls,
      'problem_description': autoDesc,
      'status': 'DRAFT_DATE_PENDING',
      'updated_at': DateTime.now().toIso8601String(),
    };

    await MultiServiceBookingService.instance.saveDraft('car_service', payload);

    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ServiceSelectDateScreen(issueDetails: payload),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Car Service & Repair',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent_rounded, color: Color(0xFF3B49DF)),
            tooltip: 'ServiceHub AI Assistant',
            onPressed: () => ACDateTimeAIChatbotSheet.show(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle Type Header
                    const Text(
                      'Select Vehicle Type',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: _vehicleTypes.map((type) {
                        final isSelected = _selectedVehicleType == type;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedVehicleType = type);
                              _saveDraft();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF3B49DF) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.directions_car_rounded,
                                    size: 22,
                                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    type,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Brand, Model & Fuel
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
                          const Text('Brand / Manufacturer', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedBrand,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                            items: _brands.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedBrand = val);
                                _saveDraft();
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          const Text('Model / Variant (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _modelController,
                            decoration: InputDecoration(
                              hintText: 'e.g., Swift Dzire VXi / City ZX',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                            onChanged: (_) => _saveDraft(),
                          ),
                          const SizedBox(height: 14),
                          const Text('Fuel Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: _fuelTypes.map((fuel) {
                              final isSelected = _selectedFuelType == fuel;
                              return ChoiceChip(
                                label: Text(fuel),
                                selected: isSelected,
                                selectedColor: const Color(0xFFEEF2FF),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF475569),
                                ),
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() => _selectedFuelType = fuel);
                                    _saveDraft();
                                  }
                                },
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Service Package Selection
                    const Text(
                      'Choose Service Package',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    ..._packageBasePrices.entries.map((entry) {
                      final isSelected = _selectedPackage == entry.key;
                      final mult = _vehicleMultipliers[_selectedVehicleType] ?? 1.0;
                      final price = (entry.value * mult).roundToDouble();

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedPackage = entry.key);
                          _saveDraft();
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFFE2E8F0),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Text(
                                '₹${price.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 14),

                    // Symptoms Checklist
                    const Text(
                      'Symptoms Observed (Optional)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: _symptomOptions.map((symptom) {
                            final isChecked = _selectedSymptoms.contains(symptom);
                            return CheckboxListTile(
                              dense: true,
                              value: isChecked,
                              activeColor: const Color(0xFF3B49DF),
                              title: Text(symptom, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedSymptoms.add(symptom);
                                  } else {
                                    _selectedSymptoms.remove(symptom);
                                  }
                                });
                                _saveDraft();
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Problem description (Min 10 characters)
                    const Text(
                      'Specific Concerns or Instructions',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter at least 10 characters if providing specific instructions.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _hasError ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                          width: _hasError ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TextField(
                            controller: _problemController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'e.g., Brake pedal feels spongy, vibration starts above 60 km/h...',
                              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(14),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 12, bottom: 8),
                            child: Text(
                              '$_charCount / 10 min chars',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _charCount > 0 && _charCount < 10
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFF94A3B8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Photos (Camera/Gallery)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Upload Photos (Optional)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        TextButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.camera_alt_rounded, size: 18, color: Color(0xFF3B49DF)),
                          label: const Text('Add Photo', style: TextStyle(color: Color(0xFF3B49DF), fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    if (_uploadedPhotos.isNotEmpty)
                      SizedBox(
                        height: 75,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _uploadedPhotos.length,
                          itemBuilder: (context, idx) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(_uploadedPhotos[idx], width: 75, height: 75, fit: BoxFit.cover),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom Estimated Price Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, -4)),
                ],
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Estimated Cost', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text(
                        '₹${_calculatedPrice.toStringAsFixed(0)}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                    ],
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _handleContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B49DF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text('Select Service Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
