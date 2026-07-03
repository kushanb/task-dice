import 'package:flutter/widgets.dart';

import '../logic/formats.dart';
import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import '../widgets/completed_card.dart';
import '../widgets/efficiency_ring.dart';
import '../widgets/now_tracking_card.dart';
import '../widgets/roll_cta.dart';
import '../widgets/task_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key, this.onRollTap, this.onTaskStart});

  /// Switch to the Roll tab.
  final VoidCallback? onRollTap;

  /// Called after a task starts tracking (later: navigate to Focus mode).
  final VoidCallback? onTaskStart;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20, AppSpacing.s12, AppSpacing.s20, AppSpacing.scrollBottom),
      children: [
        _Header(points: state.points),
        const SizedBox(height: AppSpacing.s16),
        if (state.completedInfo != null) ...[
          CompletedCard(info: state.completedInfo!),
          const SizedBox(height: AppSpacing.s16),
        ],
        if (state.isTracking) ...[
          NowTrackingCard(state: state, onTap: onTaskStart),
          const SizedBox(height: AppSpacing.s16),
        ],
        _EfficiencyCard(state: state),
        const SizedBox(height: AppSpacing.s16),
        RollCta(onTap: onRollTap),
        const SizedBox(height: AppSpacing.s18),
        Text('UP NEXT',
            style: AppText.tabLabel
                .copyWith(color: AppColors.textFaint, letterSpacing: 0.96)),
        const SizedBox(height: AppSpacing.s12),
        for (final task in state.openTasks) ...[
          TaskCard(
            task: task,
            showChevron: true,
            onTap: () {
              state.startTask(task.id);
              onTaskStart?.call();
            },
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.points});

  final int points;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dayPartLabel(DateTime.now()),
                  style: AppText.body
                      .copyWith(fontSize: 13, height: null)),
              Text('Today', style: AppText.pageTitle),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(fmtThousands(points),
                style: AppText.statValue.copyWith(color: AppColors.green)),
            Text('points', style: AppText.caption.copyWith(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _EfficiencyCard extends StatelessWidget {
  const _EfficiencyCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline),
        borderRadius: BorderRadius.circular(AppRadii.rCardHero),
      ),
      child: Row(
        children: [
          EfficiencyRing(score: state.efficiencyScore),
          const SizedBox(width: AppSpacing.s18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Efficiency today',
                    style: AppText.taskTitle
                        .copyWith(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.s8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      _Split(
                          value: fmtHoursMin(state.dayFocusBaseMin),
                          label: 'focused'),
                      const SizedBox(width: AppSpacing.s14),
                      _Split(
                          value: fmtHoursMin(state.dayBreakBaseMin),
                          label: 'on break',
                          color: AppColors.amber),
                      const SizedBox(width: AppSpacing.s14),
                      _Split(
                          value: '${state.doneCount}/${state.tasks.length}',
                          label: 'done'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Split extends StatelessWidget {
  const _Split({required this.value, required this.label, this.color});

  final String value;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppText.monoValue.copyWith(color: color)),
        Text(label, style: AppText.micro),
      ],
    );
  }
}
