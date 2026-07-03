import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Pulses its child's opacity 1 → 0.35 on a 2 s loop (design `breathe`).
class Breathe extends StatefulWidget {
  const Breathe({super.key, required this.child});

  final Widget child;

  @override
  State<Breathe> createState() => _BreatheState();
}

class _BreatheState extends State<Breathe> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.breathe ~/ 2,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.35).animate(_controller),
      child: widget.child,
    );
  }
}

/// Live-state dot on the breathe loop.
class BreathingDot extends StatelessWidget {
  const BreathingDot({super.key, required this.color, this.size = 7});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Breathe(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}
