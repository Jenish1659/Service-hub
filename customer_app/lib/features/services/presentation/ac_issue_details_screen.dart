import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/ac_booking_service.dart';
import 'ac_service_ai_chatbot_sheet.dart';
import 'ac_service_overview_screen.dart';

class ACIssueDetailsScreen extends ConsumerStatefulWidget {
  final String? serviceName;
  final double? servicePrice;

  const ACIssueDetailsScreen({
    super.key,
    this.serviceName,
    this.servicePrice,
  });

  @override
  ConsumerState<ACIssueDetailsScreen> createState() => _ACIssueDetailsScreenState();
}

class _ACIssueDetailsScreenState extends ConsumerState<ACIssueDetailsScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _problemController = TextEditingController();
  final FocusNode _problemFocusNode = FocusNode();

  // Selected Form Values
  String? _selectedAcType;
  String? _selectedAcBrand;
  String? _selectedAcAge;
  final List<File> _selectedPhotos = [];

  bool _isSubmitting = false;
  int _charCount = 0;
  bool _hasDescriptionError = false;

  // Static options
  final List<String> _acTypes = [
    'Split AC',
    'Window AC',
    'Cassette AC',
    'Central AC',
    'Tower AC',
    'Portable AC',
    'Other',
  ];

  final List<String> _acBrands = [
    'Voltas',
    'Daikin',
    'LG',
    'Samsung',
    'Blue Star',
    'Panasonic',
    'Hitachi',
    'Carrier',
    'Lloyd',
    'Godrej',
    'Haier',
    'Whirlpool',
    'O General',
    'Toshiba',
    'Mitsubishi',
    'Onida',
    'TCL',
    'Sansui',
    'Other',
  ];

  final List<String> _acAges = [
    'Less than 1 year',
    '1–2 years',
    '3–5 years',
    '6–10 years',
    'More than 10 years',
    'Not sure',
  ];

  @override
  void initState() {
    super.initState();
    _problemController.addListener(_onTextChanged);
    _loadCachedDraft();
  }

  void _loadCachedDraft() {
    final cached = ACIssueBookingService.instance.loadDraft();
    if (cached != null) {
      setState(() {
        if (cached['ac_type'] != null) _selectedAcType = cached['ac_type'] as String;
        if (cached['ac_brand'] != null) _selectedAcBrand = cached['ac_brand'] as String;
        if (cached['ac_age'] != null) _selectedAcAge = cached['ac_age'] as String;
        if (cached['problem_description'] != null) {
          final desc = cached['problem_description'] as String;
          _problemController.text = desc;
          _charCount = desc.length;
        }
      });
    }
  }

  void _onTextChanged() {
    final length = _problemController.text.length;
    setState(() {
      _charCount = length;
      if (_hasDescriptionError && length >= 10) {
        _hasDescriptionError = false;
      }
    });
    _autoSaveDraft();
  }

  void _autoSaveDraft() {
    final draft = {
      'service_name': widget.serviceName ?? 'AC Service & Repair',
      'service_price': widget.servicePrice ?? 499.0,
      'ac_type': _selectedAcType,
      'ac_brand': _selectedAcBrand,
      'problem_description': _problemController.text.trim(),
      'ac_age': _selectedAcAge,
      'status': 'DRAFT_ISSUE_DETAILS',
      'updated_at': DateTime.now().toIso8601String(),
    };
    ACIssueBookingService.instance.saveDraft(draft);
  }

  @override
  void dispose() {
    _problemController.removeListener(_onTextChanged);
    _problemController.dispose();
    _problemFocusNode.dispose();
    super.dispose();
  }

  // --- Photo Management & Permissions ---

  Future<void> _takePhoto() async {
    if (_selectedPhotos.length >= 5) {
      _showWarningSnackBar('You can upload a maximum of 5 photos.');
      return;
    }

    final status = await Permission.camera.request();
    if (status.isGranted) {
      try {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
          maxWidth: 1400,
        );
        if (photo != null) {
          setState(() {
            _selectedPhotos.add(File(photo.path));
          });
        }
      } catch (e) {
        _showWarningSnackBar('Could not capture image: $e');
      }
    } else if (status.isPermanentlyDenied) {
      _showPermissionDialog('Camera permission is required to capture photos of your AC issue.');
    } else {
      _showWarningSnackBar('Camera permission is needed to take a photo.');
    }
  }

  Future<void> _chooseFromGallery() async {
    if (_selectedPhotos.length >= 5) {
      _showWarningSnackBar('You can upload a maximum of 5 photos.');
      return;
    }

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 80,
        maxWidth: 1400,
      );
      if (images.isNotEmpty) {
        final availableSlots = 5 - _selectedPhotos.length;
        final imagesToAdd = images.take(availableSlots).map((x) => File(x.path)).toList();
        setState(() {
          _selectedPhotos.addAll(imagesToAdd);
        });

        if (images.length > availableSlots) {
          _showWarningSnackBar('Only $availableSlots photo(s) added to stay within the 5 photo limit.');
        }
      }
    } catch (e) {
      _showWarningSnackBar('Could not select photos: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  void _showPermissionDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // --- Modal Pickers ---

  void _showAcTypePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Text(
                  'Select Type of AC',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              const Divider(),
              ..._acTypes.map((type) {
                final isSelected = _selectedAcType == type;
                return ListTile(
                  leading: Icon(
                    Icons.ac_unit_rounded,
                    color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF64748B),
                  ),
                  title: Text(
                    type,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF0F172A),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF3B49DF))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedAcType = type;
                    });
                    _autoSaveDraft();
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showBrandSearchPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) {
        String searchQuery = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filtered = _acBrands
                .where((b) => b.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                    child: Text(
                      'Select Company / Brand',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        autofocus: false,
                        decoration: const InputDecoration(
                          hintText: 'Search AC brand (e.g. Voltas, Daikin, LG)...',
                          hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                          border: InputBorder.none,
                        ),
                        onChanged: (val) {
                          setModalState(() {
                            searchQuery = val;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, idx) {
                        final brand = filtered[idx];
                        final isSelected = _selectedAcBrand == brand;
                        return ListTile(
                          leading: const Icon(Icons.business_rounded, color: Color(0xFF64748B), size: 20),
                          title: Text(
                            brand,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF0F172A),
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_circle_rounded, color: Color(0xFF3B49DF))
                              : null,
                          onTap: () {
                            setState(() {
                              _selectedAcBrand = brand;
                            });
                            _autoSaveDraft();
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showAcAgePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Text(
                  'How old is your AC?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
              const Divider(),
              ..._acAges.map((age) {
                final isSelected = _selectedAcAge == age;
                return ListTile(
                  leading: Icon(
                    Icons.calendar_today_rounded,
                    color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF64748B),
                  ),
                  title: Text(
                    age,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF0F172A),
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(Icons.check_circle_rounded, color: Color(0xFF3B49DF))
                      : null,
                  onTap: () {
                    setState(() {
                      _selectedAcAge = age;
                    });
                    _autoSaveDraft();
                    Navigator.pop(ctx);
                  },
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // --- Validation and Submission ---
  Future<void> _handleNext() async {
    // 1. AC Type validation
    if (_selectedAcType == null || _selectedAcType!.isEmpty) {
      _showWarningSnackBar('Please select your Type of AC.');
      return;
    }

    // 2. AC Brand validation
    if (_selectedAcBrand == null || _selectedAcBrand!.isEmpty) {
      _showWarningSnackBar('Please select or search Company / Brand.');
      return;
    }

    // 3. Problem description validation (min 10 chars, max 500 chars)
    final text = _problemController.text.trim();
    if (text.length < 10) {
      setState(() {
        _hasDescriptionError = true;
      });
      _showWarningSnackBar('Please describe the problem in at least 10 characters.');
      return;
    }

    // 4. Photo upload validation (at least 1 photo required)
    if (_selectedPhotos.isEmpty) {
      _showWarningSnackBar('Please upload at least one photo of the problem.');
      return;
    }

    // 5. AC Age validation
    if (_selectedAcAge == null || _selectedAcAge!.isEmpty) {
      _showWarningSnackBar('Please select how old your AC is.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Upload photos to Supabase Storage
      final photoUrls = await ACIssueBookingService.instance.uploadPhotos(_selectedPhotos);

      // 2. Save issue details to local draft (No database commit yet!)
      final draftRecord = await ACIssueBookingService.instance.saveACIssueDetails(
        acType: _selectedAcType!,
        acBrand: _selectedAcBrand!,
        problemDescription: text,
        acAge: _selectedAcAge!,
        photoUrls: photoUrls,
        serviceName: widget.serviceName,
        servicePrice: widget.servicePrice,
      );

      if (!mounted) return;

      // 3. Navigate to Page 2: ACServiceOverviewScreen ("We'll keep you cool & comfortable")
      final result = await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => ACServiceOverviewScreen(issueDetails: draftRecord),
        ),
      );

      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        _showWarningSnackBar('Failed to save details: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
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
        title: const Text(
          'AC Service',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          // "Need Help?" AI Chatbot button
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InkWell(
              onTap: () => ACServiceAIChatbotSheet.show(context),
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
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B49DF),
                      ),
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Hero Banner (Matching Image 1)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFF1F5F9), Color(0xFFEFF6FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          // AC Unit Icon Badge
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 56,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFE2E8F0)),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.04),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(Icons.air_rounded, color: Color(0xFF3B49DF), size: 28),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF3B49DF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.ac_unit_rounded, color: Colors.white, size: 12),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Let's fix your AC",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Please provide accurate details so we can assign the right expert for you.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF64748B),
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // FIELD 1 — 1. Type of AC *
                    _buildSectionHeader('1. Type of AC *'),
                    const SizedBox(height: 8),
                    _buildSelectorCard(
                      icon: Icons.air_rounded,
                      text: _selectedAcType ?? 'Select AC Type',
                      isSelected: _selectedAcType != null,
                      onTap: _showAcTypePicker,
                    ),

                    const SizedBox(height: 18),

                    // FIELD 2 — 2. Company / Brand *
                    _buildSectionHeader('2. Company / Brand *'),
                    const SizedBox(height: 8),
                    _buildSelectorCard(
                      icon: Icons.business_rounded,
                      text: _selectedAcBrand ?? 'Select Company / Brand',
                      isSelected: _selectedAcBrand != null,
                      onTap: _showBrandSearchPicker,
                    ),

                    const SizedBox(height: 18),

                    // FIELD 3 — 3. Describe the problem * (0/500 live counter, max 500 hard cap)
                    _buildSectionHeader('3. Describe the problem *'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _hasDescriptionError
                              ? const Color(0xFFDC2626)
                              : (_problemFocusNode.hasFocus ? const Color(0xFF3B49DF) : const Color(0xFFE2E8F0)),
                          width: (_hasDescriptionError || _problemFocusNode.hasFocus) ? 1.5 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _hasDescriptionError
                                ? const Color(0xFFDC2626).withValues(alpha: 0.08)
                                : (_problemFocusNode.hasFocus
                                    ? const Color(0xFF3B49DF).withValues(alpha: 0.06)
                                    : Colors.black.withValues(alpha: 0.02)),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.edit_outlined,
                                    color: _problemFocusNode.hasFocus ? const Color(0xFF3B49DF) : const Color(0xFF64748B),
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _problemController,
                                    focusNode: _problemFocusNode,
                                    minLines: 3,
                                    maxLines: 5,
                                    maxLength: 500,
                                    maxLengthEnforcement: MaxLengthEnforcement.enforced,
                                    textCapitalization: TextCapitalization.sentences,
                                    style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A), height: 1.45),
                                    decoration: const InputDecoration(
                                      hintText: 'Describe the issue in short (max 500 characters)',
                                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      counterText: '',
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Live Character Counter: 0/500
                          Align(
                            alignment: Alignment.bottomRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 14, bottom: 10, top: 4),
                              child: Text(
                                '$_charCount/500',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: _charCount >= 500 ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // FIELD 4 — 4. Upload photos of the problem *
                    _buildSectionHeader('4. Upload photos of the problem *'),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC7D2FE), style: BorderStyle.solid),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEEF2FF),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.add_a_photo_outlined, color: Color(0xFF3B49DF), size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Add clear photos',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Upload photos that show the issue clearly\n(e.g., AC indoor unit, outdoor unit, error, leakage, etc.)',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.25),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Dual Buttons: Take Photo & Choose from Gallery
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF3B49DF)),
                                  label: const Text(
                                    'Take Photo',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF3B49DF)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    side: const BorderSide(color: Color(0xFFC7D2FE)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: _takePhoto,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.photo_library_outlined, size: 16, color: Color(0xFF3B49DF)),
                                  label: const Text(
                                    'Choose from Gallery',
                                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF3B49DF)),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    side: const BorderSide(color: Color(0xFFC7D2FE)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: _chooseFromGallery,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Photo limit helper info
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                        SizedBox(width: 4),
                        Text(
                          'You can upload up to 5 photos',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),

                    // Thumbnails list with Delete Badge and "+ Add More" Button
                    if (_selectedPhotos.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 80,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedPhotos.length + (_selectedPhotos.length < 5 ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            if (index == _selectedPhotos.length && _selectedPhotos.length < 5) {
                              // "+ Add More" Button
                              return InkWell(
                                onTap: _chooseFromGallery,
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFC7D2FE)),
                                  ),
                                  child: const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_circle, color: Color(0xFF3B49DF), size: 24),
                                      SizedBox(height: 4),
                                      Text(
                                        'Add More',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF3B49DF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final file = _selectedPhotos[index];
                            return Stack(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFE2E8F0)),
                                    image: DecorationImage(
                                      image: FileImage(file),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: GestureDetector(
                                    onTap: () => _removePhoto(index),
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: const BoxDecoration(
                                        color: Colors.black54,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],

                    const SizedBox(height: 18),

                    // FIELD 5 — 5. How old is your AC? *
                    _buildSectionHeader('5. How old is your AC? *'),
                    const SizedBox(height: 8),
                    _buildSelectorCard(
                      icon: Icons.calendar_today_rounded,
                      text: _selectedAcAge ?? 'Select Age',
                      isSelected: _selectedAcAge != null,
                      onTap: _showAcAgePicker,
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),

            // Bottom Navigation Bar with Next Button & Security Note
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B49DF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      onPressed: _isSubmitting ? null : _handleNext,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Next',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_rounded, size: 14, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        'Your information is safe and secure with us.',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14.5,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildSelectorCard({
    required IconData icon,
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF3B49DF), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                ),
              ),
            ),
            const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B), size: 22),
          ],
        ),
      ),
    );
  }
}
