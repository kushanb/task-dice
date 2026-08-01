import 'package:flutter/material.dart';

import '../shell/account_info.dart';
import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_toast.dart';
import '../widgets/badge_tile.dart';
import '../widgets/level_card.dart';
import '../widgets/press_scale.dart';
import '../widgets/reward_card.dart';
import '../widgets/section_label.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, this.account});

  /// Null on a local-only build, where there is nothing to sign out of.
  final AccountInfo? account;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final game = state.game;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20, AppSpacing.s12, AppSpacing.s20, AppSpacing.scrollBottom),
      children: [
        Text('Progress', style: AppText.pageTitle),
        const SizedBox(height: AppSpacing.s14),
        LevelCard(game: game),
        const SizedBox(height: AppSpacing.s16),
        const SectionLabel('Recent badges'),
        const SizedBox(height: AppSpacing.s12),
        Row(
          children: [
            for (var i = 0; i < game.badges.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.s10),
              Expanded(child: BadgeTile(badge: game.badges[i])),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.s16),
        const SectionLabel('My rewards'),
        const SizedBox(height: AppSpacing.s12),
        for (final reward in game.rewards) ...[
          RewardCard(
            reward: reward,
            onClaim: () {
              state.claimReward(reward);
              AppToast.show(context, 'Reward claimed 🎉');
            },
          ),
          const SizedBox(height: AppSpacing.s12),
        ],
        PressScale(
          onTap: () => _showAddReward(context, state),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s8),
            child: Text('+ Add a reward',
                textAlign: TextAlign.center,
                style: AppText.itemTitle
                    .copyWith(fontSize: 13, color: AppColors.textTertiary)),
          ),
        ),
        if (account case final account?) ...[
          const SizedBox(height: AppSpacing.s24),
          const SectionLabel('Account'),
          const SizedBox(height: AppSpacing.s12),
          _AccountRow(account: account),
        ],
      ],
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({required this.account});

  final AccountInfo account;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline),
        borderRadius: BorderRadius.circular(AppRadii.rCard),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              account.email ?? 'Signed in',
              style: AppText.itemTitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          PressScale(
            onTap: account.onSignOut,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s14, vertical: AppSpacing.s8),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.borderStrong),
                borderRadius: BorderRadius.circular(AppRadii.rButton),
              ),
              child: Text('Sign out', style: AppText.buttonSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _showAddReward(BuildContext context, AppState state) {
  final titleCtl = TextEditingController();
  final ptsCtl = TextEditingController(text: '500');

  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Add a reward'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: titleCtl,
            autofocus: true,
            style: AppText.itemTitle,
            decoration: const InputDecoration(hintText: 'Reward name'),
          ),
          const SizedBox(height: AppSpacing.s12),
          TextField(
            controller: ptsCtl,
            keyboardType: TextInputType.number,
            style: AppText.itemTitle,
            decoration: const InputDecoration(hintText: 'Points target'),
          ),
        ],
      ),
      actions: [
        PressScale(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s10),
            child: Text('Cancel', style: AppText.buttonSecondary),
          ),
        ),
        PressScale(
          onTap: () {
            final title = titleCtl.text.trim();
            if (title.isEmpty) return;
            state.addReward(title, int.tryParse(ptsCtl.text.trim()) ?? 500);
            Navigator.of(dialogContext).pop();
            AppToast.show(context, 'Reward added');
          },
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16, vertical: AppSpacing.s10),
            decoration: BoxDecoration(
              color: AppColors.green,
              borderRadius: BorderRadius.circular(AppRadii.rButton),
            ),
            child: Text('Add',
                style: AppText.button.copyWith(color: AppColors.onGreen)),
          ),
        ),
      ],
    ),
  );
}
