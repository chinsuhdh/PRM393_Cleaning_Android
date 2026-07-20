import 'package:flutter/material.dart';

/// Consistent icon+label row for PopupMenuItem children, so every option renders
/// as an aligned button-like row instead of bare, inconsistently-centered text.
class PopupMenuActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const PopupMenuActionItem({
    super.key,
    required this.icon,
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 20, color: effectiveColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: effectiveColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
