import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Mini bar chart: values 0..1, green alpha ramping up by recency.
class AccuracyBars extends StatelessWidget {
  const AccuracyBars({super.key, required this.values, this.height = 40});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < values.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Container(
              width: 14,
              height: height * values[i].clamp(0.0, 1.0),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(
                    alpha: 0.3 + 0.7 * (i / (values.length - 1))),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
