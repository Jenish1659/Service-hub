import 'package:flutter/material.dart';

class ServiceHubMarker extends StatelessWidget {
  final double size;
  const ServiceHubMarker({super.key, this.size = 48.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft shadow base
          Positioned(
            bottom: 2,
            child: Container(
              width: 14,
              height: 5,
              decoration: const BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.all(Radius.elliptical(14, 5)),
              ),
            ),
          ),
          // Main Pin Body
          Positioned(
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xff0f172a), // Navy background
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xfff59e0b), width: 2.5), // Gold border
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: const Icon(
                Icons.location_on,
                color: Color(0xfff59e0b), // Gold pin icon
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
