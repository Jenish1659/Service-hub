import 'package:flutter/material.dart';
import '../../presentation/car_service_requirement_screen.dart';

class CarServiceScreen extends StatelessWidget {
  final String? serviceName;
  final double? servicePrice;

  const CarServiceScreen({
    super.key,
    this.serviceName,
    this.servicePrice,
  });

  @override
  Widget build(BuildContext context) {
    return CarServiceRequirementScreen(
      serviceName: serviceName,
      servicePrice: servicePrice,
    );
  }
}
