@TestOn('browser || vm')
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:taskdice/models/game.dart';
import 'package:taskdice/models/id.dart';
import 'package:taskdice/state/app_state.dart';

/// Run these under web semantics too — `flutter test --platform chrome` — where
/// ints are JS doubles. A 32-bit shift overflow in newId only fails there, and
/// it took down the whole app because GameData.demo builds Rewards eagerly.
void main() {
  test('newId does not throw and yields distinct, non-empty ids', () {
    final ids = <String>{};
    for (var i = 0; i < 2000; i++) {
      final id = newId();
      expect(id, isNotEmpty);
      ids.add(id);
    }
    // Allow a little slack for same-microsecond collisions; the salt should
    // make them vanishingly rare.
    expect(ids.length, greaterThan(1990));
  });

  test('GameData.demo builds (it allocates ids for its rewards)', () {
    final game = GameData.demo();
    expect(game.rewards, isNotEmpty);
    expect(game.rewards.map((r) => r.id).toSet(), hasLength(game.rewards.length));
  });

  test('AppState constructs on every platform', () {
    final seeded = AppState();
    expect(seeded.tasks, isNotEmpty);
    expect(seeded.game.rewards, isNotEmpty);

    final empty = AppState(seedDemoData: false);
    expect(empty.tasks, isEmpty);
  });
}
