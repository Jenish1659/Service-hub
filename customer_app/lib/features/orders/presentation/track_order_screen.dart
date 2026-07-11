import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class TrackOrderScreen extends StatefulWidget {
  final String orderId;

  const TrackOrderScreen({super.key, required this.orderId});

  @override
  State<TrackOrderScreen> createState() => _TrackOrderScreenState();
}

class _TrackOrderScreenState extends State<TrackOrderScreen> {
  int currentStep = 2; // Mock step: Ready for Pickup

  void _simulateNextStep() {
    if (currentStep < 4) {
      setState(() {
        currentStep++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order: ${widget.orderId}'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. SIMULATOR GEOFENCE BANNER (As specified in guidelines)
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xfffffbeb),
              child: Row(
                children: [
                  const Icon(Icons.location_searching, color: Color(0xffd97706)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Delivery Simulation Active',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xffd97706)),
                        ),
                        Text(
                          'Delivery is locked to a 5 km zone from the store location.',
                          style: TextStyle(fontSize: 11, color: Color(0xffb45309)),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffd97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    onPressed: _simulateNextStep,
                    child: const Text('Simulate Step', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

            // 2. MAP VIEWPORT
            Container(
              height: 200,
              color: const Color(0xffe2e8f0),
              child: const Center(
                child: Icon(Icons.map, size: 60, color: AppTheme.textSecondaryColor),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 3. DELIVERY AGENT INFO
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: Color(0xffeff6ff),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.directions_bike, color: AppTheme.primaryColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Ravi Kumar',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Delivery Partner · Honda Activa',
                                  style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.call, color: AppTheme.successColor),
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. STEP TIMELINE
                  const Text(
                    'Order Timeline',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 16),
                  _buildStep('Order Placed', 'Payment processed successfully', currentStep >= 0),
                  _buildStep('Accepted & Packing', 'Seller preparing items', currentStep >= 1),
                  _buildStep('Ready for Pickup', 'Waiting for Delivery Agent', currentStep >= 2),
                  _buildStep('Out for Delivery', 'Agent is carrying your order', currentStep >= 3),
                  _buildStep('Delivered', 'Completed with PIN verification', currentStep >= 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String title, String subtitle, bool isCompleted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isCompleted ? AppTheme.primaryColor : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted ? AppTheme.primaryColor : AppTheme.borderCol,
                  width: 2,
                ),
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                  : null,
            ),
            Container(
              width: 2,
              height: 35,
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
                  fontSize: 13,
                  color: isCompleted ? AppTheme.textPrimaryColor : AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 11),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ],
    );
  }
}
