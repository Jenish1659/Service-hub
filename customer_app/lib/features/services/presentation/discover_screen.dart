import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final List<Map<String, dynamic>> _services = [
    {
      'name': 'AC Repair',
      'providers': '24 providers near you',
      'icon': Icons.ac_unit,
      'bg': const Color(0xffeff6ff),
      'iconColor': const Color(0xff2563eb),
    },
    {
      'name': 'Plumbing',
      'providers': '31 providers near you',
      'icon': Icons.plumbing,
      'bg': const Color(0xfff0fdfa),
      'iconColor': const Color(0xff0d9488),
    },
    {
      'name': 'Car Service',
      'providers': '18 providers near you',
      'icon': Icons.directions_car,
      'bg': const Color(0xfffff1f2),
      'iconColor': const Color(0xffe11d48),
    },
    {
      'name': 'Cooking',
      'providers': '42 hygiene certified',
      'icon': Icons.soup_kitchen,
      'bg': const Color(0xfffffbeb),
      'iconColor': const Color(0xffd97706),
    },
    {
      'name': 'Laundry',
      'providers': '27 hygiene certified',
      'icon': Icons.local_laundry_service,
      'bg': const Color(0xfffaf5ff),
      'iconColor': const Color(0xff7c3aed),
    },
  ];

  void _startBookingFlow(BuildContext context, String serviceName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _BookingFlowWidget(serviceName: serviceName),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _services.length,
                itemBuilder: (context, index) {
                  final service = _services[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () => _startBookingFlow(context, service['name']),
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: service['bg'],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                service['icon'],
                                size: 28,
                                color: service['iconColor'],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppTheme.textPrimaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    service['providers'],
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
  const _BookingFlowWidget({required this.serviceName});

  @override
  State<_BookingFlowWidget> createState() => _BookingFlowWidgetState();
}

class _BookingFlowWidgetState extends State<_BookingFlowWidget> {
  int _currentStep = 1; // 1: Describe, 2: Slot, 3: Confirm
  final TextEditingController _issueController = TextEditingController();
  String _selectedDate = 'Today, July 11';
  String _selectedTime = '06:30 PM';
  String _selectedPayment = 'Cash on Service';

  @override
  Widget build(BuildContext context) {
    // Keyboard spacer
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
              if (_currentStep > 1) ...[
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
                  onPressed: _onNext,
                  child: Text(_currentStep == 3 ? 'Confirm Booking' : 'Continue'),
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
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe what needs to be fixed (e.g. AC cooling problem, leaking pipe)...',
            hintStyle: const TextStyle(fontSize: 13),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Attach Photo (Optional)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo attachments are mock enabled for prototype.')),
            );
          },
          child: Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: const Color(0xffeff6ff),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: const Icon(Icons.add_a_photo, color: AppTheme.primaryColor),
          ),
        ),
      ],
    );
  }

  Widget _buildSlotStep() {
    final dates = ['Today, July 11', 'Tomorrow, July 12', 'Monday, July 13'];
    final times = ['10:00 AM', '02:00 PM', '06:30 PM', '08:00 PM'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Schedule Date',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: dates.map((d) {
            final isSelected = d == _selectedDate;
            return ChoiceChip(
              label: Text(d),
              selected: isSelected,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimaryColor),
              onSelected: (val) {
                if (val) setState(() => _selectedDate = d);
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        const Text(
          'Preferred Time Slot',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: times.map((t) {
            final isSelected = t == _selectedTime;
            return ChoiceChip(
              label: Text(t),
              selected: isSelected,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimaryColor),
              onSelected: (val) {
                if (val) setState(() => _selectedTime = t);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildConfirmStep() {
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
              _buildDetailRow('Estimated Price', '₹1,200'),
            ],
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
      // Completed, redirect to tracking!
      Navigator.pop(context); // Close bottom sheet
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking request dispatched to nearby partners!')),
      );
      context.push('/track-booking/BOOK-5892');
    }
  }
}
