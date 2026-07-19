import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class PartnerMapScreen extends StatefulWidget {
  final String taskId;
  final String customerName;
  final String address;
  final String serviceName;
  final String price;
  final String type; // 'service' or 'delivery'
  final String deliveryPin;

  const PartnerMapScreen({
    super.key,
    required this.taskId,
    required this.customerName,
    required this.address,
    required this.serviceName,
    required this.price,
    required this.type,
    required this.deliveryPin,
  });

  @override
  State<PartnerMapScreen> createState() => _PartnerMapScreenState();
}

class _PartnerMapScreenState extends State<PartnerMapScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  String _mapStyle = 'standard'; // 'standard', 'satellite', 'dark'
  bool _isNavigating = false;
  double _distanceRemaining = 450.0; // in meters
  String _navigationInstruction = 'Tap "Start Navigation" to begin journey';
  
  final TextEditingController _completionCodeController = TextEditingController();
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    );

    _animationController.addListener(() {
      setState(() {
        _distanceRemaining = (1.0 - _animationController.value) * 450.0;
        if (_distanceRemaining <= 0.0) {
          _navigationInstruction = 'You have arrived at your destination!';
          _isNavigating = false;
        } else if (_distanceRemaining < 100.0) {
          _navigationInstruction = 'Prepare to stop. Destination is on your right.';
        } else if (_distanceRemaining < 250.0) {
          _navigationInstruction = 'Turn left in 50 meters onto Digvijay Plot Road.';
        } else {
          _navigationInstruction = 'Head northeast towards ${widget.address}.';
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _completionCodeController.dispose();
    super.dispose();
  }

  void _toggleNavigation() {
    if (_isNavigating) {
      _animationController.stop();
      setState(() {
        _isNavigating = false;
      });
    } else {
      if (_animationController.value >= 1.0) {
        _animationController.reset();
      }
      _animationController.forward();
      setState(() {
        _isNavigating = true;
      });
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(widget.type == 'delivery' ? 'Verify Delivery PIN' : 'Verify Completion OTP'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.type == 'delivery' 
                    ? 'Enter the 4-digit PIN provided by the customer.'
                    : 'Enter the 4-digit OTP provided by the customer.',
                style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _completionCodeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 4,
                decoration: InputDecoration(
                  hintText: 'Enter 4-Digit Code (Demo Code: ${widget.type == 'delivery' ? widget.deliveryPin : '5892'})',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  counterText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                final enteredCode = _completionCodeController.text.trim();
                final correctCode = widget.type == 'delivery' ? widget.deliveryPin : '5892';
                
                if (enteredCode == correctCode) {
                  Navigator.pop(ctx);
                  setState(() {
                    _completed = true;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(widget.type == 'delivery' ? 'Delivery verification successful!' : 'Service verification successful! Payout dispatched.'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) Navigator.pop(context);
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Invalid code. Please verify with the customer.'),
                      backgroundColor: AppTheme.dangerColor,
                    ),
                  );
                }
              },
              child: const Text('Verify & Finish', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Color mapBgColor;
    if (_mapStyle == 'satellite') {
      mapBgColor = const Color(0xff1b261e);
    } else if (_mapStyle == 'dark') {
      mapBgColor = const Color(0xff121212);
    } else {
      mapBgColor = const Color(0xfff1f5f9);
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Hyperlocal Map Navigation'),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // 1. DYNAMIC VECTOR-STYLED MAP CANVAS
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  painter: PartnerMapPainter(
                    animationProgress: _animationController.value,
                    style: _mapStyle,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),

          // 2. MAP TYPE TOGGLE CHIPS
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildStyleChip('standard', 'Standard', Icons.map_outlined),
                  const SizedBox(width: 4),
                  _buildStyleChip('satellite', 'Satellite', Icons.public),
                  const SizedBox(width: 4),
                  _buildStyleChip('dark', 'Dark', Icons.nights_stay),
                ],
              ),
            ),
          ),

          // 3. TURN-BY-TURN NAVIGATION HUD
          Positioned(
            top: 16,
            left: 16,
            right: 120, // Avoid overlapping the style toggles
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _isNavigating ? Icons.navigation : Icons.directions,
                    color: Colors.white,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _navigationInstruction,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _distanceRemaining > 0 
                              ? '${_distanceRemaining.toStringAsFixed(0)} meters remaining · GPS Locked'
                              : 'Arrived at destination',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. BOTTOM ADDRESS & ACTION CONTROL SHEET
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Customer Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryColor),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppTheme.textSecondaryColor, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xffeff6ff),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.price,
                          style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  
                  // Task details
                  Row(
                    children: [
                      const Icon(Icons.assignment_outlined, size: 16, color: AppTheme.textSecondaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.type.toUpperCase()}: ${widget.serviceName}',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textPrimaryColor),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _toggleNavigation,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppTheme.primaryColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(_isNavigating ? Icons.pause : Icons.play_arrow),
                          label: Text(_isNavigating ? 'Pause' : 'Start Journey'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _completed ? null : _showCompletionDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _completed ? AppTheme.successColor : AppTheme.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: Icon(_completed ? Icons.check : Icons.lock_open),
                          label: Text(_completed ? 'Completed' : 'Verify & Finish'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleChip(String style, String label, IconData icon) {
    final isSelected = _mapStyle == style;
    return InkWell(
      onTap: () {
        setState(() {
          _mapStyle = style;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PartnerMapPainter extends CustomPainter {
  final double animationProgress;
  final String style;

  PartnerMapPainter({
    required this.animationProgress,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Color bg;
    Color streetColor;
    Color streetBorder;
    Color greenArea;
    Color waterArea;
    Color pathColor;
    Color textCol;

    if (style == 'satellite') {
      bg = const Color(0xff1b261e);
      streetColor = const Color(0xff333e36);
      streetBorder = const Color(0xff445248);
      greenArea = const Color(0xff142016);
      waterArea = const Color(0xff0b182b);
      pathColor = Colors.amber;
      textCol = Colors.white70;
    } else if (style == 'dark') {
      bg = const Color(0xff121212);
      streetColor = const Color(0xff2c2c2c);
      streetBorder = const Color(0xff3a3a3a);
      greenArea = const Color(0xff18221c);
      waterArea = const Color(0xff0d1f2d);
      pathColor = Colors.orangeAccent;
      textCol = Colors.white60;
    } else {
      // Standard
      bg = const Color(0xfff1f5f9);
      streetColor = Colors.white;
      streetBorder = const Color(0xffcbd5e1);
      greenArea = const Color(0xffdcfce7);
      waterArea = const Color(0xffe0f2fe);
      pathColor = AppTheme.primaryColor;
      textCol = AppTheme.textSecondaryColor;
    }

    // Paint Map Background
    final bgPaint = Paint()..color = bg;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Draw gridlines to look like map lines
    final gridPaint = Paint()
      ..color = streetBorder.withOpacity(0.2)
      ..strokeWidth = 1.0;
    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double j = 0; j < size.height; j += 40) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), gridPaint);
    }

    // Draw Water/Lake Body
    final waterPaint = Paint()..color = waterArea;
    final waterPath = Path()
      ..moveTo(size.width * 0.7, 0)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.2, size.width, size.height * 0.1)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(waterPath, waterPaint);

    // Draw Green Park Body
    final greenPaint = Paint()..color = greenArea;
    final greenRect = Rect.fromLTWH(20, size.height * 0.4, size.width * 0.35, 100);
    canvas.drawRRect(RRect.fromRectAndRadius(greenRect, const Radius.circular(16)), greenPaint);

    // Draw Streets/Road Network
    final roadPaint = Paint()
      ..color = streetColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16.0
      ..strokeCap = StrokeCap.round;

    final roadBorderPaint = Paint()
      ..color = streetBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18.0
      ..strokeCap = StrokeCap.round;

    // We draw borders first, then overlay with streetColor
    List<Path> streets = [];
    
    // Main horizontal road
    streets.add(Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(size.width, size.height * 0.5));
    
    // Secondary diagonal road
    streets.add(Path()
      ..moveTo(size.width * 0.2, 0)
      ..lineTo(size.width * 0.8, size.height));

    // Curved loop road
    streets.add(Path()
      ..moveTo(size.width * 0.1, size.height * 0.2)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.1, size.width * 0.9, size.height * 0.3));

    // Draw Road Borders
    for (var p in streets) {
      canvas.drawPath(p, roadBorderPaint);
    }
    // Draw Roads Core
    for (var p in streets) {
      canvas.drawPath(p, roadPaint);
    }

    // Draw Route Path (Bezier path connecting provider and customer)
    final startPoint = Offset(size.width * 0.15, size.height * 0.18);
    final endPoint = Offset(size.width * 0.65, size.height * 0.75);
    final cp1 = Offset(size.width * 0.3, size.height * 0.6);
    final cp2 = Offset(size.width * 0.5, size.height * 0.3);

    final routePath = Path()
      ..moveTo(startPoint.dx, startPoint.dy)
      ..cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, endPoint.dx, endPoint.dy);

    final routePaint = Paint()
      ..color = pathColor.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round;

    final routeActivePaint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(routePath, routePaint);

    // Draw active animated path segment
    final pathMetrics = routePath.computeMetrics().toList();
    if (pathMetrics.isNotEmpty) {
      final metric = pathMetrics.first;
      final activePath = metric.extractPath(0, metric.length * animationProgress);
      canvas.drawPath(activePath, routeActivePaint);

      // Draw vehicle location marker
      final tangent = metric.getTangentForOffset(metric.length * animationProgress);
      if (tangent != null) {
        final currentPos = tangent.position;

        // Pulsing radar wave
        final pulsePaint = Paint()
          ..color = pathColor.withOpacity(0.15)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(currentPos, 14 + 8 * (animationProgress % 0.25 * 4), pulsePaint);

        // Core marker
        final markerPaint = Paint()
          ..color = pathColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(currentPos, 9, markerPaint);

        final innerMarker = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;
        canvas.drawCircle(currentPos, 4, innerMarker);
      }
    }

    // Draw Pin at Start
    final startPinPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    canvas.drawCircle(startPoint, 6, startPinPaint);
    canvas.drawCircle(startPoint, 3, Paint()..color = Colors.white);

    // Draw Pin at Destination (End)
    final endPinPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPoint, 8, endPinPaint);
    
    final endPinInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(endPoint, 3.5, endPinInner);
  }

  @override
  bool shouldRepaint(covariant PartnerMapPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress || oldDelegate.style != style;
  }
}
