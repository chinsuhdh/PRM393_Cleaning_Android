import 'package:flutter/material.dart';

/// A static pin icon with a looping, expanding, fading ring behind it — used to draw attention to
/// the client's chosen/current job location on the booking-detail maps.
class PulsingLocationMarker extends StatefulWidget {
  const PulsingLocationMarker({
    super.key,
    required this.icon,
    required this.color,
    this.iconSize = 40,
    this.boxSize = 80,
  });

  final IconData icon;
  final Color color;
  final double iconSize;
  final double boxSize;

  @override
  State<PulsingLocationMarker> createState() => _PulsingLocationMarkerState();
}

class _PulsingLocationMarkerState extends State<PulsingLocationMarker> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    return SizedBox(
      width: widget.boxSize,
      height: widget.boxSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: curved,
            builder: (context, child) {
              final ringSize = widget.iconSize + (widget.boxSize - widget.iconSize) * curved.value;
              return Opacity(
                opacity: (1 - curved.value).clamp(0.0, 1.0),
                child: Container(
                  width: ringSize,
                  height: ringSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.color.withValues(alpha: 0.25),
                  ),
                ),
              );
            },
          ),
          Icon(widget.icon, color: widget.color, size: widget.iconSize),
        ],
      ),
    );
  }
}
