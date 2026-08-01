import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/firestore_task_store.dart';
import '../data/task_store.dart';
import '../screens/sign_in_screen.dart';
import '../shell/account_info.dart';
import '../shell/app_shell.dart';
import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import 'auth_service.dart';

/// Chooses between the sign-in screen and the app, and owns the [AppState]
/// belonging to the signed-in user.
///
/// A fresh AppState is built per user — keyed on uid — so signing out and back
/// in as someone else cannot leave the previous account's tasks on screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.auth});

  final AuthService auth;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: widget.auth.authStateChanges,
      builder: (context, snapshot) {
        // Until Firebase has restored any persisted session, showing the
        // sign-in screen would make a returning user think they were logged
        // out — so wait instead.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }

        final user = snapshot.data;
        if (user == null) {
          return SignInScreen(
            onSignIn: () async {
              try {
                await widget.auth.signInWithGoogle();
              } catch (error) {
                throw describeAuthError(error);
              }
            },
          );
        }

        return _SignedIn(
          key: ValueKey(user.uid),
          uid: user.uid,
          account: AccountInfo(
            email: user.email,
            onSignOut: widget.auth.signOut,
          ),
        );
      },
    );
  }
}

/// Loads the user's data once, then runs the app against it.
class _SignedIn extends StatefulWidget {
  const _SignedIn({super.key, required this.uid, required this.account});

  final String uid;
  final AccountInfo account;

  @override
  State<_SignedIn> createState() => _SignedInState();
}

class _SignedInState extends State<_SignedIn> {
  late final TaskStore _store = FirestoreTaskStore(uid: widget.uid);

  // Seeding is off: a real account starts empty and fills from Firestore.
  late final AppState _state = AppState(seedDemoData: false, store: _store);

  late Future<void> _loaded = _load();

  Future<void> _load() async {
    final data = await _store.load();
    _state.applyStored(data);
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loaded,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        if (snapshot.hasError) {
          return _LoadFailed(
            error: describeStoreError(snapshot.error!),
            onRetry: () => setState(() => _loaded = _load()),
          );
        }
        return AppShell(state: _state, account: widget.account);
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation(AppColors.green),
          ),
        ),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Couldn't load your tasks.",
                  style: AppText.cardTitle, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s8),
              Text(error, style: AppText.meta, textAlign: TextAlign.center),
              const SizedBox(height: AppSpacing.s20),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      ),
    );
  }
}
