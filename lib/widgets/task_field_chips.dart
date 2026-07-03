import 'package:flutter/material.dart';

import '../models/task.dart';
import '../theme/app_tokens.dart';
import 'priority_dot.dart';

/// The est / tag / priority chip menus shared by the Plan composer and the
/// edit-task sheet, plus an optional "due today" toggle chip.
class TaskFieldChips extends StatelessWidget {
  const TaskFieldChips({
    super.key,
    required this.est,
    required this.tag,
    required this.priority,
    required this.onEst,
    required this.onTag,
    required this.onPriority,
    this.due,
    this.onDue,
  });

  static const estOptions = [5, 10, 15, 20, 25, 30, 45, 60, 90];
  static const tagOptions = [
    'Inbox', 'Deep work', 'Admin', 'Code', 'Creative', 'Errand',
  ];

  final int est;
  final String tag;
  final Priority priority;
  final ValueChanged<int> onEst;
  final ValueChanged<String> onTag;
  final ValueChanged<Priority> onPriority;

  /// When non-null, shows the "due today" toggle chip.
  final bool? due;
  final ValueChanged<bool>? onDue;

  Widget _chip(Widget label, {Color? background, Color? border}) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s10, vertical: AppSpacing.s6),
        decoration: BoxDecoration(
          color: background ?? AppColors.surfaceRaised,
          border: border != null ? Border.all(color: border) : null,
          borderRadius: BorderRadius.circular(AppRadii.rChip),
        ),
        child: label,
      );

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        PopupMenuButton<int>(
          onSelected: onEst,
          itemBuilder: (_) => [
            for (final m in estOptions)
              PopupMenuItem(value: m, height: 40, child: Text('${m}m')),
          ],
          child: _chip(Text('est ${est}m',
              style: AppText.chip.copyWith(
                  fontFamily: AppText.monoBody.fontFamily,
                  color: AppColors.textSecondary))),
        ),
        PopupMenuButton<String>(
          onSelected: onTag,
          itemBuilder: (_) => [
            for (final t in tagOptions)
              PopupMenuItem(value: t, height: 40, child: Text(t)),
          ],
          child: _chip(Text('$tag ▾',
              style: AppText.chip.copyWith(color: AppColors.textSecondary))),
        ),
        PopupMenuButton<Priority>(
          onSelected: onPriority,
          itemBuilder: (_) => [
            for (final p in Priority.values)
              PopupMenuItem(
                value: p,
                height: 40,
                child: Text('● ${p.label}',
                    style: TextStyle(color: priorityColor(p))),
              ),
          ],
          child: _chip(Text('● ${priority.label} ▾',
              style: AppText.chip.copyWith(color: priorityColor(priority)))),
        ),
        if (due != null)
          GestureDetector(
            onTap: () => onDue?.call(!due!),
            child: _chip(
              Text('due today',
                  style: AppText.chip.copyWith(
                      color:
                          due! ? AppColors.green : AppColors.textTertiary)),
              background: due! ? AppColors.greenTint : AppColors.surfaceRaised,
              border: due! ? AppColors.borderGreen : null,
            ),
          ),
      ],
    );
  }
}
