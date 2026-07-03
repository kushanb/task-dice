import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// "carried ×N" debt badge.
class CarriedBadge extends StatelessWidget {
  const CarriedBadge({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.redBadgeTint,
        borderRadius: BorderRadius.circular(AppRadii.rBadge),
      ),
      child: Text(
        'carried ×$count',
        style: AppText.monoCaption.copyWith(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: AppColors.red,
        ),
      ),
    );
  }
}
