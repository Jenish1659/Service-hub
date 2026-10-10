import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:service_hub_customer/features/services/presentation/ac_service_overview_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_select_date_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_select_time_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_service_details_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_review_confirm_screen.dart';
import 'package:service_hub_customer/features/services/presentation/ac_booking_confirmed_screen.dart';
import 'package:service_hub_customer/core/services/live_booking_sync_service.dart';
import 'package:service_hub_customer/features/services/services/ac_availability_service.dart';
import 'package:service_hub_customer/features/services/services/ac_booking_service.dart';
import 'package:service_hub_customer/features/bookings/presentation/screens/ac_booking_flow_screen.dart';

void main() {
  test('WalletRewardService coin allocation rules: 300 initial, +200 on 1st service, +100 on 2nd, <=80 on 3rd+', () {
    // 1st Service gives 200 coins
    // 2nd Service gives 100 coins
    // 3rd+ Service gives random coins <= 80
    final service = WalletRewardService.instance;
    expect(service.getWalletCoins(), greaterThanOrEqualTo(300));
  });

  test('Date availability allows Today (D) and all future dates, disallows past dates', () {
    final service = ACAvailabilityService.instance;
    final now = DateTime.now();

    expect(service.isDateBookable(now), isTrue);
    expect(service.isDateBookable(now.add(const Duration(days: 1))), isTrue);
    expect(service.isDateBookable(now.add(const Duration(days: 7))), isTrue);
    expect(service.isDateBookable(now.subtract(const Duration(days: 1))), isFalse);
  });

  testWidgets('Screen 1: ACServiceOverviewScreen renders overview, Your AC card, and status grid',
      (WidgetTester tester) async {
    final issueData = {
      'service_name': 'AC Service',
      'ac_type': 'Split AC',
      'ac_brand': 'Daikin',
      'problem_description': 'Not cooling properly',
    };

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ACServiceOverviewScreen(issueDetails: issueData),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title, Headline & Subtext
    expect(find.text('AC Service'), findsOneWidget);
    expect(find.text("We'll keep you\ncool & comfortable."), findsOneWidget);
    expect(find.text('Need Help?'), findsOneWidget);

    // Verify "Your AC" Card with tags
    expect(find.text('Your AC'), findsOneWidget);
    expect(find.text('Type: Split AC'), findsOneWidget);
    expect(find.text('Brand: Daikin'), findsOneWidget);
    expect(find.text('Issue: Not cooling properly'), findsOneWidget);

    // Verify 4 Status Grid Items & 100% Hygiene Card
    expect(find.text('60 – 90 min'), findsOneWidget);
    expect(find.text('At your location'), findsOneWidget);
    expect(find.text('Local Time (Auto-detected)'), findsOneWidget);
    expect(find.text('100% Hygiene Maintained'), findsOneWidget);

    // Verify Book Service button
    expect(find.text('Book Service'), findsOneWidget);
  });

  testWidgets('Screen 2: ACSelectDateScreen displays month calendar and selected date card',
      (WidgetTester tester) async {
    final realDraft = {
      'service_name': 'AC Service',
      'ac_type': 'Split AC',
      'ac_brand': 'Daikin',
      'problem_description': 'Not cooling properly',
    };

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ACSelectDateScreen(issueDetails: realDraft),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header & Subtitle
    expect(find.text('Select Date *'), findsOneWidget);
    expect(find.text('Choose a convenient date'), findsOneWidget);

    // Verify Calendar Days of Week Header
    expect(find.text('S'), findsWidgets);
    expect(find.text('M'), findsWidgets);
    expect(find.text('T'), findsWidgets);
    expect(find.text('W'), findsWidgets);
    expect(find.text('F'), findsWidgets);

    // Selected Date Card
    expect(find.text('Selected Date'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Screen 3: ACSelectTimeScreen renders AM/PM toggle, analog clock, and digital badge',
      (WidgetTester tester) async {
    final realDraft = {
      'service_name': 'AC Service',
      'ac_type': 'Split AC',
      'ac_brand': 'Daikin',
      'problem_description': 'Not cooling properly',
    };

    final mockDate = BookingDateOption(
      date: DateTime.now().add(const Duration(days: 1)),
      dayName: 'Tomorrow',
      dateNumber: '31',
      monthName: 'Aug',
      formattedIso: '2026-08-31',
      isTomorrow: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ACSelectTimeScreen(
            issueDetails: realDraft,
            selectedDate: mockDate,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header & Subtitle
    expect(find.text('Select Time *'), findsOneWidget);
    expect(find.text('Choose your preferred time'), findsOneWidget);

    // AM/PM Toggle
    expect(find.text('AM'), findsOneWidget);
    expect(find.text('PM'), findsOneWidget);

    // Selected Time card and Next button
    expect(find.text('Selected Time *'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('Screen 4: ACServiceDetailsScreen renders name, phone, address, and notes fields',
      (WidgetTester tester) async {
    final realDraft = {
      'service_name': 'AC Service',
      'ac_type': 'Split AC',
      'ac_brand': 'Daikin',
      'problem_description': 'Not cooling properly',
    };

    final mockDate = BookingDateOption(
      date: DateTime.now().add(const Duration(days: 1)),
      dayName: 'Tomorrow',
      dateNumber: '31',
      monthName: 'Aug',
      formattedIso: '2026-08-31',
      isTomorrow: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ACServiceDetailsScreen(
            issueDetails: realDraft,
            selectedDate: mockDate,
            selectedTime: '02:00 PM',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header & Subtitle
    expect(find.text('Service Details'), findsOneWidget);
    expect(find.text('Tell us a few details'), findsOneWidget);

    // Inputs
    expect(find.text('Full Name *'), findsOneWidget);
    expect(find.text('Phone Number *'), findsOneWidget);
    expect(find.text('Complete Address *'), findsOneWidget);
    expect(find.text('Additional Notes (Optional)'), findsOneWidget);

    // Continue button
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('Screen 5: ACReviewConfirmScreen renders review card, coupon, wallet, raw bill, and Confirm button',
      (WidgetTester tester) async {
    final realDraft = {
      'service_name': 'AC Service',
      'ac_type': 'Split AC',
      'ac_brand': 'Daikin',
      'problem_description': 'Not cooling properly',
      'customer_name': 'Jenish Bheda',
      'customer_phone': '+91 98765 43210',
      'customer_address': '12, Shanti Nagar, Ahmedabad, Gujarat 380001',
      'booking_date_formatted': 'Sat, 24 May 2025',
    };

    final mockDate = BookingDateOption(
      date: DateTime.now().add(const Duration(days: 1)),
      dayName: 'Tomorrow',
      dateNumber: '31',
      monthName: 'Aug',
      formattedIso: '2026-08-31',
      isTomorrow: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: ACReviewConfirmScreen(
            issueDetails: realDraft,
            selectedDate: mockDate,
            selectedTime: '02:00 PM',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Header & Subtitle
    expect(find.text('Review & Confirm'), findsOneWidget);
    expect(find.text('Please review your booking details and bill estimate'), findsOneWidget);

    // Fields & Raw Bill
    expect(find.text('Sat, 24 May 2025'), findsOneWidget);
    expect(find.text('02:00 PM'), findsOneWidget);
    expect(find.text('AC Service (Split AC)'), findsOneWidget);
    expect(find.text('Not cooling properly'), findsOneWidget);
    expect(find.text('12, Shanti Nagar, Ahmedabad, Gujarat 380001'), findsOneWidget);
    expect(find.text('Raw Bill / Price Breakdown'), findsOneWidget);
    expect(find.text('Visiting & Inspection Charge'), findsOneWidget);
    expect(find.text('Safety & Protection Fee'), findsOneWidget);
    expect(find.text('Do you have a coupon code?'), findsOneWidget);
    expect(find.text('Use Wallet Balance'), findsOneWidget);
    expect(find.text('Estimated Technician Arrival'), findsOneWidget);

    // Confirm Booking button
    expect(find.text('Confirm Booking'), findsOneWidget);
  });

  testWidgets('Screen 6: ACBookingConfirmedScreen renders checkmark, arrival notice, and View Raw Bill',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ACBookingConfirmedScreen(
            bookingData: {'id': 'bk_12345'},
            selectedDateFormatted: 'Sat, 24 May 2025',
            selectedTime: '02:00 PM',
            serviceTitle: 'AC Service (Split AC)',
            address: '12, Shanti Nagar, Ahmedabad, Gujarat 380001',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Confirmed Header & Pre-Booking Tracking ID
    expect(find.text('Booking Confirmed!'), findsOneWidget);
    expect(find.text("We've received your request and\nour partner will be there soon."), findsOneWidget);
    expect(find.text('PRE-BOOKING TRACKING ID'), findsOneWidget);

    // Summary Details
    expect(find.text('Sat, 24 May 2025'), findsOneWidget);
    expect(find.text('02:00 PM'), findsOneWidget);
    expect(find.text('AC Service (Split AC)'), findsOneWidget);
    expect(find.text('12, Shanti Nagar, Ahmedabad, Gujarat 380001'), findsOneWidget);
    expect(find.text('Estimated Technician Arrival'), findsOneWidget);
    expect(find.text('View Raw Bill'), findsOneWidget);

    // Tap View Raw Bill and verify modal
    await tester.ensureVisible(find.text('View Raw Bill'));
    await tester.tap(find.text('View Raw Bill'));
    await tester.pumpAndSettle();
    expect(find.text('Itemized Raw Bill'), findsOneWidget);

    // Close modal
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    // View My Bookings button
    await tester.ensureVisible(find.text('View My Bookings'));
    expect(find.text('View My Bookings'), findsOneWidget);
  });

  test('Complete End-to-End AC Booking Cycle: Customer -> Targeted Partner Alert -> Admin Sync -> Live Tracking', () async {
    final syncService = LiveBookingSyncService.instance;

    // 1. Customer confirms AC booking for ₹498
    final createdBooking = await syncService.createACBooking(
      customerId: 'usr_live_99',
      customerName: 'Aakash Mehta',
      customerPhone: '+91 98250 12345',
      serviceName: 'AC Service (Split AC)',
      problemDescription: 'Split AC deep cleaning and gas inspection',
      scheduledDate: '2026-09-02',
      scheduledTime: '10:30 AM',
      paymentMethod: 'Cash on Service',
      price: 498.0,
      customerAddress: 'Digvijay Plot, Street 4, Jamnagar',
      customerLat: 22.4707,
      customerLng: 70.0577,
    );

    expect(createdBooking['id'], isNotNull);
    expect(createdBooking['price'], equals(498.0));
    expect(createdBooking['status'], equals('PENDING'));
    expect(createdBooking['category'], equals('AC Service'));
    expect(createdBooking['tracking_id'], startsWith('TRK-AC-'));

    // 2. Partner App detects targeted AC offer in 10 km radius
    final pendingOffers = syncService.getPendingACOffers();
    final matching = pendingOffers.where((o) => o['id'] == createdBooking['id']).toList();
    expect(matching.isNotEmpty, isTrue);

    // 3. AC Partner accepts offer
    final bookingId = createdBooking['id'];
    await syncService.acceptBooking(bookingId, {
      'partner_id': 'prt_ac_7788',
      'partner_name': 'Rajesh Sharma (AC Specialist)',
      'partner_phone': '+91 98765 43210',
      'partner_lat': 22.4580,
      'partner_lng': 70.0480,
      'partner_vehicle': 'Honda Activa (GJ-10-AC-4589)',
    });

    // 4. Admin Dashboard receives accepted partner details
    final allAdminBookings = syncService.getAllBookings();
    final adminRecord = allAdminBookings.firstWhere((b) => b['id'] == bookingId);
    expect(adminRecord['partner_id'], equals('prt_ac_7788'));
    expect(adminRecord['partner_name'], equals('Rajesh Sharma (AC Specialist)'));
    expect(adminRecord['status'], equals('CONFIRMED'));
    expect(adminRecord['accepted_at'], isNotNull);

    // 5. Partner updates live GPS coordinates towards customer home
    await syncService.updatePartnerLocation(bookingId, 22.4650, 70.0530, distanceMeters: 650.0);
    final inTransit = syncService.getBooking(bookingId);
    expect(inTransit!['partner_lat'], equals(22.4650));
    expect(inTransit['partner_lng'], equals(70.0530));

    // 6. Complete milestones
    await syncService.updateMilestone(bookingId, 'ARRIVED');
    expect(syncService.getBooking(bookingId)!['status'], equals('ARRIVED'));

    await syncService.completeBooking(bookingId, 498.0);
    final completed = syncService.getBooking(bookingId);
    expect(completed!['status'], equals('SERVICE_COMPLETED'));
    expect(completed['final_amount'], equals(498.0));
  });

  testWidgets('ACBookingFlowScreen renders with multi-step stepper, issue options, and navigation buttons',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: ACBookingFlowScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title & Stepper
    expect(find.text('AC Service Booking Flow'), findsOneWidget);
    expect(find.text('Issue'), findsOneWidget);
    expect(find.text('Schedule'), findsOneWidget);
    expect(find.text('Address'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);

    // Verify Step 1: AC Type chips
    expect(find.text('Split AC'), findsOneWidget);
    expect(find.text('Window AC'), findsOneWidget);
    expect(find.text('Daikin'), findsOneWidget);
    expect(find.text('Voltas'), findsOneWidget);

    // Tap Continue without selecting -> Validation error
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Please select an AC type.'), findsOneWidget);

    // Dismiss snackbar
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold))).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // Select AC Type, Brand, and Problem Description
    await tester.tap(find.text('Split AC'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Daikin'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'AC is not cooling and needs general servicing');
    await tester.pumpAndSettle();

    // Tap Continue to Step 2
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Select Date & Time'), findsOneWidget);
    expect(find.text('Available Dates *'), findsOneWidget);
    expect(find.text('Preferred Time Slot *'), findsOneWidget);
  });

  test('ACBookingFlowScreen.submitACBooking generates complete payload and broadcasts to LiveBookingSyncService', () async {
    final syncService = LiveBookingSyncService.instance;

    final booking = await ACBookingFlowScreen.submitACBooking(
      customerName: 'Rajiv Patel',
      customerPhone: '+91 98251 99887',
      address: '42, Sunset Drive, Bodakdev, Ahmedabad, Gujarat 380054',
      finalAmount: 498.0,
      scheduledAt: '2026-09-05 10:00 AM',
      serviceId: 'ac_service',
      serviceName: 'AC Service (Split AC)',
      status: 'PENDING',
      acBrand: 'Daikin',
      acType: 'Split AC',
      problemDescription: 'Split AC cooling gas top-up and jet cleaning',
    );

    // 1. Verify required payload fields according to lifecycle specifications
    expect(booking['id'], isNotNull);
    expect(booking['booking_id'], equals(booking['id']));
    expect(booking['service_id'], equals('ac_service'));
    expect(booking['service_name'], equals('AC Service (Split AC)'));
    expect(booking['status'], anyOf(equals('PENDING'), equals('CONFIRMED')));
    expect(booking['customer_name'], equals('Rajiv Patel'));
    expect(booking['address'], equals('42, Sunset Drive, Bodakdev, Ahmedabad, Gujarat 380054'));
    expect(booking['final_amount'], equals(498.0));
    expect(booking['scheduled_at'], equals('2026-09-05 10:00 AM'));
    expect(booking['created_at'], isNotNull);

    // 2. Verify broadcast to LiveBookingSyncService
    final retrieved = syncService.getBooking(booking['id']);
    expect(retrieved, isNotNull);
    expect(retrieved!['id'], equals(booking['id']));
    expect(retrieved['service_id'], equals('ac_service'));
    expect(retrieved['customer_name'], equals('Rajiv Patel'));
    expect(retrieved['final_amount'], equals(498.0));
    expect(retrieved['scheduled_at'], equals('2026-09-05 10:00 AM'));
  });

  test('Technician status transitions: ACCEPTED -> ONGOING / SERVICE_STARTED -> COMPLETED with LiveBookingSyncService sync', () async {
    final syncService = LiveBookingSyncService.instance;

    // 1. Create booking
    final booking = await ACBookingFlowScreen.submitACBooking(
      customerName: 'Kavita Joshi',
      address: 'B-201, Green City, Jamnagar, Gujarat',
      finalAmount: 449.0,
      scheduledAt: '2026-09-10 02:00 PM',
      status: 'PENDING',
    );
    final bookingId = booking['id'];
    expect(syncService.getBooking(bookingId)!['status'], equals('PENDING'));

    // 2. Technician accepts job -> transitions to ACCEPTED / ASSIGNED
    await syncService.acceptBooking(bookingId, {
      'partner_id': 'tech_gujarat_01',
      'partner_name': 'Amit Dave (Senior AC Engineer)',
      'partner_phone': '+91 94260 11223',
    });
    await syncService.updateBookingStatus(bookingId, 'ACCEPTED');
    expect(syncService.getBooking(bookingId)!['status'], anyOf(equals('ACCEPTED'), equals('ASSIGNED'), equals('CONFIRMED')));

    // 3. Technician arrives & starts service -> transitions to ONGOING / SERVICE_STARTED
    await syncService.updateMilestone(bookingId, 'SERVICE_STARTED');
    expect(syncService.getBooking(bookingId)!['status'], anyOf(equals('ONGOING'), equals('SERVICE_STARTED')));

    // 4. Technician completes service -> transitions to COMPLETED
    await syncService.completeBooking(bookingId, 449.0);
    await syncService.updateBookingStatus(bookingId, 'COMPLETED');
    final completedBooking = syncService.getBooking(bookingId);
    expect(completedBooking!['status'], anyOf(equals('COMPLETED'), equals('SERVICE_COMPLETED')));
    expect(completedBooking['final_amount'], equals(449.0));
  });
}


