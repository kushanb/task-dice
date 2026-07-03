import 'package:flutter/material.dart';

import '../models/task.dart';
import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import 'app_toast.dart';
import 'press_scale.dart';
import 'task_field_chips.dart';

/// Bottom-sheet task editor (opened by tapping a task on Plan).
Future<void> showEditTaskSheet(BuildContext context, AppState state, Task task) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: _EditTaskForm(state: state, task: task),
    ),
  );
}

class _EditTaskForm extends StatefulWidget {
  const _EditTaskForm({required this.state, required this.task});

  final AppState state;
  final Task task;

  @override
  State<_EditTaskForm> createState() => _EditTaskFormState();
}

class _EditTaskFormState extends State<_EditTaskForm> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.task.title);
  late int _est = widget.task.estMin;
  late String _tag = widget.task.tag;
  late Priority _priority = widget.task.priority;
  late bool _due = widget.task.dueToday;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    widget.state.updateTask(
      widget.task,
      title: _controller.text,
      tag: _tag,
      estMin: _est,
      priority: _priority,
      dueToday: _due,
    );
    Navigator.of(context).pop();
    AppToast.show(context, 'Task updated');
  }

  void _delete() {
    widget.state.removeTask(widget.task);
    Navigator.of(context).pop();
    AppToast.show(context, 'Task deleted');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20, 0, AppSpacing.s20, AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Edit task', style: AppText.cardTitle),
            const SizedBox(height: AppSpacing.s14),
            TextField(
              controller: _controller,
              style: AppText.itemTitle,
              decoration: const InputDecoration(
                fillColor: AppColors.surfaceSunken,
                hintText: 'Task title',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.s14),
            TaskFieldChips(
              est: _est,
              tag: _tag,
              priority: _priority,
              due: _due,
              onEst: (v) => setState(() => _est = v),
              onTag: (v) => setState(() => _tag = v),
              onPriority: (v) => setState(() => _priority = v),
              onDue: (v) => setState(() => _due = v),
            ),
            const SizedBox(height: AppSpacing.s16),
            PressScale(
              onTap: _save,
              child: Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColors.green,
                  borderRadius: BorderRadius.circular(AppRadii.rButton),
                ),
                child: Center(
                  child: Text('Save changes',
                      style: AppText.button.copyWith(color: AppColors.onGreen)),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s10),
            PressScale(
              onTap: _delete,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s8),
                child: Center(
                  child: Text('Delete task',
                      style: AppText.chipBold.copyWith(color: AppColors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
