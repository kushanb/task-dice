import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Row of intensity cells (green alpha ramp) showing focus across the day.
class FocusHeatmap extends StatelessWidget {
  const FocusHeatmap({super.key, required this.intensities});

  final List<double> intensities;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < intensities.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.heatmap(intensities[i]),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
