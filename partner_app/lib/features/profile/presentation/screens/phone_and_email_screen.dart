import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/core/storage/local_registration_cache.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';

class PhoneAndEmailScreen extends StatefulWidget {
  final ProfileController controller;

  const PhoneAndEmailScreen({
    super.key,
    required this.controller,
  });

  @override
  State<PhoneAndEmailScreen> createState() => _PhoneAndEmailScreenState();
}

class _PhoneAndEmailScreenState extends State<PhoneAndEmailScreen> {
  late TextEditingController _emergencyPhoneCtrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _emergencyPhoneCtrl = TextEditingController(
      text: (widget.controller.partnerData?['emergency_phone'] ?? '').toString().trim(),
    );
  }

  @override
  void dispose() {
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  void _showUpdatePhoneSheet() {
    final phoneCtrl = TextEditingController();
    final otpCtrl = TextEditingController();
    bool otpSent = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Update Mobile Number', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('We will send a 6-digit verification OTP to your new phone number.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
              const SizedBox(height: 16),
              if (!otpSent) ...[
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 10,
                  buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(fontSize: 13.5),
                  decoration: const InputDecoration(
                    prefixText: '+91 ',
                    labelText: 'New Mobile Number',
                    hintText: '98765 00000',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (phoneCtrl.text.trim().length < 10) {
                        TopToast.show(context, 'Enter a valid 10-digit number', isError: true);
                        return;
                      }
                      setSheetState(() => otpSent = true);
                      TopToast.show(context, 'OTP sent to +91 ${phoneCtrl.text.trim()}', isError: false);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                    child: const Text('Send Verification OTP'),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: otpCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 3),
                  decoration: const InputDecoration(
                    labelText: 'Enter 6-Digit OTP',
                    hintText: '123456',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (otpCtrl.text.trim().length != 6) {
                        TopToast.show(context, 'Enter complete 6-digit OTP', isError: true);
                        return;
                      }
                      final newPhone = '+91 ${phoneCtrl.text.trim()}';
                      widget.controller.phoneNumber = newPhone;
                      setState(() {});
                      Navigator.pop(ctx);
                      TopToast.show(context, 'Mobile number updated and verified!', isError: false);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF16A34A), foregroundColor: Colors.white),
                    child: const Text('Verify & Update Phone'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showUpdateEmailSheet() {
    final emailCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Update Email Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text('Tax invoices and daily earning summaries will be sent to this email.', style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(fontSize: 13.5),
              decoration: const InputDecoration(
                labelText: 'New Email Address',
                hintText: 'partner@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final email = emailCtrl.text.trim();
                  if (!email.contains('@') || !email.contains('.')) {
                    TopToast.show(context, 'Enter a valid email address', isError: true);
                    return;
                  }
                  widget.controller.emailAddress = email;
                  setState(() {});
                  Navigator.pop(ctx);
                  TopToast.show(context, 'Email updated and verification link sent!', isError: false);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
                child: const Text('Update Email'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isSaving = true);
    final emergency = _emergencyPhoneCtrl.text.trim();
    if (emergency.isNotEmpty) {
      await LocalRegistrationCache.updateActivePartner({'emergency_phone': emergency});
    }
    await widget.controller.saveProfileDetails(
      name: widget.controller.partnerName,
      phone: widget.controller.phoneNumber,
      email: widget.controller.emailAddress,
      dob: widget.controller.dateOfBirth,
      bizName: widget.controller.businessName,
      exp: widget.controller.experienceYears,
      bio: widget.controller.shortBio,
      city: widget.controller.serviceCity,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    TopToast.show(context, 'Contact preferences saved and updated in database successfully!', isError: false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;

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
                          'Phone & Email',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Manage your verified contact information',
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Phone
                    _buildContactCard(
                      icon: Icons.phone_android_rounded,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Primary Mobile Number',
                      value: c.phoneNumber.isNotEmpty ? c.phoneNumber : 'Not Linked',
                      description: 'Used for live dispatch incoming alerts, SMS OTP authentication, and customer coordination calls.',
                      buttonLabel: 'Update Mobile',
                      onButtonTap: _showUpdatePhoneSheet,
                    ),
                    const SizedBox(height: 16),

                    // Card 2: Email
                    _buildContactCard(
                      icon: Icons.mail_outline_rounded,
                      iconBg: const Color(0xFFFDF4FF),
                      iconColor: const Color(0xFFC026D3),
                      title: 'Primary Email Address',
                      value: c.emailAddress.isNotEmpty ? c.emailAddress : 'partner@servicehub.in',
                      description: 'Used for automated daily payout summaries, monthly earnings invoices, and official platform notifications.',
                      buttonLabel: 'Update Email',
                      onButtonTap: _showUpdateEmailSheet,
                    ),
                    const SizedBox(height: 16),

                    // Card 3: Emergency Contact
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                                child: const Icon(Icons.emergency_outlined, color: Color(0xFFD97706), size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Emergency Backup Contact', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                    Text('Alternate contact reachable during field jobs', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: _emergencyPhoneCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              labelText: 'Alternate Phone Number',
                              hintText: '98250 00000',
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: _isSaving
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded, size: 20),
                        label: Text(
                          _isSaving ? 'Saving...' : 'Save Contact Details',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
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

  Widget _buildContactCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String description,
    required String buttonLabel,
    required VoidCallback onButtonTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            value,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                          child: const Text('Verified', style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(description, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.3)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onButtonTap,
            icon: const Icon(Icons.edit_outlined, size: 14),
            label: Text(buttonLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              side: const BorderSide(color: Color(0xFFCBD5E1)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }
}
