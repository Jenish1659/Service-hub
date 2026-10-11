import 'package:flutter/material.dart';

/// Screen 11: Dedicated Verification Documents Sub-Screen for Care Taker Specialist
class CareDocumentsScreen extends StatelessWidget {
  const CareDocumentsScreen({super.key});

  static const Color primaryIndigo = Color(0xFF4F46E5);
  static const Color darkSlate = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color scaffoldBg = Color(0xFFF8FAFC);

  final List<Map<String, dynamic>> _documents = const [
    {
      'title': 'Aadhar Card',
      'status': 'Uploaded',
      'icon': Icons.badge_outlined,
      'color': Color(0xFFF59E0B),
      'verified': true,
    },
    {
      'title': 'PAN Card',
      'status': 'Uploaded',
      'icon': Icons.credit_card_rounded,
      'color': Color(0xFF10B981),
      'verified': true,
    },
    {
      'title': 'Caregiver Certificate',
      'status': 'Uploaded',
      'icon': Icons.workspace_premium_rounded,
      'color': Color(0xFF6366F1),
      'verified': true,
    },
    {
      'title': 'Medical Training Cert.',
      'status': 'Uploaded',
      'icon': Icons.medical_services_outlined,
      'color': Color(0xFF0EA5E9),
      'verified': true,
    },
    {
      'title': 'Background Verification',
      'status': 'Uploaded',
      'icon': Icons.verified_user_outlined,
      'color': Color(0xFF10B981),
      'verified': true,
    },
    {
      'title': 'Profile Photo',
      'status': 'Uploaded',
      'icon': Icons.account_box_outlined,
      'color': Color(0xFFEC4899),
      'verified': true,
    },
  ];

  void _showDocumentPreview(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cardBorder),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 48),
                    SizedBox(height: 8),
                    Text(
                      'Document Verified & Encrypted',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: darkSlate),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Official Government / Board Validated',
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryIndigo,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: const Text(
          'Verification Documents',
          style: TextStyle(color: darkSlate, fontSize: 17, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: darkSlate, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _documents.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final doc = _documents[index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: cardBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (doc['color'] as Color).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(doc['icon'] as IconData, color: doc['color'] as Color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doc['title'].toString(),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: darkSlate),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              doc['status'].toString(),
                              style: const TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: primaryIndigo,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () => _showDocumentPreview(context, doc['title'].toString()),
                        child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Update Documents Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryIndigo,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Document upload channel ready for camera & gallery scan'),
                      backgroundColor: primaryIndigo,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Update Documents', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
