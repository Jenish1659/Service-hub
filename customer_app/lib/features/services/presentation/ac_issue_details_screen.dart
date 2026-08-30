import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_theme.dart';
import '../services/ac_booking_service.dart';
import 'ac_service_ai_chatbot_sheet.dart';
import 'ac_date_time_selection_screen.dart';

class ACIssueDetailsScreen extends ConsumerStatefulWidget {
  final String? serviceName;
  final double? servicePrice;

  const ACIssueDetailsScreen({
    super.key,
    this.serviceName = 'AC Service & Repair',
    this.servicePrice = 499.0,
  });

  @override
  ConsumerState<ACIssueDetailsScreen> createState() => _ACIssueDetailsScreenState();
}

class _ACIssueDetailsScreenState extends ConsumerState<ACIssueDetailsScreen> {
  final TextEditingController _problemController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  String? _selectedAcType;
  String? _selectedAcBrand;
  String? _selectedAcAge;
  final List<File> _selectedPhotos = [];
  bool _isSubmitting = false;

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
    'Mitsubishi Electric',
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
  void dispose() {
    _problemController.dispose();
    super.dispose();
  }

  // --- Photo Pickers with Permission Handling ---
  Future<void> _takePhoto() async {
    if (_selectedPhotos.length >= 5) {
      _showWarningSnackBar('You can upload a maximum of 5 photos.');
      return;
    }

    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      _showPermissionDialog('Camera Permission', 'Please enable camera access in settings to capture AC photos.');
      return;
    }

    if (status.isGranted || status.isLimited) {
      try {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
          maxWidth: 1600,
        );
        if (photo != null && mounted) {
          setState(() {
            _selectedPhotos.add(File(photo.path));
          });
        }
      } catch (e) {
        _showWarningSnackBar('Could not open camera: $e');
      }
    } else {
      _showWarningSnackBar('Camera permission is required to take photos.');
    }
  }

  Future<void> _chooseFromGallery() async {
    if (_selectedPhotos.length >= 5) {
      _showWarningSnackBar('You can upload a maximum of 5 photos.');
      return;
    }

    // Attempt gallery selection
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1600,
      );
      if (images.isNotEmpty && mounted) {
        setState(() {
          for (final img in images) {
            if (_selectedPhotos.length < 5) {
              _selectedPhotos.add(File(img.path));
            }
          }
        });
      }
    } catch (e) {
      // Fallback to single image pick
      try {
        final XFile? img = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (img != null && mounted) {
          setState(() {
            if (_selectedPhotos.length < 5) {
              _selectedPhotos.add(File(img.path));
            }
          });
        }
      } catch (err) {
        _showWarningSnackBar('Could not open photo gallery: $err');
      }
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  void _showPermissionDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B49DF)),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Open Settings', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- AC Type Bottom Sheet Picker ---
  void _showAcTypePicker() {
    showModalBottomSheet(
      context: context,
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
                  'Select AC Type',
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

  // --- Searchable Brand Picker Bottom Sheet ---
  void _showBrandSearchPicker() {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredBrands = _acBrands
                .where((b) => b.toLowerCase().contains(searchQuery.toLowerCase()))
                .toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCBD5E1),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select AC Brand / Company',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            autofocus: false,
                            decoration: const InputDecoration(
                              hintText: 'Search AC brand (e.g. Voltas, Daikin, LG)...',
                              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                            ),
                            onChanged: (val) {
                              setModalState(() {
                                searchQuery = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredBrands.length,
                      itemBuilder: (context, index) {
                        final brand = filteredBrands[index];
                        final isSelected = _selectedAcBrand == brand;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEEF2FF) : const Color(0xFFF8FAFC),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: isSelected ? const Color(0xFF3B49DF) : const Color(0xFF64748B),
                              size: 20,
                            ),
                          ),
                          title: Text(
                            brand,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
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

  // --- AC Age Picker Bottom Sheet ---
  void _showAcAgePicker() {
    showModalBottomSheet(
      context: context,
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
                  'Select AC Age (Approx.)',
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
      _showWarningSnackBar('Please select your AC Type.');
      return;
    }

    // 2. AC Brand validation
    if (_selectedAcBrand == null || _selectedAcBrand!.isEmpty) {
      _showWarningSnackBar('Please select or search your AC Brand / Company.');
      return;
    }

    // 3. Problem description validation (min 50 chars, max 500 chars)
    final text = _problemController.text.trim();
    if (text.length < 50) {
      _showWarningSnackBar('Please describe the problem in a little more detail.');
      return;
    }

    // 4. Photo upload validation (at least 1 photo required)
    if (_selectedPhotos.isEmpty) {
      _showWarningSnackBar('Please upload at least one photo of your AC or the problem.');
      return;
    }

    // 5. AC Age validation
    if (_selectedAcAge == null || _selectedAcAge!.isEmpty) {
      _showWarningSnackBar('Please select approximate AC Age.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // 1. Upload photos to Supabase Storage
      final photoUrls = await ACIssueBookingService.instance.uploadPhotos(_selectedPhotos);

      // 2. Save issue details in database / local cache
      final bookingDraft = await ACIssueBookingService.instance.saveACIssueDetails(
        acType: _selectedAcType!,
        acBrand: _selectedAcBrand!,
        problemDescription: text,
        acAge: _selectedAcAge!,
        photoUrls: photoUrls,
        serviceName: widget.serviceName,
        servicePrice: widget.servicePrice,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ AC issue details saved successfully! Proceeding to next step.'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Successfully saved! Navigate to Date & Time Selection screen with real issue data
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ACDateTimeSelectionScreen(issueDetails: bookingDraft),
        ),
      );
      if (result != null && mounted) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        _showWarningSnackBar('Failed to save issue details: $e');
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
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner with AC Unit Illustration (Matches Reference Design)
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tell us about your AC',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Please provide accurate details so we can assign the right expert for you.',
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Color(0xFF64748B),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // AC Unit Illustration with Snowflake
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 80,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 50,
                                height: 3,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCBD5E1),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: 64,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Color(0xFF38BDF8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.ac_unit, color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // 1. AC Type *
              _buildFieldLabel('1. AC Type *'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _showAcTypePicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.air_rounded, color: Color(0xFF3B49DF), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedAcType ?? 'Select AC Type',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedAcType != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            fontWeight: _selectedAcType != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 2. AC Brand / Company *
              _buildFieldLabel('2. AC Brand / Company *'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _showBrandSearchPicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.storefront_rounded, color: Color(0xFF3B49DF), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedAcBrand ?? 'Search or select brand',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedAcBrand != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            fontWeight: _selectedAcBrand != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // 3. Describe the Problem *
              _buildFieldLabel('3. Describe the Problem *'),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.edit_outlined, color: Color(0xFF3B49DF), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _problemController,
                            maxLength: 500,
                            maxLines: 4,
                            minLines: 3,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            decoration: const InputDecoration(
                              hintText: 'Please describe the problem in detail.\n(For example: AC is not cooling, making noise, water leaking etc.)',
                              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8), height: 1.4),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            onChanged: (_) {
                              setState(() {});
                            },
                          ),
                        ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Text(
                        '${_problemController.text.length}/500',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF94A3B8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 4. Upload AC / Problem Photo *
              _buildFieldLabel('4. Upload AC / Problem Photo *'),
              const SizedBox(height: 6),
              _buildPhotoUploadBox(),

              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF64748B)),
                  SizedBox(width: 6),
                  Text(
                    'You can upload up to 5 photos',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),

              // Thumbnails preview if photos selected
              if (_selectedPhotos.isNotEmpty) ...[
                const SizedBox(height: 10),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _selectedPhotos.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _selectedPhotos[index],
                              width: 72,
                              height: 72,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFDC2626),
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

              // 5. AC Age (Approx.) *
              _buildFieldLabel('5. AC Age (Approx.) *'),
              const SizedBox(height: 6),
              InkWell(
                onTap: _showAcAgePicker,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Color(0xFF3B49DF), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedAcAge ?? 'Select AC Age',
                          style: TextStyle(
                            fontSize: 14,
                            color: _selectedAcAge != null ? const Color(0xFF0F172A) : const Color(0xFF94A3B8),
                            fontWeight: _selectedAcAge != null ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Next Button (Solid Vibrant Blue)
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

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildPhotoUploadBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFC7D2FE),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: Column(
        children: [
          // Circular camera icon
          Container(
            width: 54,
            height: 54,
            decoration: const BoxDecoration(
              color: Color(0xFFEEF2FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_a_photo_outlined,
              color: Color(0xFF3B49DF),
              size: 26,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Add Photos',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Upload clear photos of your AC\nor the problem.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          // Two Action Buttons: Take Photo & Choose from Gallery
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.camera_alt_outlined, size: 18, color: Color(0xFF3B49DF)),
                  label: const Text(
                    'Take Photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B49DF),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _takePhoto,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.photo_library_outlined, size: 18, color: Color(0xFF3B49DF)),
                  label: const Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3B49DF),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _chooseFromGallery,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
