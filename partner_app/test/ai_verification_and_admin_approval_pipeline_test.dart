import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_partner/core/services/ai_verification_engine.dart';
import 'package:service_hub_partner/core/services/live_booking_sync_service.dart';

void main() {
  group('AI Verification Software Engine Tests', () {
    final aiEngine = AIVerificationEngine.instance;

    test('Aadhaar QR & Verhoeff validation should authenticate valid 12-digit numbers', () {
      final res = aiEngine.validateAadhaar('742918456230');
      expect(res.isValid, isTrue);
      expect(res.isQrCryptographicallySigned, isTrue);
      expect(res.formattedAadhaar.contains('XXXX-XXXX'), isTrue);
    });

    test('OCR Document Tamper Detector should confirm original physical watermark and high fidelity', () {
      final ocrRes = aiEngine.scanDocumentOcr(
        docType: 'Aadhaar Card Front',
        candidateName: 'Rajesh Sharma',
        city: 'Jamnagar, Gujarat',
      );
      expect(ocrRes.isAuthentic, isTrue);
      expect(ocrRes.tamperingDetected, isFalse);
      expect(ocrRes.confidenceScore, greaterThan(0.95));
      expect(ocrRes.extractedFields['Full Name'], equals('Rajesh Sharma'));
      expect(ocrRes.extractedFields['State/City'], equals('Jamnagar, Gujarat'));
    });

    test('FaceRD Biometric Matcher should return >= 99% confidence for UIDAI compliant face', () {
      final faceRes = aiEngine.verifyFaceBiometrics(isLivenessVerified: true, matchConfidence: 99.4);
      expect(faceRes.isLivenessVerified, isTrue);
      expect(faceRes.faceMatchScore, equals(99.4));
      expect(faceRes.isUidaiFaceRdCompliant, isTrue);
      expect(faceRes.matchStatus, equals('BIOMETRIC_MATCH_CONFIRMED'));
    });

    test('Bank Penny Drop Engine should simulate ₹1.00 micro-deposit and resolve IFSC bank', () {
      final pennyRes = aiEngine.verifyBankPennyDrop(
        accountNumber: '50100458963214',
        ifscCode: 'HDFC0000123',
        accountHolderName: 'Rajesh Sharma',
      );
      expect(pennyRes.isVerified, isTrue);
      expect(pennyRes.bankName, equals('HDFC Bank'));
      expect(pennyRes.nameMatchPercentage, equals(100.0));
      expect(pennyRes.utrNumber.startsWith('IMPS'), isTrue);
    });

    test('Composite AI Inspection Report should compute Low Risk Score (0.02) and 99.8% Trust', () {
      final draft = {
        'first_name': 'Rajesh',
        'last_name': 'Sharma',
        'city': 'Jamnagar',
        'state': 'Gujarat',
        'aadhaar_number': '742918456230',
        'bank_account_number': '50100458963214',
        'bank_ifsc': 'HDFC0000123',
      };

      final report = aiEngine.generateAIInspectionReport(draft);
      expect(report.aiRiskScore, equals(0.02));
      expect(report.trustScore, equals(99.8));
      expect(report.riskLevel, equals('LOW_RISK'));
      expect(report.recommendation, equals('RECOMMENDED_FOR_APPROVAL'));
      expect(report.aadhaarResult.isValid, isTrue);
      expect(report.ocrResult.isAuthentic, isTrue);
      expect(report.faceResult.isLivenessVerified, isTrue);
      expect(report.pennyDropResult.isVerified, isTrue);

      // JSON serialization integrity
      final json = report.toJson();
      final deserialized = AIVerificationReport.fromJson(json);
      expect(deserialized.aiRiskScore, equals(0.02));
      expect(deserialized.trustScore, equals(99.8));
    });
  });

  group('Partner Onboarding, AI Verification & Admin Approval End-to-End Lifecycle', () {
    final syncService = LiveBookingSyncService.instance;
    final String candidateId = 'partner_test_${DateTime.now().millisecondsSinceEpoch}';

    test('Submit candidate application -> Broadcasts AI report to Admin queue', () async {
      final draft = {
        'first_name': 'Rajesh',
        'last_name': 'Sharma',
        'city': 'Jamnagar',
      };
      final aiReport = AIVerificationEngine.instance.generateAIInspectionReport(draft);

      final candidateRecord = {
        'id': candidateId,
        'verification_id': candidateId,
        'username': 'rajesh_ac_expert',
        'name': 'Rajesh Sharma',
        'full_name': 'Rajesh Sharma',
        'business_name': 'Rajesh AC Expert Center',
        'phone': '+91 98765 43210',
        'email': 'rajesh@servicehub.com',
        'category': 'ac_service',
        'category_name': 'AC Service Specialist',
        'city': 'Jamnagar',
        'state': 'Gujarat',
        'status': 'PENDING',
        'verification_status': 'PENDING',
        'ai_risk_score': aiReport.aiRiskScore,
        'trust_score': aiReport.trustScore,
        'ai_report': aiReport.toJson(),
      };

      // 1. Candidate submits application
      await syncService.submitPartnerVerification(candidateRecord);

      // 2. Admin retrieves pending candidates
      final pendingList = syncService.getPendingPartnerVerifications();
      final found = pendingList.firstWhere((p) => p['id'] == candidateId || p['verification_id'] == candidateId);
      expect(found, isNotNull);
      expect(found['status'], equals('PENDING'));
      expect(found['ai_risk_score'], equals(0.02));

      // 3. Admin reviews and approves candidate
      await syncService.approvePartnerVerification(candidateId);

      // 4. Verification stream pushes APPROVED state
      final updated = syncService.getAllPartnerVerifications().firstWhere((p) => p['id'] == candidateId || p['verification_id'] == candidateId);
      expect(updated['status'], equals('APPROVED'));
    });
  });
}
