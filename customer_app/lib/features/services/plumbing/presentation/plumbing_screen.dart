import 'package:flutter/material.dart';
import '../../presentation/plumbing_requirement_screen.dart';

class PlumbingScreen extends StatelessWidget {
  final String? serviceName;
  final double? servicePrice;

  const PlumbingScreen({
    super.key,
    this.serviceName,
    this.servicePrice,
  });

  @override
  Widget build(BuildContext context) {
    return PlumbingRequirementScreen(
      serviceName: serviceName,
      servicePrice: servicePrice,
    );
  }
}
