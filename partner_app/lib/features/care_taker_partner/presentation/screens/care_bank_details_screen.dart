import 'package:flutter/material.dart';
import '../../../../core/storage/local_registration_cache.dart';

/// Screen: Dedicated Bank Details Sub-Screen for Care Taker Specialist
class CareBankDetailsScreen extends StatefulWidget {
  const CareBankDetailsScreen({super.key});

  @override
  State<CareBankDetailsScreen> createState() => _CareBankDetailsScreenState();
}

class _CareBankDetailsScreenState extends State<CareBankDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _holderController;
  late TextEditingController _bankNameController;
  late TextEditingController _accountController;
  late TextEditingController _ifscController;
  late TextEditingController _upiController;
  bool _isLoading = true;

  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _holderController = TextEditingController();
    _bankNameController = TextEditingController();
    _accountController = TextEditingController();
    _ifscController = TextEditingController();
    _upiController = TextEditingController();
    _loadBankData();
  }

  @override
  void dispose() {
    _holderController.dispose();
    _bankNameController.dispose();
    _accountController.dispose();
    _ifscController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  Future<void> _loadBankData() async {
    final cached = await LocalRegistrationCache.getActiveServiceProvider() ??
        await LocalRegistrationCache.getActivePartner();
    if (mounted) {
      setState(() {
        _holderController.text = (cached?['account_holder'] ?? cached?['name'] ?? 'Neha Patel').toString();
        _bankNameController.text = (cached?['bank_name'] ?? 'HDFC Bank').toString();
        _accountController.text = (cached?['account_number'] ?? '50100234567890').toString();
        _ifscController.text = (cached?['ifsc_code'] ?? 'HDFC0000123').toString();
        _upiController.text = (cached?['upi_id'] ?? 'nehapatel@okhdfcbank').toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBankDetails() async {
    if (!_formKey.currentState!.validate()) return;
    await LocalRegistrationCache.updateActiveServiceProvider({
      'account_holder': _holderController.text.trim(),
      'bank_name': _bankNameController.text.trim(),
      'account_number': _accountController.text.trim(),
      'ifsc_code': _ifscController.text.trim(),
      'upi_id': _upiController.text.trim(),
      'role': 'care_taker',
      'category': 'care_taker',
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bank & payout details saved securely!'),
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
          'Bank Details',
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
              // Security info banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryIndigo.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryIndigo.withValues(alpha: 0.2)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, color: primaryIndigo, size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your earnings from nursing and home care jobs will be deposited directly into this account.',
                        style: TextStyle(fontSize: 12, color: darkSlate, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Account Holder
              const Text('Account Holder Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _holderController,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Account holder name is required' : null,
              ),

              const SizedBox(height: 16),

              // Bank Name
              const Text('Bank Name *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _bankNameController,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Bank name is required' : null,
              ),

              const SizedBox(height: 16),

              // Account Number
              const Text('Account Number *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _accountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Account number is required' : null,
              ),

              const SizedBox(height: 16),

              // IFSC Code
              const Text('IFSC Code *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _ifscController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: cardBorder)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'IFSC code is required' : null,
              ),

              const SizedBox(height: 16),

              // UPI ID (Optional)
              const Text('UPI ID (Optional)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _upiController,
                decoration: InputDecoration(
                  hintText: 'username@upi',
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
                  onPressed: _saveBankDetails,
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
