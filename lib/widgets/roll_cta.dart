import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'press_scale.dart';

/// The big green "Roll a task" bar on Today.
class RollCta extends StatelessWidget {
  const RollCta({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s20),
        decoration: BoxDecoration(
          color: AppColors.green,
          borderRadius: BorderRadius.circular(AppRadii.rCardHero),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _DiceGlyph(),
            const SizedBox(width: AppSpacing.s12),
            Text('Roll a task',
                style: AppText.buttonLarge.copyWith(color: AppColors.onGreen)),
          ],
        ),
      ),
    );
  }
}

/// Mini dice icon: dark rounded square with two green pips on the diagonal.
class _DiceGlyph extends StatelessWidget {
  const _DiceGlyph();

  @override
  Widget build(BuildContext context) {
    Widget pip({required bool visible}) => Center(
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: visible ? AppColors.green : const Color(0x00000000),
              shape: BoxShape.circle,
            ),
          ),
        );

    return Container(
      width: 26,
      height: 26,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.onGreen,
        borderRadius: BorderRadius.circular(7),
      ),
      child: GridView.count(
        crossAxisCount: 2,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          pip(visible: true),
          pip(visible: false),
          pip(visible: false),
          pip(visible: true),
        ],
      ),
    );
  }
}
