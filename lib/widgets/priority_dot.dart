import 'package:flutter/widgets.dart';

import '../models/task.dart';
import '../theme/app_tokens.dart';

Color priorityColor(Priority p) => switch (p) {
      Priority.high => AppColors.red,
      Priority.med => AppColors.amber,
      Priority.low => AppColors.grey,
    };

class PriorityDot extends StatelessWidget {
  const PriorityDot({super.key, required this.priority});

  final Priority priority;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration:
          BoxDecoration(color: priorityColor(priority), shape: BoxShape.circle),
    );
  }
}
