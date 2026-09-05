import 'package:flutter/material.dart';

class AdminAIOperationsView extends StatefulWidget {
  const AdminAIOperationsView({super.key});

  @override
  State<AdminAIOperationsView> createState() => _AdminAIOperationsViewState();
}

class _AdminAIOperationsViewState extends State<AdminAIOperationsView> {
  double _matchingRadius = 15.0;
  double _minTrustScore = 98.0;
  bool _autoApproveLowRisk = true;
  bool _liveBiometricsStrict = true;

  final List<Map<String, dynamic>> _aiLogs = [
    {
      'timestamp': 'Just now',
      'module': 'Aadhaar Verhoeff Engine',
      'target': 'SHB-1788429693914',
      'result': 'PASSED (Checksum & QR Signature Authentic)',
      'status': 'SUCCESS',
    },
    {
      'timestamp': '5 mins ago',
      'module': 'FaceRD Biometric Liveness',
      'target': 'SHB-1788429693914',
      'result': 'MATCHED (Confidence: 99.4%, Passive 3D Verified)',
      'status': 'SUCCESS',
    },
    {
      'timestamp': '12 mins ago',
      'module': 'Bank Penny Drop (NPCI / IMPS)',
      'target': 'HDFC0000456 (₹1.00)',
      'result': 'MATCHED (Beneficiary Name Match 100%)',
      'status': 'SUCCESS',
    },
    {
      'timestamp': '30 mins ago',
      'module': 'AC Smart Dispatch AI',
      'target': 'Booking AC_1788204910',
      'result': 'Dispatched to Rajesh Sharma (Distance: 1.8km, Rating: 4.9)',
      'status': 'SUCCESS',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI Operations & Security Intelligence Engine', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                  const SizedBox(height: 3),
                  Text('Autonomous KYC verification software, fraud defense telemetry, FaceRD neural matching, and smart dispatch tuning', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade600)),
                ],
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFBBF7D0))),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFF059669), size: 16),
                    SizedBox(width: 4),
                    Text('AI Core: Online & Active', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF059669))),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 2 Column layout: Settings & Telemetry Log
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column: Parameters
                Expanded(
                  flex: 4,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AI Dispatch & Verification Thresholds', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                        const SizedBox(height: 16),

                        // Radius Slider
                        Text('Smart Dispatch Maximum Search Radius: ${_matchingRadius.toStringAsFixed(0)} km', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Slider(
                          value: _matchingRadius,
                          min: 5.0,
                          max: 30.0,
                          divisions: 25,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (v) => setState(() => _matchingRadius = v),
                        ),
                        const SizedBox(height: 14),

                        // Trust Score Threshold
                        Text('Minimum AI Trust Score Required: ${_minTrustScore.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Slider(
                          value: _minTrustScore,
                          min: 90.0,
                          max: 99.9,
                          divisions: 99,
                          activeColor: const Color(0xFF10B981),
                          onChanged: (v) => setState(() => _minTrustScore = v),
                        ),
                        const SizedBox(height: 14),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Auto-Flag High Risk KYC Candidates', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Instantly holds candidates with Risk Score > 0.05', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          value: _autoApproveLowRisk,
                          activeThumbColor: const Color(0xFF2563EB),
                          onChanged: (v) => setState(() => _autoApproveLowRisk = v),
                        ),

                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Strict FaceRD Biometric 3D Liveness', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: const Text('Enforces UIDAI neural anti-spoofing checks', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          value: _liveBiometricsStrict,
                          activeThumbColor: const Color(0xFF2563EB),
                          onChanged: (v) => setState(() => _liveBiometricsStrict = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 20),

                // Right Column: Live AI Telemetry Logs
                Expanded(
                  flex: 6,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Real-time AI Inspection & Verification Telemetry', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(6)),
                              child: const Text('LIVE STREAM', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        Expanded(
                          child: ListView.separated(
                            itemCount: _aiLogs.length,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
                            itemBuilder: (ctx, idx) {
                              final log = _aiLogs[idx];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(log['module'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F172A))),
                                              Text(log['timestamp'], style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text('Target: ${log['target']}', style: const TextStyle(fontSize: 11.5, color: Color(0xFF2563EB), fontFamily: 'monospace')),
                                          const SizedBox(height: 2),
                                          Text(log['result'], style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
                                        ],
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
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
