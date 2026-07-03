import 'package:flutter/widgets.dart';

import '../models/task.dart';
import '../theme/app_tokens.dart';
import 'carried_badge.dart';
import 'press_scale.dart';
import 'priority_dot.dart';

/// Task list tile. Carried variant gets the red debt treatment; done variant
/// is struck through and faint.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onLongPress,
    this.showChevron = false,
    this.meta,
  });

  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool showChevron;

  /// Overrides the default [Task.meta] line (Plan shows the priority bump).
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final carried = task.isCarried;
    final titleColor = carried
        ? AppColors.redSoftText
        : (task.isDone ? AppColors.textFaint : AppColors.textPrimary);

    return PressScale(
      onTap: onTap,
      onLongPress: onLongPress,
      scale: 0.98,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16, vertical: AppSpacing.s14),
        decoration: BoxDecoration(
          color: carried ? AppColors.redTint : AppColors.surface,
          border: Border.all(
              color: carried ? AppColors.borderRed : AppColors.borderHairline),
          borderRadius: BorderRadius.circular(AppRadii.rCard),
        ),
        child: Row(
          children: [
            PriorityDot(priority: task.priority),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.taskTitle.copyWith(
                      color: titleColor,
                      decoration:
                          task.isDone ? TextDecoration.lineThrough : null,
                      decorationColor: titleColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s2),
                  Text(meta ?? task.meta, style: AppText.meta),
                ],
              ),
            ),
            if (carried) ...[
              const SizedBox(width: AppSpacing.s12),
              CarriedBadge(count: task.carried),
            ],
            if (task.isDone) ...[
              const SizedBox(width: AppSpacing.s12),
              Text('✓',
                  style: AppText.monoValue
                      .copyWith(fontSize: 12, color: AppColors.green)),
            ],
            if (showChevron) ...[
              const SizedBox(width: AppSpacing.s12),
              Text('▶',
                  style: AppText.monoCaption
                      .copyWith(fontSize: 12, color: AppColors.textFaint)),
            ],
          ],
        ),
      ),
    );
  }
}
