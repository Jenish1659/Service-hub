import 'package:flutter/material.dart';

class AdminPartnersView extends StatelessWidget {
  final List<Map<String, dynamic>> unverifiedPartners;
  final Function(String id, String name) onApprove;
  final Function(String id, String name) onReject;

  const AdminPartnersView({
    super.key,
    required this.unverifiedPartners,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Partner Verification & KYC Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  SizedBox(height: 2),
                  Text('AI Pre-Verified candidate applications requiring administrative approval', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBFDBFE))),
                child: Row(
                  children: [
                    const Icon(Icons.verified_user_rounded, color: Color(0xFF2563EB), size: 16),
                    const SizedBox(width: 6),
                    Text('${unverifiedPartners.length} Pending Approvals', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF1E40AF))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          Expanded(
            child: unverifiedPartners.isEmpty
                ? Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE2E8F0))),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 56, color: Color(0xFF10B981)),
                          SizedBox(height: 12),
                          Text('All KYC applications verified & up to date!', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: unverifiedPartners.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, idx) {
                      final p = unverifiedPartners[idx];
                      final id = p['id'] ?? p['verification_id'] ?? 'PID-1';
                      final name = p['name'] ?? p['full_name'] ?? 'Partner Candidate';
                      final phone = p['phone'] ?? '+91 98765 43210';
                      final city = p['city'] ?? 'Jamnagar';
                      final riskScore = p['ai_risk_score'] ?? 0.02;
                      final trustScore = p['trust_score'] ?? 99.8;

                      return Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: const Color(0xFFEFF6FF),
                              child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB), fontSize: 16)),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(6)),
                                        child: Text('AI Trust: $trustScore%', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text('Phone: $phone • City: $city • Risk Score: $riskScore', style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFEF4444)),
                                foregroundColor: const Color(0xFFEF4444),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => onReject(id, name),
                              child: const Text('Reject'),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.verified_rounded, size: 16),
                              label: const Text('Approve & Activate'),
                              onPressed: () => onApprove(id, name),
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
  }
}
