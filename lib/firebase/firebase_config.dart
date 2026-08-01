import 'package:firebase_core/firebase_core.dart';

/// Firebase project settings, supplied at build time.
///
/// These come from `--dart-define` rather than a checked-in
/// `firebase_options.dart`, so the same source builds against a scratch project
/// locally and the real one on Vercel. See README "Firebase".
///
/// None of these are secrets. A Firebase web config identifies the project, it
/// does not authorise anything — every client that loads the app can read them
/// out of the bundle, by design. What actually protects the data is the
/// Firestore rules in `firestore.rules` plus the Authorized domains list in the
/// Firebase console. Do not treat `apiKey` as a credential.
abstract final class FirebaseConfig {
  static const apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');
  static const projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const storageBucket = String.fromEnvironment('FIREBASE_STORAGE_BUCKET');
  static const messagingSenderId =
      String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const appId = String.fromEnvironment('FIREBASE_APP_ID');

  /// Whether enough was defined to talk to a project at all.
  ///
  /// When this is false the app still runs — it just keeps everything in
  /// memory, which is what `flutter test` and a plain `flutter run` do. That
  /// means a missing env var degrades to the old behaviour instead of a crash
  /// on a blank screen.
  static bool get isConfigured =>
      apiKey.isNotEmpty && projectId.isNotEmpty && appId.isNotEmpty;

  /// The subset of settings that were left empty, for a readable warning.
  static List<String> get missingKeys => {
        'FIREBASE_API_KEY': apiKey,
        'FIREBASE_AUTH_DOMAIN': authDomain,
        'FIREBASE_PROJECT_ID': projectId,
        'FIREBASE_STORAGE_BUCKET': storageBucket,
        'FIREBASE_MESSAGING_SENDER_ID': messagingSenderId,
        'FIREBASE_APP_ID': appId,
      }.entries.where((e) => e.value.isEmpty).map((e) => e.key).toList();

  static FirebaseOptions get options => FirebaseOptions(
        apiKey: apiKey,
        authDomain: authDomain,
        projectId: projectId,
        storageBucket: storageBucket,
        messagingSenderId: messagingSenderId,
        appId: appId,
      );
}
