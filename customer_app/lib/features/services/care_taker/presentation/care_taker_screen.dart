import 'package:flutter/material.dart';
import '../../presentation/care_taker_requirement_screen.dart';

class CareTakerScreen extends StatelessWidget {
  final String? serviceName;
  final double? servicePrice;

  const CareTakerScreen({
    super.key,
    this.serviceName,
    this.servicePrice,
  });

  @override
  Widget build(BuildContext context) {
    return CareTakerRequirementScreen(
      serviceName: serviceName,
      servicePrice: servicePrice,
    );
  }
}
