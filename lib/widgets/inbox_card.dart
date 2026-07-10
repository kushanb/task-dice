import 'package:flutter/widgets.dart';

import '../logic/formats.dart';
import '../models/task.dart';
import '../theme/app_tokens.dart';
import 'press_scale.dart';

/// A captured thought with triage actions (design `InboxCard`).
class InboxCard extends StatelessWidget {
  const InboxCard({
    super.key,
    required this.item,
    required this.onToday,
    required this.onLater,
    required this.onDelete,
  });

  final InboxItem item;
  final VoidCallback onToday;
  final VoidCallback onLater;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderHairline),
        borderRadius: BorderRadius.circular(AppRadii.rCardSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.text, style: AppText.itemTitle),
          const SizedBox(height: 3),
          Text(capturedLabel(item.capturedAt, midFocus: item.midFocus),
              style: AppText.monoCaption
                  .copyWith(fontSize: 11, color: AppColors.textFaint)),
          const SizedBox(height: AppSpacing.s10),
          Row(
            children: [
              _Action(
                label: '→ Today',
                color: AppColors.green,
                background: AppColors.greenTint,
                onTap: onToday,
              ),
              const SizedBox(width: AppSpacing.s8),
              _Action(
                label: 'Later',
                color: AppColors.textTertiary,
                background: AppColors.surfaceRaised,
                onTap: onLater,
              ),
              const SizedBox(width: AppSpacing.s8),
              _Action(
                label: 'Delete',
                color: AppColors.textFaint,
                onTap: onDelete,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({
    required this.label,
    required this.color,
    required this.onTap,
    this.background,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      scale: 0.95,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s12, vertical: AppSpacing.s6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(AppRadii.rChip),
        ),
        child: Text(label,
            style: AppText.chipBold.copyWith(fontSize: 11.5, color: color)),
      ),
    );
  }
}
