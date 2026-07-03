enum Priority {
  low('Low'),
  med('Med'),
  high('High');

  const Priority(this.label);
  final String label;
}

enum TaskStatus { planned, carried, done }

class Task {
  Task({
    required this.id,
    required this.title,
    required this.tag,
    required this.priority,
    required this.estMin,
    this.status = TaskStatus.planned,
    this.carried = 0,
    this.dueToday = false,
    this.actualMin,
    this.bumpedFrom,
  });

  final int id;
  String title;
  String tag;
  Priority priority;
  int estMin;
  TaskStatus status;
  int carried;
  bool dueToday;
  int? actualMin;

  /// Priority before the carry-over bump ("High ↑ (was Med)" on Plan).
  Priority? bumpedFrom;

  bool get isCarried => status == TaskStatus.carried;
  bool get isDone => status == TaskStatus.done;
  bool get isOpen => !isDone;

  /// Metadata line: "Deep work · est 60m · High · due today · took 41m"
  String get meta => [
        tag,
        'est ${estMin}m',
        priority.label,
        if (dueToday) 'due today',
        if (isDone && actualMin != null) 'took ${actualMin}m',
      ].join(' · ');
}

class InboxItem {
  InboxItem({required this.text, required this.capturedAt, this.midFocus = false});

  final String text;
  final DateTime capturedAt;

  /// Captured while a task was tracking ("mid-focus" stamp in the inbox).
  final bool midFocus;
}
