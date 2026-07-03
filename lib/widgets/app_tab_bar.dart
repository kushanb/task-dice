import 'dart:ui';

import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Translucent, blurred bottom tab bar with label-only items.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    super.key,
    required this.labels,
    required this.index,
    required this.onSelect,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: EdgeInsets.fromLTRB(
              AppSpacing.s10, AppSpacing.s12, AppSpacing.s10,
              bottomInset > 0 ? bottomInset : AppSpacing.s24),
          decoration: const BoxDecoration(
            color: AppColors.tabBarBackground,
            border: Border(top: BorderSide(color: AppColors.borderHairline)),
          ),
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onSelect(i),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.s6),
                      child: Text(
                        labels[i],
                        textAlign: TextAlign.center,
                        style: AppText.tabLabel.copyWith(
                          color: i == index
                              ? AppColors.green
                              : AppColors.textFaint,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
