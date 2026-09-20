import 'package:flutter/material.dart';
import 'package:service_hub_partner/features/profile/presentation/controllers/profile_controller.dart';

class DocumentsAndVerificationScreen extends StatelessWidget {
  final ProfileController controller;

  const DocumentsAndVerificationScreen({
    super.key,
    required this.controller,
  });

  void _showDocumentPreview(BuildContext context, String title, String docNumber, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 22),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Document Number:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Text(docNumber, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                  const SizedBox(height: 10),
                  const Text('Status:', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      const Text('Verified & Approved by Admin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(description, style: const TextStyle(fontSize: 12, color: Color(0xFF475569))),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = controller;

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
                          'Documents & Verification',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'View and manage your KYC credentials',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Main Content
            Expanded(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Verified Overview Banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.verified_user_rounded, color: Color(0xFF059669), size: 30),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '100% KYC Verified Partner',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF065F46)),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Your identity, professional skills, and bank account have been reviewed and approved by ServiceHub Admin.',
                                  style: TextStyle(fontSize: 11, color: Color(0xFF047857), height: 1.3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 1: IDENTITY DOCUMENTS
                    _buildSectionHeader('GOVERNMENT IDENTITY PROOFS'),
                    _buildDocumentCard(
                      context: context,
                      icon: Icons.badge_outlined,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      title: 'Aadhaar Card',
                      number: c.aadhaarNumber,
                      subtitle: 'Front & Back verified with UIDAI registry',
                      isVerified: true,
                      onTap: () => _showDocumentPreview(
                        context,
                        'Aadhaar Card',
                        c.aadhaarNumber,
                        'Front and back copies of your Aadhaar card are securely archived and verified.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentCard(
                      context: context,
                      icon: Icons.credit_card_outlined,
                      iconBg: const Color(0xFFFDF4FF),
                      iconColor: const Color(0xFFC026D3),
                      title: 'PAN Card',
                      number: c.panNumber,
                      subtitle: 'Taxpayer identity verified with NSDL',
                      isVerified: true,
                      onTap: () => _showDocumentPreview(
                        context,
                        'PAN Card',
                        c.panNumber,
                        'PAN card details verified for automated tax reporting and payouts.',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 2: PROFESSIONAL & BACKGROUND
                    _buildSectionHeader('TRADE & BACKGROUND CERTIFICATIONS'),
                    _buildDocumentCard(
                      context: context,
                      icon: Icons.workspace_premium_outlined,
                      iconBg: const Color(0xFFFFF7ED),
                      iconColor: const Color(0xFFEA580C),
                      title: 'Trade Skill Certification',
                      number: 'CERT-SH-8842',
                      subtitle: c.tradeCertificate,
                      isVerified: true,
                      onTap: () => _showDocumentPreview(
                        context,
                        'Trade Certification',
                        'CERT-SH-8842',
                        c.tradeCertificate,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDocumentCard(
                      context: context,
                      icon: Icons.gavel_rounded,
                      iconBg: const Color(0xFFF0FDF4),
                      iconColor: const Color(0xFF16A34A),
                      title: 'Police & Background Clearance',
                      number: 'BGC-PASS-2026',
                      subtitle: 'Zero criminal history verified by local authorities',
                      isVerified: true,
                      onTap: () => _showDocumentPreview(
                        context,
                        'Background Clearance',
                        'BGC-PASS-2026',
                        'Complete background screening passed with valid address verification.',
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 3: BANK DETAILS FOR PAYOUTS
                    _buildSectionHeader('PAYOUT BANKING INFORMATION'),
                    _buildDocumentCard(
                      context: context,
                      icon: Icons.account_balance_outlined,
                      iconBg: const Color(0xFFEFF6FF),
                      iconColor: const Color(0xFF2563EB),
                      title: c.bankName,
                      number: 'A/C: ${c.bankAccountNumber}',
                      subtitle: 'IFSC: ${c.ifscCode} • Direct Penny Drop Verified',
                      isVerified: true,
                      onTap: () => _showDocumentPreview(
                        context,
                        'Direct Payout Bank Account',
                        'A/C: ${c.bankAccountNumber}',
                        'Bank: ${c.bankName}\nIFSC: ${c.ifscCode}\nStatus: Active for instant automated daily payouts.',
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Encryption Guarantee Note
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock_outline_rounded, color: Color(0xFF64748B), size: 20),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Banking-Grade Encryption: All your government documents are encrypted using 256-bit AES and never displayed publicly.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF475569), height: 1.3),
                            ),
                          ),
                        ],
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

  Widget _buildDocumentCard({
    required BuildContext context,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String number,
    required String subtitle,
    required bool isVerified,
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
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
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
                    Row(
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Verified',
                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      number,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ),
    );
  }
}
