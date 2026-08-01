import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:taskdice/data/task_store.dart';
import 'package:taskdice/models/game.dart';
import 'package:taskdice/models/task.dart';
import 'package:taskdice/state/app_state.dart';

/// Records what AppState asked to persist, so the write-through wiring can be
/// checked without a Firebase project.
class RecordingStore implements TaskStore {
  RecordingStore({this.data = const StoredData.empty()});

  StoredData data;
  final List<String> calls = [];

  @override
  Future<StoredData> load() async => data;

  @override
  Future<void> saveTask(Task task) async => calls.add('saveTask:${task.title}');

  @override
  Future<void> deleteTask(Task task) async =>
      calls.add('deleteTask:${task.title}');

  @override
  Future<void> saveInboxItem(InboxItem item) async =>
      calls.add('saveInbox:${item.text}');

  @override
  Future<void> deleteInboxItem(InboxItem item) async =>
      calls.add('deleteInbox:${item.text}');

  @override
  Future<void> saveReward(Reward reward) async =>
      calls.add('saveReward:${reward.title}');

  @override
  Future<void> saveCounters(StoredCounters counters) async =>
      calls.add('saveCounters:${counters.points}');

  /// Last session written, so tests can assert on what was stored rather than
  /// only that a write happened.
  StoredSession? savedSession;

  final StreamController<StoredSession?> sessions =
      StreamController<StoredSession?>.broadcast();

  @override
  Future<void> saveSession(StoredSession session) async {
    savedSession = session;
    calls.add('saveSession:${session.activeTaskId}');
  }

  @override
  Future<void> clearSession() async {
    savedSession = null;
    calls.add('clearSession');
  }

  @override
  Stream<StoredSession?> watchSession() => sessions.stream;
}

AppState emptyState(TaskStore store) =>
    AppState(seedDemoData: false, store: store);

void main() {
  test('with no store, nothing is persisted and behaviour is unchanged', () {
    final state = AppState(seedDemoData: false);
    state.addTask('Write the thing');

    expect(state.tasks.single.title, 'Write the thing');
  });

  test('adding, editing and removing a task writes through', () {
    final store = RecordingStore();
    final state = emptyState(store);

    state.addTask('Write the thing');
    final task = state.tasks.single;
    state.updateTask(task, title: 'Write it well');
    state.removeTask(task);

    expect(store.calls, [
      'saveTask:Write the thing',
      'saveTask:Write it well',
      'deleteTask:Write it well',
    ]);
    expect(state.tasks, isEmpty);
  });

  test('inbox capture and triage write through', () {
    final store = RecordingStore();
    final state = emptyState(store);

    state.addToInbox('An idea');
    state.promoteToToday(state.inbox.single);

    // Promoting must delete the inbox row as well as create the task —
    // otherwise the item reappears on the next load.
    expect(store.calls, [
      'saveInbox:An idea',
      'deleteInbox:An idea',
      'saveTask:An idea',
    ]);
    expect(state.inbox, isEmpty);
    expect(state.tasks.single.title, 'An idea');
  });

  test('completing a task saves both the task and the day counters', () {
    final store = RecordingStore();
    final state = emptyState(store);

    state.addTask('Ship it');
    store.calls.clear();

    state.startTask(state.tasks.single.id);
    state.completeActiveTask();

    expect(store.calls.where((c) => c.startsWith('saveTask')), hasLength(1));
    expect(store.calls.where((c) => c.startsWith('saveCounters')), hasLength(1));
    expect(state.tasks.single.isDone, isTrue);

    state.dispose();
  });

  test('rewards write through on add and claim', () {
    final store = RecordingStore();
    final state = emptyState(store);

    state.addReward('A long walk', 1000);
    state.claimReward(state.game.rewards.last);

    expect(store.calls, ['saveReward:A long walk', 'saveReward:A long walk']);
  });

  test('applyStored replaces state and keeps demo rewards when none stored', () {
    final store = RecordingStore();
    final state = emptyState(store);
    final demoRewardCount = state.game.rewards.length;

    state.applyStored(StoredData(
      tasks: [
        Task(id: 4, title: 'Loaded', tag: 'Deep work', priority: Priority.high, estMin: 30),
      ],
      inbox: [InboxItem(text: 'Loaded idea', capturedAt: DateTime(2026, 8, 1))],
      rewards: const [],
      counters: const StoredCounters(points: 120, dayFocusBaseMin: 45),
    ));

    expect(state.tasks.single.title, 'Loaded');
    expect(state.inbox.single.text, 'Loaded idea');
    expect(state.points, 120);
    expect(state.dayFocusBaseMin, 45);
    // No stored rewards, so the designed placeholders stay rather than leaving
    // the Progress screen blank.
    expect(state.game.rewards, hasLength(demoRewardCount));
  });

  group('focus session survives a reload', () {
    Task aTask({int id = 1}) => Task(
        id: id,
        title: 'Deep work',
        tag: 'Deep work',
        priority: Priority.high,
        estMin: 60);

    test('starting a task stores the start instant, not a running count', () {
      final store = RecordingStore();
      final state = emptyState(store);
      state.addTask('Deep work');

      state.startTask(state.tasks.single.id);

      final session = store.savedSession!;
      expect(session.activeTaskId, state.tasks.single.id);
      expect(session.runningSince, isNotNull);
      expect(session.accum, Duration.zero);

      state.dispose();
    });

    test('a reload rebuilds elapsed time from the stored start instant', () {
      final store = RecordingStore();
      final state = emptyState(store);

      // Simulates a page refresh: fresh state, told the timer began 10 minutes
      // ago. Those 10 minutes must be counted even though nothing was running.
      final startedAt =
          DateTime.now().subtract(const Duration(minutes: 10));
      state.applyStored(StoredData(
        tasks: [aTask()],
        inbox: const [],
        rewards: const [],
        counters: const StoredCounters(),
        session: StoredSession(activeTaskId: 1, runningSince: startedAt),
      ));

      expect(state.isTracking, isTrue);
      expect(state.isRunning, isTrue);
      expect(state.activeTask!.title, 'Deep work');
      expect(state.elapsed.inMinutes, 10);

      state.dispose();
    });

    test('a paused session reloads paused, and does not accrue time', () {
      final store = RecordingStore();
      final state = emptyState(store);

      state.applyStored(StoredData(
        tasks: [aTask()],
        inbox: const [],
        rewards: const [],
        counters: const StoredCounters(),
        session: const StoredSession(
          activeTaskId: 1,
          accum: Duration(minutes: 7),
          runningSince: null,
        ),
      ));

      expect(state.isTracking, isTrue);
      expect(state.isRunning, isFalse);
      // Frozen at what was banked — a pause that lasted an hour adds nothing.
      expect(state.elapsed, const Duration(minutes: 7));

      state.dispose();
    });

    test('break time in progress is rebuilt from its own instant', () {
      final store = RecordingStore();
      final state = emptyState(store);

      final now = DateTime.now();
      state.applyStored(StoredData(
        tasks: [aTask()],
        inbox: const [],
        rewards: const [],
        counters: const StoredCounters(),
        session: StoredSession(
          activeTaskId: 1,
          runningSince: now.subtract(const Duration(minutes: 30)),
          breakSince: now.subtract(const Duration(minutes: 5)),
          breakReason: 'Snack',
        ),
      ));

      expect(state.onBreak, isTrue);
      expect(state.breakReason, 'Snack');
      expect(state.sessionBreak.inMinutes, 5);
      // The task keeps tracking through a break; focus is the difference.
      expect(state.elapsed.inMinutes, 30);
      expect(state.sessionFocus.inMinutes, 25);

      state.dispose();
    });

    test('completing clears the stored session', () async {
      final store = RecordingStore();
      final state = emptyState(store);
      state.addTask('Deep work');
      state.startTask(state.tasks.single.id);
      store.calls.clear();

      state.completeActiveTask();

      expect(store.calls, contains('clearSession'));
      expect(store.savedSession, isNull);

      state.dispose();
    });

    test('a session naming an unknown task is discarded, not crashed on', () {
      final store = RecordingStore();
      final state = emptyState(store);

      // The task was deleted on another device while this one was away.
      state.applyStored(StoredData(
        tasks: [aTask(id: 1)],
        inbox: const [],
        rewards: const [],
        counters: const StoredCounters(),
        session: const StoredSession(activeTaskId: 99),
      ));

      expect(state.isTracking, isFalse);
      expect(state.activeTask, isNull);

      state.dispose();
    });
  });

  group('sessions sync across devices', () {
    test('a session started elsewhere appears without a reload', () async {
      final store = RecordingStore();
      final state = emptyState(store);
      state.applyStored(StoredData(
        tasks: [
          Task(id: 1, title: 'Deep work', tag: 'Deep work', priority: Priority.high, estMin: 60),
        ],
        inbox: const [],
        rewards: const [],
        counters: const StoredCounters(),
      ));
      state.startSessionSync();

      expect(state.isTracking, isFalse);

      // The other device starts the timer.
      store.sessions.add(StoredSession(
        activeTaskId: 1,
        runningSince: DateTime.now().subtract(const Duration(minutes: 3)),
      ));
      await Future<void>.delayed(Duration.zero);

      expect(state.isTracking, isTrue);
      expect(state.elapsed.inMinutes, 3);

      state.dispose();
    });

    test('completing elsewhere stops this device too', () async {
      final store = RecordingStore();
      final state = emptyState(store);
      state.applyStored(StoredData(
        tasks: [
          Task(id: 1, title: 'Deep work', tag: 'Deep work', priority: Priority.high, estMin: 60),
        ],
        inbox: const [],
        rewards: const [],
        counters: const StoredCounters(),
        session: StoredSession(activeTaskId: 1, runningSince: DateTime.now()),
      ));
      state.startSessionSync();
      expect(state.isTracking, isTrue);

      store.sessions.add(null);
      await Future<void>.delayed(Duration.zero);

      expect(state.isTracking, isFalse);

      state.dispose();
    });
  });

  test('next task id continues past ids loaded from the store', () {
    final store = RecordingStore();
    final state = emptyState(store);

    state.applyStored(StoredData(
      tasks: [
        Task(id: 9, title: 'Loaded', tag: 'Admin', priority: Priority.low, estMin: 5),
      ],
      inbox: const [],
      rewards: const [],
      counters: const StoredCounters(),
    ));
    state.addTask('New one');

    expect(state.tasks.map((t) => t.id), [9, 10]);
  });
}
