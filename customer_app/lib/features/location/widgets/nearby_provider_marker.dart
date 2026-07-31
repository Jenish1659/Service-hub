import 'package:flutter/material.dart';

class NearbyProviderMarker extends StatelessWidget {
  final String providerName;
  final String category;

  const NearbyProviderMarker({
    super.key,
    required this.providerName,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xff0f172a),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xfff59e0b), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified, color: Color(0xfff59e0b), size: 14),
          const SizedBox(width: 4),
          Text(
            providerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
