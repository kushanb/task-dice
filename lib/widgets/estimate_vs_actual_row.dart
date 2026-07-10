import 'package:flutter/widgets.dart';

import '../logic/scoring.dart';
import '../theme/app_tokens.dart';
import 'hairline_bar.dart';

/// One task's estimate-vs-actual comparison: title + `Nm / Nm`, then a faint
/// estimate bar over a green/red actual bar (design `EstimateVsActualRow`).
class EstimateVsActualRow extends StatelessWidget {
  const EstimateVsActualRow({
    super.key,
    required this.title,
    required this.estMin,
    required this.actualMin,
    required this.maxMin,
  });

  final String title;
  final int estMin;
  final int actualMin;

  /// Largest est/actual across the group, so bars share a scale.
  final int maxMin;

  @override
  Widget build(BuildContext context) {
    final over = isOverEstimate(actualMin: actualMin, estMin: estMin);
    final actualColor = over ? AppColors.red : AppColors.green;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.itemTitle.copyWith(fontSize: 12.5)),
            ),
            const SizedBox(width: AppSpacing.s8),
            Text('${actualMin}m / ${estMin}m',
                style: AppText.monoValue.copyWith(fontSize: 12, color: actualColor)),
          ],
        ),
        const SizedBox(height: 5),
        HairlineBar(
          fraction: estMin / maxMin,
          color: AppColors.barEstimate,
          height: 5,
          background: const Color(0x00000000),
        ),
        const SizedBox(height: 2),
        HairlineBar(
          fraction: actualMin / maxMin,
          color: actualColor,
          height: 5,
          background: const Color(0x00000000),
        ),
      ],
    );
  }
}
