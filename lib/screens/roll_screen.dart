import 'dart:async';

import 'package:flutter/widgets.dart';

import '../logic/scoring.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import '../widgets/dice_tile.dart';
import '../widgets/pop_in.dart';
import '../widgets/press_scale.dart';
import '../widgets/segmented_toggle.dart';
import '../widgets/why_chip.dart';

/// Roll (task randomizer). Smart mode weights by priority/carried/due; the die
/// shakes and cycles candidate names for ~1.45 s before landing.
class RollScreen extends StatefulWidget {
  const RollScreen({super.key, this.onStart});

  /// Called after "Start now" begins tracking (shell → Focus mode).
  final VoidCallback? onStart;

  @override
  State<RollScreen> createState() => _RollScreenState();
}

class _RollScreenState extends State<RollScreen> {
  bool _smart = true;
  bool _rolling = false;
  String _rollName = '';
  int? _resultId;

  Timer? _cycleTimer;
  Timer? _landTimer;

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _landTimer?.cancel();
    super.dispose();
  }

  List<Task> _candidates(AppState state) => state.tasks
      .where((t) => t.status == TaskStatus.planned || t.isCarried)
      .toList();

  void _roll(AppState state) {
    final candidates = _candidates(state);
    if (candidates.isEmpty || _rolling) return;

    _cycleTimer?.cancel();
    _landTimer?.cancel();
    setState(() {
      _rolling = true;
      _resultId = null;
      _rollName = candidates.first.title;
    });

    var i = 0;
    _cycleTimer = Timer.periodic(AppMotion.rollNameCycle, (_) {
      i++;
      setState(() => _rollName = candidates[i % candidates.length].title);
    });

    _landTimer = Timer(AppMotion.rollDuration, () {
      _cycleTimer?.cancel();
      final pick = rollPick(candidates, smart: _smart);
      setState(() {
        _rolling = false;
        _rollName = '';
        _resultId = pick.id;
      });
    });
  }

  List<String> _whyChips(AppState state, Task result) {
    if (!_smart) return const ['True random — pure luck'];
    return [
      '${result.priority.label} priority',
      if (result.isCarried) 'Carried ×${result.carried}',
      if (result.dueToday) 'Due today',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final result =
        _resultId == null ? null : state.tasks.firstWhere((t) => t.id == _resultId);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Roll', style: AppText.pageTitle),
          ),
          const SizedBox(height: AppSpacing.s14),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: SegmentedToggle<bool>(
              values: const [true, false],
              selected: _smart,
              onChanged: (v) => setState(() => _smart = v),
              labelOf: (v) => v ? 'Smart (weighted)' : 'True random',
              activeBgOf: (_) => AppColors.green,
              activeFgOf: (_) => AppColors.onGreen,
              background: AppColors.surface,
              border: AppColors.borderInput,
              segmentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16, vertical: AppSpacing.s8),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DiceTile(rolling: _rolling, onTap: () => _roll(state)),
                const SizedBox(height: AppSpacing.s20),
                if (_rolling)
                  SizedBox(
                    height: 22,
                    child: Text(_rollName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.monoBody
                            .copyWith(color: AppColors.textTertiary)),
                  )
                else if (result != null)
                  _ResultCard(
                    result: result,
                    chips: _whyChips(state, result),
                    weightLine: _smart
                        ? _weightLine(state, result)
                        : null,
                    onReroll: () => _roll(state),
                    onStart: () {
                      state.startTask(result.id);
                      widget.onStart?.call();
                    },
                  )
                else
                  Text('Tap the die — let it decide.',
                      style: AppText.body.copyWith(height: null)),
              ],
            ),
          ),
          if (_smart)
            Text(
              'Smart weight = 1 + priority + carried(+3) + due today(+2)',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
        ],
      ),
    );
  }

  String _weightLine(AppState state, Task result) {
    final total =
        _candidates(state).fold<int>(0, (sum, t) => sum + smartWeight(t));
    final w = smartWeight(result);
    final pct = (w / total * 100).round();
    return 'Weight $w of $total → $pct% chance';
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.result,
    required this.chips,
    required this.weightLine,
    required this.onReroll,
    required this.onStart,
  });

  final Task result;
  final List<String> chips;
  final String? weightLine;
  final VoidCallback onReroll;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return PopIn(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.s18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderGreen),
          borderRadius: BorderRadius.circular(AppRadii.rCardProminent),
        ),
        child: Column(
          children: [
            Text('THE DICE SAY',
                style: AppText.overline.copyWith(fontSize: 11)),
            const SizedBox(height: AppSpacing.s6),
            Text(result.title,
                textAlign: TextAlign.center,
                style: AppText.cardTitle.copyWith(fontSize: 18)),
            const SizedBox(height: AppSpacing.s10),
            Wrap(
              spacing: AppSpacing.s6,
              runSpacing: AppSpacing.s6,
              alignment: WrapAlignment.center,
              children: [for (final c in chips) WhyChip(c)],
            ),
            if (weightLine != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(weightLine!, style: AppText.caption),
            ],
            const SizedBox(height: AppSpacing.s14),
            Row(
              children: [
                Expanded(
                  child: PressScale(
                    onTap: onReroll,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.s12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(AppRadii.rButton),
                      ),
                      child: Text('Re-roll',
                          textAlign: TextAlign.center,
                          style: AppText.buttonSecondary.copyWith(fontSize: 13)),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s10),
                Expanded(
                  child: PressScale(
                    onTap: onStart,
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.s12),
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(AppRadii.rButton),
                      ),
                      child: Text('Start now',
                          textAlign: TextAlign.center,
                          style: AppText.button
                              .copyWith(fontSize: 13, color: AppColors.onGreen)),
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
