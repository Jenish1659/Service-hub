import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

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
                          'Terms & Conditions',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'ServiceHub Partner Agreement • Version 2026.1',
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
                      title: 'Partner Relationship & Eligibility',
                      content:
                          'By registering as a Service Provider, Delivery Agent, or Shopkeeper on ServiceHub, you confirm that you are at least 18 years of age, legally eligible to work in India, and have provided genuine Aadhaar, PAN, and address credentials. You operate as an independent professional partner and not an employee of ServiceHub Technologies.',
                    ),
                    _buildSection(
                      number: '2',
                      title: 'Service Standards & Safety Conduct',
                      content:
                          'Partners agree to deliver high-quality, professional services to customers with utmost courtesy and safety. You agree to adhere to standard industry safety guidelines, carry appropriate certified tools, wear identification badges, and respect customer property and privacy.',
                    ),
                    _buildSection(
                      number: '3',
                      title: 'Transparent Pricing & Direct Payouts',
                      content:
                          'All service pricing is established by verified catalog rates. Partners must not charge arbitrary cash surcharges without customer consent and platform billing. Completed bookings are settled via automated direct bank payouts minus applicable platform service fees.',
                    ),
                    _buildSection(
                      number: '4',
                      title: 'Doorstep Cancellations & Inspection Guarantee',
                      content:
                          'If a customer cancels an on-demand booking after you have arrived at their registered service address, a guaranteed doorstep inspection fee of ₹150 is credited directly to your partner wallet to compensate for fuel and travel time.',
                    ),
                    _buildSection(
                      number: '5',
                      title: 'Zero Tolerance Fraud & Misconduct Policy',
                      content:
                          'ServiceHub maintains a zero-tolerance policy against fraudulent billing, abusive behavior toward customers or staff, off-platform solicitation, or submitting fabricated KYC documents. Violations result in immediate suspension and forfeiture of unverified balances.',
                    ),
                    _buildSection(
                      number: '6',
                      title: 'Account Termination',
                      content:
                          'Partners may choose to deactivate or delete their account at any time via the Partner App settings, provided all active service jobs have been concluded and settled.',
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Questions regarding our partner agreement? Contact legal@servicehub.in',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
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

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Row(
        children: [
          Icon(Icons.gavel_rounded, color: Color(0xFF2563EB), size: 26),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Please read these terms carefully before delivering services on the ServiceHub network.',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF0F172A), height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String number, required String title, required String content}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(number, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(content, style: const TextStyle(fontSize: 12, color: Color(0xFF475569), height: 1.45)),
        ],
      ),
    );
  }
}
