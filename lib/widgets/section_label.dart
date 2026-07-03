import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';

/// Mono overline section header ("CARRIED OVER — CLEAR THESE FIRST").
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color = AppColors.textFaint});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(), style: AppText.overline.copyWith(color: color));
  }
}
