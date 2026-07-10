import 'package:flutter/widgets.dart';

import '../models/game.dart';
import '../theme/app_tokens.dart';
import 'hairline_bar.dart';
import 'press_scale.dart';

/// Reward row. Reached-but-unclaimed shows a green Claim button; in-progress
/// shows a green bar; claimed reads faint (design `RewardCard`).
class RewardCard extends StatelessWidget {
  const RewardCard({super.key, required this.reward, required this.onClaim});

  final Reward reward;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final claimable = reward.reached && !reward.claimed;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: claimable ? AppColors.green.withValues(alpha: .09) : AppColors.surface,
        border: Border.all(
            color: claimable ? AppColors.borderGreen : AppColors.borderHairline),
        borderRadius: BorderRadius.circular(AppRadii.rCard),
      ),
      child: reward.claimed
          ? _claimedRow()
          : claimable
              ? _claimableRow()
              : _progressRows(),
    );
  }

  Widget _claimedRow() => Row(
        children: [
          Expanded(
            child: Text(reward.title,
                style: AppText.taskTitle.copyWith(color: AppColors.textFaint)),
          ),
          Text('Claimed ✓',
              style: AppText.chipBold.copyWith(color: AppColors.textFaint)),
        ],
      );

  Widget _claimableRow() => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward.title, style: AppText.taskTitle),
                const SizedBox(height: AppSpacing.s2),
                Text(reward.detail,
                    style: AppText.caption.copyWith(
                        fontSize: 11.5, color: AppColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          PressScale(
            onTap: onClaim,
            scale: 0.95,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(AppRadii.rInput),
              ),
              child: Text('Claim 🎉',
                  style: AppText.chipBold
                      .copyWith(fontSize: 12.5, color: AppColors.onGreen)),
            ),
          ),
        ],
      );

  Widget _progressRows() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text(reward.title, style: AppText.taskTitle)),
              const SizedBox(width: AppSpacing.s8),
              Text(reward.detail,
                  style: AppText.monoCaption
                      .copyWith(fontSize: 11.5, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: AppSpacing.s10),
          HairlineBar(fraction: reward.fraction, color: AppColors.green),
        ],
      );
}
