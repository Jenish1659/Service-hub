import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_location_model.dart';
import '../models/location_model.dart';
import '../services/location_api_service.dart';
import '../../../../core/theme/app_theme.dart';

class BookForSomeoneElseSheet extends StatefulWidget {
  final LocationModel location;
  final Function(CustomerLocationModel recipientLocation) onSave;

  const BookForSomeoneElseSheet({
    super.key,
    required this.location,
    required this.onSave,
  });

  @override
  State<BookForSomeoneElseSheet> createState() => _BookForSomeoneElseSheetState();
}

class _BookForSomeoneElseSheetState extends State<BookForSomeoneElseSheet> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();

  AddressType _selectedTag = AddressType.home;
  bool _isForSomeoneElse = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _landmarkController.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final apiService = LocationApiService();
      final existing = await apiService.getAllSavedLocations();
      if (existing.length >= 10) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Maximum limit of 10 saved contacts/addresses reached. Please remove an existing address first.'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? 'cust_${DateTime.now().millisecondsSinceEpoch}';

      final savedLoc = CustomerLocationModel(
        id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
        customerId: userId,
        latitude: widget.location.latitude,
        longitude: widget.location.longitude,
        address: widget.location.address,
        area: widget.location.area,
        city: widget.location.city,
        state: widget.location.state,
        country: widget.location.country,
        postalCode: widget.location.postalCode,
        addressType: _selectedTag,
        isForSomeoneElse: _isForSomeoneElse,
        recipientName: _isForSomeoneElse ? _nameController.text.trim() : null,
        recipientPhone: _isForSomeoneElse ? _phoneController.text.trim() : null,
        houseNumber: _houseController.text.trim(),
        landmark: _landmarkController.text.trim(),
        createdAt: DateTime.now(),
      );

      widget.onSave(savedLoc);
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xffcbd5e1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Save Address & Contact Details',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.location.area}, ${widget.location.city}',
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 16),

              // Booking for someone else toggle card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xffeff6ff),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffbfdbfe)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_pin_circle, color: AppTheme.primaryColor, size: 22),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking for Someone Else?',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff0f172a)),
                          ),
                          Text(
                            'Share service updates & OTP with recipient',
                            style: TextStyle(fontSize: 11, color: Color(0xff64748b)),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isForSomeoneElse,
                      activeTrackColor: AppTheme.primaryColor,
                      onChanged: (val) {
                        setState(() {
                          _isForSomeoneElse = val;
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_isForSomeoneElse) ...[
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Recipient Full Name *',
                    hintText: 'e.g. Ramesh Kumar (Father / Friend)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.person, color: Color(0xff64748b)),
                  ),
                  validator: (val) {
                    if (_isForSomeoneElse && (val == null || val.trim().isEmpty)) {
                      return 'Please enter recipient name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Recipient Mobile Number *',
                    hintText: '10-digit phone number',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.phone_android, color: Color(0xff64748b)),
                  ),
                  validator: (val) {
                    if (_isForSomeoneElse) {
                      if (val == null || val.trim().isEmpty) return 'Please enter recipient phone number';
                      if (val.trim().length < 10) return 'Enter valid 10-digit phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
              ],

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _houseController,
                      decoration: InputDecoration(
                        labelText: 'House / Flat / Floor *',
                        hintText: 'Flat 402, Block B',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Required';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _landmarkController,
                      decoration: InputDecoration(
                        labelText: 'Landmark (Optional)',
                        hintText: 'Near City Mall',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text(
                'Save Address As',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
              ),
              const SizedBox(height: 8),

              // Address Tag Chips
              Wrap(
                spacing: 8,
                children: AddressType.values.map((tag) {
                  final isSelected = _selectedTag == tag;
                  return ChoiceChip(
                    label: Text(
                      tag.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : const Color(0xff64748b),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: AppTheme.primaryColor,
                    backgroundColor: const Color(0xfff1f5f9),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedTag = tag;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submitForm,
                  child: const Text(
                    'Save Address & Confirm Booking',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
