import 'package:flutter/material.dart';

class CurrentLocationButton extends StatelessWidget {
  final VoidCallback onPressed;
  const CurrentLocationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(shape: BoxShape.circle),
          child: const Icon(Icons.my_location, color: Color(0xfff59e0b), size: 24),
        ),
      ),
    );
  }
}
