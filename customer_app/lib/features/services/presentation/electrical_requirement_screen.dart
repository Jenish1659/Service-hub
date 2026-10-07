// ignore_for_file: deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../services/multi_service_booking_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';
import 'service_select_date_screen.dart';

/// Screen 1 for Electrical Service & Repairs:
/// Captures electrical issue categories, property type, emergency urgency,
/// photo uploads, and problem description (min 10 chars).
class ElectricalRequirementScreen extends ConsumerStatefulWidget {
  final String? serviceName;
  final double? servicePrice;

  const ElectricalRequirementScreen({
    super.key,
    this.serviceName,
    this.servicePrice,
  });

  @override
  ConsumerState<ElectricalRequirementScreen> createState() => _ElectricalRequirementScreenState();
}

class _ElectricalRequirementScreenState extends ConsumerState<ElectricalRequirementScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _problemController = TextEditingController();

  Set<String> _selectedIssues = {'Switchboard & Socket Repair'};
  String _selectedProperty = 'Apartment / Flat';
  bool _isEmergency = false;

  final List<String> _issueOptions = [
    'Switchboard & Socket Repair',
    'Ceiling Fan Installation & Repair',
    'MCB Tripping & Short Circuit Repair',
    'Light Fixtures, LED & Chandelier Setup',
    'Inverter & Battery Wiring',
    'Appliance Power Cable Connection',
    'Complete Home Wiring Diagnostic',
  ];

  final Map<String, double> _issueBasePrices = {
    'Switchboard & Socket Repair': 249.0,
    'Ceiling Fan Installation & Repair': 299.0,
    'MCB Tripping & Short Circuit Repair': 399.0,
    'Light Fixtures, LED & Chandelier Setup': 349.0,
    'Inverter & Battery Wiring': 499.0,
    'Appliance Power Cable Connection': 249.0,
    'Complete Home Wiring Diagnostic': 699.0,
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
    final draft = MultiServiceBookingService.instance.loadDraft('electrical');
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
    final mainIssue = _selectedIssues.isNotEmpty ? _selectedIssues.first : 'Electrical General Repair';
    final issueNames = _selectedIssues.join(', ');
    final draft = {
      'category_id': 'electrical',
      'service_name': issueNames,
      'issue_type': mainIssue,
      'selected_issues': _selectedIssues.toList(),
      'property_type': _selectedProperty,
      'is_emergency': _isEmergency,
      'service_price': _calculatedPrice,
      'problem_description': _problemController.text.trim(),
      'status': 'DRAFT_REQUIREMENTS',
      'updated_at': DateTime.now().toIso8601String(),
    };
    MultiServiceBookingService.instance.saveDraft('electrical', draft);
  }

  double get _calculatedPrice {
    if (_selectedIssues.isEmpty) return widget.servicePrice ?? 249.0;
    double maxBase = 0.0;
    for (final issue in _selectedIssues) {
      final p = _issueBasePrices[issue] ?? 249.0;
      if (p > maxBase) maxBase = p;
    }
    double extra = (_selectedIssues.length - 1) * 99.0;
    double total = maxBase + extra;
    if (_isEmergency) total += 149.0;
    return total;
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
      _showWarningSnackBar('Please select at least one electrical issue.');
      return;
    }

    List<String> photoUrls = [];
    if (_uploadedPhotos.isNotEmpty) {
      photoUrls = await MultiServiceBookingService.instance.uploadPhotos(
        _uploadedPhotos,
        prefix: 'electrical',
      );
    }

    final issueSummary = _selectedIssues.join(', ');
    final autoDesc = problemDesc.isNotEmpty
        ? problemDesc
        : '$issueSummary at $_selectedProperty${_isEmergency ? " (URGENT REPAIR)" : ""}';

    final payload = {
      'category_id': 'electrical',
      'service_name': issueSummary,
      'issue_type': _selectedIssues.first,
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

    await MultiServiceBookingService.instance.saveDraft('electrical', payload);

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
          'Electrical Service & Repair',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: () => ACDateTimeAIChatbotSheet.show(
                context,
                selectedDateText: 'Electrical Service Diagnostic',
              ),
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verified Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Certified electricians • High-voltage safety insured • 30-day warranty',
                              style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Issue Types (Checkboxes for multiple issues)
                    const Text(
                      'Select Electrical Issue(s)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Select one or multiple electrical tasks required',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 12),
                    ..._issueOptions.map((issue) {
                      final isSelected = _selectedIssues.contains(issue);
                      final price = _issueBasePrices[issue] ?? 249.0;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              if (_selectedIssues.length > 1) {
                                _selectedIssues.remove(issue);
                              }
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
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      issue,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF334155),
                                      ),
                                    ),
                                    Text(
                                      'Starts at ₹${price.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                    ),
                                  ],
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

                    const SizedBox(height: 20),

                    // Property Type
                    const Text(
                      'Property Type',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: _propertyTypes.map((prop) {
                        final isSelected = _selectedProperty == prop;
                        return Expanded(
                          child: InkWell(
                            onTap: () {
                              setState(() => _selectedProperty = prop);
                              _saveDraft();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFF3B49DF) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFFE2E8F0),
                                ),
                              ),
                              child: Text(
                                prop.split(' / ').first,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: isSelected ? Colors.white : const Color(0xFF334155),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Emergency Service Toggle
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.flash_on_rounded, color: Color(0xFFDC2626), size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Urgent / Priority Dispatch', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
                                Text('Immediate electrician dispatch within 30 mins (+₹149)', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isEmergency,
                            activeColor: const Color(0xFF3B49DF),
                            onChanged: (val) {
                              setState(() => _isEmergency = val);
                              _saveDraft();
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Problem Description
                    const Text(
                      'Describe the Problem (Optional)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
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
                              hintText: 'e.g., Sparks coming from bedroom AC switchboard, power tripped...',
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
