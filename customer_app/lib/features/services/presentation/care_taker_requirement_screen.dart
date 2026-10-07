// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../services/multi_service_booking_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';
import 'service_select_date_screen.dart';

/// Screen 1 for Care Taker Service:
/// Captures care category, shift duration, gender preference,
/// mobility status, daily assistance checklist, patient medical notes (min 10 chars),
/// and optional prescription/discharge summary photos.
class CareTakerRequirementScreen extends ConsumerStatefulWidget {
  final String? serviceName;
  final double? servicePrice;

  const CareTakerRequirementScreen({
    super.key,
    this.serviceName,
    this.servicePrice,
  });

  @override
  ConsumerState<CareTakerRequirementScreen> createState() => _CareTakerRequirementScreenState();
}

class _CareTakerRequirementScreenState extends ConsumerState<CareTakerRequirementScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  String _selectedCareType = 'Elderly Companion & Assistance';
  String _selectedShift = '8 Hours (Full Day Shift)';
  String _selectedGenderPref = 'Any Qualified Professional';
  String _selectedMobility = 'Needs Support / Walker';

  final List<String> _careTypes = [
    'Elderly Companion & Assistance',
    'Post-Surgery Recovery Care',
    'Bedridden Patient Nursing Assistance',
    'Infant & Babysitting Care',
    'Special Needs Assistance',
  ];

  final Map<String, double> _careTypeBasePrices = {
    'Elderly Companion & Assistance': 599.0,
    'Post-Surgery Recovery Care': 799.0,
    'Bedridden Patient Nursing Assistance': 999.0,
    'Infant & Babysitting Care': 499.0,
    'Special Needs Assistance': 699.0,
  };

  final Map<String, double> _shiftMultipliers = {
    '4 Hours (Half Day Shift)': 1.0,
    '8 Hours (Full Day Shift)': 1.7,
    '12 Hours (Day/Night Shift)': 2.2,
    '24 Hours (Round-the-clock Live-in)': 3.5,
  };

  final List<String> _genderPreferences = [
    'Any Qualified Professional',
    'Female Caretaker Preferred',
    'Male Caretaker Preferred',
  ];

  final List<String> _mobilityOptions = [
    'Fully Mobile',
    'Needs Support / Walker',
    'Bedridden / Wheelchair',
  ];

  final Set<String> _selectedAssistanceTasks = {};
  final List<String> _assistanceTasks = [
    'Personal hygiene, bathing & grooming',
    'Timely medication administration & logs',
    'Feeding & dietary meal assistance',
    'Mobility, gentle exercise & walking support',
    'Vital signs tracking (BP, Sugar, Pulse)',
    'Companionship & mental engagement',
  ];

  final List<File> _uploadedPhotos = [];
  int _charCount = 0;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _notesController.addListener(_onTextChanged);
    _loadDraft();
  }

  void _onTextChanged() {
    setState(() {
      _charCount = _notesController.text.length;
      if (_hasError && _charCount >= 10) {
        _hasError = false;
      }
    });
    _saveDraft();
  }

  void _loadDraft() {
    final draft = MultiServiceBookingService.instance.loadDraft('care_taker');
    if (draft != null) {
      setState(() {
        if (draft['care_type'] != null) _selectedCareType = draft['care_type'] as String;
        if (draft['shift_duration'] != null) _selectedShift = draft['shift_duration'] as String;
        if (draft['gender_preference'] != null) _selectedGenderPref = draft['gender_preference'] as String;
        if (draft['mobility_status'] != null) _selectedMobility = draft['mobility_status'] as String;
        if (draft['patient_age'] != null) _ageController.text = draft['patient_age'] as String;
        if (draft['assistance_tasks'] is List) {
          _selectedAssistanceTasks.clear();
          _selectedAssistanceTasks.addAll(List<String>.from(draft['assistance_tasks'] as List));
        }
        if (draft['problem_description'] != null) {
          _notesController.text = draft['problem_description'] as String;
          _charCount = _notesController.text.length;
        }
      });
    }
  }

  void _saveDraft() {
    final draft = {
      'category_id': 'care_taker',
      'service_name': _selectedCareType,
      'care_type': _selectedCareType,
      'shift_duration': _selectedShift,
      'gender_preference': _selectedGenderPref,
      'mobility_status': _selectedMobility,
      'patient_age': _ageController.text.trim(),
      'service_price': _calculatedPrice,
      'assistance_tasks': _selectedAssistanceTasks.toList(),
      'problem_description': _notesController.text.trim(),
      'status': 'DRAFT_REQUIREMENTS',
      'updated_at': DateTime.now().toIso8601String(),
    };
    MultiServiceBookingService.instance.saveDraft('care_taker', draft);
  }

  double get _calculatedPrice {
    final base = _careTypeBasePrices[_selectedCareType] ?? (widget.servicePrice ?? 599.0);
    final mult = _shiftMultipliers[_selectedShift] ?? 1.0;
    return (base * mult).roundToDouble();
  }

  @override
  void dispose() {
    _notesController.removeListener(_onTextChanged);
    _notesController.dispose();
    _ageController.dispose();
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
    final notes = _notesController.text.trim();
    if (notes.isNotEmpty && notes.length < 10) {
      setState(() => _hasError = true);
      _showWarningSnackBar('Medical notes / instructions must be at least 10 characters.');
      return;
    }

    final photoUrls = await MultiServiceBookingService.instance.uploadPhotos(
      _uploadedPhotos,
      prefix: 'care_taker',
    );

    final autoDesc = notes.isNotEmpty
        ? notes
        : '$_selectedCareType for ${_ageController.text.trim().isNotEmpty ? "${_ageController.text.trim()}yo " : ""}($_selectedShift)';

    final payload = {
      'category_id': 'care_taker',
      'service_name': _selectedCareType,
      'care_type': _selectedCareType,
      'service_price': _calculatedPrice,
      'estimated_amount': _calculatedPrice,
      'shift_duration': _selectedShift,
      'gender_preference': _selectedGenderPref,
      'mobility_status': _selectedMobility,
      'patient_age': _ageController.text.trim(),
      'assistance_tasks': _selectedAssistanceTasks.toList(),
      'photo_urls': photoUrls,
      'problem_description': autoDesc,
      'status': 'DRAFT_DATE_PENDING',
      'updated_at': DateTime.now().toIso8601String(),
    };

    await MultiServiceBookingService.instance.saveDraft('care_taker', payload);

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
          'Care Taker & Nursing',
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
                    // Care Category
                    const Text(
                      'Type of Care Needed',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    ..._careTypes.map((care) {
                      final isSelected = _selectedCareType == care;
                      final basePrice = _careTypeBasePrices[care] ?? 599.0;
                      return GestureDetector(
                        onTap: () {
                          setState(() => _selectedCareType = care);
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
                                  care,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Text(
                                'From ₹${basePrice.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Shift Duration
                    const Text(
                      'Shift Duration',
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
                          children: _shiftMultipliers.keys.map((shift) {
                            return RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              activeColor: const Color(0xFF3B49DF),
                              title: Text(shift, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                              value: shift,
                              groupValue: _selectedShift,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedShift = val);
                                  _saveDraft();
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Gender Preference & Patient Info
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
                          const Text('Caretaker Gender Preference', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedGenderPref,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                            items: _genderPreferences.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedGenderPref = val);
                                _saveDraft();
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          const Text('Patient Mobility Status', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedMobility,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                            items: _mobilityOptions.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedMobility = val);
                                _saveDraft();
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          const Text('Patient Age (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _ageController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'e.g., 68',
                              hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                            onChanged: (_) => _saveDraft(),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Daily Tasks Checklist
                    const Text(
                      'Daily Assistance Tasks Required',
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
                          children: _assistanceTasks.map((task) {
                            final isChecked = _selectedAssistanceTasks.contains(task);
                            return CheckboxListTile(
                              dense: true,
                              value: isChecked,
                              activeColor: const Color(0xFF3B49DF),
                              title: Text(task, style: const TextStyle(fontSize: 13, color: Color(0xFF334155))),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedAssistanceTasks.add(task);
                                  } else {
                                    _selectedAssistanceTasks.remove(task);
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

                    // Medical Notes (Min 10 characters)
                    const Text(
                      'Medical Condition & Care Instructions',
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
                            controller: _notesController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              hintText: 'e.g., Diabetic diet, BP medication at 8 AM, requires gentle wheelchair assistance...',
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

                    // Prescription / Documents Upload
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Prescriptions / Notes (Optional)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        TextButton.icon(
                          onPressed: _pickPhoto,
                          icon: const Icon(Icons.camera_alt_rounded, size: 18, color: Color(0xFF3B49DF)),
                          label: const Text('Add Document', style: TextStyle(color: Color(0xFF3B49DF), fontWeight: FontWeight.w600)),
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
                      const Text('Estimated Rate', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
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
                        child: const Text('Select Care Schedule', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
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
