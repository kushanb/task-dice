import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// How the attempt to bring Firebase up ended.
enum FirebaseStartup {
  /// No project configured. The app runs locally with demo data — used by
  /// `flutter test` and by a build with no `--dart-define`.
  notConfigured,

  /// Firebase is up; auth and Firestore are usable.
  ready,

  /// A project is configured but could not be reached or initialised.
  failed,
}

/// Shown while Firebase is starting.
///
/// Visually continuous with the boot splash in web/index.html, so a slow start
/// reads as one continuous load rather than a flash between two screens.
class FirebaseBootScreen extends StatelessWidget {
  const FirebaseBootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: _DiceMark()),
    );
  }
}

/// Shown when a configured project cannot be initialised.
///
/// This does not fall back to the demo shell on purpose: presenting seeded
/// sample tasks to someone whose real tasks failed to load would read as their
/// data having been wiped.
class FirebaseUnavailableScreen extends StatelessWidget {
  const FirebaseUnavailableScreen({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _DiceMark(),
                const SizedBox(height: AppSpacing.s24),
                Text("Can't reach TaskDice",
                    style: AppText.cardTitle, textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.s8),
                Text(
                  'Your tasks are safe. This device just cannot reach the '
                  'server right now.',
                  style: AppText.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.s20),
                TextButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The app mark at rest — the Roll screen's five-face.
class _DiceMark extends StatelessWidget {
  const _DiceMark();

  @override
  Widget build(BuildContext context) {
    const filled = {0, 2, 4, 6, 8};
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderStrong),
        borderRadius: BorderRadius.circular(AppRadii.rDice * 88 / 120),
      ),
      child: Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: GridView.count(
            crossAxisCount: 3,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (var i = 0; i < 9; i++)
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: filled.contains(i)
                        ? AppColors.green
                        : const Color(0x00000000),
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
