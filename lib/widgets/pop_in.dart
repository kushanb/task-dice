import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Entrance: scale 0.85 → 1 with fade (design `popIn`).
class PopIn extends StatelessWidget {
  const PopIn({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.popIn,
      curve: Curves.easeOut,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
      ),
    );
  }
}
