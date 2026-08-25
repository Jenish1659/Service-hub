import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hive/hive.dart';
import '../../../../core/services/live_booking_sync_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../location/providers/location_provider.dart';
import '../../location/screens/map_screen.dart';
import '../../location/screens/saved_locations_screen.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  void _startBookingFlow(BuildContext context, String serviceName, double servicePrice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingFlowWidget(serviceName: serviceName, servicePrice: servicePrice),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 6 Required Services with their photos & metadata
    final leftColumnServices = [
      {
        'title': 'AC Services',
        'image': 'assets/images/service_ac.png',
        'price': 499.0,
        'imageHeight': 190.0,
        'sub': 'Diagnostic, repair & cleaning',
      },
      {
        'title': 'Care Taker',
        'image': 'assets/images/service_caretaker.png',
        'price': 599.0,
        'imageHeight': 210.0,
        'sub': 'Elderly & patient care specialist',
      },
      {
        'title': 'Laundry',
        'image': 'assets/images/service_laundry.png',
        'price': 199.0,
        'imageHeight': 185.0,
        'sub': 'Wash, dry & steam iron',
      },
    ];

    final rightColumnServices = [
      {
        'title': 'Car Service',
        'image': 'assets/images/service_car.png',
        'price': 799.0,
        'imageHeight': 175.0,
        'sub': 'Full auto checkup & detailing',
      },
      {
        'title': 'Cooking',
        'image': 'assets/images/service_cooking.png',
        'price': 399.0,
        'imageHeight': 210.0,
        'sub': 'Personal chef & meal prep',
      },
      {
        'title': 'Plumbing',
        'image': 'assets/images/service_plumbing.png',
        'price': 299.0,
        'imageHeight': 200.0,
        'sub': 'Leakage fix & pipe fitting',
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        backgroundColor: const Color(0xfff8fafc),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xff0f172a)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. GIANT ELEGANT HEADER TITLE
            const Text(
              'Discover',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: Color(0xff0f172a),
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Choose from services for you\nand your home',
              style: TextStyle(
                fontSize: 17,
                color: Color(0xff64748b),
                fontWeight: FontWeight.w400,
                height: 1.3,
              ),
            ),

            const SizedBox(height: 24),

            // 2. STAGGERED 2-COLUMN SERVICE CARDS (MATCHING EXACT SCREENSHOT STYLE)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Column
                Expanded(
                  child: Column(
                    children: leftColumnServices.map((service) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: _buildStaggeredServiceCard(
                          context: context,
                          title: service['title'] as String,
                          image: service['image'] as String,
                          price: service['price'] as double,
                          sub: service['sub'] as String,
                          imageHeight: service['imageHeight'] as double,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(width: 14),

                // Right Column
                Expanded(
                  child: Column(
                    children: rightColumnServices.map((service) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18.0),
                        child: _buildStaggeredServiceCard(
                          context: context,
                          title: service['title'] as String,
                          image: service['image'] as String,
                          price: service['price'] as double,
                          sub: service['sub'] as String,
                          imageHeight: service['imageHeight'] as double,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaggeredServiceCard({
    required BuildContext context,
    required String title,
    required String image,
    required double price,
    required String sub,
    required double imageHeight,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _startBookingFlow(context, title, price),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Header Container
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  height: imageHeight,
                  width: double.infinity,
                  color: const Color(0xfff1f5f9),
                  child: Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xffe2e8f0),
                        child: const Center(
                          child: Icon(Icons.cleaning_services_rounded, color: Color(0xff94a3b8), size: 40),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Title and Price Label Below Image
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xff0f172a),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'From ₹${price.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: Color(0xff0052cc),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BookingFlowWidget extends ConsumerStatefulWidget {
  final String serviceName;
  final double servicePrice;
  const _BookingFlowWidget({required this.serviceName, required this.servicePrice});

  @override
  ConsumerState<_BookingFlowWidget> createState() => _BookingFlowWidgetState();
}

class _BookingFlowWidgetState extends ConsumerState<_BookingFlowWidget> {
  int _currentStep = 1; // 1: Describe, 2: Slot, 3: Confirm
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();
  String _selectedDate = 'Today, August 9';
  String _selectedTime = '06:30 PM';
  String _selectedPayment = 'Cash on Service';
  bool _isSubmitting = false;
  bool _useWallet = false;

  String? _appliedPromoCode;
  double _promoDiscount = 0.0;

  Future<void> _createBooking() async {
    setState(() {
      _isSubmitting = true;
    });

    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    final userId = user?.id ?? 'cust_${DateTime.now().millisecondsSinceEpoch}';

    final locState = ref.read(locationProvider);
    final activeLocation = locState.selectedLocation ?? locState.currentLocation;
    final serviceAddress = activeLocation?.address ?? 'Selected Service Location, Jamnagar';
    final serviceLat = activeLocation?.latitude ?? 22.4707;
    final serviceLng = activeLocation?.longitude ?? 70.0577;

    final box = Hive.box('customer_cache');
    final double walletBalance = box.get('wallet_balance_inr', defaultValue: 50.0) as double;
    double walletDeduction = 0.0;
    if (_useWallet) {
      final double subTotal = widget.servicePrice - _promoDiscount;
      walletDeduction = walletBalance < subTotal ? walletBalance : subTotal;
    }

    final finalPrice = widget.servicePrice - _promoDiscount - walletDeduction;

    if (_useWallet) {
      box.put('wallet_balance_inr', walletBalance - walletDeduction);
    }
    final int currentCoins = box.get('wallet_coins', defaultValue: 500) as int;
    box.put('wallet_coins', currentCoins + 100);

    final createdBooking = await LiveBookingSyncService.instance.createACBooking(
      customerId: userId,
      customerName: 'Jenish Bheda',
      customerPhone: '+91 98765 43210',
      serviceName: widget.serviceName,
      problemDescription: _issueController.text.trim().isNotEmpty
          ? _issueController.text.trim()
          : '${widget.serviceName} requested by customer',
      scheduledDate: _selectedDate,
      scheduledTime: _selectedTime,
      paymentMethod: _selectedPayment,
      price: finalPrice,
      customerAddress: serviceAddress,
      customerLat: serviceLat,
      customerLng: serviceLng,
      entrancePin: '7429',
      completionOtp: '5892',
    );

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ Booking request placed live! Partner notified.'), backgroundColor: AppTheme.successColor),
      );
      final bookingId = createdBooking['id'];
      context.push('/track-booking/$bookingId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin: const EdgeInsets.only(top: 80),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Book ${widget.serviceName} ($_currentStep/3)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimaryColor),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 20),

            if (_currentStep == 1) _buildDescribeStep(),
            if (_currentStep == 2) _buildSlotStep(),
            if (_currentStep == 3) _buildConfirmStep(),

            const SizedBox(height: 24),

            Row(
              children: [
                if (_currentStep > 1 && !_isSubmitting) ...[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _onNext,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(_currentStep == 3 ? 'Confirm Booking' : 'Continue'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescribeStep() {
    final locationState = ref.watch(locationProvider);
    final location = locationState.selectedLocation ?? locationState.currentLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Service Location Section (OpenStreetMap / Locator based)
        const Text(
          'Service Location',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xfff8fafc),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderCol),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xffeff6ff),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on_rounded, color: AppTheme.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location?.area ?? 'Location Detected',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff0f172a)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          location?.address ?? 'OpenStreetMap Hyperlocal Address',
                          style: const TextStyle(fontSize: 12, color: Color(0xff64748b), height: 1.3),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.map_outlined, size: 16),
                      label: const Text('Open Map', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const MapScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bookmark_outline, size: 16),
                      label: const Text('Saved', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        minimumSize: Size.zero,
                      ),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const SavedLocationsScreen()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // 2. Issue Description
        const Text(
          'Describe the Issue / Requirements',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _issueController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g., Water leaking from tap / Need full AC cleaning & service.',
          ),
        ),
      ],
    );
  }

  Widget _buildSlotStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date Slot',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedDate,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'Today, August 9', child: Text('Today, August 9')),
            DropdownMenuItem(value: 'Tomorrow, August 10', child: Text('Tomorrow, August 10')),
            DropdownMenuItem(value: 'Monday, August 11', child: Text('Monday, August 11')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedDate = val;
              });
            }
          },
        ),
        const SizedBox(height: 16),
        const Text(
          'Select Time Slot',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedTime,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: '09:00 AM - 12:00 PM', child: Text('09:00 AM - 12:00 PM (Morning)')),
            DropdownMenuItem(value: '12:00 PM - 03:00 PM', child: Text('12:00 PM - 03:00 PM (Afternoon)')),
            DropdownMenuItem(value: '03:00 PM - 06:00 PM', child: Text('03:00 PM - 06:00 PM (Evening)')),
            DropdownMenuItem(value: '06:30 PM', child: Text('06:30 PM (Immediate)')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedTime = val;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
    final box = Hive.box('customer_cache');
    final double walletBalance = box.get('wallet_balance_inr', defaultValue: 50.0) as double;
    
    double walletDeduction = 0.0;
    if (_useWallet) {
      final double subTotal = widget.servicePrice - _promoDiscount;
      walletDeduction = walletBalance < subTotal ? walletBalance : subTotal;
    }

    final double finalPrice = widget.servicePrice - _promoDiscount - walletDeduction;

    final locationState = ref.watch(locationProvider);
    final location = locationState.selectedLocation ?? locationState.currentLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Booking Details',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xfff8fafc),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderCol),
          ),
          child: Column(
            children: [
              _buildDetailRow('Service Category', widget.serviceName),
              const Divider(height: 20),
              _buildDetailRow('Service Location', location?.address ?? 'Selected Hyperlocal Location'),
              const Divider(height: 20),
              _buildDetailRow('Schedule', '$_selectedDate at $_selectedTime'),
              const Divider(height: 20),
              _buildDetailRow('Original Price', '₹${widget.servicePrice.toStringAsFixed(0)}'),
              if (_appliedPromoCode != null) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Promo Code ($_appliedPromoCode)', style: const TextStyle(color: Color(0xff16a34a), fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('-₹${_promoDiscount.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xff16a34a), fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
              if (_useWallet && walletDeduction > 0) ...[
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Wallet Deduction', style: TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.bold)),
                    Text('-₹${walletDeduction.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
              ],
              const Divider(height: 20),
              _buildDetailRow('Final Estimated Price', '₹${finalPrice.toStringAsFixed(0)}'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: Text('Use Wallet Balance (Available: ₹${walletBalance.toStringAsFixed(0)})', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          subtitle: const Text('Convert your coins to INR in Profile to add balance', style: TextStyle(fontSize: 11)),
          value: _useWallet,
          activeColor: AppTheme.primaryColor,
          onChanged: walletBalance > 0
              ? (val) {
                  setState(() {
                    _useWallet = val ?? false;
                  });
                }
              : null,
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
        const SizedBox(height: 8),
        const Text(
          'Promo Code / Coupons',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _promoController,
                decoration: InputDecoration(
                  hintText: 'Enter code (e.g. FREEVISIT)...',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                final code = _promoController.text.trim().toUpperCase();
                if (code == 'FREEVISIT') {
                  setState(() {
                    _appliedPromoCode = 'FREEVISIT';
                    _promoDiscount = 150.0;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('FREEVISIT applied! ₹150 discount applied.'), backgroundColor: AppTheme.successColor),
                  );
                } else if (code.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invalid promo code.'), backgroundColor: AppTheme.dangerColor),
                  );
                }
              },
              child: const Text('Apply'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'Select Payment Method',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: _selectedPayment,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'Cash on Service', child: Text('Cash/UPI on Service Completion')),
            DropdownMenuItem(value: 'Online UPI', child: Text('Pay with UPI (GPay/PhonePe)')),
            DropdownMenuItem(value: 'Card', child: Text('Credit/Debit Card')),
          ],
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _selectedPayment = val;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String val) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13)),
        Text(val, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }

  void _onNext() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep++;
      });
    } else {
      _createBooking();
    }
  }
}
