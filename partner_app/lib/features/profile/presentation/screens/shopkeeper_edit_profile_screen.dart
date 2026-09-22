import 'package:flutter/material.dart';
import '../controllers/shopkeeper_profile_controller.dart';

class ShopkeeperEditProfileScreen extends StatefulWidget {
  final ShopkeeperProfileController controller;

  const ShopkeeperEditProfileScreen({super.key, required this.controller});

  @override
  State<ShopkeeperEditProfileScreen> createState() => _ShopkeeperEditProfileScreenState();
}

class _ShopkeeperEditProfileScreenState extends State<ShopkeeperEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _shopNameCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _pincodeCtrl;
  late final TextEditingController _categoryCtrl;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _shopNameCtrl = TextEditingController(text: widget.controller.shopName);
    _ownerNameCtrl = TextEditingController(text: widget.controller.ownerName);
    _phoneCtrl = TextEditingController(text: widget.controller.phone);
    _emailCtrl = TextEditingController(text: widget.controller.email);
    _addressCtrl = TextEditingController(text: widget.controller.address);
    _cityCtrl = TextEditingController(text: widget.controller.city);
    _pincodeCtrl = TextEditingController(text: widget.controller.pincode);
    _categoryCtrl = TextEditingController(text: widget.controller.category);
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    _categoryCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await widget.controller.updateStoreDetails(
        newShopName: _shopNameCtrl.text.trim(),
        newOwnerName: _ownerNameCtrl.text.trim(),
        newPhone: _phoneCtrl.text.trim(),
        newEmail: _emailCtrl.text.trim(),
        newAddress: _addressCtrl.text.trim(),
        newCity: _cityCtrl.text.trim(),
        newPincode: _pincodeCtrl.text.trim(),
        newCategory: _categoryCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Store Profile updated successfully!'),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const emeraldColor = Color(0xFF16A34A);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Store Details',
          style: TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold, fontSize: 17),
        ),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _handleSave,
            icon: _isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: emeraldColor))
                : const Icon(Icons.check_rounded, color: emeraldColor, size: 20),
            label: const Text('Save', style: TextStyle(color: emeraldColor, fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Header Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDCFCE7), Color(0xFFF0FDF4)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.storefront_rounded, color: emeraldColor, size: 28),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Retail Store Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF14532D))),
                          SizedBox(height: 2),
                          Text('Update your store details and customer contact information', style: TextStyle(fontSize: 11.5, color: Color(0xFF15803D))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              _buildFieldGroup('STORE INFORMATION', [
                _buildTextField('Shop / Business Name', _shopNameCtrl, Icons.store_rounded, isRequired: true),
                const SizedBox(height: 14),
                _buildTextField('Business Category', _categoryCtrl, Icons.category_rounded, isRequired: true),
              ]),
              const SizedBox(height: 20),

              _buildFieldGroup('OWNER & CONTACT DETAILS', [
                _buildTextField('Owner Full Name', _ownerNameCtrl, Icons.person_rounded, isRequired: true),
                const SizedBox(height: 14),
                _buildTextField('Phone Number', _phoneCtrl, Icons.phone_rounded, keyboardType: TextInputUnit.phone, isRequired: true),
                const SizedBox(height: 14),
                _buildTextField('Email Address', _emailCtrl, Icons.email_rounded, keyboardType: TextInputType.emailAddress),
              ]),
              const SizedBox(height: 20),

              _buildFieldGroup('STORE LOCATION & ADDRESS', [
                _buildTextField('Shop Full Address', _addressCtrl, Icons.location_on_rounded, maxLines: 2, isRequired: true),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _buildTextField('City', _cityCtrl, Icons.location_city_rounded, isRequired: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildTextField('Pincode', _pincodeCtrl, Icons.pin_drop_rounded, keyboardType: TextInputType.number, isRequired: true)),
                  ],
                ),
              ]),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: _isSaving ? null : _handleSave,
                  icon: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_rounded, size: 20),
                  label: Text(_isSaving ? 'Saving Changes...' : 'Save Store Details', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldGroup(String label, List<Widget> fields) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B), letterSpacing: 0.5)),
          const SizedBox(height: 14),
          ...fields,
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    bool isRequired = false,
    int maxLines = 1,
    dynamic keyboardType,
  }) {
    TextInputType kb = TextInputType.text;
    if (keyboardType == TextInputUnit.phone) {
      kb = TextInputType.phone;
    } else if (keyboardType is TextInputType) {
      kb = keyboardType;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
            if (isRequired) const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: kb,
          validator: isRequired
              ? (v) => (v == null || v.trim().isEmpty) ? '$label is required' : null
              : null,
          style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 18),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.5)),
          ),
        ),
      ],
    );
  }
}

enum TextInputUnit { phone }
