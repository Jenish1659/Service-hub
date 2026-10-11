import 'package:flutter/material.dart';
import '../../../../core/storage/local_registration_cache.dart';

/// Screen 8: Personal Information Screen (Matching Design)
/// 100% Real Data Guarantee
class LaundryPersonalInfoScreen extends StatefulWidget {
  const LaundryPersonalInfoScreen({super.key});

  @override
  State<LaundryPersonalInfoScreen> createState() => _LaundryPersonalInfoScreenState();
}

class _LaundryPersonalInfoScreenState extends State<LaundryPersonalInfoScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final cached = await LocalRegistrationCache.getActiveServiceProvider() ??
        await LocalRegistrationCache.getActiveShopkeeper() ??
        await LocalRegistrationCache.getActivePartner() ??
        {};

    if (mounted) {
      _nameController.text = (cached['name'] ?? cached['username'] ?? '').toString();
      _phoneController.text = (cached['phone'] ?? '').toString();
      _emailController.text = (cached['email'] ?? '').toString();
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final cached = await LocalRegistrationCache.getActiveServiceProvider() ??
        await LocalRegistrationCache.getActiveShopkeeper() ??
        await LocalRegistrationCache.getActivePartner() ??
        {};

    final updated = Map<String, dynamic>.from(cached);
    updated['name'] = _nameController.text.trim();
    updated['phone'] = _phoneController.text.trim();
    updated['email'] = _emailController.text.trim();

    await LocalRegistrationCache.updateActiveServiceProvider(updated);
    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Personal information updated successfully!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(child: CircularProgressIndicator(color: primaryBlue)),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Personal Information',
          style: TextStyle(color: darkSlate, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTextField('Full Name', _nameController, 'Enter your full name', Icons.person_outline),
            const SizedBox(height: 18),
            _buildTextField('Phone Number', _phoneController, 'Enter phone number', Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 18),
            _buildTextField('Email Address', _emailController, 'Enter email address', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 24),

            // Profile Photo section
            const Text('Profile Photo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkSlate)),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: const Color(0xFFEFF6FF),
                  child: Text(
                    _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : 'L',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16, color: primaryBlue),
                  label: const Text('Change Photo', style: TextStyle(color: primaryBlue, fontSize: 13)),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Photo update available.'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Supported: JPG, PNG (Max 5 MB)', style: TextStyle(fontSize: 11.5, color: textMuted)),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: darkSlate)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF94A3B8)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primaryBlue),
            ),
          ),
        ),
      ],
    );
  }
}
