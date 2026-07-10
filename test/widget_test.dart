import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:taskdice/main.dart';
import 'package:taskdice/widgets/dice_tile.dart';

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('Today screen renders header, efficiency card and tasks',
      (tester) async {
    await tester.pumpWidget(const TaskDiceApp());
    await tester.pump();

    expect(find.text('Today'), findsWidgets); // page title + tab label
    expect(find.text('Efficiency today'), findsOneWidget);
    expect(find.text('Roll a task'), findsOneWidget);
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('Finish quarterly report draft'), findsOneWidget);
    expect(find.text('carried ×2'), findsOneWidget);
  });

  testWidgets('Plan screen shows sections, priority bump, and adds a task',
      (tester) async {
    // Tall surface so all three sections are on screen at once.
    tester.view.physicalSize = const Size(1170, 4500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TaskDiceApp());
    await tester.pump();

    await tester.tap(find.text('Plan'));
    await tester.pump();

    expect(find.text('Plan the day'), findsOneWidget);
    expect(find.text('CARRIED OVER — CLEAR THESE FIRST'), findsOneWidget);
    expect(find.text('PLANNED TODAY'), findsOneWidget);
    expect(find.text('DONE'), findsOneWidget);
    expect(find.textContaining('High ↑ (was Med)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Water the plants');
    await tester.tap(find.text('Add'));
    await tester.pump();
    expect(find.text('Water the plants'), findsOneWidget);
    expect(find.text('Added to today'), findsOneWidget); // toast

    // Let the toast timer finish so no timers are pending at teardown.
    await tester.pump(const Duration(seconds: 3));
  });

  testWidgets('Long-pressing a task on Plan opens the editor and saves changes',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 4500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TaskDiceApp());
    await tester.pump();

    await tester.tap(find.text('Plan'));
    await tester.pump();

    await tester.longPress(find.text('Outline blog post'));
    await tester.pumpAndSettle();
    expect(find.text('Edit task'), findsOneWidget);

    await tester.enterText(
        find.widgetWithText(TextField, 'Outline blog post'), 'Draft blog post');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(find.text('Draft blog post'), findsOneWidget);
    expect(find.text('Outline blog post'), findsNothing);

    await tester.pump(const Duration(seconds: 3)); // drain toast timer
  });

  testWidgets('Starting a task opens Focus mode; completing returns to Today',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 4500);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TaskDiceApp());
    await tester.pump();

    await tester.tap(find.text('Book dentist appointment'));
    // Focus screen has looping animations — use fixed pumps, not pumpAndSettle.
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('IN FOCUS'), findsOneWidget);
    expect(find.text('Complete ✓'), findsOneWidget);

    // Break flow via the break sheet. (pump twice: start + finish the
    // sheet animation — pumpAndSettle would hang on the looping dot.)
    await tester.tap(find.text('☕  Take a break'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Log a break'), findsOneWidget);
    expect(find.text('+5 min'), findsOneWidget);

    await tester.tap(find.text('▶ Start break timer'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('■ Stop break'), findsOneWidget);
    expect(find.text('ON BREAK — TASK STILL TRACKING'), findsOneWidget);

    await tester.tap(find.text('■ Stop break'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400)); // sheet closes
    expect(find.text('Break logged — back to it'), findsOneWidget); // toast
    expect(find.text('ON BREAK — TASK STILL TRACKING'), findsNothing);

    // Quick-add chips log minutes against the budget.
    await tester.tap(find.textContaining('☕  Take a break'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('+5 min'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('+5 min break logged'), findsOneWidget); // toast
    expect(find.textContaining('29'), findsWidgets); // 24 + 5 budget minutes

    // Energy check-in appears after 18 s of focus.
    await tester.pump(const Duration(seconds: 18));
    expect(find.text("Quick check — how's your energy?"), findsOneWidget);
    await tester.tap(find.text('🙂'));
    await tester.pump(const Duration(milliseconds: 400));

    await tester.tap(find.text('Complete ✓'));
    await tester.pump(const Duration(milliseconds: 400));

    // Back on Today with the earned-moment card.
    expect(find.text('✓ Book dentist appointment'), findsOneWidget);
    expect(find.textContaining('pts · score'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3)); // drain toast timer
  });

  testWidgets('Roll picks a task and Start now opens Focus mode',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TaskDiceApp());
    await tester.pump();

    await tester.tap(find.text('Roll'));
    await tester.pump();
    expect(find.text('Tap the die — let it decide.'), findsOneWidget);
    expect(find.text('Smart (weighted)'), findsOneWidget);

    // Tap the die: it shakes and cycles names for ~1.45 s, then lands.
    await tester.tap(find.byType(DiceTile));
    await tester.pump(const Duration(milliseconds: 300)); // rolling
    await tester.pump(const Duration(milliseconds: 1500)); // landed
    await tester.pump(const Duration(milliseconds: 350)); // result pops in

    expect(find.text('THE DICE SAY'), findsOneWidget);
    expect(find.text('Start now'), findsOneWidget);
    expect(find.textContaining('% chance'), findsOneWidget);

    await tester.tap(find.text('Start now'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('IN FOCUS'), findsOneWidget);
  });

  testWidgets('Tapping the efficiency card opens the data-driven Day review',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TaskDiceApp());
    await tester.pump();

    await tester.tap(find.text('Efficiency today'));
    await tester.pumpAndSettle();

    expect(find.text('Day review'), findsOneWidget); // app bar title
    expect(find.text('Focus ratio'), findsOneWidget);
    expect(find.text('Completion'), findsOneWidget);
    expect(find.text('Estimates'), findsOneWidget);
    expect(find.text('ESTIMATE VS ACTUAL'), findsOneWidget);
    // Seeded done tasks with actuals appear as est-vs-actual rows.
    expect(find.text('41m / 25m'), findsOneWidget); // Review PR #142 (over → red)
    expect(find.text('+181'), findsOneWidget); // points earned today
  });

  testWidgets('Trends renders its four analytics cards', (tester) async {
    tester.view.physicalSize = const Size(1170, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TaskDiceApp());
    await tester.pump();

    await tester.tap(find.text('Trends'));
    await tester.pump();

    expect(find.text('Weekly efficiency'), findsOneWidget);
    expect(find.textContaining('vs last wk'), findsOneWidget);
    expect(find.text('Focus heatmap'), findsOneWidget);
    expect(find.textContaining('9–11am'), findsOneWidget);
    expect(find.text('Break patterns · this week'), findsOneWidget);
    expect(find.text('Interrupted'), findsOneWidget);
    expect(find.text('Estimate accuracy'), findsOneWidget);
    expect(find.text('64%'), findsOneWidget);
  });

  testWidgets('Progress shows level, badges, rewards; Claim works',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 3600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TaskDiceApp());
    await tester.pump();

    await tester.tap(find.text('Progress'));
    await tester.pump();

    expect(find.text('Level 7 · Flow Apprentice'), findsOneWidget);
    expect(find.text('RECENT BADGES'), findsOneWidget);
    expect(find.text('Sharp-shooter'), findsOneWidget);
    expect(find.text('MY REWARDS'), findsOneWidget);
    expect(find.text('Watch one episode'), findsOneWidget);
    expect(find.text('+ Add a reward'), findsOneWidget);

    // Claim the reached reward → it flips to "Claimed ✓".
    await tester.tap(find.text('Claim 🎉'));
    await tester.pump();
    expect(find.text('Claimed ✓'), findsOneWidget);
    expect(find.text('Reward claimed 🎉'), findsOneWidget); // toast

    await tester.pump(const Duration(seconds: 3)); // drain toast
  });

  testWidgets('Inbox lists captured items; triage moves and deletes',
      (tester) async {
    tester.view.physicalSize = const Size(1170, 2600);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const TaskDiceApp());
    await tester.pump();

    // Open the inbox from the Today header pill.
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    expect(find.textContaining('thoughts captured'), findsOneWidget);
    expect(find.text('Ask Sam about the Friday demo'), findsOneWidget);
    expect(find.textContaining('mid-focus'), findsOneWidget); // seeded mid-focus item

    // → Today promotes an item off the inbox and into the task list.
    await tester.tap(find.text('→ Today').first);
    await tester.pump();
    expect(find.text('Moved to today'), findsOneWidget); // toast

    // Delete removes another.
    await tester.tap(find.text('Delete').first);
    await tester.pump();
    expect(find.text('Ask Sam about the Friday demo'), findsNothing);

    await tester.pump(const Duration(seconds: 3)); // drain toast
  });
}
