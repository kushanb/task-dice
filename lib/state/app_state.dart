import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

import '../data/task_store.dart';
import '../logic/scoring.dart';
import '../models/game.dart';
import '../models/task.dart';
import '../models/trends.dart';

enum BreakType {
  rest('Break'),
  interruption('Interruption');

  const BreakType(this.label);
  final String label;
}

class CompletedInfo {
  const CompletedInfo({required this.title, required this.summary, required this.note});

  final String title;
  final String summary;
  final String note;
}

/// Day-level app state + the focus-session state machine.
///
/// Timer model (from the design prototype):
///   elapsed = accumulated + (now − runningSince)   — total task time
///   sessionBreak = breakAccumulated + (now − breakSince)
///   focus = elapsed − sessionBreak
/// Breaks do NOT stop the task timer — the task keeps tracking.
class AppState extends ChangeNotifier {
  AppState({bool seedDemoData = true, TaskStore? store}) : _store = store {
    if (seedDemoData) _seedDemo();
  }

  /// Where mutations are mirrored to, or null to stay purely in memory.
  ///
  /// Writes are fire-and-forget: Firestore's local cache applies them
  /// immediately and queues the network round trip, so the UI never waits on
  /// one and an offline edit is not lost. [lastWriteError] records the last
  /// failure rather than throwing into a callback.
  final TaskStore? _store;

  Object? lastWriteError;

  final List<Task> tasks = [];
  final List<InboxItem> inbox = [];

  /// Seeded weekly history behind the Trends screen (see [TrendsData]).
  final TrendsData trends = TrendsData.demo();

  /// Gamification state behind the Progress screen (see [GameData]).
  final GameData game = GameData.demo();

  int points = 0;
  int pointsEarnedToday = 0;

  /// Minutes banked from earlier sessions today (before the current one).
  int dayFocusBaseMin = 0;
  int dayBreakBaseMin = 0;

  int breakBudgetMin = 60;

  /// Break-budget minutes already used before the current session.
  int usedBreakBudgetBaseMin = 0;

  // Focus-session state machine.
  int? activeTaskId;
  Duration _accum = Duration.zero;
  DateTime? runningSince;
  Duration _breakAccum = Duration.zero;
  DateTime? breakSince;

  CompletedInfo? completedInfo;

  /// Energy check-in prompt during focus. 18 s matches the design prototype
  /// (demo cadence — flagged as TBD in DESIGN.md §8).
  static const energyCheckInDelay = Duration(seconds: 18);
  bool energyPromptVisible = false;
  Timer? _energyTimer;

  Timer? _ticker;

  /// Live session updates from other devices; null when there is no store.
  StreamSubscription<StoredSession?>? _sessionSub;

  // ---- Derived state ----

  /// Null-safe on purpose: a restored session can name a task that was deleted
  /// on another device, and firstWhere would throw building the Focus screen.
  Task? get activeTask {
    final id = activeTaskId;
    if (id == null) return null;
    for (final task in tasks) {
      if (task.id == id) return task;
    }
    return null;
  }

  bool get isTracking => activeTaskId != null;
  bool get isRunning => runningSince != null;
  bool get onBreak => breakSince != null;

  Duration get elapsed => elapsedAt(DateTime.now());

  Duration get sessionBreak => sessionBreakAt(DateTime.now());

  Duration get sessionFocus {
    // One clock read for both halves. Taking `now` twice makes the subtraction
    // lose the microseconds between the reads, which is enough to round the
    // displayed minute down by one.
    final now = DateTime.now();
    final focus = elapsedAt(now) - sessionBreakAt(now);
    return focus.isNegative ? Duration.zero : focus;
  }

  /// Total task time as of [now] — banked time plus the run in progress.
  @visibleForTesting
  Duration elapsedAt(DateTime now) =>
      _accum +
      (runningSince != null ? now.difference(runningSince!) : Duration.zero);

  /// Break time as of [now], on the same basis as [elapsedAt].
  @visibleForTesting
  Duration sessionBreakAt(DateTime now) =>
      _breakAccum +
      (breakSince != null ? now.difference(breakSince!) : Duration.zero);

  int get efficiencyScore =>
      computeEfficiency(tasks, dayFocusBaseMin, dayBreakBaseMin);

  int get doneCount => tasks.where((t) => t.isDone).length;

  int get breakBudgetUsedMin =>
      usedBreakBudgetBaseMin + sessionBreak.inMinutes;

  /// Open tasks, carried-over pinned first (insertion order within groups).
  List<Task> get openTasks => [
        ...tasks.where((t) => t.status == TaskStatus.carried),
        ...tasks.where((t) => t.status == TaskStatus.planned),
      ];

  // ---- Session actions ----

  void startTask(int id) {
    activeTaskId = id;
    _accum = Duration.zero;
    runningSince = DateTime.now();
    _breakAccum = Duration.zero;
    breakSince = null;
    completedInfo = null;
    energyPromptVisible = false;
    _energyTimer?.cancel();
    _energyTimer = Timer(energyCheckInDelay, () {
      if (isTracking) {
        energyPromptVisible = true;
        notifyListeners();
      }
    });
    _startTicker();
    _persistSession();
    notifyListeners();
  }

  void logEnergy(int level) {
    energyPromptVisible = false;
    notifyListeners();
  }

  void togglePause() {
    if (runningSince != null) {
      _accum += DateTime.now().difference(runningSince!);
      runningSince = null;
    } else if (isTracking) {
      runningSince = DateTime.now();
    }
    _persistSession();
    notifyListeners();
  }

  void completeActiveTask() {
    final task = activeTask;
    if (task == null) return;
    final totalMin = max(1, (elapsed.inSeconds / 60).round());
    final breakMin = (sessionBreak.inSeconds / 60).round();
    final focusMin = max(0, totalMin - breakMin);

    final oldScore = efficiencyScore;
    task.status = TaskStatus.done;
    task.actualMin = totalMin;

    final bonus = earnsEstimateBonus(actualMin: totalMin, estMin: task.estMin)
        ? estimateBonusPoints
        : 0;
    final pts = focusMin + completionPoints(task.priority) + bonus;

    dayFocusBaseMin += focusMin;
    dayBreakBaseMin += breakMin;
    usedBreakBudgetBaseMin += breakMin;
    points += pts;
    pointsEarnedToday += pts;
    final newScore = efficiencyScore;

    completedInfo = CompletedInfo(
      title: task.title,
      summary: '+$pts pts · score $oldScore → $newScore',
      note:
          '${bonus > 0 ? 'Landed within 15% of your estimate — +$bonus bonus. ' : ''}'
          '${focusMin}m focused, ${breakMin}m on break.',
    );

    _resetSession();

    _write((store) => store.saveTask(task));
    _write((store) => store.saveCounters(_counters));
    _write((store) => store.clearSession());

    notifyListeners();
  }

  // ---- Breaks ----

  static const breakReasonOptions = [
    'Bathroom', 'Messages', 'Snack', 'Stretch', 'Someone came by',
  ];

  BreakType breakType = BreakType.rest;
  String? breakReason;

  void setBreakType(BreakType type) {
    breakType = type;
    _persistSession();
    notifyListeners();
  }

  void toggleBreakReason(String reason) {
    breakReason = breakReason == reason ? null : reason;
    _persistSession();
    notifyListeners();
  }

  void startBreak() {
    if (breakSince != null) return;
    breakSince = DateTime.now();
    _persistSession();
    notifyListeners();
  }

  void stopBreak() {
    if (breakSince == null) return;
    _breakAccum += DateTime.now().difference(breakSince!);
    breakSince = null;
    _persistSession();
    notifyListeners();
  }

  void addBreakMinutes(int minutes) {
    _breakAccum += Duration(minutes: minutes);
    _persistSession();
    notifyListeners();
  }

  // ---- Tasks & inbox ----

  void addTask(String title,
      {String tag = 'Inbox', int estMin = 25, Priority priority = Priority.med}) {
    final v = title.trim();
    if (v.isEmpty) return;
    final task = Task(
      id: _nextId(),
      title: v,
      tag: tag,
      priority: priority,
      estMin: estMin,
    );
    tasks.add(task);
    _write((store) => store.saveTask(task));
    notifyListeners();
  }

  void updateTask(
    Task task, {
    String? title,
    String? tag,
    int? estMin,
    Priority? priority,
    bool? dueToday,
  }) {
    if (title != null && title.trim().isNotEmpty) task.title = title.trim();
    if (tag != null) task.tag = tag;
    if (estMin != null) task.estMin = estMin;
    if (priority != null && priority != task.priority) {
      task.priority = priority;
      task.bumpedFrom = null; // manual choice overrides the carry-over bump
    }
    if (dueToday != null) task.dueToday = dueToday;
    _write((store) => store.saveTask(task));
    notifyListeners();
  }

  void removeTask(Task task) {
    if (activeTaskId == task.id) {
      _resetSession();
      _write((store) => store.clearSession());
    }
    tasks.remove(task);
    _write((store) => store.deleteTask(task));
    notifyListeners();
  }

  // ---- Rewards ----

  void claimReward(Reward reward) {
    reward.claimed = true;
    _write((store) => store.saveReward(reward));
    notifyListeners();
  }

  void addReward(String title, int targetPoints) {
    final v = title.trim();
    if (v.isEmpty) return;
    final reward = Reward(
      title: v,
      detail: '0 / $targetPoints pts',
      fraction: 0,
    );
    game.rewards.add(reward);
    _write((store) => store.saveReward(reward));
    notifyListeners();
  }

  void addToInbox(String text) {
    final v = text.trim();
    if (v.isEmpty) return;
    final item =
        InboxItem(text: v, capturedAt: DateTime.now(), midFocus: isTracking);
    inbox.insert(0, item);
    _write((store) => store.saveInboxItem(item));
    notifyListeners();
  }

  void removeFromInbox(InboxItem item) {
    inbox.remove(item);
    _write((store) => store.deleteInboxItem(item));
    notifyListeners();
  }

  void promoteToToday(InboxItem item) {
    // Goes through removeFromInbox so the item is deleted from the store too,
    // not just from the list.
    removeFromInbox(item);
    addTask(item.text, estMin: 15);
  }

  // ---- Persistence ----

  /// Replaces in-memory state with what came back from the store.
  ///
  /// Rewards are only taken when the account has some, so a new user keeps the
  /// designed placeholder set rather than landing on an empty Progress screen —
  /// see [GameData.demo].
  void applyStored(StoredData data) {
    tasks
      ..clear()
      ..addAll(data.tasks);
    inbox
      ..clear()
      ..addAll(data.inbox);

    if (data.rewards.isNotEmpty) {
      game.rewards
        ..clear()
        ..addAll(data.rewards);
    }

    points = data.counters.points;
    pointsEarnedToday = data.counters.pointsEarnedToday;
    dayFocusBaseMin = data.counters.dayFocusBaseMin;
    dayBreakBaseMin = data.counters.dayBreakBaseMin;
    usedBreakBudgetBaseMin = data.counters.usedBreakBudgetBaseMin;
    breakBudgetMin = data.counters.breakBudgetMin;

    _restoreSession(data.session);

    notifyListeners();
  }

  /// Starts mirroring session changes from other devices.
  ///
  /// Separate from [applyStored] so the initial load settles first: subscribing
  /// mid-load could apply a session before its task list exists.
  void startSessionSync() {
    final store = _store;
    if (store == null) return;
    _sessionSub?.cancel();
    _sessionSub = store.watchSession().listen(
      (session) {
        _restoreSession(session);
        notifyListeners();
      },
      onError: (Object error) {
        lastWriteError = error;
        debugPrint('TaskDice: session sync failed — $error');
      },
    );
  }

  /// Adopts a stored session, from the initial load or from another device.
  ///
  /// Elapsed time needs no adjustment: [elapsed] and [sessionBreak] derive it
  /// from [runningSince]/[breakSince] against the current clock, so time that
  /// passed while this device was closed is already accounted for.
  void _restoreSession(StoredSession? session) {
    if (session == null) {
      if (activeTaskId != null) _resetSession();
      return;
    }

    // A session for a task this device does not have is not restorable —
    // the task was deleted elsewhere, or has not synced yet.
    final exists = tasks.any((t) => t.id == session.activeTaskId);
    if (!exists) {
      if (activeTaskId != null) _resetSession();
      return;
    }

    activeTaskId = session.activeTaskId;
    _accum = session.accum;
    runningSince = session.runningSince;
    _breakAccum = session.breakAccum;
    breakSince = session.breakSince;
    breakType = BreakType.values
            .where((t) => t.name == session.breakType)
            .firstOrNull ??
        BreakType.rest;
    breakReason = session.breakReason;
    _startTicker();
  }

  /// Clears the in-memory session. Does not touch the store — callers decide
  /// whether this is a local end (write a clear) or an echo of one.
  void _resetSession() {
    activeTaskId = null;
    _accum = Duration.zero;
    runningSince = null;
    _breakAccum = Duration.zero;
    breakSince = null;
    energyPromptVisible = false;
    _energyTimer?.cancel();
    _stopTicker();
  }

  /// Mirrors the live session out. Called on transitions only — never from the
  /// display ticker, which would mean a Firestore write every second.
  void _persistSession() {
    final id = activeTaskId;
    if (id == null) return;
    _write((store) => store.saveSession(StoredSession(
          activeTaskId: id,
          accum: _accum,
          runningSince: runningSince,
          breakAccum: _breakAccum,
          breakSince: breakSince,
          breakType: breakType.name,
          breakReason: breakReason,
        )));
  }

  StoredCounters get _counters => StoredCounters(
        points: points,
        pointsEarnedToday: pointsEarnedToday,
        dayFocusBaseMin: dayFocusBaseMin,
        dayBreakBaseMin: dayBreakBaseMin,
        usedBreakBudgetBaseMin: usedBreakBudgetBaseMin,
        breakBudgetMin: breakBudgetMin,
      );

  /// Runs a write without blocking the caller, recording any failure.
  void _write(Future<void> Function(TaskStore store) action) {
    final store = _store;
    if (store == null) return;
    action(store).catchError((Object error) {
      lastWriteError = error;
      debugPrint('TaskDice: write failed — $error');
    });
  }

  // ---- Internals ----

  int _nextId() =>
      tasks.fold<int>(0, (m, t) => max(m, t.id)) + 1;

  void _startTicker() {
    _ticker ??=
        Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  void dispose() {
    _energyTimer?.cancel();
    _sessionSub?.cancel();
    _stopTicker();
    super.dispose();
  }

  /// Demo dataset matching the design handoff, so screens review true to spec.
  /// Remove for a real, empty first-run day.
  void _seedDemo() {
    tasks.addAll([
      Task(
          id: 1,
          title: 'Finish quarterly report draft',
          tag: 'Deep work',
          priority: Priority.high,
          estMin: 60,
          status: TaskStatus.carried,
          carried: 2,
          dueToday: true,
          bumpedFrom: Priority.med),
      Task(
          id: 2,
          title: "Reply to Anna's email",
          tag: 'Admin',
          priority: Priority.med,
          estMin: 15,
          status: TaskStatus.done,
          actualMin: 12),
      Task(
          id: 3,
          title: 'Review PR #142',
          tag: 'Code',
          priority: Priority.med,
          estMin: 25,
          status: TaskStatus.done,
          actualMin: 41),
      Task(
          id: 4,
          title: 'Outline blog post',
          tag: 'Creative',
          priority: Priority.med,
          estMin: 30),
      Task(
          id: 5,
          title: 'Book dentist appointment',
          tag: 'Errand',
          priority: Priority.low,
          estMin: 5),
      Task(
          id: 6,
          title: 'Clear inbox to zero',
          tag: 'Admin',
          priority: Priority.low,
          estMin: 20),
    ]);
    inbox.addAll([
      InboxItem(
          text: 'Idea: color-code tags by energy needed',
          capturedAt: DateTime.now().subtract(const Duration(hours: 1)),
          midFocus: true),
      InboxItem(
          text: 'Ask Sam about the Friday demo',
          capturedAt: DateTime.now().subtract(const Duration(hours: 4))),
    ]);
    points = 231;
    pointsEarnedToday = 181;
    dayFocusBaseMin = 96;
    dayBreakBaseMin = 24;
    usedBreakBudgetBaseMin = 24;
  }
}

/// Exposes [AppState] to the widget tree; rebuilds dependents on notify.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child})
      : super(notifier: state);

  static AppState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
