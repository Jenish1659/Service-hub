import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

import '../controllers/delivery_agent_profile_controller.dart';

class DeliveryHelpSupportScreen extends StatefulWidget {
  final DeliveryAgentProfileController? controller;
  const DeliveryHelpSupportScreen({super.key, this.controller});

  @override
  State<DeliveryHelpSupportScreen> createState() => _DeliveryHelpSupportScreenState();
}

class _DeliveryHelpSupportScreenState extends State<DeliveryHelpSupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, String>> _faqs = [
    {
      'q': 'What should I do if the merchant/store is closed upon arrival?',
      'a': 'Do not cancel the order yourself. Tap "Report Store Closed" in the active delivery screen. Take a photo of the closed storefront. Support will verify and compensate your transit fare.',
    },
    {
      'q': 'How does customer delivery OTP verification work?',
      'a': 'Never hand over parcels without receiving the delivery OTP. The customer will provide a secure dynamic OTP upon arrival. Enter the digits in the delivery app to mark the order delivered.',
    },
    {
      'q': 'When are weekly earnings deposited into my bank account?',
      'a': 'Weekly earnings from Monday to Sunday are processed every Tuesday morning and deposited directly to your verified bank account via IMPS/NEFT without withdrawal fees.',
    },
    {
      'q': 'How do I change my registered delivery vehicle or DL?',
      'a': 'Go to "Documents & Verification" in your profile and select "Upload New RC" or "Upload New DL". Our verification team reviews document changes within 2 to 4 business hours.',
    },
    {
      'q': 'What happens if my bike has a breakdown during an active delivery?',
      'a': 'Immediately press the "Emergency SOS" button or contact Partner Support. Our local Jamnagar dispatch manager will reassign another nearby rider to complete the delivery safely.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _triggerEmergencySos() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.emergency_rounded, color: Color(0xFFEF4444), size: 24),
            ),
            const SizedBox(width: 12),
            const Text('Emergency SOS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you in immediate danger or experienced a road accident?',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF0F172A)),
            ),
            SizedBox(height: 8),
            Text(
              'Tapping "Call Emergency (112)" will connect you to national emergency services. Our operations team will also receive your live GPS coordinate instantly.',
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Dialing Police & Medical Emergency (112)...'),
                  backgroundColor: Color(0xFFEF4444),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.call, size: 18),
            label: const Text('Call 112'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const orangeColor = AppColors.deliveryOrangeDark;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help & Support',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: orangeColor,
          labelColor: orangeColor,
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Support & FAQs'),
            Tab(text: 'About App'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSupportTab(orangeColor),
          _buildAboutTab(orangeColor),
        ],
      ),
    );
  }

  Widget _buildSupportTab(Color orangeColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // SOS Emergency Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFEF2F2), Color(0xFFFEE2E2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFEF4444),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Emergency Rider SOS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF991B1B)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'One-tap immediate assistance & police beacon',
                      style: TextStyle(fontSize: 11.5, color: Color(0xFF7F1D1D)),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _triggerEmergencySos,
                child: const Text('SOS', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Contact Channels
        Row(
          children: [
            Expanded(
              child: _buildContactTile(
                icon: Icons.support_agent_rounded,
                iconColor: const Color(0xFF2563EB),
                title: 'Rider Helpline',
                subtitle: '+91 1800 200 9999',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dialing ServiceHub Rider Helpline: 1800-200-9999'),
                      backgroundColor: Color(0xFF2563EB),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildContactTile(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF059669),
                title: 'WhatsApp Chat',
                subtitle: 'Jamnagar Hub Help',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Opening ServiceHub Partner WhatsApp Chat...'),
                      backgroundColor: Color(0xFF059669),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Frequently Asked Questions
        const Text(
          'FREQUENTLY ASKED QUESTIONS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8, color: Color(0xFF94A3B8)),
        ),
        const SizedBox(height: 10),
        ..._faqs.map((faq) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                shape: const RoundedRectangleBorder(side: BorderSide.none),
                title: Text(
                  faq['q']!,
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                children: [
                  Text(
                    faq['a']!,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.4),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildAboutTab(Color orangeColor) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEA580C), Color(0xFFC2410C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(color: Color(0x33EA580C), blurRadius: 16, offset: Offset(0, 6)),
                  ],
                ),
                child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 14),
              const Text(
                'ServiceHub Delivery Partner',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 4),
              const Text(
                'Version 1.0.0 (Build 100) • Jamnagar Fleet',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.description_outlined, color: Color(0xFF475569)),
                title: const Text('Terms of Service', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: Color(0xFF475569)),
                title: const Text('Privacy Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                onTap: () {},
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: const Icon(Icons.source_outlined, color: Color(0xFF475569)),
                title: const Text('Open Source Licenses', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFF94A3B8)),
                onTap: () {},
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Center(
          child: Text(
            'Made with ❤️ in Jamnagar, Gujarat\n© 2026 ServiceHub Technologies Inc.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8), height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }
}
