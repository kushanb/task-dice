import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'pop_in.dart';
import 'press_scale.dart';

/// Floating "how's your energy?" popover shown during focus.
class EnergyCheckIn extends StatelessWidget {
  const EnergyCheckIn({super.key, required this.onPick});

  static const faces = ['😴', '😕', '😐', '🙂', '⚡'];

  /// Called with the 1–5 energy level.
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return PopIn(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s18, vertical: AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderStrong),
          borderRadius: BorderRadius.circular(AppRadii.rCardProminent),
          boxShadow: AppShadows.overlay,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Quick check — how's your energy?",
                style: AppText.taskTitle.copyWith(fontSize: 13.5)),
            const SizedBox(height: AppSpacing.s10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < faces.length; i++)
                  PressScale(
                    onTap: () => onPick(i + 1),
                    scale: 1.25, // design: faces grow on press
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
                      child: Text(faces[i],
                          style: const TextStyle(fontSize: 26)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
