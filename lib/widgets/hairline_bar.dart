import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Thin rounded progress bar over a faint track (design `HairlineBar`).
class HairlineBar extends StatelessWidget {
  const HairlineBar({
    super.key,
    required this.fraction,
    required this.color,
    this.height = 6,
    this.background = AppColors.track,
    this.radius = 3,
  });

  /// 0..1.
  final double fraction;
  final Color color;
  final double height;
  final Color background;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: fraction.clamp(0.0, 1.0),
        child: Container(color: color),
      ),
    );
  }
}
