import 'package:flutter/widgets.dart';

import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import 'pop_in.dart';

/// Green "earned moment" card shown on Today after completing a task.
class CompletedCard extends StatelessWidget {
  const CompletedCard({super.key, required this.info});

  final CompletedInfo info;

  @override
  Widget build(BuildContext context) {
    return PopIn(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s18, vertical: AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.greenTint,
          border: Border.all(color: AppColors.borderGreen),
          borderRadius: BorderRadius.circular(AppRadii.rCardProminent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('✓ ${info.title}',
                style: AppText.taskTitle
                    .copyWith(fontSize: 14, color: AppColors.green)),
            const SizedBox(height: AppSpacing.s4),
            Text(info.summary,
                style:
                    AppText.monoBody.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.s4),
            Text(info.note, style: AppText.meta),
          ],
        ),
      ),
    );
  }
}
