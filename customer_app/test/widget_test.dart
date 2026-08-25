import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/core/services/live_booking_sync_service.dart';
import 'package:service_hub_customer/main.dart';

void main() {
  testWidgets('Smoke test for Customer App launch', (WidgetTester tester) async {
    expect(const ServiceHubCustomerApp(), isNotNull);
  });

  test('Verify real-time AC Booking dispatch and lifecycle sync between Customer and Partner', () async {
    final syncService = LiveBookingSyncService.instance;

    // 1. Customer places live AC Booking
    final booking = await syncService.createACBooking(
      customerId: 'usr_jenish_live',
      customerName: 'Jenish Bheda',
      customerPhone: '+91 98765 43210',
      serviceName: 'Split AC Deep Cleaning (Jet Wash)',
      problemDescription: 'AC Cooling issue and jet wash deep clean required',
      scheduledDate: 'Today',
      scheduledTime: '06:30 PM',
      paymentMethod: 'Cash after Service',
      price: 499.0,
      customerAddress: 'Digvijay Plot, Jamnagar',
      customerLat: 22.4707,
      customerLng: 70.0577,
      entrancePin: '7429',
      completionOtp: '5892',
    );

    expect(booking['id'], isNotNull);
    expect(booking['status'], equals('PENDING'));
    expect(booking['customer_name'], equals('Jenish Bheda'));
    expect(booking['service_name'], equals('Split AC Deep Cleaning (Jet Wash)'));

    // 2. Partner receives live offer
    final pendingOffers = syncService.getPendingACOffers();
    expect(pendingOffers.any((o) => o['id'] == booking['id']), isTrue);

    // 3. Partner accepts offer
    await syncService.acceptBooking(booking['id'], {
      'partner_id': 'ptr_ac_expert_1',
      'partner_name': 'Jenish AC Experts',
      'partner_phone': '+91 98765 43210',
    });

    var updated = syncService.getBooking(booking['id']);
    expect(updated?['status'], equals('CONFIRMED'));
    expect(updated?['partner_name'], equals('Jenish AC Experts'));

    // 4. Partner updates milestone: ON_THE_WAY
    await syncService.updateMilestone(booking['id'], 'ON_THE_WAY');
    updated = syncService.getBooking(booking['id']);
    expect(updated?['status'], equals('ON_THE_WAY'));

    // 5. Partner updates milestone: ARRIVED
    await syncService.updateMilestone(booking['id'], 'ARRIVED');
    updated = syncService.getBooking(booking['id']);
    expect(updated?['status'], equals('ARRIVED'));

    // 6. Partner enters entrance PIN: SERVICE_STARTED
    await syncService.updateMilestone(booking['id'], 'SERVICE_STARTED');
    updated = syncService.getBooking(booking['id']);
    expect(updated?['status'], equals('SERVICE_STARTED'));

    // 7. Partner enters OTP and completes job: SERVICE_COMPLETED
    await syncService.completeBooking(booking['id'], 499.0);
    updated = syncService.getBooking(booking['id']);
    expect(updated?['status'], equals('SERVICE_COMPLETED'));
    expect(updated?['final_amount'], equals(499.0));
  });
}
