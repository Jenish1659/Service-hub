import 'package:flutter/material.dart';
import '../../data/customer_profile_service.dart';

class CustomerAddPaymentMethodScreen extends StatefulWidget {
  const CustomerAddPaymentMethodScreen({super.key});

  @override
  State<CustomerAddPaymentMethodScreen> createState() => _CustomerAddPaymentMethodScreenState();
}

class _CustomerAddPaymentMethodScreenState extends State<CustomerAddPaymentMethodScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedTab = 0; // 0: UPI, 1: Debit Card, 2: Credit Card

  // UPI form controllers
  final TextEditingController _upiIdController = TextEditingController();

  // Card form controllers
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _cardHolderController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  bool _isDefault = true;
  bool _isLoading = false;

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);

  @override
  void dispose() {
    _upiIdController.dispose();
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _savePaymentMethod() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    if (_selectedTab == 0) {
      final upi = _upiIdController.text.trim();
      await CustomerProfileService.instance.savePaymentMethod({
        'type': 'UPI',
        'title': 'UPI',
        'detail': upi,
        'is_default': _isDefault,
      });
    } else {
      final num = _cardNumberController.text.trim().replaceAll(' ', '');
      final last4 = num.length >= 4 ? num.substring(num.length - 4) : '0000';
      final isDebit = _selectedTab == 1;

      await CustomerProfileService.instance.savePaymentMethod({
        'type': isDebit ? 'Bank' : 'Card',
        'title': isDebit ? 'Debit Card' : 'Credit Card',
        'detail': '**** $last4',
        'is_default': _isDefault,
      });
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Payment method saved successfully!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Add Payment Method',
          style: TextStyle(color: darkSlate, fontSize: 18, fontWeight: FontWeight.bold),
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
              // 3 Method Tabs (UPI, Debit Card, Credit Card)
              Row(
                children: [
                  _buildTabItem(0, 'UPI', Icons.account_balance_wallet_rounded),
                  const SizedBox(width: 12),
                  _buildTabItem(1, 'Debit Card', Icons.credit_card_rounded),
                  const SizedBox(width: 12),
                  _buildTabItem(2, 'Credit Card', Icons.credit_card_outlined),
                ],
              ),
              const SizedBox(height: 24),

              if (_selectedTab == 0) ...[
                // UPI Form
                _buildFieldLabel('UPI ID *'),
                _buildTextInput(
                  controller: _upiIdController,
                  hintText: 'e.g. username@okhdfcbank or phone@upi',
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter UPI ID';
                    if (!v.contains('@')) return 'Enter a valid UPI ID with @';
                    return null;
                  },
                ),
              ] else ...[
                // Card Form
                _buildFieldLabel('Card Number *'),
                _buildTextInput(
                  controller: _cardNumberController,
                  hintText: 'XXXX XXXX XXXX XXXX',
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.length < 12 ? 'Enter valid 16-digit card number' : null,
                ),
                const SizedBox(height: 16),
                _buildFieldLabel('Cardholder Name *'),
                _buildTextInput(
                  controller: _cardHolderController,
                  hintText: 'Full Name on Card',
                  validator: (v) => v == null || v.isEmpty ? 'Enter name on card' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('Expiry (MM/YY) *'),
                          _buildTextInput(
                            controller: _expiryController,
                            hintText: 'MM/YY',
                            keyboardType: TextInputType.datetime,
                            validator: (v) => v == null || v.isEmpty ? 'MM/YY' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildFieldLabel('CVV *'),
                          _buildTextInput(
                            controller: _cvvController,
                            hintText: '***',
                            keyboardType: TextInputType.number,
                            validator: (v) => v == null || v.length < 3 ? '3-digit CVV' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),

              // Set as Default Payment Method Switch
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
                      'Set as Default Payment Method',
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
              const SizedBox(height: 20),

              // Security Encryption Notice Card
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.shield_outlined, color: primaryBlue, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Your payment details are securely encrypted. We do not store sensitive bank information.',
                        style: TextStyle(fontSize: 12.5, color: textMuted, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save Action Button
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
                  onPressed: _isLoading ? null : _savePaymentMethod,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _selectedTab == 0 ? 'Save UPI' : 'Save Card',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildTabItem(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
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
                  fontSize: 12.5,
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
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: darkSlate, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
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
