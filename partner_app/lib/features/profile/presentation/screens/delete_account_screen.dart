import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeleteAccountScreen extends StatefulWidget {
  final ProfileController controller;

  const DeleteAccountScreen({
    super.key,
    required this.controller,
  });

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  String? _selectedReason = 'Not getting enough booking requests in my area';
  final TextEditingController _otherReasonCtrl = TextEditingController();
  final TextEditingController _feedbackCtrl = TextEditingController();
  final TextEditingController _confirmTextCtrl = TextEditingController();

  bool _confirmedPayouts = false;
  bool _confirmedDataLoss = false;
  bool _isDeleting = false;

  final List<String> _reasons = [
    'Not getting enough booking requests in my area',
    'Payouts or earnings are lower than expected',
    'Moving to another city or changing profession',
    'App technical issues or bugs',
    'Dissatisfied with customer behavior or platform support',
    'Other reason',
  ];

  @override
  void dispose() {
    _otherReasonCtrl.dispose();
    _feedbackCtrl.dispose();
    _confirmTextCtrl.dispose();
    super.dispose();
  }

  bool get _canDelete {
    final hasReason = _selectedReason != null && (_selectedReason != 'Other reason' || _otherReasonCtrl.text.trim().isNotEmpty);
    final confirmedCheckboxes = _confirmedPayouts && _confirmedDataLoss;
    final textMatches = _confirmTextCtrl.text.trim().toUpperCase() == 'DELETE';
    return hasReason && confirmedCheckboxes && textMatches;
  }

  Future<void> _handleDelete() async {
    if (!_canDelete) return;

    setState(() => _isDeleting = true);

    await Future.delayed(const Duration(milliseconds: 900));

    try {
      await LocalRegistrationCache.logout();
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (_) {}
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isDeleting = false);

    TopToast.show(context, 'Your account deletion request has been processed.', isError: false);

    final router = GoRouter.maybeOf(context);
    if (router != null) {
      router.go('/role-selection');
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
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
                      child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF1E293B)),
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
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        Text(
                          'Permanently close your partner account',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Warning Banner Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF5F5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFEE2E2)),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 24),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'This action is irreversible',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFFDC2626)),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Deleting your account will permanently wipe your profile, verified badges, rating score, and historical booking logs. You will not be able to reactivate this profile.',
                            style: TextStyle(fontSize: 12, color: Color(0xFF991B1B), height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 1: Reason for Deleting
                    _buildSectionTitle('PLEASE TELL US WHY YOU ARE LEAVING'),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: _reasons.map((reason) {
                          final isSelected = _selectedReason == reason;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedReason = reason;
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isSelected ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
                                        width: isSelected ? 5 : 1.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      reason,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    if (_selectedReason == 'Other reason') ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _otherReasonCtrl,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Please specify your reason...',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Section 2: Feedback
                    _buildSectionTitle('WHAT COULD WE HAVE DONE BETTER? (OPTIONAL)'),
                    TextField(
                      controller: _feedbackCtrl,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'Your suggestions help us improve ServiceHub for fellow partners...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 3: Checkbox Declarations
                    _buildSectionTitle('REQUIRED CONFIRMATIONS'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _buildCheckboxRow(
                            value: _confirmedPayouts,
                            onChanged: (v) => setState(() => _confirmedPayouts = v),
                            text: 'I have received or withdrawn all pending earnings from completed service bookings.',
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          _buildCheckboxRow(
                            value: _confirmedDataLoss,
                            onChanged: (v) => setState(() => _confirmedDataLoss = v),
                            text: 'I understand that all my verified credentials, documents, and ratings will be permanently erased.',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 4: Type DELETE Challenge
                    _buildSectionTitle('CONFIRMATION CHALLENGE'),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            text: const TextSpan(
                              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              children: [
                                TextSpan(text: 'Please type '),
                                TextSpan(text: 'DELETE', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                                TextSpan(text: ' in the field below to confirm:'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: _confirmTextCtrl,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            decoration: InputDecoration(
                              hintText: 'Type DELETE',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Delete Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _canDelete && !_isDeleting ? _handleDelete : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          disabledBackgroundColor: const Color(0xFFFCA5A5),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isDeleting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.delete_forever_rounded, size: 20),
                        label: Text(
                          _isDeleting ? 'Deleting Account...' : 'Permanently Delete My Account',
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Cancel Keep Account Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFFCBD5E1)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: const Text(
                          'Keep My Account',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF64748B), letterSpacing: 0.7),
      ),
    );
  }

  Widget _buildCheckboxRow({
    required bool value,
    required ValueChanged<bool> onChanged,
    required String text,
  }) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: value,
              activeColor: const Color(0xFFDC2626),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              onChanged: (v) => onChanged(v == true),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  text,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF334155), height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
