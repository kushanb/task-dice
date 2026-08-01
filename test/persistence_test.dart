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
