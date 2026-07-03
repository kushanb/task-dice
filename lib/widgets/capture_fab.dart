import 'package:flutter/widgets.dart';

import '../theme/app_tokens.dart';
import 'press_scale.dart';

/// 54 px inverse "+" capture button, floating above the tab bar.
class CaptureFab extends StatelessWidget {
  const CaptureFab({super.key, this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      scale: 0.92,
      child: Container(
        width: 54,
        height: 54,
        decoration: const BoxDecoration(
          color: AppColors.inverseSurface,
          shape: BoxShape.circle,
          boxShadow: AppShadows.floating,
        ),
        child: Center(
          child: Text(
            '+',
            style: TextStyle(
              fontSize: 28,
              height: 1,
              color: AppColors.inverseText,
              fontFamily: AppText.itemTitle.fontFamily,
            ),
          ),
        ),
      ),
    );
  }
}
