import 'package:flutter/material.dart';

class MapSearchBar extends StatelessWidget {
  final VoidCallback onTap;
  final String? currentSearchText;

  const MapSearchBar({
    super.key,
    required this.onTap,
    this.currentSearchText,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 6,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xffe2e8f0)),
          ),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(0xfff59e0b), size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentSearchText?.isNotEmpty == true
                      ? currentSearchText!
                      : 'Search area, street, or city...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: currentSearchText?.isNotEmpty == true
                        ? const Color(0xff0f172a)
                        : const Color(0xff94a3b8),
                    fontWeight: currentSearchText?.isNotEmpty == true
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xfff1f5f9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.tune, color: Color(0xff64748b), size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
