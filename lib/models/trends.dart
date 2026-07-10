import '../logic/formats.dart';

class BreakPattern {
  const BreakPattern(this.label, this.minutes, {this.interruption = false});

  final String label;
  final int minutes;
  final bool interruption;
}

/// Aggregated history behind the Trends screen.
///
/// NOTE: the app has no historical store yet, so [TrendsData.demo] seeds a
/// representative week. A real backend (or on-device history log) would
/// populate this from past days. Flagged in DESIGN.md §9.
class TrendsData {
  const TrendsData({
    required this.weeklyEfficiency,
    required this.deltaVsLastWeek,
    required this.dayLabels,
    required this.heatmap,
    required this.peakWindow,
    required this.heatmapAxis,
    required this.breakPatterns,
    required this.accuracyWeeks,
    required this.accuracyPct,
  });

  /// One efficiency score (0–100) per day, oldest → newest.
  final List<int> weeklyEfficiency;
  final int deltaVsLastWeek;
  final List<String> dayLabels;

  /// 12 focus-intensity buckets across the day, 0..1.
  final List<double> heatmap;
  final String peakWindow;
  final List<String> heatmapAxis;

  final List<BreakPattern> breakPatterns;

  /// Estimate accuracy per week (0..1), oldest → newest.
  final List<double> accuracyWeeks;
  final int accuracyPct;

  factory TrendsData.demo() {
    final now = DateTime.now();
    return TrendsData(
      weeklyEfficiency: const [55, 61, 52, 70, 64, 78, 84],
      deltaVsLastWeek: 9,
      dayLabels: [
        for (var i = 6; i >= 0; i--)
          weekdayShort(now.subtract(Duration(days: i))),
      ],
      heatmap: const [
        .08, .25, .85, 1, .6, .2, .12, .35, .55, .3, .1, .05,
      ],
      peakWindow: '9–11am',
      heatmapAxis: const ['7a', '10a', '1p', '4p', '7p'],
      breakPatterns: const [
        BreakPattern('Messages', 54),
        BreakPattern('Snack', 33),
        BreakPattern('Bathroom', 22),
        BreakPattern('Interrupted', 18, interruption: true),
      ],
      accuracyWeeks: const [.45, .55, .62, .78],
      accuracyPct: 64,
    );
  }
}
