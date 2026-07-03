import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Pill segment control. Active segment gets a solid accent fill + on-ink;
/// inactive segments are transparent with tertiary text.
class SegmentedToggle<T> extends StatelessWidget {
  const SegmentedToggle({
    super.key,
    required this.values,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    required this.activeBgOf,
    required this.activeFgOf,
    this.background = AppColors.surfaceSunken,
    this.border,
    this.segmentPadding = const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12, vertical: AppSpacing.s6),
  });

  final List<T> values;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T) labelOf;
  final Color Function(T) activeBgOf;
  final Color Function(T) activeFgOf;
  final Color background;
  final Color? border;
  final EdgeInsets segmentPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: background,
        border: border != null ? Border.all(color: border!) : null,
        borderRadius: BorderRadius.circular(AppRadii.rInput),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final value in values)
            GestureDetector(
              onTap: () => onChanged(value),
              child: Container(
                padding: segmentPadding,
                decoration: BoxDecoration(
                  color: value == selected
                      ? activeBgOf(value)
                      : const Color(0x00000000),
                  borderRadius: BorderRadius.circular(AppRadii.rChip),
                ),
                child: Text(
                  labelOf(value),
                  style: AppText.chipBold.copyWith(
                    color: value == selected
                        ? activeFgOf(value)
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
