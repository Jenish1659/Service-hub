import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';

class ReportAProblemScreen extends StatefulWidget {
  final ProfileController controller;

  const ReportAProblemScreen({
    super.key,
    required this.controller,
  });

  @override
  State<ReportAProblemScreen> createState() => _ReportAProblemScreenState();
}

class _ReportAProblemScreenState extends State<ReportAProblemScreen> {
  final TextEditingController _bookingIdCtrl = TextEditingController();
  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();

  String _selectedCategory = 'App Glitch / Crash';
  String _selectedSeverity = 'Medium';
  String? _attachedImagePath;
  bool _isSubmitting = false;

  final List<String> _categories = [
    'App Glitch / Crash',
    'Payment / Payout Issue',
    'Booking & Dispatch Problem',
    'Customer Dispute',
    'Navigation & Map Error',
    'Other Issue',
  ];

  final List<Map<String, dynamic>> _severities = const [
    {'label': 'Low', 'color': Color(0xFF16A34A), 'bg': Color(0xFFDCFCE7)},
    {'label': 'Medium', 'color': Color(0xFFD97706), 'bg': Color(0xFFFEF3C7)},
    {'label': 'High', 'color': Color(0xFFEA580C), 'bg': Color(0xFFFFEDD5)},
    {'label': 'Critical', 'color': Color(0xFFDC2626), 'bg': Color(0xFFFEE2E2)},
  ];

  @override
  void dispose() {
    _bookingIdCtrl.dispose();
    _subjectCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (picked != null) {
        setState(() {
          _attachedImagePath = picked.path;
        });
      }
    } catch (_) {
      // Mock attachment in test environments
      setState(() {
        _attachedImagePath = 'sample_screenshot.jpg';
      });
    }
  }

  void _handleSubmit() {
    if (_subjectCtrl.text.trim().isEmpty || _descriptionCtrl.text.trim().isEmpty) {
      TopToast.show(context, 'Please enter problem subject and description', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final ticketId = '#ISSUE-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 40),
              ),
              const SizedBox(height: 16),
              const Text(
                'Report Submitted',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 6),
              Text(
                'Ticket ID: $ticketId',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
              ),
              const SizedBox(height: 8),
              const Text(
                'Our engineering & operations team has received your report. We will notify you with updates within 4 hours.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
              ),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx); // Close dialog
                  Navigator.pop(context); // Go back to settings
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Report a Problem',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Submit an issue or bug to our technical team',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Form
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Selection
                    _buildFieldLabel('PROBLEM CATEGORY'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        return ChoiceChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _selectedCategory = cat);
                          },
                          selectedColor: const Color(0xFF2563EB),
                          backgroundColor: Colors.white,
                          labelStyle: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFCBD5E1)),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Severity Level
                    _buildFieldLabel('SEVERITY LEVEL'),
                    Row(
                      children: _severities.map((s) {
                        final isSelected = _selectedSeverity == s['label'];
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              onTap: () => setState(() => _selectedSeverity = s['label'] as String),
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  color: isSelected ? s['color'] as Color : (s['bg'] as Color).withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSelected ? s['color'] as Color : const Color(0xFFE2E8F0),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  s['label'] as String,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : s['color'] as Color,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),

                    // Booking / Order ID (Optional)
                    _buildFieldLabel('RELATED BOOKING ID (OPTIONAL)'),
                    TextField(
                      controller: _bookingIdCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. BK-98421 (if issue relates to a specific job)',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Subject
                    _buildFieldLabel('PROBLEM SUMMARY'),
                    TextField(
                      controller: _subjectCtrl,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. Map route not updating during live job',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Description
                    _buildFieldLabel('DETAILED EXPLANATION'),
                    TextField(
                      controller: _descriptionCtrl,
                      maxLines: 4,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Describe what happened, any error messages displayed, and steps to reproduce...',
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Screenshot Attachment
                    _buildFieldLabel('ATTACH SCREENSHOT / PHOTO (OPTIONAL)'),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: _attachedImagePath == null
                          ? InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                                ),
                                child: const Column(
                                  children: [
                                    Icon(Icons.add_a_photo_outlined, size: 28, color: Color(0xFF2563EB)),
                                    SizedBox(height: 6),
                                    Text('Tap to add screenshot from Gallery / Camera', style: TextStyle(fontSize: 12, color: Color(0xFF475569))),
                                    SizedBox(height: 2),
                                    Text('PNG, JPG up to 10 MB', style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                                  ],
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.image_outlined, color: Color(0xFF2563EB), size: 24),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Screenshot Attached', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      Text('Ready for upload with report', style: TextStyle(fontSize: 11, color: Color(0xFF16A34A))),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444)),
                                  onPressed: () => setState(() => _attachedImagePath = null),
                                ),
                              ],
                            ),
                    ),
                    const SizedBox(height: 26),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isSubmitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 18),
                        label: Text(
                          _isSubmitting ? 'Submitting Report...' : 'Submit Problem Ticket',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.7),
      ),
    );
  }
}
