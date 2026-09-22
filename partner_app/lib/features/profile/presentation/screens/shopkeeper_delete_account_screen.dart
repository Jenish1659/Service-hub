import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../controllers/shopkeeper_profile_controller.dart';

class ShopkeeperDeleteAccountScreen extends StatefulWidget {
  final ShopkeeperProfileController? controller;

  const ShopkeeperDeleteAccountScreen({super.key, this.controller});

  @override
  State<ShopkeeperDeleteAccountScreen> createState() =>
      _ShopkeeperDeleteAccountScreenState();
}

class _ShopkeeperDeleteAccountScreenState
    extends State<ShopkeeperDeleteAccountScreen> {
  late final ShopkeeperProfileController _controller;
  bool _internalController = false;

  final TextEditingController _confirmTextCtrl = TextEditingController();
  String? _selectedReason = 'Closing retail business or moving shop';
  bool _confirmedDataLoss = false;
  bool _confirmedPayoutLoss = false;
  bool _isDeleting = false;

  final List<String> _reasons = [
    'Closing retail business or moving shop',
    'Low order volume from local technicians',
    'Switching to another platform or POS system',
    'Temporary seasonal break',
    'Other reason',
  ];

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
  }

  @override
  void dispose() {
    if (_internalController) {
      _controller.dispose();
    }
    _confirmTextCtrl.dispose();
    super.dispose();
  }

  bool get _canDelete {
    return _confirmedDataLoss &&
        _confirmedPayoutLoss &&
        _confirmTextCtrl.text.trim().toUpperCase() == 'DELETE';
  }

  void _showConfirmDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Permanently Delete?',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
            ),
          ],
        ),
        content: const Text(
          'Are you completely sure? This action is irreversible. All products, order records, and merchant profile data will be permanently wiped.',
          style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isDeleting = true);

              try {
                await _controller.deleteAccount();
                if (!mounted) return;
                setState(() => _isDeleting = false);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Shopkeeper account deleted successfully'),
                    backgroundColor: Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );

                context.go('/login/shopkeeper');
              } catch (e) {
                if (!mounted) return;
                setState(() => _isDeleting = false);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting account: $e'),
                    backgroundColor: const Color(0xFFDC2626),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Delete', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: Colors.white,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
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
                          'Delete Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Permanently close your merchant account',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Red Alert Box with Trash Icon and 4 Warning Points (Screen 17 requirement)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEE2E2),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: const Color(0xFFFCA5A5)),
                                ),
                                child: const Icon(
                                  Icons.delete_forever_rounded,
                                  color: Color(0xFFDC2626),
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Permanent Account Closure',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF991B1B),
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Please read the consequences carefully before proceeding.',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        color: Color(0xFFB91C1C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(height: 1, color: Color(0xFFFECACA)),
                          const SizedBox(height: 14),

                          // 4 Exact Warning Points
                          _buildWarningPoint('All your data will be permanently deleted.'),
                          const SizedBox(height: 10),
                          _buildWarningPoint('You will lose access to your shop and earnings.'),
                          const SizedBox(height: 10),
                          _buildWarningPoint('Pending payouts (if any) may be affected.'),
                          const SizedBox(height: 10),
                          _buildWarningPoint('This action cannot be undone.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Reason Selector
                    _buildSectionHeader('REASON FOR LEAVING'),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedReason,
                          isExpanded: true,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF64748B)),
                          items: _reasons.map((r) {
                            return DropdownMenuItem<String>(
                              value: r,
                              child: Text(
                                r,
                                style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A)),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) => setState(() => _selectedReason = val),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirmation Checkboxes
                    _buildSectionHeader('ACKNOWLEDGEMENT'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: Column(
                          children: [
                            CheckboxListTile(
                              value: _confirmedDataLoss,
                              activeColor: const Color(0xFFDC2626),
                              onChanged: (v) => setState(() => _confirmedDataLoss = v ?? false),
                              title: const Text(
                                'I understand that my catalog, store rating, and history will be deleted.',
                                style: TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                              ),
                            ),
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            CheckboxListTile(
                              value: _confirmedPayoutLoss,
                              activeColor: const Color(0xFFDC2626),
                              onChanged: (v) => setState(() => _confirmedPayoutLoss = v ?? false),
                              title: const Text(
                                'I confirm that all pending orders are fulfilled and bank settlements completed.',
                                style: TextStyle(fontSize: 12.5, color: Color(0xFF334155)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Verification Text
                    _buildSectionHeader('TYPE "DELETE" TO CONFIRM'),
                    TextField(
                      controller: _confirmTextCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Type DELETE in capital letters',
                        hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF64748B)),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Red 'Delete Account' Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _canDelete && !_isDeleting ? _showConfirmDeleteDialog : null,
                        icon: _isDeleting
                            ? const SizedBox.shrink()
                            : const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
                        label: _isDeleting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                              )
                            : const Text(
                                'Delete Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          disabledBackgroundColor: const Color(0xFFFCA5A5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.7,
        ),
      ),
    );
  }

  Widget _buildWarningPoint(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 4),
          child: Icon(
            Icons.circle,
            size: 6,
            color: Color(0xFFDC2626),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF7F1D1D),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
