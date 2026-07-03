import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:taskdice/logic/scoring.dart';
import 'package:taskdice/models/task.dart';

Task _task({
  required int id,
  Priority priority = Priority.med,
  TaskStatus status = TaskStatus.planned,
  int carried = 0,
  bool dueToday = false,
  int estMin = 30,
  int? actualMin,
}) =>
    Task(
      id: id,
      title: 'T$id',
      tag: 'Test',
      priority: priority,
      estMin: estMin,
      status: status,
      carried: carried,
      dueToday: dueToday,
      actualMin: actualMin,
    );

void main() {
  group('smartWeight', () {
    test('sums 1 + priority + carried + due', () {
      // 1 + high(3) + carried(3) + due(2) = 9, matching the design example.
      expect(
        smartWeight(_task(
            id: 1,
            priority: Priority.high,
            status: TaskStatus.carried,
            carried: 2,
            dueToday: true)),
        9,
      );
      // 1 + low(1) = 2.
      expect(smartWeight(_task(id: 2, priority: Priority.low)), 2);
    });
  });

  group('rollPick', () {
    test('true random can reach every candidate', () {
      final tasks = [_task(id: 1), _task(id: 2), _task(id: 3)];
      final seen = <int>{};
      final rng = Random(42);
      for (var i = 0; i < 200; i++) {
        seen.add(rollPick(tasks, smart: false, random: rng).id);
      }
      expect(seen, {1, 2, 3});
    });

    test('smart weighting favors the heavier task', () {
      final light = _task(id: 1, priority: Priority.low); // weight 2
      final heavy = _task(
          id: 2,
          priority: Priority.high,
          status: TaskStatus.carried,
          carried: 2,
          dueToday: true); // weight 9
      final rng = Random(7);
      var heavyWins = 0;
      for (var i = 0; i < 1000; i++) {
        if (rollPick([light, heavy], smart: true, random: rng).id == 2) {
          heavyWins++;
        }
      }
      // Expected ~9/11 ≈ 82%; assert a comfortable margin.
      expect(heavyWins, greaterThan(700));
    });
  });

  group('computeEfficiency', () {
    test('matches the 40·FR + 35·CR + 25·EA formula', () {
      final tasks = [
        _task(id: 1, status: TaskStatus.done, estMin: 30, actualMin: 30),
        _task(id: 2, status: TaskStatus.planned),
      ];
      // FR = 90/(90+30)=0.75 → 30; CR = 1/2 → 17.5; EA = 1 → 25. Total ≈ 73.
      expect(computeEfficiency(tasks, 90, 30), 73);
    });
  });

  group('completion points', () {
    test('bonus applies within 15% of estimate', () {
      expect(earnsEstimateBonus(actualMin: 34, estMin: 30), isTrue); // 13%
      expect(earnsEstimateBonus(actualMin: 40, estMin: 30), isFalse); // 33%
      expect(completionPoints(Priority.high), 100);
    });
  });
}
