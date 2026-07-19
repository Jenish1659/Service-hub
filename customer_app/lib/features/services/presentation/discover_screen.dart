import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';
import 'services_provider.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  String? _initialCategory;
  late String _selectedCategory;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialCategory == null) {
      final queryCategory = GoRouterState.of(context).uri.queryParameters['category'];
      _selectedCategory = queryCategory ?? 'All';
      _initialCategory = _selectedCategory;
    }
  }

  // Helpers to get visual style based on service category
  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'AC':
        return Icons.ac_unit;
      case 'Plumbing':
        return Icons.plumbing;
      case 'Car':
        return Icons.directions_car;
      case 'Cooking':
        return Icons.soup_kitchen;
      case 'Laundry':
        return Icons.local_laundry_service;
      default:
        return Icons.build;
    }
  }

  Color _getBgColorForCategory(String category) {
    switch (category) {
      case 'AC':
        return const Color(0xffeff6ff);
      case 'Plumbing':
        return const Color(0xfff0fdfa);
      case 'Car':
        return const Color(0xfffff1f2);
      case 'Cooking':
        return const Color(0xfffffbeb);
      case 'Laundry':
        return const Color(0xfffaf5ff);
      default:
        return const Color(0xfff1f5f9);
    }
  }

  Color _getIconColorForCategory(String category) {
    switch (category) {
      case 'AC':
        return const Color(0xff2563eb);
      case 'Plumbing':
        return const Color(0xff0d9488);
      case 'Car':
        return const Color(0xffe11d48);
      case 'Cooking':
        return const Color(0xffd97706);
      case 'Laundry':
        return const Color(0xff7c3aed);
      default:
        return AppTheme.primaryColor;
    }
  }

  void _startBookingFlow(BuildContext context, String serviceName, double servicePrice) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingFlowWidget(serviceName: serviceName, servicePrice: servicePrice),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    String displayLabel = category;
    if (category == 'AC') displayLabel = 'AC Repair';
    if (category == 'Car') displayLabel = 'Car Service';

    return ChoiceChip(
      label: Text(displayLabel),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _selectedCategory = category;
          });
        }
      },
      selectedColor: AppTheme.primaryColor.withOpacity(0.1),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicesAsync = ref.watch(servicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Services'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            const Text(
              'Home Services',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: AppTheme.textPrimaryColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select a service category to find top rated professionals within 5 km.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryColor,
              ),
            ),
            const SizedBox(height: 16),
            // Horizontal list of Category Filter Chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip('All'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('AC'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Plumbing'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Car'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Cooking'),
                  const SizedBox(width: 8),
                  _buildCategoryChip('Laundry'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: servicesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text('Error loading services: ${err.toString()}', style: const TextStyle(color: AppTheme.dangerColor)),
                ),
                data: (servicesList) {
                  final filteredServices = _selectedCategory == 'All'
                      ? servicesList
                      : servicesList.where((s) => s['category'] == _selectedCategory).toList();

                  if (filteredServices.isEmpty) {
                    return const Center(
                      child: Text('No services found in this category.', style: TextStyle(color: AppTheme.textSecondaryColor)),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredServices.length,
                    itemBuilder: (context, index) {
                      final service = filteredServices[index];
                      final category = service['category'] ?? '';
                      final name = service['name'] ?? '';
                      final price = (service['price'] as num?)?.toDouble() ?? 0.0;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () => _startBookingFlow(context, name, price),
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: _getBgColorForCategory(category),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _getIconForCategory(category),
                                    size: 28,
                                    color: _getIconColorForCategory(category),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppTheme.textPrimaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Starting from ₹${price.toStringAsFixed(0)} · 5 km coverage',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondaryColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: AppTheme.textSecondaryColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingFlowWidget extends StatefulWidget {
  final String serviceName;
  final double servicePrice;
  const _BookingFlowWidget({required this.serviceName, required this.servicePrice});

  @override
  State<_BookingFlowWidget> createState() => _BookingFlowWidgetState();
}

class _BookingFlowWidgetState extends State<_BookingFlowWidget> {
  int _currentStep = 1; // 1: Describe, 2: Slot, 3: Confirm
  final TextEditingController _issueController = TextEditingController();
  final TextEditingController _promoController = TextEditingController();
  String _selectedDate = 'Today, July 12';
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
    final supabaseUser = client.auth.currentUser;
    String userId = '';
    
    if (supabaseUser != null) {
      userId = supabaseUser.id;
    } else {
      userId = Hive.box('customer_cache').get('user_id', defaultValue: '') as String;
    }

    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to confirm booking.'), backgroundColor: AppTheme.warningColor),
      );
      context.go('/login');
      return;
    }

    final box = Hive.box('customer_cache');
    final double walletBalance = box.get('wallet_balance_inr', defaultValue: 50.0) as double;
    double walletDeduction = 0.0;
    if (_useWallet) {
      final double subTotal = widget.servicePrice - _promoDiscount;
      walletDeduction = walletBalance < subTotal ? walletBalance : subTotal;
    }

    final finalPrice = widget.servicePrice - _promoDiscount - walletDeduction;

    // Update wallet and award coins
    if (_useWallet) {
      box.put('wallet_balance_inr', walletBalance - walletDeduction);
    }
    final int currentCoins = box.get('wallet_coins', defaultValue: 500) as int;
    box.put('wallet_coins', currentCoins + 100); // Earn 100 coins for booking!

    if (userId.startsWith('mock_')) {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request created successfully! You earned 100 coins!'), backgroundColor: AppTheme.successColor),
        );
        context.push('/track-booking/mock_booking_id');
      }
      return;
    }

    try {
      final response = await client.from('bookings').insert({
        'customer_id': userId,
        'service_name': widget.serviceName,
        'issue_description': _issueController.text.trim(),
        'scheduled_date': _selectedDate,
        'scheduled_time': _selectedTime,
        'payment_method': _selectedPayment,
        'price': finalPrice,
        'status': 'Pending',
        'entrance_pin': '7429',
        'completion_otp': '5892',
      }).select().single();

      if (mounted) {
        Navigator.pop(context); // Close bottom sheet
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking request created successfully! You earned 100 coins!'), backgroundColor: AppTheme.successColor),
        );
        final bookingId = response['id'];
        context.push('/track-booking/$bookingId');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking service: ${e.toString()}'), backgroundColor: AppTheme.dangerColor),
        );
      }
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Book ${widget.serviceName} (${_currentStep}/3)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimaryColor),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20),

          // Steps Content
          if (_currentStep == 1) _buildDescribeStep(),
          if (_currentStep == 2) _buildSlotStep(),
          if (_currentStep == 3) _buildConfirmStep(),

          const SizedBox(height: 24),

          // Actions
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
    );
  }

  Widget _buildDescribeStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Describe the Issue',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _issueController,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'e.g., Water leaking from AC unit / Tap has very low pressure.',
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
          value: _selectedDate,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          items: const [
            DropdownMenuItem(value: 'Today, July 12', child: Text('Today, July 12')),
            DropdownMenuItem(value: 'Tomorrow, July 13', child: Text('Tomorrow, July 13')),
            DropdownMenuItem(value: 'Tuesday, July 14', child: Text('Tuesday, July 14')),
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
          value: _selectedTime,
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
        const SizedBox(height: 8),
        InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('FREEVISIT Terms & Conditions'),
                content: const Text(
                  '1. Applicable to the first booking of any service.\n'
                  '2. The discount covers the visiting charge up to a maximum value of ₹150.\n'
                  '3. Cannot be combined with any other offers or product discounts.\n'
                  '4. Valid for residents inside Jamnagar city limits only.',
                  style: const TextStyle(height: 1.4),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
          child: const Text(
            'View T&C for Promo Code "FREEVISIT"',
            style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, decoration: TextDecoration.underline),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Select Payment Method',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedPayment,
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
