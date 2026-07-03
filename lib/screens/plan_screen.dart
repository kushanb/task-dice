import 'package:flutter/material.dart';

import '../logic/formats.dart';
import '../models/task.dart';
import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_toast.dart';
import '../widgets/edit_task_sheet.dart';
import '../widgets/press_scale.dart';
import '../widgets/section_label.dart';
import '../widgets/task_card.dart';
import '../widgets/task_field_chips.dart';

class PlanScreen extends StatelessWidget {
  const PlanScreen({super.key});

  /// Plan meta shows the carry-over priority bump: "High ↑ (was Med)".
  String _planMeta(Task t) => [
        t.tag,
        'est ${t.estMin}m',
        t.priority.label +
            (t.bumpedFrom != null ? ' ↑ (was ${t.bumpedFrom!.label})' : ''),
        if (t.dueToday) 'due today',
        if (t.isDone && t.actualMin != null) 'took ${t.actualMin}m',
      ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final carried =
        state.tasks.where((t) => t.status == TaskStatus.carried).toList();
    final planned =
        state.tasks.where((t) => t.status == TaskStatus.planned).toList();
    final done = state.tasks.where((t) => t.isDone).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20, AppSpacing.s12, AppSpacing.s20, AppSpacing.scrollBottom),
      children: [
        Text('Plan the day', style: AppText.pageTitle),
        const SizedBox(height: AppSpacing.s4),
        Text(
          '${weekdayShort(DateTime.now())} · ${planned.length} planned · '
          '${carried.length} carried in',
          style: AppText.body.copyWith(fontSize: 12.5, height: null),
        ),
        const SizedBox(height: AppSpacing.s14),
        const _AddTaskCard(),
        if (carried.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s16),
          const SectionLabel('Carried over — clear these first',
              color: AppColors.red),
          const SizedBox(height: AppSpacing.s12),
          for (final t in carried) ...[
            TaskCard(
                task: t,
                meta: _planMeta(t),
                onLongPress: () => showEditTaskSheet(context, state, t)),
            const SizedBox(height: AppSpacing.s12),
          ],
        ],
        if (planned.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          const SectionLabel('Planned today'),
          const SizedBox(height: AppSpacing.s12),
          for (final t in planned) ...[
            TaskCard(
                task: t,
                meta: _planMeta(t),
                onLongPress: () => showEditTaskSheet(context, state, t)),
            const SizedBox(height: AppSpacing.s12),
          ],
        ],
        if (done.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.s4),
          const SectionLabel('Done'),
          const SizedBox(height: AppSpacing.s12),
          for (final t in done) ...[
            TaskCard(task: t, meta: _planMeta(t)),
            const SizedBox(height: AppSpacing.s12),
          ],
        ],
      ],
    );
  }
}

/// Composer card: borderless input + est / tag / priority chip menus + Add.
class _AddTaskCard extends StatefulWidget {
  const _AddTaskCard();

  @override
  State<_AddTaskCard> createState() => _AddTaskCardState();
}

class _AddTaskCardState extends State<_AddTaskCard> {
  final _controller = TextEditingController();
  int _est = 25;
  String _tag = 'Inbox';
  Priority _priority = Priority.med;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    AppScope.of(context)
        .addTask(title, tag: _tag, estMin: _est, priority: _priority);
    _controller.clear();
    AppToast.show(context, 'Added to today');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16, vertical: AppSpacing.s14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderInput),
        borderRadius: BorderRadius.circular(AppRadii.rCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            style: AppText.itemTitle,
            decoration: const InputDecoration(
              isCollapsed: true,
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              hintText: 'Add a task…',
            ),
            onSubmitted: (_) => _add(),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TaskFieldChips(
                  est: _est,
                  tag: _tag,
                  priority: _priority,
                  onEst: (v) => setState(() => _est = v),
                  onTag: (v) => setState(() => _tag = v),
                  onPriority: (v) => setState(() => _priority = v),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              PressScale(
                onTap: _add,
                scale: 0.95,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.s14, vertical: AppSpacing.s6),
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(AppRadii.rChip),
                  ),
                  child: Text('Add',
                      style: AppText.button
                          .copyWith(fontSize: 12, color: AppColors.onGreen)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
