import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Google sign-in, wrapped so the UI never touches FirebaseAuth directly.
///
/// This deliberately uses Firebase's own OAuth flow rather than the
/// `google_sign_in` package. Firebase hosts the consent handler at
/// `<authDomain>/__/auth/handler`, which means there is no separate Google
/// client ID to configure, no GIS script to load, and no client ID to thread
/// through the build as another env var — enabling the Google provider in the
/// Firebase console is the whole setup.
class AuthService {
  AuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signInWithGoogle() async {
    final provider = GoogleAuthProvider()
      // Always show the chooser rather than silently reusing the one session
      // the browser happens to be signed into.
      ..setCustomParameters({'prompt': 'select_account'});

    // On web the popup is a real browser popup; elsewhere Firebase drives the
    // platform's native OAuth flow.
    if (kIsWeb) {
      await _auth.signInWithPopup(provider);
    } else {
      await _auth.signInWithProvider(provider);
    }
  }

  Future<void> signOut() => _auth.signOut();
}

/// A sign-in failure translated into something worth showing a person.
///
/// Firebase codes are stable, so these are matched rather than shown raw.
String describeAuthError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'popup-closed-by-user' ||
      'cancelled-popup-request' ||
      'user-cancelled' =>
        'Sign-in was cancelled.',
      'popup-blocked' =>
        'Your browser blocked the sign-in popup. Allow popups for this site and try again.',
      'network-request-failed' =>
        "Couldn't reach Google. Check your connection and try again.",
      'unauthorized-domain' =>
        'This domain is not authorised in the Firebase console.',
      'operation-not-allowed' =>
        'Google sign-in is not enabled for this Firebase project.',
      'user-disabled' => 'This account has been disabled.',
      _ => error.message ?? 'Sign-in failed. Please try again.',
    };
  }
  return 'Sign-in failed. Please try again.';
}
