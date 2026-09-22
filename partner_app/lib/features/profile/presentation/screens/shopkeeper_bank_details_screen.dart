import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../controllers/shopkeeper_profile_controller.dart';

class ShopkeeperBankDetailsScreen extends StatefulWidget {
  final ShopkeeperProfileController? controller;

  const ShopkeeperBankDetailsScreen({super.key, this.controller});

  @override
  State<ShopkeeperBankDetailsScreen> createState() => _ShopkeeperBankDetailsScreenState();
}

class _ShopkeeperBankDetailsScreenState extends State<ShopkeeperBankDetailsScreen> {
  late final ShopkeeperProfileController _controller;
  bool _internalController = false;
  bool _showFullAccountNumber = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = ShopkeeperProfileController();
      _internalController = true;
      _controller.loadShopkeeperProfile();
    }
    _controller.addListener(_onControllerUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerUpdate);
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  String _formatMaskedAccountNumber(String raw) {
    if (raw.trim().isEmpty) return '';
    final clean = raw.replaceAll(' ', '').replaceAll('-', '');
    if (clean.length > 4) {
      final last4 = clean.substring(clean.length - 4);
      return '•••• •••• $last4';
    }
    return raw;
  }

  void _showEditBankModal() {
    final formKey = GlobalKey<FormState>();
    final isNew = _controller.accountNumber.trim().isEmpty;
    final holderCtrl = TextEditingController(text: _controller.accountHolderName);
    final bankCtrl = TextEditingController(text: _controller.bankName);
    final cleanRaw = _controller.accountNumber.replaceAll(RegExp(r'[^0-9]'), '');
    final accNumberCtrl = TextEditingController(text: cleanRaw);
    final confirmAccCtrl = TextEditingController(text: cleanRaw);
    final ifscCtrl = TextEditingController(text: _controller.ifscCode);
    String selectedAccountType = _controller.accountType.isNotEmpty ? _controller.accountType : 'Savings Account';
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Icon(
                          isNew ? Icons.add_circle_outline_rounded : Icons.account_balance_rounded,
                          color: const Color(0xFF16A34A),
                          size: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isNew ? 'Add Bank Details' : 'Edit Bank Details',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Provide your bank account coordinates for settlement payouts and order transfers.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),

                    // Account Holder Name
                    _buildFormField(
                      label: 'Account Holder Name *',
                      hint: 'e.g. Rajesh Kumar or Store Entity',
                      controller: holderCtrl,
                      icon: Icons.person_outline_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Account holder name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Bank Name
                    _buildFormField(
                      label: 'Bank Name *',
                      hint: 'e.g. HDFC Bank, ICICI Bank, State Bank of India',
                      controller: bankCtrl,
                      icon: Icons.account_balance_rounded,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Bank name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Account Number
                    _buildFormField(
                      label: 'Account Number *',
                      hint: 'e.g. 50100428912345',
                      controller: accNumberCtrl,
                      icon: Icons.numbers_rounded,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Account number is required';
                        }
                        if (val.trim().length < 9) {
                          return 'Account number must be at least 9 digits';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Confirm Account Number
                    _buildFormField(
                      label: 'Re-Enter Account Number *',
                      hint: 'Confirm your account number',
                      controller: confirmAccCtrl,
                      icon: Icons.check_circle_outline_rounded,
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please confirm account number';
                        }
                        if (val.trim() != accNumberCtrl.text.trim()) {
                          return 'Account numbers do not match';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // IFSC Code
                    _buildFormField(
                      label: 'IFSC Code *',
                      hint: 'e.g. HDFC0001234',
                      controller: ifscCtrl,
                      icon: Icons.qr_code_rounded,
                      textCapitalization: TextCapitalization.characters,
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'IFSC code is required';
                        }
                        final clean = val.trim().toUpperCase();
                        if (clean.length != 11) {
                          return 'IFSC code must be exactly 11 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Account Type Selector
                    const Text(
                      'Account Type *',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => selectedAccountType = 'Savings Account'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedAccountType == 'Savings Account'
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedAccountType == 'Savings Account'
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFE2E8F0),
                                  width: selectedAccountType == 'Savings Account' ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    selectedAccountType == 'Savings Account'
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: selectedAccountType == 'Savings Account'
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF94A3B8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Savings Account',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selectedAccountType == 'Savings Account'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: selectedAccountType == 'Savings Account'
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: InkWell(
                            onTap: () => setModalState(() => selectedAccountType = 'Current Account'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: selectedAccountType == 'Current Account'
                                    ? const Color(0xFFDCFCE7)
                                    : const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: selectedAccountType == 'Current Account'
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFE2E8F0),
                                  width: selectedAccountType == 'Current Account' ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    selectedAccountType == 'Current Account'
                                        ? Icons.radio_button_checked_rounded
                                        : Icons.radio_button_off_rounded,
                                    color: selectedAccountType == 'Current Account'
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFF94A3B8),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Current Account',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: selectedAccountType == 'Current Account'
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: selectedAccountType == 'Current Account'
                                          ? const Color(0xFF15803D)
                                          : const Color(0xFF334155),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setModalState(() => isSaving = true);

                                try {
                                  await _controller.updateBankDetails(
                                    newAccountHolder: holderCtrl.text.trim(),
                                    newBankName: bankCtrl.text.trim(),
                                    newAccountNumber: accNumberCtrl.text.trim(),
                                    newIfsc: ifscCtrl.text.trim().toUpperCase(),
                                    newAccountType: selectedAccountType,
                                  );

                                  if (ctx.mounted) {
                                    Navigator.pop(ctx);
                                  }
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('✓ Bank details updated successfully for payouts!'),
                                        backgroundColor: Color(0xFF16A34A),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                                    );
                                  }
                                } finally {
                                  if (ctx.mounted) {
                                    setModalState(() => isSaving = false);
                                  }
                                }
                              },
                        child: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : Text(
                                isNew ? 'Save Bank Details' : 'Update Bank Details',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF64748B), size: 20),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF16A34A), width: 1.6),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildEmptyBankState(Color emeraldColor) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF86EFAC), width: 2),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 44,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'No Bank Account Linked',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add Bank Account for Daily Payouts',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF16A34A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Link your business or personal bank account to receive automatic daily settlements from customer orders every morning directly to your account.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF64748B),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: emeraldColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => _showEditBankModal(),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text(
                  'Add Bank Details',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: const Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank-Grade 256-bit Security',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Your bank credentials are encrypted with AES-256 and never shared with third parties. Used strictly for settlement payouts.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Divider(height: 1, color: Color(0xFFE2E8F0)),
              SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.schedule_rounded, color: Color(0xFF2563EB), size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily 10:00 AM Settlement Window',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'All order revenues and customer payments are transferred to this account every morning at 10:00 AM with zero deduction fees.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    const emeraldColor = Color(0xFF16A34A);
    final bool hasBankAccount = _controller.accountNumber.trim().isNotEmpty;
    final maskedAccount = _formatMaskedAccountNumber(_controller.accountNumber);
    final displayAccount = _showFullAccountNumber ? _controller.accountNumber : maskedAccount;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back button, 'Bank Details', subtitle 'For payouts and settlements'
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bank Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'For payouts and settlements',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: hasBankAccount
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Virtual Settlement Bank Card Hero
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF0F172A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22059669),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.credit_card_rounded, color: Colors.white, size: 18),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'SETTLEMENT ACCOUNT',
                                    style: TextStyle(
                                      color: Color(0xFFA7F3D0),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                              Text(
                                _controller.bankName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Account Number
                          Row(
                            children: [
                              Text(
                                maskedAccount,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2.2,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: _controller.accountNumber));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Account number copied to clipboard'),
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Icon(Icons.copy_rounded, color: Color(0xFFA7F3D0), size: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Card Footer: Holder Name, IFSC, Account Type
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'ACCOUNT HOLDER',
                                    style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _controller.accountHolderName,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'IFSC CODE',
                                    style: TextStyle(color: Color(0xFFA7F3D0), fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _controller.ifscCode,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'ACCOUNT PARTICULARS',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Detail Card 1: Account Holder Name
                    _buildDetailCard(
                      title: 'Account Holder Name',
                      value: _controller.accountHolderName,
                      subtitle: 'Matches business owner name registered with bank',
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFEFF6FF),
                    ),

                    // Detail Card 2: Bank Name
                    _buildDetailCard(
                      title: 'Bank Name',
                      value: _controller.bankName,
                      subtitle: 'Primary financial institution for merchant payouts',
                      icon: Icons.account_balance_rounded,
                      iconColor: const Color(0xFF0D9488),
                      iconBg: const Color(0xFFCCFBF1),
                    ),

                    // Detail Card 3: Account Number (masked)
                    _buildDetailCard(
                      title: 'Account Number',
                      value: displayAccount,
                      subtitle: 'Masked for data protection and banking compliance',
                      icon: Icons.numbers_rounded,
                      iconColor: const Color(0xFFEA580C),
                      iconBg: const Color(0xFFFFF7ED),
                      trailing: IconButton(
                        icon: Icon(
                          _showFullAccountNumber ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF64748B),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _showFullAccountNumber = !_showFullAccountNumber),
                      ),
                    ),

                    // Detail Card 4: IFSC Code
                    _buildDetailCard(
                      title: 'IFSC Code',
                      value: _controller.ifscCode,
                      subtitle: 'Branch clearing identifier code for electronic NEFT/IMPS transfers',
                      icon: Icons.qr_code_rounded,
                      iconColor: const Color(0xFF9333EA),
                      iconBg: const Color(0xFFF3E8FF),
                    ),

                    // Detail Card 5: Account Type
                    _buildDetailCard(
                      title: 'Account Type',
                      value: _controller.accountType,
                      subtitle: 'Settlement account configuration',
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: emeraldColor,
                      iconBg: const Color(0xFFDCFCE7),
                    ),

                    const SizedBox(height: 14),

                    // Settlement cycle notice
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 18),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Automatic Daily Settlements (T+1)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E293B)),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'All order revenues and customer payments are transferred to this account every morning at 10:00 AM with zero deduction fees.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                )
              : _buildEmptyBankState(emeraldColor),
              ),
            ),

            // Bottom Action Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: emeraldColor,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () => _showEditBankModal(),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        hasBankAccount ? Icons.edit_note_rounded : Icons.add_circle_outline_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        hasBankAccount ? 'Edit Bank Details' : 'Add Bank Details',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
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
