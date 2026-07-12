import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class TrackBookingScreen extends StatefulWidget {
  final String bookingId;

  const TrackBookingScreen({super.key, required this.bookingId});

  @override
  State<TrackBookingScreen> createState() => _TrackBookingScreenState();
}

class _TrackBookingScreenState extends State<TrackBookingScreen> {
  int _distance = 420;
  bool _providerArrived = false;
  bool _pinVerified = false;
  bool _workCommenced = false;
  bool _serviceCompleted = false;

  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = '7429';

  void _simulateArrival() {
    setState(() {
      _distance = 3;
      _providerArrived = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulation: Provider is now within 5m zone! Verification PIN active.'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _verifyPin() {
    if (_pinController.text == _correctPin) {
      setState(() {
        _pinVerified = true;
        _workCommenced = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN Verified ✓ Work commenced by provider!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid PIN. Please enter "7429" to simulate.'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    }
  }

  void _simulateCompletion() {
    setState(() {
      _serviceCompleted = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Service Completed successfully! OTP verification complete.'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. MAP SECTION (MOCK)
            Container(
              height: 220,
              width: double.infinity,
              color: const Color(0xffe2e8f0),
              child: Stack(
                children: [
                  const Center(
                    child: Icon(Icons.map, size: 80, color: AppTheme.textSecondaryColor),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _providerArrived ? Icons.check_circle : Icons.directions_run,
                            color: _providerArrived ? AppTheme.successColor : AppTheme.primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _providerArrived ? 'Provider is here (3 m away)' : 'Provider is $_distance m away',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Simulation Button
                  if (!_providerArrived)
                    Positioned(
                      bottom: 16,
                      right: 16,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.location_searching, size: 16),
                        label: const Text('Simulate Arrival', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.warningColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        onPressed: _simulateArrival,
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. PROVIDER CARD
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Color(0xffeff6ff),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'RE',
                                style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Rajesh Electricals',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'AC Service Expert · ★4.8',
                                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          // Actions
                          IconButton(
                            icon: const Icon(Icons.call, color: AppTheme.successColor),
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. SECURE PIN / OTP ENTRY CARD
                  if (_providerArrived && !_pinVerified) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.warningColor, width: 1.5),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                      ),
                      child: Column(
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock, color: AppTheme.warningColor, size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Verify Provider Entrance PIN',
                                style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warningColor, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Provider must enter the secure PIN (7429) to start work.',
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 160,
                            child: TextField(
                              controller: _pinController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              obscureText: true,
                              style: const TextStyle(fontSize: 20, letterSpacing: 8, fontWeight: FontWeight.bold),
                              decoration: const InputDecoration(
                                hintText: '••••',
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              minimumSize: Size.zero,
                            ),
                            onPressed: _verifyPin,
                            child: const Text('Confirm PIN', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_pinVerified && !_serviceCompleted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xffeff6ff),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'Service In Progress',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 15),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Share OTP with Provider on Completion:',
                            style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '5 8 9 2',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 8,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.successColor,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              minimumSize: Size.zero,
                            ),
                            onPressed: _simulateCompletion,
                            child: const Text('Simulate Completion', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  if (_serviceCompleted) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xfff0fdf4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.successColor),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.check_circle, color: AppTheme.successColor, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Service Completed Successfully! Thank you for using ServiceHub.',
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.successColor, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // 4. TIMELINE TRACKER
                  const Text(
                    'Booking Updates',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 16),
                  _buildTimelineStep('Booking Confirmed', 'Provider accepted your request', true, true),
                  _buildTimelineStep('Provider En Route', 'Travelling to customer location', _providerArrived || _workCommenced || _serviceCompleted, false),
                  _buildTimelineStep('Work Commenced', 'Provider starts service with secure PIN verification', _workCommenced || _serviceCompleted, false),
                  _buildTimelineStep('Service Completed', 'Verify with OTP code 5892', _serviceCompleted, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(String title, String subtitle, bool isCompleted, bool isFirst) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: isCompleted ? AppTheme.primaryColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppTheme.primaryColor : AppTheme.borderCol,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            Container(
              width: 2,
              height: 40,
              color: isCompleted ? AppTheme.primaryColor : AppTheme.borderCol,
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isCompleted ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}
