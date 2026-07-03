import 'dart:math';

import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Circular efficiency-score ring: faint track, green arc from 12 o'clock,
/// round caps, animated fill. Sizes from the design: 92/8 (home), 110/9 (review).
class EfficiencyRing extends StatelessWidget {
  const EfficiencyRing({
    super.key,
    required this.score,
    this.size = 92,
    this.strokeWidth = 8,
    this.sublabel,
  });

  /// 0–100.
  final int score;
  final double size;
  final double strokeWidth;
  final String? sublabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: score / 100),
        duration: AppMotion.ringFill,
        curve: AppMotion.emphasized,
        builder: (context, progress, _) => CustomPaint(
          painter: _RingPainter(progress: progress, strokeWidth: strokeWidth),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$score',
                    style: size >= 110 ? AppText.ringValueLarge : AppText.ringValue),
                if (sublabel != null)
                  Text(sublabel!, style: AppText.micro.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.strokeWidth});

  final double progress;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    // Same proportion as the design: r 38 in a 92 box.
    final radius = size.width * 38 / 92;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = AppColors.track;
    canvas.drawCircle(center, radius, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = AppColors.green;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress || old.strokeWidth != strokeWidth;
}
