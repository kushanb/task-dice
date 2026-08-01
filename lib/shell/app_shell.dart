import 'package:flutter/material.dart';

import '../screens/focus_screen.dart';
import '../screens/plan_screen.dart';
import '../screens/progress_screen.dart';
import '../screens/roll_screen.dart';
import '../screens/today_screen.dart';
import '../screens/trends_screen.dart';
import '../state/app_state.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/capture_fab.dart';
import '../widgets/capture_overlay.dart';
import 'account_info.dart';

/// Root scaffold: 5 tabs (Inbox is reached via the capture FAB / Today),
/// capture FAB, and the tab bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key, this.state, this.account});

  /// State to run against. When null the shell makes its own demo-seeded one,
  /// which is the local-only path used by `flutter test` and by a build with no
  /// Firebase config. When signed in, [AuthGate] passes the user's loaded state.
  final AppState? state;

  /// Drives the Account section on Progress. Null on a local-only build.
  final AccountInfo? account;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _tabs = ['Today', 'Plan', 'Roll', 'Trends', 'Progress'];
  static const _focusIndex = 5;

  late final AppState _state = widget.state ?? AppState();

  /// Only dispose what this widget created — the injected one outlives it.
  late final bool _ownsState = widget.state == null;

  int _index = 0;

  @override
  void dispose() {
    if (_ownsState) _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: Scaffold(
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: _index,
            children: [
              TodayScreen(
                onRollTap: () => setState(() => _index = 2),
                onTaskStart: () => setState(() => _index = _focusIndex),
              ),
              const PlanScreen(),
              RollScreen(
                onStart: () => setState(() => _index = _focusIndex),
              ),
              const TrendsScreen(),
              ProgressScreen(account: widget.account),
              // Focus mode lives outside the tab row; reached by starting a task.
              FocusScreen(onDone: () => setState(() => _index = 0)),
            ],
          ),
        ),
        floatingActionButton: CaptureFab(
          onTap: () => showCaptureOverlay(context, _state),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: AppTabBar(
          labels: _tabs,
          index: _index,
          onSelect: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
