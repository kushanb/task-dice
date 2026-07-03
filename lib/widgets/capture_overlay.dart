import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import 'app_toast.dart';
import 'pop_in.dart';
import 'press_scale.dart';

/// Quick-capture dialog (from the FAB). Never touches the running timer.
Future<void> showCaptureOverlay(BuildContext context, AppState state) {
  final hint = state.isTracking
      ? 'Timer keeps running — dump it and get back.'
      : 'Straight to the inbox, zero friction.';

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Quick capture',
    barrierColor: AppColors.scrimDialog,
    transitionDuration: AppMotion.popIn,
    pageBuilder: (context, _, _) {
      final controller = TextEditingController();

      void save() {
        final text = controller.text.trim();
        if (text.isEmpty) return;
        state.addToInbox(text);
        Navigator.of(context).pop();
        AppToast.show(
            context, state.isTracking ? 'Captured — timer untouched' : 'Captured');
      }

      return SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 108, 16, 0),
            child: PopIn(
              child: Material(
                color: const Color(0x00000000),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.s18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.borderStrong),
                    borderRadius: BorderRadius.circular(AppRadii.rCardHero),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Quick capture',
                          style: AppText.cardTitle.copyWith(fontSize: 16)),
                      const SizedBox(height: AppSpacing.s6),
                      Text(hint, style: AppText.meta),
                      const SizedBox(height: AppSpacing.s12),
                      TextField(
                        controller: controller,
                        autofocus: true,
                        style: AppText.itemTitle,
                        decoration: const InputDecoration(
                          hintText: "What's on your mind?",
                          fillColor: AppColors.surfaceSunken,
                        ),
                        onSubmitted: (_) => save(),
                      ),
                      const SizedBox(height: AppSpacing.s12),
                      PressScale(
                        onTap: save,
                        child: Container(
                          padding: const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: AppColors.green,
                            borderRadius:
                                BorderRadius.circular(AppRadii.rButton),
                          ),
                          child: Center(
                            child: Text('Capture → Inbox',
                                style: AppText.button
                                    .copyWith(color: AppColors.onGreen)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
