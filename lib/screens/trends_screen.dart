import 'package:flutter/widgets.dart';

import '../models/trends.dart';
import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import '../widgets/accuracy_bars.dart';
import '../widgets/focus_heatmap.dart';
import '../widgets/hairline_bar.dart';
import '../widgets/trend_line.dart';

class TrendsScreen extends StatelessWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final trends = AppScope.of(context).trends;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20, AppSpacing.s12, AppSpacing.s20, AppSpacing.scrollBottom),
      children: [
        Text('Trends', style: AppText.pageTitle),
        const SizedBox(height: AppSpacing.s14),
        _WeeklyEfficiencyCard(trends: trends),
        const SizedBox(height: AppSpacing.s14),
        _HeatmapCard(trends: trends),
        const SizedBox(height: AppSpacing.s14),
        _BreakPatternsCard(trends: trends),
        const SizedBox(height: AppSpacing.s14),
        _AccuracyCard(trends: trends),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline),
        borderRadius: BorderRadius.circular(AppRadii.rCard),
      ),
      child: child,
    );
  }
}

Widget _cardTitle(String text) =>
    Text(text, style: AppText.taskTitle.copyWith(fontSize: 13, color: AppColors.textSecondary));

class _WeeklyEfficiencyCard extends StatelessWidget {
  const _WeeklyEfficiencyCard({required this.trends});

  final TrendsData trends;

  @override
  Widget build(BuildContext context) {
    final delta = trends.deltaVsLastWeek;
    final up = delta >= 0;
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _cardTitle('Weekly efficiency')),
              Text('${up ? '↑ +' : '↓ '}$delta vs last wk',
                  style: AppText.monoCaption.copyWith(
                      fontSize: 12,
                      color: up ? AppColors.green : AppColors.red)),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          TrendLine(values: trends.weeklyEfficiency),
          const SizedBox(height: AppSpacing.s4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final day in trends.dayLabels)
                Text(day,
                    style: AppText.monoCaption
                        .copyWith(fontSize: 10, color: AppColors.textFaint)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.trends});

  final TrendsData trends;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardTitle('Focus heatmap'),
          const SizedBox(height: AppSpacing.s2),
          Text.rich(
            TextSpan(
              style: AppText.caption.copyWith(fontSize: 11.5),
              children: [
                const TextSpan(text: 'Your peak window: '),
                TextSpan(
                    text: trends.peakWindow,
                    style: const TextStyle(color: AppColors.green)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s10),
          FocusHeatmap(intensities: trends.heatmap),
          const SizedBox(height: AppSpacing.s6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final label in trends.heatmapAxis)
                Text(label,
                    style: AppText.monoCaption
                        .copyWith(fontSize: 10, color: AppColors.textFaint)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakPatternsCard extends StatelessWidget {
  const _BreakPatternsCard({required this.trends});

  final TrendsData trends;

  @override
  Widget build(BuildContext context) {
    final maxMin = trends.breakPatterns
        .map((b) => b.minutes)
        .reduce((a, b) => a > b ? a : b);
    // Headroom so the busiest category doesn't run edge-to-edge.
    final denom = maxMin * 1.4;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _cardTitle('Break patterns · this week'),
          const SizedBox(height: AppSpacing.s12),
          for (var i = 0; i < trends.breakPatterns.length; i++) ...[
            if (i > 0) const SizedBox(height: 9),
            _BreakRow(pattern: trends.breakPatterns[i], denom: denom),
          ],
        ],
      ),
    );
  }
}

class _BreakRow extends StatelessWidget {
  const _BreakRow({required this.pattern, required this.denom});

  final BreakPattern pattern;
  final double denom;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(pattern.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.caption.copyWith(
                  fontSize: 11.5, color: AppColors.textTertiary)),
        ),
        const SizedBox(width: AppSpacing.s10),
        Expanded(
          child: HairlineBar(
            fraction: pattern.minutes / denom,
            color: pattern.interruption ? AppColors.red : AppColors.amber,
          ),
        ),
        const SizedBox(width: AppSpacing.s10),
        Text('${pattern.minutes}m',
            style: AppText.monoCaption
                .copyWith(fontSize: 11, color: AppColors.textTertiary)),
      ],
    );
  }
}

class _AccuracyCard extends StatelessWidget {
  const _AccuracyCard({required this.trends});

  final TrendsData trends;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _cardTitle('Estimate accuracy'),
                const SizedBox(height: AppSpacing.s2),
                Text('4-week trend',
                    style: AppText.caption.copyWith(fontSize: 11.5)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s10),
          AccuracyBars(values: trends.accuracyWeeks),
          const SizedBox(width: AppSpacing.s12),
          Text('${trends.accuracyPct}%',
              style: AppText.statValueSmall.copyWith(color: AppColors.green)),
        ],
      ),
    );
  }
}
