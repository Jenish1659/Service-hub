import 'package:flutter/material.dart';
import '../../presentation/cooking_requirement_screen.dart';

class CookingScreen extends StatelessWidget {
  final String? serviceName;
  final double? servicePrice;

  const CookingScreen({
    super.key,
    this.serviceName,
    this.servicePrice,
  });

  @override
  Widget build(BuildContext context) {
    return CookingRequirementScreen(
      serviceName: serviceName,
      servicePrice: servicePrice,
    );
  }
}
