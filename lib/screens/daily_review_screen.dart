import 'package:flutter/material.dart';

import '../logic/formats.dart';
import '../logic/scoring.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import '../widgets/efficiency_ring.dart';
import '../widgets/estimate_vs_actual_row.dart';
import '../widgets/hairline_bar.dart';
import '../widgets/section_label.dart';
import '../widgets/stat_tile.dart';

/// Daily review — the end-of-day summary. Pushed as its own route (from the
/// Today efficiency card), so it receives [state] directly.
class DailyReviewScreen extends StatelessWidget {
  const DailyReviewScreen({super.key, required this.state});

  final AppState state;

  static Future<void> open(BuildContext context, AppState state) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => DailyReviewScreen(state: state),
      ));

  String _subtitle(int score, int done, int total) {
    final lead = switch (score) {
      >= 75 => 'Strong day.',
      >= 60 => 'Solid day.',
      >= 40 => 'Steady day.',
      _ => 'Tough day — reset tomorrow.',
    };
    return '$lead $done of $total tasks done — that\'s momentum.';
  }

  String _insight(List<Task> done) {
    Task? worst;
    var worstOver = 0.0;
    for (final t in done) {
      final a = t.actualMin;
      if (a == null || !isOverEstimate(actualMin: a, estMin: t.estMin)) continue;
      final over = (a - t.estMin) / t.estMin;
      if (over > worstOver) {
        worstOver = over;
        worst = t;
      }
    }
    if (worst == null) {
      return 'Estimates were sharp today — closer guesses keep earning bonus points.';
    }
    final pct = (worstOver * 100).round();
    final suggest = ((worst.actualMin! / 5).floor() * 5);
    return '${worst.tag} tasks ran ~$pct% over estimate. Try estimating '
        '${suggest}m next time — closer guesses, more bonus points.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Day review')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final breakdown = efficiencyBreakdown(
              state.tasks, state.dayFocusBaseMin, state.dayBreakBaseMin);
          final total = state.tasks.length;
          final done =
              state.tasks.where((t) => t.isDone).toList();
          final carry = state.tasks.where((t) => !t.isDone).length;
          final measured =
              done.where((t) => t.actualMin != null).toList();
          final maxMin = measured.isEmpty
              ? 1
              : measured
                  .map((t) => t.actualMin! > t.estMin ? t.actualMin! : t.estMin)
                  .reduce((a, b) => a > b ? a : b);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20, AppSpacing.s12, AppSpacing.s20, AppSpacing.s24),
            children: [
              Text(_subtitle(breakdown.total, done.length, total),
                  style: AppText.body.copyWith(fontSize: 12.5, height: 1.4)),
              const SizedBox(height: AppSpacing.s14),
              _ScoreCard(breakdown: breakdown),
              const SizedBox(height: AppSpacing.s14),
              Row(
                children: [
                  Expanded(
                    child: StatTile(
                      value: '+${fmtThousands(state.pointsEarnedToday)}',
                      label: 'points earned',
                      valueColor: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s10),
                  Expanded(
                    child: StatTile(
                        value: '${done.length}/$total', label: 'completed'),
                  ),
                  const SizedBox(width: AppSpacing.s10),
                  Expanded(
                    child: StatTile(
                      value: '$carry',
                      label: 'carry to ${weekdayShort(_tomorrow())}',
                      valueColor: AppColors.red,
                    ),
                  ),
                ],
              ),
              if (measured.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.s16),
                const SectionLabel('Estimate vs actual'),
                const SizedBox(height: AppSpacing.s12),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.borderHairline),
                    borderRadius: BorderRadius.circular(AppRadii.rCard),
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < measured.length; i++) ...[
                        if (i > 0) const SizedBox(height: 13),
                        EstimateVsActualRow(
                          title: measured[i].title,
                          estMin: measured[i].estMin,
                          actualMin: measured[i].actualMin!,
                          maxMin: maxMin,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.s14),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s14, vertical: AppSpacing.s12),
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: .06),
                  border: Border.all(color: AppColors.green.withValues(alpha: .2)),
                  borderRadius: BorderRadius.circular(AppRadii.rCardSmall),
                ),
                child: Text(_insight(done),
                    style: AppText.body.copyWith(fontSize: 12, height: 1.5)),
              ),
            ],
          );
        },
      ),
    );
  }

  DateTime _tomorrow() => DateTime.now().add(const Duration(days: 1));
}

class _ScoreCard extends StatelessWidget {
  const _ScoreCard({required this.breakdown});

  final EfficiencyBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline),
        borderRadius: BorderRadius.circular(AppRadii.rCardHero),
      ),
      child: Row(
        children: [
          EfficiencyRing(
            score: breakdown.total,
            size: 110,
            strokeWidth: 9,
            sublabel: 'efficiency',
          ),
          const SizedBox(width: AppSpacing.s20),
          Expanded(
            child: Column(
              children: [
                _SubScore(
                    label: 'Focus ratio',
                    value: breakdown.focus,
                    max: EfficiencyBreakdown.focusMax),
                const SizedBox(height: 9),
                _SubScore(
                    label: 'Completion',
                    value: breakdown.completion,
                    max: EfficiencyBreakdown.completionMax),
                const SizedBox(height: 9),
                _SubScore(
                    label: 'Estimates',
                    value: breakdown.estimate,
                    max: EfficiencyBreakdown.estimateMax),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SubScore extends StatelessWidget {
  const _SubScore(
      {required this.label, required this.value, required this.max});

  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(
                      fontSize: 11.5, color: AppColors.textTertiary)),
            ),
            const SizedBox(width: AppSpacing.s6),
            Text('$value/$max',
                style: AppText.monoCaption
                    .copyWith(fontSize: 11.5, color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 4),
        HairlineBar(fraction: value / max, color: AppColors.green, height: 4),
      ],
    );
  }
}
