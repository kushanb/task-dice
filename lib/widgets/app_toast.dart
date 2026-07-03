import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Compact inverse toast pill floating above the tab bar; auto-dismisses
/// after 2.4 s (design `toastUp`). One at a time — a new toast replaces it.
class AppToast {
  static OverlayEntry? _entry;
  static Timer? _timer;

  static void show(BuildContext context, String message) {
    dismiss();
    final entry = OverlayEntry(
      builder: (context) => Positioned(
        left: 0,
        right: 0,
        bottom: 170,
        child: IgnorePointer(
          child: Center(child: _ToastBody(message: message)),
        ),
      ),
    );
    _entry = entry;
    Overlay.of(context, rootOverlay: true).insert(entry);
    _timer = Timer(AppMotion.toastHold, dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ToastBody extends StatelessWidget {
  const _ToastBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.toastUp,
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 14 * (1 - t)), child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16, vertical: AppSpacing.s10),
        decoration: BoxDecoration(
          color: AppColors.inverseSurface,
          borderRadius: BorderRadius.circular(AppRadii.rButton),
          boxShadow: AppShadows.floating,
        ),
        child: Text(
          message,
          style: AppText.chipBold
              .copyWith(fontSize: 13, color: AppColors.inverseText),
        ),
      ),
    );
  }
}
