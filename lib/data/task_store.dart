import '../models/game.dart';
import '../models/task.dart';

/// Everything loaded for a user in one round trip.
class StoredData {
  const StoredData({
    required this.tasks,
    required this.inbox,
    required this.rewards,
    required this.counters,
  });

  const StoredData.empty()
      : tasks = const [],
        inbox = const [],
        rewards = const [],
        counters = const StoredCounters();

  final List<Task> tasks;
  final List<InboxItem> inbox;
  final List<Reward> rewards;
  final StoredCounters counters;
}

/// The scalar day/score state that lives on the user document.
class StoredCounters {
  const StoredCounters({
    this.points = 0,
    this.pointsEarnedToday = 0,
    this.dayFocusBaseMin = 0,
    this.dayBreakBaseMin = 0,
    this.usedBreakBudgetBaseMin = 0,
    this.breakBudgetMin = 60,
  });

  /// Running total across all days — never reset by the day rollover.
  final int points;

  final int pointsEarnedToday;
  final int dayFocusBaseMin;
  final int dayBreakBaseMin;
  final int usedBreakBudgetBaseMin;
  final int breakBudgetMin;
}

/// Persistence boundary for [AppState].
///
/// Kept as an interface so AppState carries no Firebase import: with no store
/// it behaves exactly as it did before (in-memory, demo-seeded), which is what
/// the widget tests and an unconfigured `flutter run` rely on.
abstract interface class TaskStore {
  Future<StoredData> load();

  Future<void> saveTask(Task task);
  Future<void> deleteTask(Task task);

  Future<void> saveInboxItem(InboxItem item);
  Future<void> deleteInboxItem(InboxItem item);

  Future<void> saveReward(Reward reward);

  Future<void> saveCounters(StoredCounters counters);
}
