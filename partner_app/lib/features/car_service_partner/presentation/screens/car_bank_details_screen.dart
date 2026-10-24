import 'package:flutter/material.dart';
import '../../../../core/storage/local_registration_cache.dart';

/// Subpage: Bank Details for Car Service Provider
class CarBankDetailsScreen extends StatefulWidget {
  const CarBankDetailsScreen({super.key});

  @override
  State<CarBankDetailsScreen> createState() => _CarBankDetailsScreenState();
}

class _CarBankDetailsScreenState extends State<CarBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _holderController;
  late final TextEditingController _bankNameController;
  late final TextEditingController _accountNumberController;
  late final TextEditingController _ifscController;
  late final TextEditingController _upiController;

  bool _isLoading = true;
  bool _isSaving = false;

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _holderController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountNumberController = TextEditingController();
    _ifscController = TextEditingController();
    _upiController = TextEditingController();
    _loadBankData();
  }

  @override
  void dispose() {
    _holderController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _loadBankData() async {
    final cached = await LocalRegistrationCache.getActiveServiceProvider() ??
        await LocalRegistrationCache.getActivePartner();

    if (mounted) {
      setState(() {
        _holderController.text = (cached?['bank_holder_name'] ?? cached?['full_name'] ?? 'Karan Mehta').toString();
        _bankNameController.text = (cached?['bank_name'] ?? 'State Bank of India').toString();
        _accountNumberController.text = (cached?['bank_account_number'] ?? 'XXXX-XXXX-4589').toString();
        _ifscController.text = (cached?['ifsc_code'] ?? 'SBIN0001234').toString();
        _upiController.text = (cached?['upi_id'] ?? 'karanmehta@sbi').toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await LocalRegistrationCache.updateActiveServiceProvider({
        'bank_holder_name': _holderController.text.trim(),
        'bank_name': _bankNameController.text.trim(),
        'bank_account_number': _accountNumberController.text.trim(),
        'ifsc_code': _ifscController.text.trim(),
        'upi_id': _upiController.text.trim(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bank details updated successfully!'),
            backgroundColor: primaryBlue,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Notice: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text(
          'Bank Details',
          style: TextStyle(
            color: darkSlate,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFieldLabel('Account Holder Name *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _holderController,
                decoration: _inputDecoration('Account holder full name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 18),

              _buildFieldLabel('Bank Name *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bankNameController,
                decoration: _inputDecoration('Bank name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 18),

              _buildFieldLabel('Account Number *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _accountNumberController,
                decoration: _inputDecoration('Bank account number'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 18),

              _buildFieldLabel('IFSC Code *'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ifscController,
                decoration: _inputDecoration('IFSC code'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 18),

              _buildFieldLabel('UPI ID (Optional)'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _upiController,
                decoration: _inputDecoration('e.g. mobile@upi'),
              ),
              const SizedBox(height: 36),

              
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
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
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isSaving ? null : _saveChanges,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: darkSlate,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: textMuted),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cardBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 1.5),
      ),
    );
  }
}
