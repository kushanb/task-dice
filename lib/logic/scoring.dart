import 'dart:math';

import '../models/task.dart';

/// Scoring & weighting rules from the design prototype — see DESIGN.md §8.

int priorityWeight(Priority p) => switch (p) {
      Priority.low => 1,
      Priority.med => 2,
      Priority.high => 3,
    };

/// Smart-roll weight: 1 + priority + carried(+3) + due today(+2).
int smartWeight(Task t) =>
    1 + priorityWeight(t.priority) + (t.isCarried ? 3 : 0) + (t.dueToday ? 2 : 0);

/// Picks a task from [candidates]. Smart mode is weighted by [smartWeight];
/// otherwise uniform random. [random] is injectable for deterministic tests.
Task rollPick(List<Task> candidates, {required bool smart, Random? random}) {
  final rng = random ?? Random();
  if (!smart) return candidates[rng.nextInt(candidates.length)];
  final weights = candidates.map(smartWeight).toList();
  final total = weights.reduce((a, b) => a + b);
  var r = rng.nextDouble() * total;
  for (var i = 0; i < candidates.length; i++) {
    r -= weights[i];
    if (r <= 0) return candidates[i];
  }
  return candidates.last;
}

/// Points awarded on completion, by priority.
int completionPoints(Priority p) => switch (p) {
      Priority.low => 25,
      Priority.med => 50,
      Priority.high => 100,
    };

/// Bonus for landing within 15% of the estimate.
const estimateBonusPoints = 20;

bool earnsEstimateBonus({required int actualMin, required int estMin}) =>
    (actualMin - estMin).abs() / estMin <= 0.15;

/// The three weighted components of the efficiency score. Displayed on the
/// daily review as "33/40" etc.; the ring value is their sum.
class EfficiencyBreakdown {
  const EfficiencyBreakdown({
    required this.focus,
    required this.completion,
    required this.estimate,
  });

  final int focus; // 0..40
  final int completion; // 0..35
  final int estimate; // 0..25

  int get total => focus + completion + estimate;

  static const focusMax = 40;
  static const completionMax = 35;
  static const estimateMax = 25;
}

EfficiencyBreakdown efficiencyBreakdown(
    List<Task> tasks, int focusMin, int breakMin) {
  final focusRatio =
      focusMin + breakMin > 0 ? focusMin / (focusMin + breakMin) : 1.0;
  final done = tasks.where((t) => t.isDone).toList();
  final completionRate = tasks.isEmpty ? 0.0 : done.length / tasks.length;
  final accuracies = done
      .where((t) => t.actualMin != null)
      .map((t) => max(0.0, 1 - (t.actualMin! - t.estMin).abs() / t.estMin))
      .toList();
  final estimateAccuracy = accuracies.isEmpty
      ? 0.0
      : accuracies.reduce((a, b) => a + b) / accuracies.length;
  return EfficiencyBreakdown(
    focus: (EfficiencyBreakdown.focusMax * focusRatio).round(),
    completion: (EfficiencyBreakdown.completionMax * completionRate).round(),
    estimate: (EfficiencyBreakdown.estimateMax * estimateAccuracy).round(),
  );
}

/// Efficiency score 0–100 = 40·focusRatio + 35·completionRate + 25·estimateAccuracy.
int computeEfficiency(List<Task> tasks, int focusMin, int breakMin) =>
    efficiencyBreakdown(tasks, focusMin, breakMin).total;

/// Estimate is "over" (shown red on the review) when actual exceeds it by more
/// than the 15% bonus threshold; at or under reads green.
bool isOverEstimate({required int actualMin, required int estMin}) =>
    actualMin > estMin * 1.15;
