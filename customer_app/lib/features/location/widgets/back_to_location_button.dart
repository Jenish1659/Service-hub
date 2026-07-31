import 'package:flutter/material.dart';

class BackToLocationButton extends StatelessWidget {
  final VoidCallback onPressed;
  const BackToLocationButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xff0f172a),
        foregroundColor: Colors.white,
        elevation: 6,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.navigation, color: Color(0xfff59e0b), size: 16),
      label: const Text(
        'Re-center GPS',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
