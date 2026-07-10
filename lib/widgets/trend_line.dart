import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Green efficiency polyline with muted past dots and a green current dot.
class TrendLine extends StatelessWidget {
  const TrendLine({super.key, required this.values, this.height = 90});

  final List<int> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _TrendPainter(values)),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    const padY = 12.0;
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final span = (maxV - minV) == 0 ? 1 : (maxV - minV);

    Offset pointAt(int i) {
      final x = size.width * i / (values.length - 1);
      final norm = (values[i] - minV) / span; // 0..1, higher = better
      final y = size.height - padY - norm * (size.height - 2 * padY);
      return Offset(x, y);
    }

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = AppColors.green;

    final path = Path()..moveTo(pointAt(0).dx, pointAt(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(pointAt(i).dx, pointAt(i).dy);
    }
    canvas.drawPath(path, line);

    final mutedDot = Paint()..color = AppColors.chartDotMuted;
    for (var i = 0; i < values.length - 1; i++) {
      canvas.drawCircle(pointAt(i), 3, mutedDot);
    }
    canvas.drawCircle(
        pointAt(values.length - 1), 4, Paint()..color = AppColors.green);
  }

  @override
  bool shouldRepaint(_TrendPainter old) => old.values != values;
}
