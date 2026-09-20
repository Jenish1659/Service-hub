import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

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
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Partner Privacy & Data Protection • Updated 2026',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Legal Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildIntroCard(),
                    const SizedBox(height: 16),
                    _buildSection(
                      number: '1',
                      title: 'Information We Collect',
                      content:
                          'To enable partner registration and service operations, ServiceHub collects identity credentials (Aadhaar, PAN, Skill Certification), contact information (mobile number, email), payout details (bank account/IFSC or UPI ID), and device metadata (operating system, app version, IP address).',
                    ),
                    const SizedBox(height: 14),
                    _buildSection(
                      number: '2',
                      title: 'How We Use Partner Data',
                      content:
                          'Your information is strictly utilized to verify KYC authenticity, match incoming customer booking requests within your operating radius, facilitate doorstep service navigation, calculate transparent weekly payouts, and uphold platform safety standards.',
                    ),
                    const SizedBox(height: 14),
                    _buildSection(
                      number: '3',
                      title: 'Location & Telemetry Protection',
                      content:
                          'ServiceHub accesses GPS location only when the partner toggles "Online" or is actively navigating to an accepted customer booking. Background location is paused whenever you toggle "Offline". Your real-time location is never shared publicly or sold to third parties.',
                    ),
                    const SizedBox(height: 14),
                    _buildSection(
                      number: '4',
                      title: 'Customer Masking & Anti-Spam',
                      content:
                          'To protect your privacy, customer communications are routed through secure virtual IVR numbers. Your personal telephone number and permanent residential address remain shielded. Only your verified first name, profile photo, and public rating are displayed to booked customers.',
                    ),
                    const SizedBox(height: 14),
                    _buildSection(
                      number: '5',
                      title: 'Financial Data & AES-256 Encryption',
                      content:
                          'All payout details and identity documents are stored in RBI-compliant, ISO 27001 certified cloud infrastructure secured with military-grade 256-bit AES encryption at rest and TLS 1.3 in transit. Payouts are routed directly via licensed NPCI banking partners.',
                    ),
                    const SizedBox(height: 14),
                    _buildSection(
                      number: '6',
                      title: 'Partner Rights & Data Deletion',
                      content:
                          'You maintain full sovereignty over your personal data. You can request a complete copy of your records or execute an account deletion request at any time through Settings > Delete Account. Upon deletion, personal identifiers are purged within 30 days, subject to mandatory statutory tax retention obligations.',
                    ),
                    const SizedBox(height: 14),
                    _buildSection(
                      number: '7',
                      title: 'Grievance & Privacy Officer Contact',
                      content:
                          'If you have any questions or concerns regarding our privacy practices, you can contact our Data Protection Officer at privacy@servicehub.in or postal mail to: Data Privacy Desk, ServiceHub Technologies Pvt. Ltd., Tech Boulevard, Sector 4, Bangalore, India.',
                    ),
                    const SizedBox(height: 24),
                    _buildFooterNote(),
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

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined, color: Color(0xFF16A34A), size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Privacy is Sacred',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF14532D)),
                ),
                SizedBox(height: 4),
                Text(
                  'We safeguard your personal documents, phone numbers, and banking details with top-tier security standards and end-to-end caller ID masking.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF15803D), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String number, required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x04000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  number,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF475569), height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterNote() {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 28),
          const SizedBox(height: 6),
          const Text(
            'ISO 27001 Certified & RBI Compliant Storage',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 2),
          Text(
            'Effective Date: January 1, 2026',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
