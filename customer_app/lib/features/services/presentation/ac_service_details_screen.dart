import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

import '../../location/providers/location_provider.dart';
import '../services/ac_availability_service.dart';
import '../services/ac_booking_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';
import 'ac_review_confirm_screen.dart';

class ACServiceDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> issueDetails;
  final BookingDateOption selectedDate;
  final String selectedTime;

  const ACServiceDetailsScreen({
    super.key,
    required this.issueDetails,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  ConsumerState<ACServiceDetailsScreen> createState() => _ACServiceDetailsScreenState();
}

class _ACServiceDetailsScreenState extends ConsumerState<ACServiceDetailsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initUserData();
  }

  void _initUserData() {
    String name = '';
    String phone = '';
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user != null) {
        name = user.userMetadata?['name'] as String? ?? 
               user.userMetadata?['full_name'] as String? ?? 
               user.email?.split('@').first ?? '';
        phone = user.phone ?? user.userMetadata?['phone'] as String? ?? '';
      }
    } catch (_) {}

    if (name.isEmpty) {
      try {
        final box = Hive.box('customer_cache');
        name = box.get('user_name', defaultValue: '') as String;
        if (phone.isEmpty) {
          phone = box.get('user_phone', defaultValue: '') as String;
        }
      } catch (_) {}
    }

    final locState = ref.read(locationProvider);
    final activeLocation = locState.selectedLocation ?? locState.currentLocation;
    final address = activeLocation?.address ?? '';

    if (widget.issueDetails['customer_name'] != null &&
        (widget.issueDetails['customer_name'] as String).isNotEmpty) {
      name = widget.issueDetails['customer_name'] as String;
    }
    if (widget.issueDetails['customer_phone'] != null &&
        (widget.issueDetails['customer_phone'] as String).isNotEmpty) {
      phone = widget.issueDetails['customer_phone'] as String;
    }
    if (widget.issueDetails['customer_address'] != null &&
        (widget.issueDetails['customer_address'] as String).isNotEmpty) {
      _addressController.text = widget.issueDetails['customer_address'] as String;
    } else {
      _addressController.text = address;
    }

    _nameController.text = name;
    _phoneController.text = phone;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
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
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final address = _addressController.text.trim();
    final notes = _notesController.text.trim();

    if (name.isEmpty) {
      _showWarningSnackBar('Please enter your full name *.');
      return;
    }
    if (phone.isEmpty) {
      _showWarningSnackBar('Please enter your contact phone number *.');
      return;
    }
    if (address.isEmpty) {
      _showWarningSnackBar('Please enter your complete address *.');
      return;
    }

    final updatedDraft = Map<String, dynamic>.from(widget.issueDetails);
    updatedDraft['customer_name'] = name;
    updatedDraft['customer_phone'] = phone;
    updatedDraft['customer_address'] = address;
    updatedDraft['additional_notes'] = notes;
    updatedDraft['status'] = 'DRAFT_DETAILS_COMPLETED';
    updatedDraft['updated_at'] = DateTime.now().toIso8601String();

    await ACIssueBookingService.instance.saveDraft(updatedDraft);

    if (!mounted) return;

    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ACReviewConfirmScreen(
          issueDetails: updatedDraft,
          selectedDate: widget.selectedDate,
          selectedTime: widget.selectedTime,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      resizeToAvoidBottomInset: true,
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
              onTap: () => ACDateTimeAIChatbotSheet.show(
                context,
                selectedDateText: '${widget.selectedDate.dayName}, ${widget.selectedDate.dateNumber} ${widget.selectedDate.monthName}',
                selectedTimeText: widget.selectedTime,
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Title & Subtitle (Matching Screen 4 Reference)
              const Text(
                'Service Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Tell us a few details',
                style: TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 20),

              // Full Name Card
              _buildInputField(
                controller: _nameController,
                label: 'Full Name *',
                hintText: 'Enter your full name',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
              ),

              const SizedBox(height: 14),

              // Phone Number Card
              _buildInputField(
                controller: _phoneController,
                label: 'Phone Number *',
                hintText: 'Enter 10-digit phone number',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),

              const SizedBox(height: 14),

              // Complete Address Card
              _buildInputField(
                controller: _addressController,
                label: 'Complete Address *',
                hintText: 'Enter complete service address',
                icon: Icons.location_on_outlined,
                maxLines: 2,
                keyboardType: TextInputType.streetAddress,
              ),

              const SizedBox(height: 14),

              // Additional Notes (Optional) Card
              _buildInputField(
                controller: _notesController,
                label: 'Additional Notes (Optional)',
                hintText: 'e.g., Gate code, floor number, etc.',
                icon: Icons.notes_rounded,
                maxLines: 2,
              ),

              const SizedBox(height: 32),

              // Continue Button
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
                  onPressed: _handleContinue,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continue',
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

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: maxLines > 1 ? 4 : 0),
            child: Icon(icon, color: const Color(0xFF64748B), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                TextField(
                  controller: controller,
                  maxLines: maxLines,
                  keyboardType: keyboardType,
                  maxLength: keyboardType == TextInputType.phone ? 10 : null,
                  buildCounter: keyboardType == TextInputType.phone
                      ? (context, {required currentLength, required isFocused, maxLength}) => null
                      : null,
                  inputFormatters: keyboardType == TextInputType.phone
                      ? [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ]
                      : null,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: hintText ?? label,
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
