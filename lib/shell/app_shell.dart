import 'package:flutter/material.dart';

import '../screens/focus_screen.dart';
import '../screens/plan_screen.dart';
import '../screens/roll_screen.dart';
import '../screens/today_screen.dart';
import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/capture_fab.dart';
import '../widgets/capture_overlay.dart';

/// Root scaffold: 5 tabs (Inbox is reached via the capture FAB / Today),
/// capture FAB, and the tab bar.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _tabs = ['Today', 'Plan', 'Roll', 'Trends', 'Progress'];
  static const _focusIndex = 5;

  final AppState _state = AppState();
  int _index = 0;

  @override
  void dispose() {
    _state.dispose();
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
              const _ComingSoon(title: 'Trends'),
              const _ComingSoon(title: 'Progress'),
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

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: AppText.pageTitle),
          const SizedBox(height: AppSpacing.s8),
          Text('Coming in a later step',
              style: AppText.caption),
        ],
      ),
    );
  }
}
