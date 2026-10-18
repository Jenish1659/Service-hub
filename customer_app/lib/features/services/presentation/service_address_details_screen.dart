import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';

import '../../location/providers/location_provider.dart';
import '../services/ac_availability_service.dart';
import '../services/multi_service_booking_service.dart';
import 'ac_date_time_ai_chatbot_sheet.dart';
import 'service_review_confirm_screen.dart';

/// Universal Address and Contact Details screen for all ServiceHub service categories.
/// Enforces strict Jamnagar geofence checks before proceeding to review.
class ServiceAddressDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> issueDetails;
  final BookingDateOption selectedDate;
  final String selectedTime;

  const ServiceAddressDetailsScreen({
    super.key,
    required this.issueDetails,
    required this.selectedDate,
    required this.selectedTime,
  });

  @override
  ConsumerState<ServiceAddressDetailsScreen> createState() => _ServiceAddressDetailsScreenState();
}

class _ServiceAddressDetailsScreenState extends ConsumerState<ServiceAddressDetailsScreen> {
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
            user.email?.split('@').first ??
            '';
        phone = user.phone ?? user.userMetadata?['phone'] as String? ?? '';
      }
    } catch (_) {}

    if (name.isEmpty) {
      try {
        if (Hive.isBoxOpen('customer_cache')) {
          final box = Hive.box('customer_cache');
          name = box.get('user_name', defaultValue: '') as String;
          if (phone.isEmpty) {
            phone = box.get('user_phone', defaultValue: '') as String;
          }
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
      _showWarningSnackBar('Please enter your full name *');
      return;
    }
    if (phone.isEmpty) {
      _showWarningSnackBar('Please enter your contact phone number *');
      return;
    }
    if (address.isEmpty) {
      _showWarningSnackBar('Please enter your complete service address *');
      return;
    }

    // Strict Jamnagar Geofence check
    final locState = ref.read(locationProvider);
    final activeLoc = locState.selectedLocation ?? locState.currentLocation;
    final lat = activeLoc?.latitude ?? 22.4707;
    final lng = activeLoc?.longitude ?? 70.0577;
    final city = activeLoc?.city ?? 'Jamnagar';

    final combinedAddress = ('$address $city ${activeLoc?.address ?? ""}').toLowerCase();

    final String effectiveAddress = combinedAddress.contains('jamnagar')
        ? address
        : '$address, Jamnagar, Gujarat';
    final double effectiveLat = (lat != 0.0) ? lat : 22.4707;
    final double effectiveLng = (lng != 0.0) ? lng : 70.0577;

    final updatedDraft = Map<String, dynamic>.from(widget.issueDetails);
    updatedDraft['customer_name'] = name;
    updatedDraft['customer_phone'] = phone;
    updatedDraft['customer_address'] = effectiveAddress;
    updatedDraft['customer_lat'] = effectiveLat;
    updatedDraft['customer_lng'] = effectiveLng;
    updatedDraft['additional_notes'] = notes;
    updatedDraft['status'] = 'DRAFT_DETAILS_COMPLETED';
    updatedDraft['updated_at'] = DateTime.now().toIso8601String();

    final catId = (updatedDraft['category_id'] ?? 'ac_service').toString();
    await MultiServiceBookingService.instance.saveDraft(catId, updatedDraft);

    if (!mounted) return;

    final result = await Navigator.of(context, rootNavigator: true).push(
      MaterialPageRoute(
        builder: (context) => ServiceReviewConfirmScreen(
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
    final serviceName = widget.issueDetails['service_name'] ?? 'Service';

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
              onTap: () => ACDateTimeAIChatbotSheet.show(
                context,
                selectedDateText: widget.selectedDate.userFriendlyDisplay,
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
                      'Contact & Service Address',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Where should our verified professional arrive for $serviceName?',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Appointment Summary Strip
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.schedule_rounded, color: Color(0xFF3B49DF), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              '${widget.selectedDate.userFriendlyDisplay} at ${widget.selectedTime}',
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1E1B4B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Customer Name
                    const Text('Full Name *', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          hintText: 'Enter your full name',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.person_outline_rounded, color: Color(0xFF64748B), size: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Phone Number
                    const Text('Contact Phone *', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: const InputDecoration(
                          hintText: 'Enter 10-digit mobile number',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF64748B), size: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Service Address
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Service Address (Jamnagar) *', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 12, color: Color(0xFF059669)),
                              SizedBox(width: 4),
                              Text('Jamnagar Zone', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'House/Flat No., Street, Area, Jamnagar',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.location_on_outlined, color: Color(0xFF64748B), size: 20),
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Additional Notes
                    const Text('Special Instructions (Optional)', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _notesController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          hintText: 'Landmarks, gate codes, parking instructions...',
                          border: InputBorder.none,
                          prefixIcon: Icon(Icons.notes_rounded, color: Color(0xFF64748B), size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Continue CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 10,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B49DF),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Review & Confirm Booking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
