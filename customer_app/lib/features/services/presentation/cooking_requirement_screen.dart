// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../services/multi_service_booking_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';
import 'service_select_date_screen.dart';

/// Screen 1 for Home Cook & Chef Services:
/// Captures service package, meals required, dietary preference,
/// number of persons, custom menu / allergy instructions (min 10 chars),
/// and optional kitchen photos.
class CookingRequirementScreen extends ConsumerStatefulWidget {
  final String? serviceName;
  final double? servicePrice;

  const CookingRequirementScreen({
    super.key,
    this.serviceName,
    this.servicePrice,
  });

  @override
  ConsumerState<CookingRequirementScreen> createState() => _CookingRequirementScreenState();
}

class _CookingRequirementScreenState extends ConsumerState<CookingRequirementScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _menuInstructionsController = TextEditingController();

  final TextEditingController _customHeadcountController = TextEditingController();

  String? _selectedCookingType;
  String? _selectedDiet;
  String? _selectedHeadcount;

  final List<String> _cookingTypes = [
    'Daily Home Cook (Lunch & Dinner)',
    'One-Time Special Party Chef',
    'Healthy Fitness & Diet Meal Prep',
    'Traditional Gujarati Thali & Sweets',
    'Multi-Cuisine North / South Indian Chef',
  ];

  final Map<String, double> _cookingBasePrices = {
    'Daily Home Cook (Lunch & Dinner)': 399.0,
    'One-Time Special Party Chef': 1199.0,
    'Healthy Fitness & Diet Meal Prep': 499.0,
    'Traditional Gujarati Thali & Sweets': 549.0,
    'Multi-Cuisine North / South Indian Chef': 649.0,
  };

  final Map<String, double> _headcountMultipliers = {
    '1 - 2 Persons': 1.0,
    '3 - 5 Persons': 1.25,
    '6 - 10 Persons': 1.75,
    '10+ Persons (Party)': 2.5,
  };

  final List<String> _dietaryOptions = [
    'Pure Vegetarian',
    'Jain (No Root Veg / Onion / Garlic)',
    'Swaminarayan (No Onion / Garlic)',
    'Eggitarian / Non-Vegetarian',
    'Vegan',
  ];

  final Set<String> _selectedMeals = {};
  final List<String> _mealOptions = [
    'Breakfast',
    'Lunch',
    'Evening Snacks & Tea',
    'Dinner',
  ];

  final List<File> _uploadedPhotos = [];
  int _charCount = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _menuInstructionsController.addListener(_onTextChanged);
    _customHeadcountController.addListener(_onCustomHeadcountChanged);
    _loadDraft();
  }

  void _onCustomHeadcountChanged() {
    setState(() {});
    _saveDraft();
  }

  void _onTextChanged() {
    setState(() {
      _charCount = _menuInstructionsController.text.length;
      if (_hasError && _charCount >= 10) {
        _hasError = false;
      }
    });
    _saveDraft();
  }

  void _loadDraft() {
    final draft = MultiServiceBookingService.instance.loadDraft('cooking');
    if (draft != null) {
      setState(() {
        if (draft['cooking_type'] != null) _selectedCookingType = draft['cooking_type'] as String;
        if (draft['dietary_preference'] != null) _selectedDiet = draft['dietary_preference'] as String;
        if (draft['headcount'] != null) _selectedHeadcount = draft['headcount'] as String;
        if (draft['custom_headcount'] != null) {
          _customHeadcountController.text = draft['custom_headcount'].toString();
        }
        if (draft['meals'] is List) {
          _selectedMeals.clear();
          _selectedMeals.addAll(List<String>.from(draft['meals'] as List));
        }
        if (draft['problem_description'] != null) {
          _menuInstructionsController.text = draft['problem_description'] as String;
          _charCount = _menuInstructionsController.text.length;
        }
      });
    }
  }

  String get _effectiveHeadcountText {
    if (_selectedHeadcount == null) return '';
    if (_selectedHeadcount!.contains('10+')) {
      final customNum = int.tryParse(_customHeadcountController.text.trim());
      if (customNum != null && customNum > 10) {
        return '$customNum Persons (Party)';
      }
      return '10+ Persons (Party)';
    }
    return _selectedHeadcount!;
  }

  void _saveDraft() {
    if (_selectedCookingType == null && _selectedMeals.isEmpty && _selectedHeadcount == null) return;
    final draft = {
      'category_id': 'cooking',
      'service_name': _selectedCookingType ?? 'Home Cook Service',
      'cooking_type': _selectedCookingType,
      'dietary_preference': _selectedDiet,
      'headcount': _effectiveHeadcountText,
      'custom_headcount': _customHeadcountController.text.trim(),
      'meals': _selectedMeals.toList(),
      'service_price': _calculatedPrice,
      'problem_description': _menuInstructionsController.text.trim(),
      'status': 'DRAFT_REQUIREMENTS',
      'updated_at': DateTime.now().toIso8601String(),
    };
    MultiServiceBookingService.instance.saveDraft('cooking', draft);
  }

  double get _calculatedPrice {
    if (_selectedCookingType == null || _selectedMeals.isEmpty || _selectedHeadcount == null) return 0.0;
    final base = _cookingBasePrices[_selectedCookingType!] ?? (widget.servicePrice ?? 399.0);
    double mult = _headcountMultipliers[_selectedHeadcount!] ?? 1.0;
    if (_selectedHeadcount!.contains('10+')) {
      final count = int.tryParse(_customHeadcountController.text.trim());
      if (count != null && count > 10) {
        mult = (2.5 + ((count - 10) * 0.08)).clamp(2.5, 6.0);
      }
    }
    return (base * mult).roundToDouble();
  }

  @override
  void dispose() {
    _menuInstructionsController.removeListener(_onTextChanged);
    _menuInstructionsController.dispose();
    _customHeadcountController.removeListener(_onCustomHeadcountChanged);
    _customHeadcountController.dispose();
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
    final instructions = _menuInstructionsController.text.trim();
    if (instructions.isNotEmpty && instructions.length < 10) {
      setState(() => _hasError = true);
      _showWarningSnackBar('Menu instructions / preferences must be at least 10 characters.');
      return;
    }

    if (_selectedCookingType == null) {
      _showWarningSnackBar('Please select cooking service *');
      return;
    }

    if (_selectedHeadcount == null) {
      _showWarningSnackBar('Please select headcount *');
      return;
    }

    if (_selectedDiet == null) {
      _showWarningSnackBar('Please select dietary preference *');
      return;
    }

    if (_selectedMeals.isEmpty) {
      _showWarningSnackBar('Please select at least one meal *');
      return;
    }

    if (_selectedHeadcount!.contains('10+')) {
      final customCount = int.tryParse(_customHeadcountController.text.trim());
      if (customCount == null || customCount <= 10) {
        _showWarningSnackBar('Please enter the exact headcount (greater than 10) for your party booking *');
        return;
      }
    }

    final photoUrls = await MultiServiceBookingService.instance.uploadPhotos(
      _uploadedPhotos,
      prefix: 'cooking',
    );

    final autoDesc = instructions.isNotEmpty
        ? instructions
        : '$_selectedCookingType - $_selectedDiet for $_effectiveHeadcountText (${_selectedMeals.join(', ')})';

    final payload = {
      'category_id': 'cooking',
      'service_name': _selectedCookingType,
      'cooking_type': _selectedCookingType,
      'service_price': _calculatedPrice,
      'estimated_amount': _calculatedPrice,
      'dietary_preference': _selectedDiet,
      'headcount': _effectiveHeadcountText,
      'custom_headcount': _customHeadcountController.text.trim(),
      'meals': _selectedMeals.toList(),
      'photo_urls': photoUrls,
      'problem_description': autoDesc,
      'status': 'DRAFT_DATE_PENDING',
      'updated_at': DateTime.now().toIso8601String(),
    };

    await MultiServiceBookingService.instance.saveDraft('cooking', payload);

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
          'Home Cook & Chef',
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
                    // Cooking Service Type
                    const Text(
                      'Select Cooking Service *',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    ..._cookingTypes.map((type) {
                      final isSelected = _selectedCookingType == type;
                      final mult = _selectedHeadcount != null ? (_headcountMultipliers[_selectedHeadcount!] ?? 1.0) : 1.0;
                      final price = ((_cookingBasePrices[type] ?? 399.0) * mult).roundToDouble();

                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCookingType = type);
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
                                  type,
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
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // 2. Headcount / Persons to Cook For (Moved to Upper Section per C4 & C5)
                    const Text(
                      'Headcount (Number of Persons) *',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: _headcountMultipliers.keys.map((hc) {
                        final isSelected = _selectedHeadcount == hc;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedHeadcount = hc);
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
                                    Icons.group_rounded,
                                    size: 18,
                                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    hc,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
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

                    // Dynamic Prompt for 10+ Headcount (Bug C5)
                    if (_selectedHeadcount != null && _selectedHeadcount!.contains('10+')) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.people_alt_rounded, size: 18, color: Color(0xFF2563EB)),
                                SizedBox(width: 8),
                                Text(
                                  'How many people?',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _customHeadcountController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Enter total guest count (e.g. 15, 25)',
                                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: const BorderSide(color: Color(0xFF93C5FD)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // 3. Dietary Preference (Now after Headcount)
                    const Text(
                      'Dietary Preference *',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: _dietaryOptions.map((diet) {
                            return RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              activeColor: const Color(0xFF3B49DF),
                              title: Text(diet, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                              value: diet,
                              groupValue: _selectedDiet,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedDiet = val);
                                  _saveDraft();
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Meals Required (Multi-Select)
                    const Text(
                      'Meals to Prepare *',
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
                          children: _mealOptions.map((meal) {
                            final isChecked = _selectedMeals.contains(meal);
                            return CheckboxListTile(
                              dense: true,
                              value: isChecked,
                              activeColor: const Color(0xFF3B49DF),
                              title: Text(meal, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedMeals.add(meal);
                                  } else {
                                    _selectedMeals.remove(meal);
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

                    // Specific Menu or Dietary Restrictions (Min 10 chars)
                    const Text(
                      'Dishes, Spice Level & Allergies (Optional)',
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
                            controller: _menuInstructionsController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'e.g., Low spice, Rotis without oil, Gujarati Kadhi, Khichdi, no peanuts...',
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

                    // Kitchen / Recipe Photos (Optional)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Text(
                            'Kitchen / Recipe Photos (Optional)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
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
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Estimated Rate', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        Text(
                          _calculatedPrice > 0 ? '₹${_calculatedPrice.toStringAsFixed(0)}' : '₹0',
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
                          child: const FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('Select Cooking Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
