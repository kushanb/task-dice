class Badge {
  const Badge(this.emoji, this.name, this.requirement, {this.unlocked = true});

  final String emoji;
  final String name;
  final String requirement;
  final bool unlocked;
}

class Reward {
  Reward({
    required this.title,
    required this.detail,
    required this.fraction,
    this.reached = false,
    this.claimed = false,
  });

  final String title;
  String detail;

  /// Progress toward the reward, 0..1 (used for the bar when not [reached]).
  double fraction;

  /// Goal met — shows the Claim button instead of a bar.
  bool reached;
  bool claimed;
}

/// Gamification state behind the Progress screen.
///
/// NOTE: level/XP/streak/badges are seeded demo values — the app has no XP or
/// streak engine yet (flagged in DESIGN.md §9). Rewards, however, are live:
/// Claim and Add mutate this model through [AppState].
class GameData {
  GameData({
    required this.level,
    required this.levelName,
    required this.xp,
    required this.xpTarget,
    required this.streakDays,
    required this.streakMultiplier,
    required this.badgeCount,
    required this.badges,
    required this.rewards,
  });

  final int level;
  final String levelName;
  final int xp;
  final int xpTarget;
  final int streakDays;
  final double streakMultiplier;
  final int badgeCount;
  final List<Badge> badges;
  final List<Reward> rewards;

  double get xpFraction => xpTarget == 0 ? 0 : xp / xpTarget;

  factory GameData.demo() => GameData(
        level: 7,
        levelName: 'Flow Apprentice',
        xp: 2140,
        xpTarget: 2600,
        streakDays: 5,
        streakMultiplier: 1.3,
        badgeCount: 11,
        badges: const [
          Badge('🎯', 'Sharp-shooter', '5 estimates ±15%'),
          Badge('🧹', 'Debt-free', 'cleared all carried'),
          Badge('🌅', 'Early bird', 'focus before 9am ×5', unlocked: false),
        ],
        rewards: [
          Reward(
              title: 'Watch one episode',
              detail: '500 pts · reached!',
              fraction: 1,
              reached: true),
          Reward(
              title: 'Long walk, no phone',
              detail: '720 / 1,000 pts',
              fraction: .72),
          Reward(
              title: 'New book Saturday',
              detail: '3 / 7 clear days',
              fraction: .43),
        ],
      );
}
