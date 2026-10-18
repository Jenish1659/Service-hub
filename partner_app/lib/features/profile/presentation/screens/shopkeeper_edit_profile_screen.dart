import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../controllers/shopkeeper_profile_controller.dart';

class ShopkeeperEditProfileScreen extends StatefulWidget {
  final ShopkeeperProfileController? controller;

  const ShopkeeperEditProfileScreen({super.key, this.controller});

  @override
  State<ShopkeeperEditProfileScreen> createState() => _ShopkeeperEditProfileScreenState();
}

class _ShopkeeperEditProfileScreenState extends State<ShopkeeperEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final ShopkeeperProfileController _controller;
  bool _createdInternally = false;
  bool _isSaving = false;

  late final TextEditingController _shopNameCtrl;
  late final TextEditingController _descriptionCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _ownerNameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _pincodeCtrl;

  final List<String> _categories = [
    'AC Parts',
    'Appliance Parts',
    'Hardware',
    'Tools & Equipment',
  ];
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = ShopkeeperProfileController();
      _createdInternally = true;
      _controller.loadShopkeeperProfile();
    }

    _shopNameCtrl = TextEditingController(text: _controller.shopName);
    _descriptionCtrl = TextEditingController(text: _controller.description);
    _phoneCtrl = TextEditingController(text: _controller.phone);
    _emailCtrl = TextEditingController(text: _controller.email);
    _ownerNameCtrl = TextEditingController(text: _controller.ownerName);
    _addressCtrl = TextEditingController(text: _controller.address);
    _cityCtrl = TextEditingController(text: _controller.city);
    _pincodeCtrl = TextEditingController(text: _controller.pincode);

    // Ensure current category is in the dropdown list
    if (_controller.category.isNotEmpty) {
      if (!_categories.contains(_controller.category)) {
        _categories.insert(0, _controller.category);
      }
      _selectedCategory = _controller.category;
    } else {
      _selectedCategory = _categories.first;
    }

    _descriptionCtrl.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _shopNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _ownerNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    if (_createdInternally) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _controller.updateStoreDetails(
        newShopName: _shopNameCtrl.text.trim(),
        newOwnerName: _ownerNameCtrl.text.trim().isNotEmpty
            ? _ownerNameCtrl.text.trim()
            : _controller.ownerName,
        newPhone: _phoneCtrl.text.trim(),
        newEmail: _emailCtrl.text.trim(),
        newAddress: _addressCtrl.text.trim().isNotEmpty
            ? _addressCtrl.text.trim()
            : _controller.address,
        newCity: _cityCtrl.text.trim().isNotEmpty
            ? _cityCtrl.text.trim()
            : _controller.city,
        newPincode: _pincodeCtrl.text.trim().isNotEmpty
            ? _pincodeCtrl.text.trim()
            : _controller.pincode,
        newCategory: _selectedCategory ?? _controller.category,
        newDescription: _descriptionCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Shop profile updated successfully!'),
              ],
            ),
            backgroundColor: const Color(0xFF047857),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _onPhotoTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Store photo upload dialog opened'),
        backgroundColor: const Color(0xFF047857),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldPrimary = Color(0xFF047857);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A), size: 18),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              context.pop();
            }
          },
        ),
        titleSpacing: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Edit Shop Profile',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Update your shop details',
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Shop Photo with Camera Badge
                Center(
                  child: Stack(
                    children: [
                      InkWell(
                        onTap: _onPhotoTap,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFA7F3D0), width: 2),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x10000000),
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.storefront_rounded,
                            size: 48,
                            color: emeraldPrimary,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: -2,
                        right: -2,
                        child: InkWell(
                          onTap: _onPhotoTap,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: emeraldPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x20000000),
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _onPhotoTap,
                    child: const Text(
                      'Change Store Photo',
                      style: TextStyle(
                        color: emeraldPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Section: Shop Details
                _buildCardContainer([
                  const Text(
                    'SHOP DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Shop Name
                  _buildInputField(
                    label: 'Shop Name',
                    controller: _shopNameCtrl,
                    icon: Icons.storefront_rounded,
                    hint: 'e.g. Modern Appliance & AC Spares',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Shop Name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Shop Type Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Shop Type',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF0F172A),
                        ),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.category_rounded, color: emeraldPrimary, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: emeraldPrimary, width: 1.5),
                          ),
                        ),
                        items: _categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedCategory = val);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Shop Description with character counter
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Shop Description',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                          Text(
                            '${_descriptionCtrl.text.length}/200',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _descriptionCtrl.text.length > 200
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _descriptionCtrl,
                        maxLines: 4,
                        maxLength: 200,
                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                        style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
                        decoration: InputDecoration(
                          hintText: 'Describe your shop, genuine parts offered, delivery promises...',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          contentPadding: const EdgeInsets.all(14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: emeraldPrimary, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]),
                const SizedBox(height: 20),

                // Section: Contact Details
                _buildCardContainer([
                  const Text(
                    'CONTACT DETAILS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Phone with edit
                  _buildInputField(
                    label: 'Phone Number',
                    controller: _phoneCtrl,
                    icon: Icons.phone_rounded,
                    hint: '9876543210',
                    keyboardType: TextInputType.phone,
                    suffixIcon: const Icon(Icons.edit_outlined, size: 18, color: emeraldPrimary),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Phone number is required';
                      if (v.trim().length != 10) return 'Phone number must be exactly 10 digits';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email with edit
                  _buildInputField(
                    label: 'Email Address',
                    controller: _emailCtrl,
                    icon: Icons.email_rounded,
                    hint: 'store@servicehub.com',
                    keyboardType: TextInputType.emailAddress,
                    suffixIcon: const Icon(Icons.edit_outlined, size: 18, color: emeraldPrimary),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email address';
                      return null;
                    },
                  ),
                ]),
                const SizedBox(height: 28),

                // Save Changes Solid Emerald Green Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: emeraldPrimary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _isSaving ? null : _handleSave,
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    const emeraldPrimary = Color(0xFF047857);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: keyboardType == TextInputType.phone ? 10 : null,
          buildCounter: keyboardType == TextInputType.phone
              ? (context, {required currentLength, required isFocused, maxLength}) => null
              : null,
          inputFormatters: keyboardType == TextInputType.phone
              ? [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)]
              : null,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
            prefixIcon: Icon(icon, color: emeraldPrimary, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: emeraldPrimary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
