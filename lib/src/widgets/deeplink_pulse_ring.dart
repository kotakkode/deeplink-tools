import 'package:flutter/material.dart';

/// An expanding, fading ring drawn around the floating button while active.
class DeeplinkPulseRing extends StatelessWidget {
  final Animation<double> progress;
  final double size;
  final Color color;

  const DeeplinkPulseRing({
    super.key,
    required this.progress,
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: progress,
        builder: (context, _) {
          final t = Curves.easeOut.transform(progress.value);
          // Scale via a transform so the ring can overflow the button's box.
          return Transform.scale(
            scale: 1 + 0.7 * t,
            child: Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withValues(alpha: (1 - t) * 0.8),
                  width: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
