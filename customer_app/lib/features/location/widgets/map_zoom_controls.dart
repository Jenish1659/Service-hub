import 'package:flutter/material.dart';

class MapZoomControls extends StatelessWidget {
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  const MapZoomControls({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onZoomIn,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Icon(Icons.add, color: Color(0xff0f172a), size: 20),
            ),
          ),
          const Divider(height: 1, color: Color(0xffe2e8f0)),
          InkWell(
            onTap: onZoomOut,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(10.0),
              child: Icon(Icons.remove, color: Color(0xff0f172a), size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
