import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/game.dart';
import '../models/task.dart';
import 'task_store.dart';

/// Firestore-backed [TaskStore], scoped to one signed-in user.
///
/// Layout — everything a user owns lives under their own document, which is
/// what lets `firestore.rules` authorise on a single path prefix:
///
///     users/{uid}                  counters + the day marker
///     users/{uid}/tasks/{id}
///     users/{uid}/inbox/{id}
///     users/{uid}/rewards/{id}
class FirestoreTaskStore implements TaskStore {
  FirestoreTaskStore({required this.uid, FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> get _user =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> get _tasks => _user.collection('tasks');
  CollectionReference<Map<String, dynamic>> get _inbox => _user.collection('inbox');
  CollectionReference<Map<String, dynamic>> get _rewards =>
      _user.collection('rewards');

  @override
  Future<StoredData> load() async {
    final results = await Future.wait([
      _user.get(),
      _tasks.get(),
      _inbox.get(),
      _rewards.get(),
    ]);

    final userDoc = results[0] as DocumentSnapshot<Map<String, dynamic>>;
    final taskDocs = results[1] as QuerySnapshot<Map<String, dynamic>>;
    final inboxDocs = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final rewardDocs = results[3] as QuerySnapshot<Map<String, dynamic>>;

    final tasks = taskDocs.docs.map((d) => _taskFrom(d.data())).toList()
      ..sort((a, b) => a.id.compareTo(b.id));

    final inbox = inboxDocs.docs.map((d) => _inboxFrom(d.id, d.data())).toList()
      // The inbox reads newest-first, matching addToInbox's insert(0, ...).
      ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));

    return StoredData(
      tasks: tasks,
      inbox: inbox,
      rewards: rewardDocs.docs.map((d) => _rewardFrom(d.id, d.data())).toList(),
      counters: _countersFrom(userDoc.data()),
    );
  }

  @override
  Future<void> saveTask(Task task) =>
      _tasks.doc(task.id.toString()).set(_taskTo(task));

  @override
  Future<void> deleteTask(Task task) => _tasks.doc(task.id.toString()).delete();

  @override
  Future<void> saveInboxItem(InboxItem item) =>
      _inbox.doc(item.id).set(_inboxTo(item));

  @override
  Future<void> deleteInboxItem(InboxItem item) => _inbox.doc(item.id).delete();

  @override
  Future<void> saveReward(Reward reward) =>
      _rewards.doc(reward.id).set(_rewardTo(reward));

  @override
  Future<void> saveCounters(StoredCounters counters) => _user.set({
        'points': counters.points,
        'pointsEarnedToday': counters.pointsEarnedToday,
        'dayFocusBaseMin': counters.dayFocusBaseMin,
        'dayBreakBaseMin': counters.dayBreakBaseMin,
        'usedBreakBudgetBaseMin': counters.usedBreakBudgetBaseMin,
        'breakBudgetMin': counters.breakBudgetMin,
        // Stamps which local day these daily figures belong to, so a session
        // opened tomorrow starts them from zero. See AppState.applyStored.
        'dayKey': todayKey(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}

/// Turns a Firestore failure into something that points at the fix.
///
/// `permission-denied` on a fresh project almost always means firestore.rules
/// was never published, not that the user did anything wrong — worth saying so
/// rather than showing a bare error code.
String describeStoreError(Object error) {
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Firestore rejected the request. If this project is new, publish '
            'firestore.rules — the default rules deny everything.',
      'unavailable' =>
        'Firestore is unreachable. Check your connection and try again.',
      'failed-precondition' =>
        'Firestore could not start its offline cache. This usually means the '
            'app is open in another tab.',
      'not-found' =>
        'No Firestore database found for this project. Create one in the '
            'Firebase console.',
      _ => error.message ?? 'Firestore error: ${error.code}',
    };
  }
  return '$error';
}

/// Local calendar day, as `YYYY-MM-DD`.
///
/// Deliberately local rather than UTC: "today" for a task tracker is the user's
/// day, not the server's.
String todayKey([DateTime? now]) {
  final d = now ?? DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

// ---- Codecs ----

Map<String, dynamic> _taskTo(Task task) => {
      'id': task.id,
      'title': task.title,
      'tag': task.tag,
      'priority': task.priority.name,
      'estMin': task.estMin,
      'status': task.status.name,
      'carried': task.carried,
      'dueToday': task.dueToday,
      'actualMin': task.actualMin,
      'bumpedFrom': task.bumpedFrom?.name,
    };

Task _taskFrom(Map<String, dynamic> data) => Task(
      id: (data['id'] as num?)?.toInt() ?? 0,
      title: data['title'] as String? ?? '',
      tag: data['tag'] as String? ?? 'Inbox',
      priority: _enumByName(Priority.values, data['priority']) ?? Priority.med,
      estMin: (data['estMin'] as num?)?.toInt() ?? 25,
      status: _enumByName(TaskStatus.values, data['status']) ?? TaskStatus.planned,
      carried: (data['carried'] as num?)?.toInt() ?? 0,
      dueToday: data['dueToday'] as bool? ?? false,
      actualMin: (data['actualMin'] as num?)?.toInt(),
      bumpedFrom: _enumByName(Priority.values, data['bumpedFrom']),
    );

Map<String, dynamic> _inboxTo(InboxItem item) => {
      'text': item.text,
      'capturedAt': Timestamp.fromDate(item.capturedAt),
      'midFocus': item.midFocus,
    };

InboxItem _inboxFrom(String id, Map<String, dynamic> data) => InboxItem(
      id: id,
      text: data['text'] as String? ?? '',
      capturedAt:
          (data['capturedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      midFocus: data['midFocus'] as bool? ?? false,
    );

Map<String, dynamic> _rewardTo(Reward reward) => {
      'title': reward.title,
      'detail': reward.detail,
      'fraction': reward.fraction,
      'reached': reward.reached,
      'claimed': reward.claimed,
    };

Reward _rewardFrom(String id, Map<String, dynamic> data) => Reward(
      id: id,
      title: data['title'] as String? ?? '',
      detail: data['detail'] as String? ?? '',
      fraction: (data['fraction'] as num?)?.toDouble() ?? 0,
      reached: data['reached'] as bool? ?? false,
      claimed: data['claimed'] as bool? ?? false,
    );

StoredCounters _countersFrom(Map<String, dynamic>? data) {
  if (data == null) return const StoredCounters();

  // Daily figures belong to the day they were written on. Opening the app the
  // next morning must not inherit yesterday's focus minutes — only `points`,
  // which is a running total, survives the rollover.
  final isSameDay = (data['dayKey'] as String?) == todayKey();
  int daily(String key) {
    if (!isSameDay) return 0;
    return (data[key] as num?)?.toInt() ?? 0;
  }

  return StoredCounters(
    points: (data['points'] as num?)?.toInt() ?? 0,
    pointsEarnedToday: daily('pointsEarnedToday'),
    dayFocusBaseMin: daily('dayFocusBaseMin'),
    dayBreakBaseMin: daily('dayBreakBaseMin'),
    usedBreakBudgetBaseMin: daily('usedBreakBudgetBaseMin'),
    breakBudgetMin: (data['breakBudgetMin'] as num?)?.toInt() ?? 60,
  );
}

T? _enumByName<T extends Enum>(List<T> values, Object? name) {
  if (name is! String) return null;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return null;
}
