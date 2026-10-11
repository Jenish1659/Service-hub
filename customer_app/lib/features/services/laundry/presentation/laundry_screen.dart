import 'package:flutter/material.dart';
import '../../presentation/laundry_requirement_screen.dart';

class LaundryScreen extends StatelessWidget {
  final String? serviceName;
  final double? servicePrice;

  const LaundryScreen({
    super.key,
    this.serviceName,
    this.servicePrice,
  });

  @override
  Widget build(BuildContext context) {
    return LaundryRequirementScreen(
      serviceName: serviceName,
      servicePrice: servicePrice,
    );
  }
}
