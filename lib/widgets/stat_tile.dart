import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Centered mono value over a faint label, in a hairline card (design `StatTile`).
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.value,
    required this.label,
    this.valueColor = AppColors.textPrimary,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline),
        borderRadius: BorderRadius.circular(AppRadii.rCard),
      ),
      child: Column(
        children: [
          Text(value, style: AppText.statValue.copyWith(color: valueColor)),
          const SizedBox(height: AppSpacing.s2),
          Text(label,
              textAlign: TextAlign.center,
              style: AppText.caption.copyWith(fontSize: 11)),
        ],
      ),
    );
  }
}
