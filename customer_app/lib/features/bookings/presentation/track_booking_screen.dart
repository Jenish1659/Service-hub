import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_theme.dart';

class TrackBookingScreen extends StatefulWidget {
  final String bookingId;

  const TrackBookingScreen({super.key, required this.bookingId});

  @override
  State<TrackBookingScreen> createState() => _TrackBookingScreenState();
}

class _TrackBookingScreenState extends State<TrackBookingScreen> {
  Map<String, dynamic>? _bookingData;
  bool _loading = true;
  String _errorMessage = '';

  int _distance = 420;
  bool _providerArrived = false;
  bool _pinVerified = false;
  bool _workCommenced = false;
  bool _serviceCompleted = false;

  final TextEditingController _pinController = TextEditingController();
  final String _correctPin = '7429';

  int _userRating = 5;
  final TextEditingController _reviewController = TextEditingController();
  bool _reviewSubmitted = false;

  @override
  void initState() {
    super.initState();
    _fetchBookingDetails();
  }

  Future<void> _fetchBookingDetails() async {
    try {
      final response = await Supabase.instance.client
          .from('service_bookings')
          .select('*, services(*), user_addresses(*)')
          .eq('booking_id', widget.bookingId)
          .maybeSingle();

      if (mounted) {
        if (response != null) {
          setState(() {
            _bookingData = response;
            _loading = false;
            
            final status = response['status'] ?? 'Pending';
            if (status == 'En Route') {
              _distance = 3;
              _providerArrived = true;
            } else if (status == 'Started') {
              _distance = 3;
              _providerArrived = true;
              _pinVerified = true;
              _workCommenced = true;
            } else if (status == 'Completed') {
              _distance = 3;
              _providerArrived = true;
              _pinVerified = true;
              _workCommenced = true;
              _serviceCompleted = true;
            } else {
              _distance = 420;
              _providerArrived = false;
              _pinVerified = false;
              _workCommenced = false;
              _serviceCompleted = false;
            }
          });
        } else {
          setState(() {
            _bookingData = {
              'id': widget.bookingId,
              'service_name': 'AC Dust Filter & Service',
              'scheduled_date': 'Today',
              'scheduled_time': '06:30 PM',
              'status': _serviceCompleted ? 'Completed' : (_workCommenced ? 'Started' : (_providerArrived ? 'En Route' : 'Pending')),
              'price': 384.0,
            };
            _loading = false;
            _errorMessage = '';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookingData = {
            'id': widget.bookingId,
            'service_name': 'AC Service & Repair (Demo)',
            'scheduled_date': 'Today, July 12',
            'scheduled_time': '06:30 PM',
            'status': _serviceCompleted ? 'Completed' : (_workCommenced ? 'Started' : (_providerArrived ? 'En Route' : 'Pending')),
            'price': 1100.0,
          };
          _loading = false;
          _errorMessage = '';
        });
      }
    }
  }

  Future<void> _updateBookingStatus(String status) async {
    try {
      await Supabase.instance.client
          .from('service_bookings')
          .update({'status': status})
          .eq('booking_id', widget.bookingId);
      
      _fetchBookingDetails();
    } catch (e) {
      if (mounted) {
        setState(() {
          if (status == 'En Route' || status == 'ON_THE_WAY') {
            _providerArrived = true;
            _distance = 3;
          } else if (status == 'Started' || status == 'SERVICE_STARTED') {
            _pinVerified = true;
            _workCommenced = true;
          } else if (status == 'Completed' || status == 'SERVICE_COMPLETED') {
            _serviceCompleted = true;
          }
          _bookingData?['status'] = status;
        });
      }
    }
  }

  void _simulateArrival() {
    _updateBookingStatus('En Route');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Simulation: Provider is now within 5m zone! Verification PIN active.'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _verifyPin() {
    if (_pinController.text == _correctPin) {
      _updateBookingStatus('Started');
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
    _updateBookingStatus('Completed');
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
    _reviewController.dispose();
    super.dispose();
  }

  Widget _buildRatingCard() {
    if (_reviewSubmitted) {
      return const Card(
        color: Color(0xfff8fafc),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(Icons.star, color: Colors.amber, size: 40),
              SizedBox(height: 8),
              Text(
                'Thank you for your feedback!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimaryColor),
              ),
              SizedBox(height: 4),
              Text(
                'Your rating and review has been submitted successfully.',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rate the Service Provider',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimaryColor),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  icon: Icon(
                    starValue <= _userRating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _userRating = starValue;
                    });
                  },
                );
              }),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reviewController,
              decoration: const InputDecoration(
                hintText: 'Share your experience (optional)...',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  setState(() {
                    _reviewSubmitted = true;
                  });
                  final box = Hive.box('customer_cache');
                  final currentCoins = box.get('wallet_coins', defaultValue: 0) as int;
                  box.put('wallet_coins', currentCoins + 50);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Review submitted! You earned 50 coins!'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                },
                child: const Text('Submit Review', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Booking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage.isNotEmpty || _bookingData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Track Booking')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(_errorMessage.isNotEmpty ? _errorMessage : 'Booking details missing.', style: const TextStyle(color: AppTheme.dangerColor)),
          ),
        ),
      );
    }

    final serviceName = _bookingData!['service_name'] ?? 'Home Service';
    final scheduledDate = _bookingData!['scheduled_date'] ?? '';
    final scheduledTime = _bookingData!['scheduled_time'] ?? '';
    final status = (_bookingData!['status'] ?? 'Pending').toString();
    final isCancelled = status.toUpperCase().contains('CANCELLED');
    final isCompleted = status.toUpperCase() == 'COMPLETED';
    final canCancel = !isCancelled && !isCompleted && !_workCommenced;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/orders');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Track Booking'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/orders');
              }
            },
          ),
          actions: [
            if (canCancel)
              TextButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Cancel Booking?'),
                      content: const Text('Are you sure you want to cancel this service booking?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('No, Keep Booking'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.dangerColor),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _updateBookingStatus('CANCELLED_BY_CUSTOMER');
                            try {
                              if (Hive.isBoxOpen('customer_cache')) {
                                final box = Hive.box('customer_cache');
                                final List<dynamic> cancelled = box.get('cancelled_booking_ids', defaultValue: []) as List<dynamic>;
                                final list = List<String>.from(cancelled);
                                if (!list.contains(widget.bookingId)) {
                                  list.add(widget.bookingId);
                                  box.put('cancelled_booking_ids', list);
                                }
                              }
                            } catch (_) {}
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Service booking cancelled successfully.'),
                                backgroundColor: AppTheme.dangerColor,
                              ),
                            );
                          },
                          child: const Text('Confirm Cancel', style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchBookingDetails,
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (isCancelled)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xfffef2f2),
                  child: const Row(
                    children: [
                      Icon(Icons.cancel, color: AppTheme.dangerColor, size: 28),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking Cancelled',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.dangerColor),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'This service booking has been cancelled.',
                              style: TextStyle(color: Color(0xff991b1b), fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            // 1. MAP SECTION (ANIMATED)
            Stack(
              children: [
                AnimatedLiveMapTracker(providerArrived: _providerArrived),
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
                                'SP',
                                style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  serviceName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Scheduled: $scheduledDate ($scheduledTime)',
                                  style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
                            onPressed: () => context.push('/chat/${widget.bookingId}'),
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
                      child: const Row(
                        children: [
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
                    _buildRatingCard(),
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

class AnimatedLiveMapTracker extends StatefulWidget {
  final bool providerArrived;
  const AnimatedLiveMapTracker({super.key, required this.providerArrived});

  @override
  State<AnimatedLiveMapTracker> createState() => _AnimatedLiveMapTrackerState();
}

class _AnimatedLiveMapTrackerState extends State<AnimatedLiveMapTracker> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xffeff6ff),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: MapPainter(_controller.value, widget.providerArrived),
                size: Size.infinite,
              );
            },
          ),
          const Positioned(
            top: 40,
            left: 40,
            child: Column(
              children: [
                Icon(Icons.store, color: AppTheme.primaryColor, size: 24),
                Text('Provider Hub', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
              ],
            ),
          ),
          const Positioned(
            bottom: 40,
            right: 40,
            child: Column(
              children: [
                Icon(Icons.home, color: Color(0xff16a34a), size: 28),
                Text('Your Home', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MapPainter extends CustomPainter {
  final double animationProgress;
  final bool arrived;
  MapPainter(this.animationProgress, this.arrived);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.04)
      ..strokeWidth = 1.0;
    for (double i = 0; i < size.width; i += 30) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double j = 0; j < size.height; j += 30) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), gridPaint);
    }

    const startOffset = Offset(50, 60);
    final endOffset = Offset(size.width - 50, size.height - 60);
    final controlPoint1 = Offset(size.width * 0.3, size.height * 0.8);
    final controlPoint2 = Offset(size.width * 0.7, size.height * 0.2);

    final path = Path()
      ..moveTo(startOffset.dx, startOffset.dy)
      ..cubicTo(controlPoint1.dx, controlPoint1.dy, controlPoint2.dx, controlPoint2.dy, endOffset.dx, endOffset.dy);

    final routePaint = Paint()
      ..color = AppTheme.primaryColor.withValues(alpha: 0.15)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, routePaint);

    final double t = arrived ? 1.0 : animationProgress;
    final metrics = path.computeMetrics().toList();
    if (metrics.isNotEmpty) {
      final pMetrics = metrics.first;
      final tangent = pMetrics.getTangentForOffset(pMetrics.length * t);
      
      if (tangent != null) {
        final agentOffset = tangent.position;
        
        final pulsePaint = Paint()
          ..color = AppTheme.primaryColor.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(agentOffset, 12 + 6 * (arrived ? 0 : animationProgress), pulsePaint);

        final agentPaint = Paint()
          ..color = AppTheme.primaryColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(agentOffset, 8, agentPaint);
        
        final corePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(agentOffset, 3, corePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant MapPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.arrived != arrived;
  }
}
