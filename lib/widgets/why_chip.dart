import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Roll-explanation chip: mono, green on green tint.
class WhyChip extends StatelessWidget {
  const WhyChip(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.greenTint,
        borderRadius: BorderRadius.circular(AppRadii.rBadge),
      ),
      child: Text(
        label,
        style: AppText.monoCaption
            .copyWith(fontSize: 11, color: AppColors.green),
      ),
    );
  }
}
