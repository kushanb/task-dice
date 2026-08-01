import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'firebase/auth_gate.dart';
import 'firebase/auth_service.dart';
import 'firebase/firebase_config.dart';
import 'firebase/firebase_startup.dart';
import 'shell/app_shell.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Fonts ship in assets/fonts/, so nothing should ever be pulled from the
  // Google Fonts CDN. Turning fetching off keeps the app fully offline-capable
  // and makes a missing variant fail loudly instead of silently hitting the
  // network.
  GoogleFonts.config.allowRuntimeFetching = false;

  // Note there is no `await` before runApp. On web, firebase_core pulls the
  // Firebase JS SDK from gstatic at runtime, so awaiting initialisation here
  // would hold the first frame hostage to a CDN — and hang on the boot splash
  // indefinitely when that request cannot complete. The app paints first and
  // resolves Firebase behind it.
  runApp(const TaskDiceApp());
}

class TaskDiceApp extends StatelessWidget {
  const TaskDiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskDice',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  late Future<FirebaseStartup> _startup = initialiseFirebase();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseStartup>(
      future: _startup,
      builder: (context, snapshot) {
        final startup = snapshot.data;

        if (startup == null) {
          return const FirebaseBootScreen();
        }

        return switch (startup) {
          // No project configured — this is the local-only mode used by
          // `flutter test` and by a plain `flutter run` with no --dart-define.
          // Demo data, nothing persisted.
          FirebaseStartup.notConfigured => const AppShell(),
          FirebaseStartup.ready => AuthGate(auth: AuthService()),
          // Configured but unreachable. Deliberately NOT falling through to the
          // demo shell: showing someone seeded fake tasks in place of their own
          // would look like data loss.
          FirebaseStartup.failed => FirebaseUnavailableScreen(
              onRetry: () => setState(() => _startup = initialiseFirebase()),
            ),
        };
      },
    );
  }
}

/// Brings Firebase up, reporting which of the three outcomes happened.
Future<FirebaseStartup> initialiseFirebase() async {
  if (!FirebaseConfig.isConfigured) {
    debugPrint(
      'TaskDice: running without Firebase — data stays in memory. '
      'Missing: ${FirebaseConfig.missingKeys.join(', ')}',
    );
    return FirebaseStartup.notConfigured;
  }

  try {
    // Idempotent. Retrying after a timeout, or a hot restart, would otherwise
    // call initializeApp twice and throw [core/duplicate-app] — turning a
    // recoverable failure into a permanent one. Settings are likewise write-once:
    // assigning them after Firestore has been used throws.
    if (Firebase.apps.isEmpty) {
      // Bounded: a stalled SDK fetch must surface as an error the user can
      // retry, not as a spinner that never ends.
      await Firebase.initializeApp(options: FirebaseConfig.options)
          .timeout(const Duration(seconds: 20));

      // Firestore's own cache is what makes the PWA usable offline: reads are
      // served locally and writes queue until the network returns.
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
    }
    return FirebaseStartup.ready;
  } catch (error, stack) {
    debugPrint('TaskDice: Firebase init failed — $error');
    debugPrintStack(stackTrace: stack);
    return FirebaseStartup.failed;
  }
}
