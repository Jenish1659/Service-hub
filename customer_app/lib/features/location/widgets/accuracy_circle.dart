import 'package:flutter/material.dart';

class AccuracyCircleWidget extends StatelessWidget {
  final double radius;
  const AccuracyCircleWidget({super.key, this.radius = 40.0});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.15),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue.withValues(alpha: 0.4), width: 1.5),
      ),
    );
  }
}
