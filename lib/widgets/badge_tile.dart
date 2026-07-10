import 'package:flutter/widgets.dart';

import '../models/game.dart' as models;
import '../theme/app_tokens.dart';

/// One badge tile; locked badges render at 45% opacity (design `BadgeTile`).
class BadgeTile extends StatelessWidget {
  const BadgeTile({super.key, required this.badge});

  final models.Badge badge;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: badge.unlocked ? 1 : 0.45,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderHairline),
          borderRadius: BorderRadius.circular(AppRadii.rCardSmall),
        ),
        child: Column(
          children: [
            Text(badge.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: AppSpacing.s4),
            Text(badge.name,
                textAlign: TextAlign.center,
                style: AppText.chipBold
                    .copyWith(fontSize: 10.5, color: AppColors.textSecondary)),
            Text(badge.requirement,
                textAlign: TextAlign.center,
                style: AppText.micro.copyWith(fontSize: 9.5)),
          ],
        ),
      ),
    );
  }
}
