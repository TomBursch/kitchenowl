import 'package:flutter/material.dart';

/// Animated three-dot typing indicator. Pass [color] to match the container.
class TypingIndicator extends StatefulWidget {
  final Color color;

  const TypingIndicator({super.key, required this.color});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double _dotScale(int index) {
    // Stagger each dot by 0.2 of the cycle period.
    final shifted = (_controller.value - index * 0.2) % 1.0;
    // Map to a 0-1-0 "bounce" within the first half of the cycle.
    final t = (shifted * 2).clamp(0.0, 1.0);
    final bounce = t < 0.5 ? t * 2 : (1.0 - t) * 2;
    return 0.6 + 0.4 * bounce;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 4),
            Transform.scale(
              scale: _dotScale(i),
              child: CircleAvatar(
                radius: 4,
                backgroundColor: widget.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
