import '../models/game.dart';
import '../models/task.dart';

/// Everything loaded for a user in one round trip.
class StoredData {
  const StoredData({
    required this.tasks,
    required this.inbox,
    required this.rewards,
    required this.counters,
    this.session,
  });

  const StoredData.empty()
      : tasks = const [],
        inbox = const [],
        rewards = const [],
        counters = const StoredCounters(),
        session = null;

  final List<Task> tasks;
  final List<InboxItem> inbox;
  final List<Reward> rewards;
  final StoredCounters counters;

  /// The focus session that was in progress, or null if nothing was tracking.
  final StoredSession? session;
}

/// A focus session in progress.
///
/// Stored as *instants and accumulated totals*, never as a running count: the
/// elapsed time is always recomputed from the clock at the moment it is read.
/// That is what lets a session survive a page refresh and be picked up on
/// another device — the seconds that passed while nothing was watching are
/// still counted, because they were never being counted by a ticker to begin
/// with. See the timer model on [AppState].
class StoredSession {
  const StoredSession({
    required this.activeTaskId,
    this.accum = Duration.zero,
    this.runningSince,
    this.breakAccum = Duration.zero,
    this.breakSince,
    this.breakType,
    this.breakReason,
  });

  /// Task being tracked.
  final int activeTaskId;

  /// Task time banked before the current run — grows each time you pause.
  final Duration accum;

  /// When the current run began, or null while paused.
  final DateTime? runningSince;

  /// Break time banked before the current break.
  final Duration breakAccum;

  /// When the current break began, or null when not on a break.
  final DateTime? breakSince;

  /// Enum *name* rather than the enum: the data layer stays free of state-layer
  /// imports, and an unrecognised value from a newer build degrades to null.
  final String? breakType;

  final String? breakReason;
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

  /// Records the session in progress. Called on transitions only — start,
  /// pause, resume, break — never on the one-second display tick.
  Future<void> saveSession(StoredSession session);

  /// Removes the stored session, on completion or when the task goes away.
  Future<void> clearSession();

  /// Session changes made anywhere, including on this device.
  ///
  /// This is what makes a timer started on the phone appear on the laptop
  /// without a reload. Emits null when no session is in progress.
  Stream<StoredSession?> watchSession();
}
