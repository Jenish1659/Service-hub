import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class TrackBookingScreen extends StatelessWidget {
  final String bookingId;

  const TrackBookingScreen({super.key, required this.bookingId});

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
              height: 250,
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
                        children: const [
                          Icon(Icons.directions_run, color: AppTheme.primaryColor, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Provider is 420 m away',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
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

                  // 3. COMPLETION OTP CODE
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderCol),
                    ),
                    child: Column(
                      children: const [
                        Text(
                          'Share OTP with Provider on Completion',
                          style: TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '5 8 9 2',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 10,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. TIMELINE TRACKER
                  const Text(
                    'Booking Updates',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 16),
                  _buildTimelineStep('Booking Confirmed', 'Provider accepted your request', true, true),
                  _buildTimelineStep('Provider En Route', 'Travelling to customer location', true, false),
                  _buildTimelineStep('Work Commenced', 'Provider starts service', false, false),
                  _buildTimelineStep('Service Completed', 'Verify with OTP code', false, false),
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
