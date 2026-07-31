import 'package:flutter/material.dart';

class CenterLocationMarker extends StatelessWidget {
  final bool isMoving;
  const CenterLocationMarker({super.key, this.isMoving = false});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      transform: Matrix4.translationValues(0, isMoving ? -12 : 0, 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff0f172a),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xfff59e0b), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black38,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: const Icon(
              Icons.location_on,
              color: Color(0xfff59e0b),
              size: 28,
            ),
          ),
          Container(
            width: 4,
            height: 12,
            color: const Color(0xff0f172a),
          ),
          Container(
            width: 10,
            height: 4,
            decoration: const BoxDecoration(
              color: Colors.black45,
              borderRadius: BorderRadius.all(Radius.elliptical(10, 4)),
            ),
          ),
        ],
      ),
    );
  }
}
