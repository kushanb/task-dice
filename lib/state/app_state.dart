import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';

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
  AppState({bool seedDemoData = true}) {
    if (seedDemoData) _seedDemo();
  }

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

  // ---- Derived state ----

  Task? get activeTask =>
      activeTaskId == null ? null : tasks.firstWhere((t) => t.id == activeTaskId);

  bool get isTracking => activeTaskId != null;
  bool get isRunning => runningSince != null;
  bool get onBreak => breakSince != null;

  Duration get elapsed =>
      _accum +
      (runningSince != null ? DateTime.now().difference(runningSince!) : Duration.zero);

  Duration get sessionBreak =>
      _breakAccum +
      (breakSince != null ? DateTime.now().difference(breakSince!) : Duration.zero);

  Duration get sessionFocus {
    final f = elapsed - sessionBreak;
    return f.isNegative ? Duration.zero : f;
  }

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

    activeTaskId = null;
    _accum = Duration.zero;
    runningSince = null;
    _breakAccum = Duration.zero;
    breakSince = null;
    energyPromptVisible = false;
    _energyTimer?.cancel();
    _stopTicker();
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
    notifyListeners();
  }

  void toggleBreakReason(String reason) {
    breakReason = breakReason == reason ? null : reason;
    notifyListeners();
  }

  void startBreak() {
    if (breakSince != null) return;
    breakSince = DateTime.now();
    notifyListeners();
  }

  void stopBreak() {
    if (breakSince == null) return;
    _breakAccum += DateTime.now().difference(breakSince!);
    breakSince = null;
    notifyListeners();
  }

  void addBreakMinutes(int minutes) {
    _breakAccum += Duration(minutes: minutes);
    notifyListeners();
  }

  // ---- Tasks & inbox ----

  void addTask(String title,
      {String tag = 'Inbox', int estMin = 25, Priority priority = Priority.med}) {
    final v = title.trim();
    if (v.isEmpty) return;
    tasks.add(Task(
      id: _nextId(),
      title: v,
      tag: tag,
      priority: priority,
      estMin: estMin,
    ));
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
    notifyListeners();
  }

  void removeTask(Task task) {
    if (activeTaskId == task.id) {
      activeTaskId = null;
      _accum = Duration.zero;
      runningSince = null;
      _breakAccum = Duration.zero;
      breakSince = null;
      energyPromptVisible = false;
      _energyTimer?.cancel();
      _stopTicker();
    }
    tasks.remove(task);
    notifyListeners();
  }

  // ---- Rewards ----

  void claimReward(Reward reward) {
    reward.claimed = true;
    notifyListeners();
  }

  void addReward(String title, int targetPoints) {
    final v = title.trim();
    if (v.isEmpty) return;
    game.rewards.add(Reward(
      title: v,
      detail: '0 / $targetPoints pts',
      fraction: 0,
    ));
    notifyListeners();
  }

  void addToInbox(String text) {
    final v = text.trim();
    if (v.isEmpty) return;
    inbox.insert(
        0, InboxItem(text: v, capturedAt: DateTime.now(), midFocus: isTracking));
    notifyListeners();
  }

  void removeFromInbox(InboxItem item) {
    inbox.remove(item);
    notifyListeners();
  }

  void promoteToToday(InboxItem item) {
    inbox.remove(item);
    addTask(item.text, estMin: 15);
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
