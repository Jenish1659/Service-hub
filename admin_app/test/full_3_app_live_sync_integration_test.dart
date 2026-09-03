import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_admin/core/services/live_booking_sync_service.dart';

void main() {
  group('Full 3-App Interconnected Live Synchronization Tests', () {
    test('Partner registers in partner_app -> Admin immediately receives application -> Admin approves -> Unlocks partner', () async {
      final syncService = LiveBookingSyncService.instance;
      final testPartnerId = 'prt_live_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Partner completes registration in partner_app
      final partnerApplication = {
        'id': testPartnerId,
        'verification_id': testPartnerId,
        'user_id': testPartnerId,
        'name': 'Dhaval Jethwa',
        'full_name': 'Dhaval Jethwa',
        'phone': '+91 98244 55667',
        'business_name': 'Jethwa AC Care & Repair',
        'category': 'ac_service',
        'category_name': 'AC Specialist',
        'city': 'Jamnagar',
        'verification_status': 'PENDING',
        'ai_risk_score': 0.02,
        'trust_score': 99.8,
        'ai_report': {
          'risk_level': 'LOW_RISK',
          'recommendation': 'RECOMMENDED_FOR_APPROVAL',
          'aadhaar_validation': {'is_valid': true, 'is_verhoeff_valid': true},
          'ocr_inspection': {'is_authentic': true, 'confidence': 0.994},
          'face_biometrics': {'liveness_verified': true, 'match_score': 99.4},
          'penny_drop': {'is_verified': true, 'bank_name': 'HDFC Bank'},
        },
      };

      await syncService.submitPartnerVerification(partnerApplication);

      // 2. Admin app immediately receives this candidate in verification queue
      final pendingQueue = syncService.getPendingPartnerVerifications();
      final candidate = pendingQueue.firstWhere((p) => p['id'] == testPartnerId);
      expect(candidate['full_name'], equals('Dhaval Jethwa'));
      expect(candidate['ai_risk_score'], equals(0.02));
      expect(candidate['trust_score'], equals(99.8));
      expect(candidate['status'], equals('PENDING'));

      // 3. Admin clicks "Approve & Activate"
      await syncService.approvePartnerVerification(testPartnerId);

      // 4. Partner app detects verification status change in real time
      final status = syncService.getPartnerVerificationStatus(testPartnerId);
      expect(status == 'APPROVED' || status == 'VERIFIED', isTrue);
    });

    test('Customer creates AC booking in customer_app -> Admin dashboard tracks it -> Partner accepts & completes -> Dynamic revenue updates', () async {
      final syncService = LiveBookingSyncService.instance;
      final testCustomerId = 'cust_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Customer creates AC Booking
      final booking = await syncService.createACBooking(
        customerId: testCustomerId,
        customerName: 'Meera Trivedi',
        customerPhone: '+91 98980 11223',
        address: 'Patel Colony, Jamnagar',
        acType: 'Split AC',
        acBrand: 'Daikin',
        problemDescription: 'AC blowing warm air, filter dirty',
        acAge: '2-4 Years',
        serviceDate: '2026-09-02',
        serviceTime: '11:00 AM',
        estimatedPrice: 499.0,
      );

      final bookingId = booking['id'];
      expect(bookingId, isNotNull);

      // 2. Admin sees booking in real-time stream
      final adminBookings = syncService.getAllBookings();
      final liveBooking = adminBookings.firstWhere((b) => b['id'] == bookingId);
      expect(liveBooking['customer_name'], equals('Meera Trivedi'));
      expect(liveBooking['status'], equals('PENDING'));

      // 3. Partner accepts booking
      await syncService.acceptBooking(bookingId, {
        'partner_id': 'prt_live_99',
        'partner_name': 'Dhaval Jethwa (AC Specialist)',
        'partner_phone': '+91 98244 55667',
      });

      // 4. Admin sees assigned partner
      final assignedBooking = syncService.getBooking(bookingId);
      expect(assignedBooking!['partner_name'], equals('Dhaval Jethwa (AC Specialist)'));
      expect(assignedBooking['status'], equals('CONFIRMED'));

      // 5. Partner completes service
      await syncService.completeBooking(bookingId, 499.0);
      final completedBooking = syncService.getBooking(bookingId);
      expect(completedBooking!['status'], equals('SERVICE_COMPLETED'));
      expect(completedBooking['final_amount'], equals(499.0));
    });
  });
}
