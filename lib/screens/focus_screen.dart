import 'package:flutter/widgets.dart';

import '../logic/formats.dart';
import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_toast.dart';
import '../widgets/break_sheet.dart';
import '../widgets/breathing_dot.dart';
import '../widgets/energy_check_in.dart';
import '../widgets/press_scale.dart';

/// Focus mode: the big timer, break CTA, pause/complete, break budget.
class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key, this.onDone});

  /// Called after completing the task (shell navigates back to Today).
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final task = state.activeTask;

    if (task == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nothing tracking', style: AppText.focusTitle),
            const SizedBox(height: AppSpacing.s8),
            Text('Pick a task on Today — or let the dice decide.',
                style: AppText.caption),
          ],
        ),
      );
    }

    final onBreak = state.onBreak;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 90),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (onBreak)
                Breathe(
                  child: Text(
                    'ON BREAK — TASK STILL TRACKING',
                    textAlign: TextAlign.center,
                    style: AppText.overline.copyWith(color: AppColors.amber),
                  ),
                )
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const BreathingDot(color: AppColors.green),
                    const SizedBox(width: AppSpacing.s6),
                    Text(state.isRunning ? 'IN FOCUS' : 'PAUSED',
                        style: AppText.overline
                            .copyWith(color: AppColors.green)),
                  ],
                ),
              const SizedBox(height: AppSpacing.s12),
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: Text(task.title,
                      textAlign: TextAlign.center, style: AppText.focusTitle),
                ),
              ),
              const SizedBox(height: AppSpacing.s4),
              Text(task.meta,
                  textAlign: TextAlign.center,
                  style: AppText.caption.copyWith(fontSize: 12.5)),
              const SizedBox(height: AppSpacing.s18),
              Text(fmtClock(state.elapsed),
                  textAlign: TextAlign.center, style: AppText.timerDisplay),
              const SizedBox(height: AppSpacing.s2),
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style:
                      AppText.monoBody.copyWith(color: AppColors.textTertiary),
                  children: [
                    TextSpan(
                        text: 'focus ${fmtClock(state.sessionFocus)} · break '),
                    TextSpan(
                        text: fmtClock(state.sessionBreak),
                        style: const TextStyle(color: AppColors.amber)),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              PressScale(
                onTap: () => showBreakSheet(context, state),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.s18),
                  decoration: BoxDecoration(
                    color: AppColors.amberTint,
                    border: Border.all(color: AppColors.borderAmber),
                    borderRadius:
                        BorderRadius.circular(AppRadii.rCardProminent),
                  ),
                  child: Text(
                    onBreak
                        ? '■ On break · ${fmtClock(state.sessionBreak)} — manage'
                        : '☕  Take a break',
                    textAlign: TextAlign.center,
                    style: AppText.buttonLarge
                        .copyWith(fontSize: 16, color: AppColors.amber),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              Row(
                children: [
                  Expanded(
                    child: PressScale(
                      onTap: state.togglePause,
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          border: Border.all(color: AppColors.borderInput),
                          borderRadius:
                              BorderRadius.circular(AppRadii.rCardSmall),
                        ),
                        child: Text(state.isRunning ? 'Pause' : 'Resume',
                            textAlign: TextAlign.center,
                            style: AppText.buttonSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s10),
                  Expanded(
                    child: PressScale(
                      onTap: () {
                        state.completeActiveTask();
                        onDone?.call();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: AppColors.green,
                          borderRadius:
                              BorderRadius.circular(AppRadii.rCardSmall),
                        ),
                        child: Text('Complete ✓',
                            textAlign: TextAlign.center,
                            style: AppText.button.copyWith(
                                fontSize: 13.5, color: AppColors.onGreen)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s14),
              Text.rich(
                textAlign: TextAlign.center,
                TextSpan(
                  style: AppText.caption,
                  children: [
                    const TextSpan(text: 'Break budget · '),
                    TextSpan(
                        text: '${state.breakBudgetUsedMin}',
                        style: AppText.monoCaption
                            .copyWith(color: AppColors.amber)),
                    TextSpan(text: ' of ${state.breakBudgetMin}m used'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s6),
              Center(
                child: _BudgetBar(
                  fraction: (state.breakBudgetUsedMin / state.breakBudgetMin)
                      .clamp(0.0, 1.0),
                ),
              ),
            ],
          ),
        ),
        if (state.energyPromptVisible)
          Positioned(
            left: AppSpacing.s16,
            right: AppSpacing.s16,
            bottom: 100,
            child: EnergyCheckIn(
              onPick: (level) {
                state.logEnergy(level);
                AppToast.show(context, 'Energy $level/5 logged');
              },
            ),
          ),
      ],
    );
  }
}

class _BudgetBar extends StatelessWidget {
  const _BudgetBar({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 4,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.track,
        borderRadius: BorderRadius.circular(2),
      ),
      child: AnimatedFractionallySizedBox(
        duration: AppMotion.barFill,
        alignment: Alignment.centerLeft,
        widthFactor: fraction,
        child: Container(color: AppColors.amber),
      ),
    );
  }
}
