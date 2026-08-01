/// The signed-in account, as the UI needs to know it.
///
/// Deliberately free of any Firebase type so the screens stay independent of
/// the auth backend — and so a local-only build (or a widget test) can simply
/// pass null and render no account section at all.
class AccountInfo {
  const AccountInfo({this.email, required this.onSignOut});

  final String? email;
  final Future<void> Function() onSignOut;
}
