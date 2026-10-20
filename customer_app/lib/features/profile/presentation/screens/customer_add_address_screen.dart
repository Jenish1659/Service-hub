import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../data/customer_profile_service.dart';

class CustomerAddAddressScreen extends StatefulWidget {
  final Map<String, dynamic>? existingAddress;

  const CustomerAddAddressScreen({super.key, this.existingAddress});

  @override
  State<CustomerAddAddressScreen> createState() => _CustomerAddAddressScreenState();
}

class _CustomerAddAddressScreenState extends State<CustomerAddAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _selectedType;
  late TextEditingController _labelController;
  late TextEditingController _addressController;
  late TextEditingController _landmarkController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  bool _isDefault = false;
  bool _isLoading = false;

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    final addr = widget.existingAddress;
    _selectedType = addr?['type'] ?? 'Home';
    _labelController = TextEditingController(text: addr?['label'] ?? 'Home');

    String initialAddress = '';
    String initialLandmark = '';
    String initialCity = 'Jamnagar';
    String initialState = 'Gujarat';
    String initialPincode = '361001';

    if (addr != null) {
      initialAddress = addr['full_address'] ?? '';
      initialLandmark = addr['landmark'] ?? '';
      initialCity = addr['city'] ?? 'Jamnagar';
      initialState = addr['state'] ?? 'Gujarat';
      initialPincode = addr['pincode'] ?? '361001';
    } else {
      try {
        if (Hive.isBoxOpen('customer_cache')) {
          final box = Hive.box('customer_cache');
          final cachedLoc = box.get('location_address') as String?;
          if (cachedLoc != null && cachedLoc.isNotEmpty) {
            initialAddress = cachedLoc;
          }
        }
      } catch (_) {}
    }

    _addressController = TextEditingController(text: initialAddress);
    _landmarkController = TextEditingController(text: initialLandmark);
    _cityController = TextEditingController(text: initialCity);
    _stateController = TextEditingController(text: initialState);
    _pincodeController = TextEditingController(text: initialPincode);
    _isDefault = addr?['is_default'] ?? false;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _onTypeSelected(String type) {
    setState(() {
      _selectedType = type;
      if (widget.existingAddress == null || _labelController.text.isEmpty) {
        _labelController.text = type == 'Others' ? 'Parents Home' : type;
      }
    });
  }

  void _detectLocation() {
    String detectedAddress = 'Kaushal Nagar, Jamnagar, Gujarat 361001';
    try {
      if (Hive.isBoxOpen('customer_cache')) {
        final box = Hive.box('customer_cache');
        final cachedLoc = box.get('location_address') as String?;
        if (cachedLoc != null && cachedLoc.isNotEmpty) {
          detectedAddress = cachedLoc;
        }
      }
    } catch (_) {}

    setState(() {
      _addressController.text = detectedAddress;
      _cityController.text = 'Jamnagar';
      _stateController.text = 'Gujarat';
      _pincodeController.text = '361001';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ Location detected: $detectedAddress'),
        backgroundColor: primaryBlue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await CustomerProfileService.instance.saveAddress({
      if (widget.existingAddress != null) 'id': widget.existingAddress!['id'],
      'label': _labelController.text.trim(),
      'type': _selectedType,
      'full_address': _addressController.text.trim(),
      'landmark': _landmarkController.text.trim(),
      'city': _cityController.text.trim(),
      'state': _stateController.text.trim(),
      'pincode': _pincodeController.text.trim(),
      'is_default': _isDefault,
    });

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingAddress != null ? '✓ Address updated successfully' : '✓ Address saved successfully'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingAddress != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: darkSlate),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Address' : 'Add New Address',
          style: const TextStyle(color: darkSlate, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 3 Category Selector Tabs (Home, Office, Others)
              Row(
                children: [
                  _buildTypeTab('Home', Icons.home_rounded),
                  const SizedBox(width: 12),
                  _buildTypeTab('Office', Icons.apartment_rounded),
                  const SizedBox(width: 12),
                  _buildTypeTab('Others', Icons.place_rounded),
                ],
              ),
              const SizedBox(height: 24),

              // Address Label
              _buildFieldLabel('Address Label'),
              _buildTextInput(
                controller: _labelController,
                hintText: 'e.g. Home, Office, Parents Home',
                validator: (v) => v == null || v.isEmpty ? 'Please enter a label' : null,
              ),
              const SizedBox(height: 16),

              // Full Address with GPS detection pin
              _buildFieldLabel('Full Address *'),
              _buildTextInput(
                controller: _addressController,
                hintText: '12, Sunrise Residency, Jamnagar, Gujarat 361001',
                maxLines: 2,
                validator: (v) => v == null || v.isEmpty ? 'Please enter address' : null,
                suffixWidget: IconButton(
                  icon: const Icon(Icons.my_location_rounded, color: primaryBlue, size: 20),
                  onPressed: _detectLocation,
                  tooltip: 'Use current GPS location',
                ),
              ),
              const SizedBox(height: 16),

              // Landmark (Optional)
              _buildFieldLabel('Landmark (Optional)'),
              _buildTextInput(
                controller: _landmarkController,
                hintText: 'Near Sunrise Mall',
              ),
              const SizedBox(height: 16),

              // City
              _buildFieldLabel('City *'),
              _buildTextInput(
                controller: _cityController,
                hintText: 'Jamnagar',
                validator: (v) => v == null || v.isEmpty ? 'Enter city' : null,
              ),
              const SizedBox(height: 16),

              // State & Pincode Row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('State *'),
                        _buildTextInput(
                          controller: _stateController,
                          hintText: 'Gujarat',
                          validator: (v) => v == null || v.isEmpty ? 'Enter state' : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFieldLabel('Pincode *'),
                        _buildTextInput(
                          controller: _pincodeController,
                          hintText: '361001',
                          keyboardType: TextInputType.number,
                          validator: (v) => v == null || v.isEmpty ? 'Enter pincode' : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Set as Default Address Switch
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: borderGrey),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Set as Default Address',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: darkSlate),
                    ),
                    Switch(
                      value: _isDefault,
                      activeThumbColor: primaryBlue,
                      onChanged: (val) => setState(() => _isDefault = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Address Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isLoading ? null : _saveAddress,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text(
                          'Save Address',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildTypeTab(String label, IconData icon) {
    final isSelected = _selectedType.toLowerCase() == label.toLowerCase();
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTypeSelected(label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFF6FF) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? primaryBlue : borderGrey,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? primaryBlue : textMuted, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? primaryBlue : darkSlate,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: darkSlate),
      ),
    );
  }

  Widget _buildTextInput({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixWidget,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: darkSlate, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        suffixIcon: suffixWidget,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryBlue, width: 1.5),
        ),
      ),
    );
  }
}
