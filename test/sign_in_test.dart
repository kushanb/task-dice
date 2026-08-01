import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:taskdice/screens/sign_in_screen.dart';
import 'package:taskdice/theme/app_theme.dart';

Widget wrap(Widget child) =>
    MaterialApp(theme: buildAppTheme(), home: child);

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('offers a single Google sign-in action', (tester) async {
    await tester.pumpWidget(wrap(SignInScreen(onSignIn: () async {})));

    expect(find.text('TaskDice'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });

  testWidgets('tapping signs in', (tester) async {
    var called = 0;
    await tester.pumpWidget(wrap(SignInScreen(onSignIn: () async => called++)));

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(called, 1);
  });

  testWidgets('a failed sign-in shows the reason and stays put', (tester) async {
    await tester.pumpWidget(wrap(SignInScreen(
      onSignIn: () async => throw 'Your browser blocked the sign-in popup.',
    )));

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Your browser blocked the sign-in popup.'), findsOneWidget);
    // The button comes back so the failure is recoverable.
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
