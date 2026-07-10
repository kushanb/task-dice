import 'package:flutter/widgets.dart';

import '../models/game.dart';
import '../theme/app_tokens.dart';
import 'hairline_bar.dart';

/// Level / XP hero card with streak stats (design `LevelCard`).
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.game});

  final GameData game;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s18),
      decoration: BoxDecoration(
        gradient: AppColors.levelGradient,
        border: Border.all(color: AppColors.borderGreen),
        borderRadius: BorderRadius.circular(AppRadii.rCardHero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text('Level ${game.level} · ${game.levelName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle.copyWith(fontSize: 17)),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text('${_fmt(game.xp)} / ${_fmt(game.xpTarget)} xp',
                  style: AppText.monoCaption
                      .copyWith(fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          HairlineBar(
            fraction: game.xpFraction,
            color: AppColors.green,
            height: 8,
            radius: 4,
            background: const Color(0x17FFFFFF),
          ),
          const SizedBox(height: AppSpacing.s14),
          Row(
            children: [
              Expanded(
                  child:
                      _Stat(value: '🔥 ${game.streakDays}', label: 'day streak')),
              Expanded(
                child: _Stat(
                    value: '×${game.streakMultiplier}',
                    label: 'streak multiplier'),
              ),
              Expanded(
                  child: _Stat(value: '${game.badgeCount}', label: 'badges')),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmt(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: AppText.statValueSmall),
        Text(label,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.micro),
      ],
    );
  }
}
