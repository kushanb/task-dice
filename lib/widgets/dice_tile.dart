import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'press_scale.dart';

/// The 120×120 dice. Shows the "5" face; shakes on the [rolling] loop
/// (design `diceShake`: rotate ±14° with a slight scale pulse).
class DiceTile extends StatefulWidget {
  const DiceTile({super.key, required this.rolling, this.onTap});

  final bool rolling;
  final VoidCallback? onTap;

  @override
  State<DiceTile> createState() => _DiceTileState();
}

class _DiceTileState extends State<DiceTile> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.diceShake,
  );

  @override
  void initState() {
    super.initState();
    if (widget.rolling) _controller.repeat();
  }

  @override
  void didUpdateWidget(DiceTile old) {
    super.didUpdateWidget(old);
    if (widget.rolling && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.rolling && _controller.isAnimating) {
      _controller.animateTo(1).then((_) {
        if (mounted) _controller.reset();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: widget.onTap,
      scale: 0.94,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Triangle wave 0→1→0 over the loop, shaped into the shake keyframes.
          final t = _controller.value;
          final swing = (t * 2 <= 1 ? t * 2 : 2 - t * 2); // 0..1..0
          final angle = (swing - 0.5) * 2 * 0.245; // ±14° ≈ 0.245 rad
          final scale = 1 + swing * 0.08;
          return Transform.rotate(
            angle: angle,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.borderStrong),
            borderRadius: BorderRadius.circular(AppRadii.rDice),
            boxShadow: AppShadows.overlay,
          ),
          child: const Center(child: _DiceFive()),
        ),
      ),
    );
  }
}

/// 3×3 pip grid showing the five-face (corners + center).
class _DiceFive extends StatelessWidget {
  const _DiceFive();

  @override
  Widget build(BuildContext context) {
    const filled = {0, 2, 4, 6, 8};
    return SizedBox(
      width: 54, // 3×14 pips + 2×6 gaps
      height: 54,
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          for (var i = 0; i < 9; i++)
            Container(
              decoration: BoxDecoration(
                color: filled.contains(i)
                    ? AppColors.green
                    : const Color(0x00000000),
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
}
