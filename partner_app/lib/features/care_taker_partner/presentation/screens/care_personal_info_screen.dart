import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/storage/local_registration_cache.dart';

/// Screen 7: Dedicated Personal Information Sub-Screen for Care Taker Specialist
class CarePersonalInfoScreen extends StatefulWidget {
  const CarePersonalInfoScreen({super.key});

  @override
  State<CarePersonalInfoScreen> createState() => _CarePersonalInfoScreenState();
}

class _CarePersonalInfoScreenState extends State<CarePersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  bool _isLoading = true;

  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
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
        await LocalRegistrationCache.getActivePartner();
    if (mounted) {
      setState(() {
        _nameController.text = (cached?['name'] ?? cached?['full_name'] ?? 'Neha Patel').toString();
        _phoneController.text = (cached?['phone'] ?? '+91 98765 43210').toString();
        _emailController.text = (cached?['email'] ?? 'nehapatel@example.com').toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;
    await LocalRegistrationCache.updateActiveServiceProvider({
      'name': _nameController.text.trim(),
      'full_name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'role': 'care_taker',
      'category': 'care_taker',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Personal information updated successfully!'),
          backgroundColor: primaryIndigo,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: scaffoldBg,
        body: Center(child: CircularProgressIndicator(color: primaryIndigo)),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Personal Information',
          style: TextStyle(color: darkSlate, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Photo Card
              const Text('Profile Photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: primaryIndigo.withValues(alpha: 0.1),
                      child: const Icon(Icons.person, color: primaryIndigo, size: 40),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryIndigo,
                              side: const BorderSide(color: primaryIndigo),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined, size: 16),
                            label: const Text('Change Photo'),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Photo picker ready for live care partner document camera'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          const Text('Supported: JPG, PNG (Max 5 MB)', style: TextStyle(fontSize: 11, color: textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Full Name
              const Text('Full Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Full name is required' : null,
              ),

              const SizedBox(height: 16),

              // Phone Number
              const Text('Phone Number *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(10),
                ],
                decoration: InputDecoration(
                  hintText: 'Enter 10-digit phone number',
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().length != 10 ? 'Valid 10-digit phone number is required' : null,
              ),

              const SizedBox(height: 16),

              // Email Address
              const Text('Email Address', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),

              const SizedBox(height: 32),

              // Save Changes Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryIndigo,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveChanges,
                  child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
