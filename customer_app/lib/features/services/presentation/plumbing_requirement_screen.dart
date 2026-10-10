// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../services/multi_service_booking_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';
import 'service_select_date_screen.dart';

/// Screen 1 for Plumbing Service & Repairs:
/// Captures plumbing issue category, property type, emergency urgency,
/// damage/leak photos, and problem description (min 10 chars).
class PlumbingRequirementScreen extends ConsumerStatefulWidget {
  final String? serviceName;
  final double? servicePrice;

  const PlumbingRequirementScreen({
    super.key,
    this.serviceName,
    this.servicePrice,
  });

  @override
  ConsumerState<PlumbingRequirementScreen> createState() => _PlumbingRequirementScreenState();
}

class _PlumbingRequirementScreenState extends ConsumerState<PlumbingRequirementScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _problemController = TextEditingController();

  Set<String> _selectedIssues = {};
  String? _selectedProperty;
  bool _isEmergency = false;

  final List<String> _issueOptions = [
    'Tap / Faucet & Shower Leakage',
    'Water Tank & Float Valve Overflow',
    'Blocked Drain & Pipe Clogging',
    'Toilet / Commode Fitting & Leak Repair',
    'Water Pump / Motor Repair',
    'Concealed Wall Leakage Inspection',
    'Complete Kitchen / Bathroom Repiping',
  ];

  final Map<String, double> _issueBasePrices = {
    'Tap / Faucet & Shower Leakage': 249.0,
    'Water Tank & Float Valve Overflow': 399.0,
    'Blocked Drain & Pipe Clogging': 349.0,
    'Toilet / Commode Fitting & Leak Repair': 499.0,
    'Water Pump / Motor Repair': 599.0,
    'Concealed Wall Leakage Inspection': 699.0,
    'Complete Kitchen / Bathroom Repiping': 899.0,
  };

  final List<String> _propertyTypes = [
    'Apartment / Flat',
    'Independent House / Villa',
    'Commercial Shop / Office',
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
    final draft = MultiServiceBookingService.instance.loadDraft('plumbing');
    if (draft != null) {
      setState(() {
        if (draft['selected_issues'] is List) {
          _selectedIssues = Set<String>.from(draft['selected_issues'] as List);
        } else if (draft['issue_type'] != null) {
          _selectedIssues = {draft['issue_type'] as String};
        }
        if (draft['property_type'] != null) _selectedProperty = draft['property_type'] as String;
        if (draft['is_emergency'] != null) _isEmergency = draft['is_emergency'] as bool;
        if (draft['problem_description'] != null) {
          _problemController.text = draft['problem_description'] as String;
          _charCount = _problemController.text.length;
        }
      });
    }
  }

  void _saveDraft() {
    if (_selectedIssues.isEmpty && _selectedProperty == null) return;
    final mainIssue = _selectedIssues.isNotEmpty ? _selectedIssues.first : 'Plumbing General Repair';
    final issueNames = _selectedIssues.join(', ');
    final draft = {
      'category_id': 'plumbing',
      'service_name': issueNames.isNotEmpty ? issueNames : 'Plumbing Service',
      'issue_type': mainIssue,
      'selected_issues': _selectedIssues.toList(),
      'property_type': _selectedProperty,
      'is_emergency': _isEmergency,
      'service_price': _calculatedPrice,
      'problem_description': _problemController.text.trim(),
      'status': 'DRAFT_REQUIREMENTS',
      'updated_at': DateTime.now().toIso8601String(),
    };
    MultiServiceBookingService.instance.saveDraft('plumbing', draft);
  }

  double get _calculatedPrice {
    if (_selectedIssues.isEmpty) return 0.0;
    double base = 0.0;
    for (final issue in _selectedIssues) {
      base += _issueBasePrices[issue] ?? 249.0;
    }
    if (_isEmergency) base += 100.0;
    return base;
  }

  @override
  void dispose() {
    _problemController.removeListener(_onTextChanged);
    _problemController.dispose();
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

    if (_selectedIssues.isEmpty) {
      _showWarningSnackBar('Please select at least one plumbing issue *');
      return;
    }

    if (_selectedProperty == null) {
      _showWarningSnackBar('Please select a property type *');
      return;
    }

    List<String> photoUrls = [];
    if (_uploadedPhotos.isNotEmpty) {
      photoUrls = await MultiServiceBookingService.instance.uploadPhotos(
        _uploadedPhotos,
        prefix: 'plumbing',
      );
    }

    final mainIssue = _selectedIssues.first;
    final issueNames = _selectedIssues.join(', ');
    final autoDesc = problemDesc.isNotEmpty
        ? problemDesc
        : '$issueNames at $_selectedProperty${_isEmergency ? " (Emergency Priority)" : ""}';

    final payload = {
      'category_id': 'plumbing',
      'service_name': issueNames,
      'issue_type': mainIssue,
      'selected_issues': _selectedIssues.toList(),
      'service_price': _calculatedPrice,
      'estimated_amount': _calculatedPrice,
      'property_type': _selectedProperty,
      'is_emergency': _isEmergency,
      'photo_urls': photoUrls,
      'problem_description': autoDesc,
      'status': 'DRAFT_DATE_PENDING',
      'updated_at': DateTime.now().toIso8601String(),
    };

    await MultiServiceBookingService.instance.saveDraft('plumbing', payload);

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
          'Plumbing Services & Repair',
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
                    // Issue Selection (Checkboxes)
                    const Text(
                      'Select Plumbing Issue(s) *',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    ..._issueOptions.map((issue) {
                      final isSelected = _selectedIssues.contains(issue);
                      final basePrice = _issueBasePrices[issue] ?? 249.0;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedIssues.remove(issue);
                            } else {
                              _selectedIssues.add(issue);
                            }
                          });
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
                                isSelected ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                                color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF94A3B8),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  issue,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              Text(
                                '₹${basePrice.toStringAsFixed(0)}',
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

                    // Property Type
                    const Text(
                      'Property Type *',
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
                          children: _propertyTypes.map((prop) {
                            return RadioListTile<String>(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              activeColor: const Color(0xFF3B49DF),
                              title: Text(prop, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                              value: prop,
                              groupValue: _selectedProperty,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedProperty = val);
                                  _saveDraft();
                                }
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Urgency Toggle
                    Material(
                      color: _isEmergency ? const Color(0xFFFEF2F2) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isEmergency ? const Color(0xFFEF4444) : const Color(0xFFE2E8F0),
                            width: _isEmergency ? 1.5 : 1,
                          ),
                        ),
                        child: SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          activeThumbColor: const Color(0xFFEF4444),
                          title: const Text(
                            'Urgent Leakage Emergency',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                          subtitle: const Text(
                            'Priority dispatch within 30 minutes (+₹100 urgency fee)',
                            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                          ),
                          value: _isEmergency,
                          onChanged: (val) {
                            setState(() => _isEmergency = val);
                            _saveDraft();
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Problem description (Min 10 characters)
                    const Text(
                      'Describe Problem / Fitting Location',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter at least 10 characters if describing specific location or problem.',
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
                              hintText: 'e.g., Continuous water leakage under master bedroom bathroom sink...',
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
                          'Upload Leak Photos (Optional)',
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
                        child: childPhotosList(),
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

  Widget childPhotosList() {
    return ListView.builder(
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
    );
  }
}
