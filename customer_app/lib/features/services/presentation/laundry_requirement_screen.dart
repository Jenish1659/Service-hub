import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../services/multi_service_booking_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';
import 'service_select_date_screen.dart';

/// Screen 1 for Laundry Service: Captures service mode, garment item counters,
/// fabric/stain care preferences, pickup details, and special instructions.
class LaundryRequirementScreen extends ConsumerStatefulWidget {
  final String? serviceName;
  final double? servicePrice;

  const LaundryRequirementScreen({
    super.key,
    this.serviceName,
    this.servicePrice,
  });

  @override
  ConsumerState<LaundryRequirementScreen> createState() => _LaundryRequirementScreenState();
}

class _LaundryRequirementScreenState extends ConsumerState<LaundryRequirementScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _instructionsController = TextEditingController();

  String _selectedMode = 'Wash & Steam Iron';
  String _selectedDeliverySpeed = 'Standard (48 Hours)';
  bool _handleDelicates = false;
  bool _stainTreatment = false;
  bool _addStarch = false;
  final List<File> _uploadedPhotos = [];

  // Garment Item Quantities & Unit Prices
  final Map<String, int> _itemCounts = {
    'Shirts / Tops': 2,
    'Trousers / Jeans': 2,
    'Sarees / Dresses': 0,
    'Bedsheets / Linens': 0,
    'Heavy Coats / Blankets': 0,
    'Undergarments / Socks': 0,
  };

  final Map<String, double> _unitPrices = {
    'Shirts / Tops': 25.0,
    'Trousers / Jeans': 30.0,
    'Sarees / Dresses': 65.0,
    'Bedsheets / Linens': 45.0,
    'Heavy Coats / Blankets': 120.0,
    'Undergarments / Socks': 15.0,
  };

  int _charCount = 0;
  bool _hasError = false;

  final List<String> _serviceModes = [
    'Wash & Steam Iron',
    'Wash & Fold Service',
    'Premium Dry Cleaning (Suits & Sarees)',
    'Steam Ironing Only',
  ];

  @override
  void initState() {
    super.initState();
    _instructionsController.addListener(_onTextChanged);
    _loadDraft();
  }

  void _onTextChanged() {
    setState(() {
      _charCount = _instructionsController.text.length;
      if (_hasError && _charCount >= 10) {
        _hasError = false;
      }
    });
    _saveDraft();
  }

  void _loadDraft() {
    final draft = MultiServiceBookingService.instance.loadDraft('laundry');
    if (draft != null) {
      setState(() {
        if (draft['service_mode'] != null) _selectedMode = draft['service_mode'] as String;
        if (draft['delivery_speed'] != null) _selectedDeliverySpeed = draft['delivery_speed'] as String;
        if (draft['handle_delicates'] != null) _handleDelicates = draft['handle_delicates'] as bool;
        if (draft['stain_treatment'] != null) _stainTreatment = draft['stain_treatment'] as bool;
        if (draft['add_starch'] != null) _addStarch = draft['add_starch'] as bool;
        if (draft['items'] is Map) {
          final itemsMap = draft['items'] as Map;
          itemsMap.forEach((k, v) {
            if (_itemCounts.containsKey(k) && v is int) {
              _itemCounts[k] = v;
            }
          });
        }
        if (draft['problem_description'] != null) {
          _instructionsController.text = draft['problem_description'] as String;
          _charCount = _instructionsController.text.length;
        }
      });
    }
  }

  void _saveDraft() {
    final draft = {
      'category_id': 'laundry',
      'service_name': _selectedMode,
      'service_mode': _selectedMode,
      'delivery_speed': _selectedDeliverySpeed,
      'handle_delicates': _handleDelicates,
      'stain_treatment': _stainTreatment,
      'add_starch': _addStarch,
      'items': _itemCounts,
      'total_items': _totalItems,
      'service_price': _calculatedPrice,
      'problem_description': _instructionsController.text.trim(),
      'status': 'DRAFT_REQUIREMENTS',
      'updated_at': DateTime.now().toIso8601String(),
    };
    MultiServiceBookingService.instance.saveDraft('laundry', draft);
  }

  int get _totalItems => _itemCounts.values.fold(0, (sum, count) => sum + count);

  double get _calculatedPrice {
    double itemSum = 0.0;
    _itemCounts.forEach((k, v) {
      itemSum += (v * (_unitPrices[k] ?? 25.0));
    });
    if (_stainTreatment) itemSum += 50.0;
    if (_selectedDeliverySpeed.contains('Express')) itemSum += 100.0;
    return itemSum > 0 ? itemSum : (widget.servicePrice ?? 199.0);
  }

  @override
  void dispose() {
    _instructionsController.removeListener(_onTextChanged);
    _instructionsController.dispose();
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
    if (_totalItems < 1) {
      _showWarningSnackBar('Please add at least 1 garment item to proceed.');
      return;
    }

    final instructions = _instructionsController.text.trim();
    if (instructions.isNotEmpty && instructions.length < 10) {
      setState(() => _hasError = true);
      _showWarningSnackBar('Special instructions must be at least 10 characters.');
      return;
    }

    final photoUrls = await MultiServiceBookingService.instance.uploadPhotos(
      _uploadedPhotos,
      prefix: 'laundry',
    );

    final payload = {
      'category_id': 'laundry',
      'service_name': _selectedMode,
      'service_mode': _selectedMode,
      'service_price': _calculatedPrice,
      'estimated_amount': _calculatedPrice,
      'items': _itemCounts,
      'total_items': _totalItems,
      'delivery_speed': _selectedDeliverySpeed,
      'handle_delicates': _handleDelicates,
      'stain_treatment': _stainTreatment,
      'add_starch': _addStarch,
      'photo_urls': photoUrls,
      'problem_description': instructions.isNotEmpty ? instructions : '$_selectedMode with $_totalItems items',
      'status': 'DRAFT_DATE_PENDING',
      'updated_at': DateTime.now().toIso8601String(),
    };

    await MultiServiceBookingService.instance.saveDraft('laundry', payload);

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
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: () => ACDateTimeAIChatbotSheet.show(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.support_agent_rounded, size: 18, color: Color(0xFF3B49DF)),
                    SizedBox(width: 6),
                    Text(
                      'Need Help?',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Color(0xFF3B49DF)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Laundry Service',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Color(0xFF0F172A), letterSpacing: -0.4),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select service mode, garment items, and fabric care requirements',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                    ),

                    const SizedBox(height: 20),

                    // Service Mode Selector
                    const Text('Service Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMode,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                          items: _serviceModes.map((mode) {
                            return DropdownMenuItem(
                              value: mode,
                              child: Text(mode, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedMode = val);
                              _saveDraft();
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Garment Items Counter Card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Garment Items & Quantity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text('$_totalItems items selected', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF3B49DF))),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _itemCounts.length,
                        separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, index) {
                          final itemKey = _itemCounts.keys.elementAt(index);
                          final count = _itemCounts[itemKey] ?? 0;
                          final price = _unitPrices[itemKey] ?? 25.0;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(itemKey, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F172A))),
                                      const SizedBox(height: 2),
                                      Text('₹${price.toStringAsFixed(0)} / piece', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF94A3B8), size: 22),
                                      onPressed: count > 0
                                          ? () {
                                              setState(() => _itemCounts[itemKey] = count - 1);
                                              _saveDraft();
                                            }
                                          : null,
                                    ),
                                    Text('$count', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_rounded, color: Color(0xFF3B49DF), size: 22),
                                      onPressed: () {
                                        setState(() => _itemCounts[itemKey] = count + 1);
                                        _saveDraft();
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Fabric Care & Special Options
                    const Text('Fabric & Special Care', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 10),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            CheckboxListTile(
                              dense: true,
                              activeColor: const Color(0xFF3B49DF),
                              title: const Text('Delicate Garments (Silk / Wool)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Gentle low-heat washing', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              value: _handleDelicates,
                              onChanged: (val) {
                                setState(() => _handleDelicates = val ?? false);
                                _saveDraft();
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            CheckboxListTile(
                              dense: true,
                              activeColor: const Color(0xFF3B49DF),
                              title: const Text('Stain Treatment (+₹50)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                              subtitle: const Text('Target collar, cuffs, or specific ink/oil spots', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              value: _stainTreatment,
                              onChanged: (val) {
                                setState(() => _stainTreatment = val ?? false);
                                _saveDraft();
                              },
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            CheckboxListTile(
                              dense: true,
                              activeColor: const Color(0xFF3B49DF),
                              title: const Text('Add Crisp Starch', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                              subtitle: const Text('For cotton shirts and traditional kurtas', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              value: _addStarch,
                              onChanged: (val) {
                                setState(() => _addStarch = val ?? false);
                                _saveDraft();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Delivery Turnaround
                    const Text('Delivery Timeline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedDeliverySpeed = 'Standard (48 Hours)');
                              _saveDraft();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _selectedDeliverySpeed.contains('Standard') ? const Color(0xFFEEF2FF) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedDeliverySpeed.contains('Standard') ? const Color(0xFF3B49DF) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Standard', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  SizedBox(height: 2),
                                  Text('48 Hours return', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedDeliverySpeed = 'Express (24 Hours)');
                              _saveDraft();
                            },
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: _selectedDeliverySpeed.contains('Express') ? const Color(0xFFEEF2FF) : Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _selectedDeliverySpeed.contains('Express') ? const Color(0xFF3B49DF) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Express (+₹100)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                  SizedBox(height: 2),
                                  Text('24 Hours return', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Special Instructions Textbox (min 10 chars constraint)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Special Instructions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Text(
                          '$_charCount / 10 min chars',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _hasError || (_charCount > 0 && _charCount < 10) ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _hasError ? const Color(0xFFDC2626) : const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _instructionsController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          hintText: 'e.g., Please treat coffee stain on white shirt carefully...',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          border: InputBorder.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Garment Photos (Optional)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Garment Photos (Optional)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        TextButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.camera_alt_outlined, size: 16),
                          label: const Text('Add Photo'),
                        ),
                      ],
                    ),
                    if (_uploadedPhotos.isNotEmpty)
                      SizedBox(
                        height: 70,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _uploadedPhotos.length,
                          itemBuilder: (context, idx) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.file(_uploadedPhotos[idx], width: 70, height: 70, fit: BoxFit.cover),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Bottom CTA Bar
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
                        child: const Text('Select Pickup Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
