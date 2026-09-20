import 'package:flutter/material.dart';
import 'package:service_hub_partner/core/widgets/top_toast.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';

class HelpAndSupportScreen extends StatefulWidget {
  final ProfileController controller;

  const HelpAndSupportScreen({
    super.key,
    required this.controller,
  });

  @override
  State<HelpAndSupportScreen> createState() => _HelpAndSupportScreenState();
}

class _HelpAndSupportScreenState extends State<HelpAndSupportScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _subjectCtrl = TextEditingController();
  final TextEditingController _messageCtrl = TextEditingController();
  String _selectedCategory = 'Payments & Payouts';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Payments & Payouts',
    'Job Dispatch & Requests',
    'Profile & KYC Verification',
    'Customer Issues & Cancellation',
    'App Technical Bug',
    'Other Inquiries',
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _handleSubmitTicket() {
    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      TopToast.show(context, 'Please enter subject and message details', isError: true);
      return;
    }
    setState(() => _isSubmitting = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _subjectCtrl.clear();
      _messageCtrl.clear();
      TopToast.show(context, 'Support ticket submitted! Ticket ID: #TK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}', isError: false);
    });
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
                          'Help & Support',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '24/7 dedicated partner assistance',
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
                    // Search Bar
                    TextField(
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        hintText: 'Search help topics, FAQs, guides...',
                        prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF64748B), size: 20),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Quick Action Grid (2x2)
                    Row(
                      children: [
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.phone_in_talk_rounded,
                            iconBg: const Color(0xFFEFF6FF),
                            iconColor: const Color(0xFF2563EB),
                            title: 'Toll-Free Call',
                            subtitle: '1800-123-SERVICE',
                            badgeText: '24/7 Active',
                            badgeColor: const Color(0xFFDCFCE7),
                            badgeTextColor: const Color(0xFF16A34A),
                            onTap: () => TopToast.show(context, 'Dialing Partner Support Hotline: 1800-123-SERVICE', isError: false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.chat_rounded,
                            iconBg: const Color(0xFFF0FDF4),
                            iconColor: const Color(0xFF16A34A),
                            title: 'WhatsApp Chat',
                            subtitle: 'Instant response',
                            badgeText: '< 2 min',
                            badgeColor: const Color(0xFFEFF6FF),
                            badgeTextColor: const Color(0xFF2563EB),
                            onTap: () => TopToast.show(context, 'Connecting to WhatsApp Support Desk...', isError: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.mail_outline_rounded,
                            iconBg: const Color(0xFFF3E8FF),
                            iconColor: const Color(0xFF9333EA),
                            title: 'Email Support',
                            subtitle: 'partner@servicehub.in',
                            badgeText: 'Official Desk',
                            badgeColor: const Color(0xFFF1F5F9),
                            badgeTextColor: const Color(0xFF475569),
                            onTap: () => TopToast.show(context, 'Email copied: partner@servicehub.in', isError: false),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.confirmation_number_outlined,
                            iconBg: const Color(0xFFFFEDD5),
                            iconColor: const Color(0xFFEA580C),
                            title: 'My Tickets',
                            subtitle: 'Track your issues',
                            badgeText: '0 Active',
                            badgeColor: const Color(0xFFFEF3C7),
                            badgeTextColor: const Color(0xFFD97706),
                            onTap: () => TopToast.show(context, 'All your past tickets are resolved.', isError: false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Frequently Asked Questions
                    _buildSectionHeader('FREQUENTLY ASKED QUESTIONS'),
                    _buildFaqItem(
                      question: 'How do I receive and accept service requests?',
                      answer:
                          'When a customer in your service radius books a service matching your skill category, you will receive an incoming job alert with sound. Review the customer area, scheduled time, and estimated earnings, then click Accept within 60 seconds.',
                    ),
                    _buildFaqItem(
                      question: 'When and how will my earnings be credited?',
                      answer:
                          'ServiceHub processes automated direct bank payouts daily for all completed and customer-paid orders. Payouts are credited directly into your verified bank account.',
                    ),
                    _buildFaqItem(
                      question: 'What happens if a customer cancels at the doorstep?',
                      answer:
                          'If a customer cancels after you have arrived at the job site, an automatic doorstep inspection fee of ₹150 is credited to your wallet to cover fuel and travel expenses.',
                    ),
                    _buildFaqItem(
                      question: 'How do I change my service radius or working hours?',
                      answer:
                          'You can adjust your service radius (1 to 50 km) anytime from My Profile -> Service Area, and customize your working hours and days from My Profile -> Availability.',
                    ),
                    _buildFaqItem(
                      question: 'How does my rating affect job dispatch?',
                      answer:
                          'Partners with a customer rating of 4.5 or higher receive preferential dispatch for high-value and recurring customer bookings.',
                    ),
                    const SizedBox(height: 22),

                    // Submit Support Ticket Card
                    _buildSectionHeader('STILL HAVE QUESTIONS? SUBMIT A QUERY'),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: const [
                          BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Issue Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedCategory,
                            isDense: true,
                            decoration: InputDecoration(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12.5)))).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedCategory = v);
                            },
                          ),
                          const SizedBox(height: 12),
                          const Text('Subject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _subjectCtrl,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Brief summary of the issue',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('Detailed Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _messageCtrl,
                            maxLines: 3,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Explain the issue with relevant order/booking details...',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              filled: true,
                              fillColor: const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 46,
                            child: ElevatedButton.icon(
                              onPressed: _isSubmitting ? null : _handleSubmitTicket,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: _isSubmitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.send_rounded, size: 18),
                              label: Text(
                                _isSubmitting ? 'Submitting...' : 'Submit Support Ticket',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
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
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required Color badgeTextColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x05000000), blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: iconColor, size: 20),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: badgeColor, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      badgeText,
                      style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: badgeTextColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({required String question, required String answer}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            title: Text(
              question,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            children: [
              Text(
                answer,
                style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
