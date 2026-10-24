import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomerHelpSupportScreen extends StatefulWidget {
  const CustomerHelpSupportScreen({super.key});

  @override
  State<CustomerHelpSupportScreen> createState() => _CustomerHelpSupportScreenState();
}

class _CustomerHelpSupportScreenState extends State<CustomerHelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color borderGrey = Color(0xFFE2E8F0);

  final List<Map<String, String>> _allFaqs = [
    {
      'question': 'How do I track my active booking?',
      'answer': 'You can track your service technician or delivery agent live from the "My Bookings" tab by tapping your active booking and selecting "Track on Map".',
    },
    {
      'question': 'What payment methods are supported?',
      'answer': 'We support all major UPI apps (Google Pay, PhonePe, Paytm), Net Banking, Debit/Credit Cards, and Cash on Delivery.',
    },
    {
      'question': 'How can I reschedule or cancel a booking?',
      'answer': 'Navigate to "My Bookings", select the booking, and tap "Reschedule" or "Cancel Booking". Cancellation is completely free before partner dispatch.',
    },
    {
      'question': 'Are ServiceHub professionals verified?',
      'answer': 'Yes, 100% of our service providers, plumbers, mechanics, cooks, and caretakers undergo mandatory KYC verification and background checks.',
    },
    {
      'question': 'What if I am unhappy with the service?',
      'answer': 'You can use the "Raise a Complaint" option below or contact our 24/7 customer care team for a free revisit or full refund.',
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFaqDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, scrollController) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkSlate)),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: _allFaqs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, idx) {
                      final item = _allFaqs[idx];
                      return Theme(
                        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                        child: ExpansionTile(
                          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                          backgroundColor: const Color(0xFFF8FAFC),
                          collapsedBackgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: borderGrey),
                          ),
                          collapsedShape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: borderGrey),
                          ),
                          title: Text(
                            item['question']!,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 14),
                              child: Text(
                                item['answer']!,
                                style: const TextStyle(fontSize: 13, color: textMuted, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showContactSupportModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contact Customer Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkSlate)),
            const SizedBox(height: 8),
            const Text('Our customer satisfaction experts are available 24/7 to assist you.', style: TextStyle(fontSize: 13, color: textMuted)),
            const SizedBox(height: 20),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: borderGrey)),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                child: const Icon(Icons.call_rounded, color: primaryBlue, size: 20),
              ),
              title: const Text('24/7 Toll-Free Hotline', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text('+91 1800 200 9999', style: TextStyle(fontSize: 13, color: primaryBlue, fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dialing Customer Support: +91 1800 200 9999')),
                );
              },
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: borderGrey)),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: primaryBlue, size: 20),
              ),
              title: const Text('Live Support Chat', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              subtitle: const Text('Instant in-app AI & human resolution', style: TextStyle(fontSize: 13, color: textMuted)),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/support');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showComplaintDialog() {
    final issueController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Raise a Complaint', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Please describe the problem you experienced with your service.', style: TextStyle(fontSize: 13, color: textMuted)),
            const SizedBox(height: 12),
            TextField(
              controller: issueController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Enter complaint details here...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final dynamicTicketId = 'TKT-${DateTime.now().millisecondsSinceEpoch % 100000}';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✓ Ticket #$dynamicTicketId created! Support team will reach out within 1 hour.'),
                  backgroundColor: const Color(0xFF10B981),
                ),
              );
            },
            child: const Text('Submit Ticket'),
          ),
        ],
      ),
    );
  }

  void _showFeedbackDialog() {
    int rating = 5;
    final feedbackController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Share Your Feedback', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        return InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => setDialogState(() => rating = index + 1),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                            child: Icon(
                              index < rating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: const Color(0xFFF59E0B),
                              size: 30,
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: feedbackController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tell us how we can make ServiceHub even better...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: textMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Thank you for your feedback!'),
                    backgroundColor: Color(0xFF10B981),
                  ),
                );
              },
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuidesSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('ServiceHub User Guides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: darkSlate)),
            const SizedBox(height: 14),
            _buildGuideItem('1. Select Your Service', 'Browse from AC, Plumbing, Laundry, Car, Care Taker, or Cooking.'),
            _buildGuideItem('2. Pick Date & Schedule', 'Select a convenient appointment slot or request immediate arrival.'),
            _buildGuideItem('3. Track Live on Radar', 'Watch your verified partner arrive on the interactive map.'),
            _buildGuideItem('4. Secure Handshake OTP', 'Share your 4-digit completion code only when job is fully satisfied.'),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF10B981), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: darkSlate)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 12.5, color: textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
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
          'Help & Support',
          style: TextStyle(color: darkSlate, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: [
            // Search Input
            TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search for help...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF94A3B8), size: 22),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: borderGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: borderGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: primaryBlue, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // If user searched, show matching FAQs
            if (_searchQuery.isNotEmpty) ...[
              ..._allFaqs
                  .where((f) => f['question']!.toLowerCase().contains(_searchQuery) || f['answer']!.toLowerCase().contains(_searchQuery))
                  .map((f) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderGrey),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(f['question']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: darkSlate)),
                            const SizedBox(height: 4),
                            Text(f['answer']!, style: const TextStyle(fontSize: 12.5, color: textMuted)),
                          ],
                        ),
                      )),
              const SizedBox(height: 10),
            ],

            // 5 Support Option Cards matching mockup
            _buildOptionCard(
              icon: Icons.help_outline_rounded,
              iconBg: const Color(0xFFEFF6FF),
              iconColor: primaryBlue,
              title: 'FAQs',
              subtitle: 'Find answers to common questions',
              onTap: _showFaqDialog,
            ),
            const SizedBox(height: 12),

            _buildOptionCard(
              icon: Icons.headset_mic_rounded,
              iconBg: const Color(0xFFEFF6FF),
              iconColor: primaryBlue,
              title: 'Contact Support',
              subtitle: 'Chat, call or email us',
              onTap: _showContactSupportModal,
            ),
            const SizedBox(height: 12),

            _buildOptionCard(
              icon: Icons.report_problem_outlined,
              iconBg: const Color(0xFFFFF1F2),
              iconColor: const Color(0xFFEF4444),
              title: 'Raise a Complaint',
              subtitle: 'Report an issue with a service',
              onTap: _showComplaintDialog,
            ),
            const SizedBox(height: 12),

            _buildOptionCard(
              icon: Icons.rate_review_outlined,
              iconBg: const Color(0xFFFAF5FF),
              iconColor: const Color(0xFF9333EA),
              title: 'Feedback',
              subtitle: 'Share your suggestions',
              onTap: _showFeedbackDialog,
            ),
            const SizedBox(height: 12),

            _buildOptionCard(
              icon: Icons.menu_book_outlined,
              iconBg: const Color(0xFFECFDF5),
              iconColor: const Color(0xFF10B981),
              title: 'Service Guides',
              subtitle: 'Learn how to book and use services',
              onTap: _showGuidesSheet,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderGrey),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: darkSlate,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }
}
