import 'package:flutter/widgets.dart';

import '../logic/formats.dart';
import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import 'breathing_dot.dart';
import 'press_scale.dart';

/// "Now tracking" hero card on Today: live timer + focus/break split.
class NowTrackingCard extends StatelessWidget {
  const NowTrackingCard({super.key, required this.state, this.onTap});

  final AppState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final task = state.activeTask!;
    final overlineColor = state.onBreak ? AppColors.amber : AppColors.green;
    final overlineText = state.onBreak ? 'ON BREAK — STILL TRACKING' : 'NOW TRACKING';

    return PressScale(
      onTap: onTap,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s18),
        decoration: BoxDecoration(
          gradient: AppColors.heroGradient,
          border: Border.all(color: AppColors.borderGreen),
          borderRadius: BorderRadius.circular(AppRadii.rCardHero),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                BreathingDot(color: overlineColor, size: 6),
                const SizedBox(width: AppSpacing.s6),
                Text(overlineText,
                    style: AppText.overline
                        .copyWith(fontSize: 10.5, color: overlineColor)),
              ],
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(task.title, style: AppText.heroTitle),
            const SizedBox(height: AppSpacing.s10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(fmtClock(state.elapsed), style: AppText.timerMedium),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text.rich(
                      TextSpan(
                        style: AppText.monoBody.copyWith(
                            fontSize: 12, color: AppColors.textTertiary),
                        children: [
                          TextSpan(
                              text:
                                  'focus ${fmtClock(state.sessionFocus)} · break '),
                          TextSpan(
                              text: fmtClock(state.sessionBreak),
                              style: const TextStyle(color: AppColors.amber)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
