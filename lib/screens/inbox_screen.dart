import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_toast.dart';
import '../widgets/inbox_card.dart';

/// Quick-capture inbox — the brain-dump list, triaged when you feel like it.
/// Pushed as its own route (from the Today header), so it receives [state].
class InboxScreen extends StatelessWidget {
  const InboxScreen({super.key, required this.state});

  final AppState state;

  static Future<void> open(BuildContext context, AppState state) =>
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => InboxScreen(state: state),
      ));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: ListenableBuilder(
        listenable: state,
        builder: (context, _) {
          final items = state.inbox;
          final count = items.length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.s20, AppSpacing.s4, AppSpacing.s20, AppSpacing.s24),
            children: [
              Text(
                count == 0
                    ? 'Nothing captured yet. Tap + anywhere to dump a thought.'
                    : '$count thought${count == 1 ? '' : 's'} captured. '
                        'Triage when you feel like it — no rush.',
                style: AppText.body.copyWith(fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.s14),
              for (final item in items) ...[
                InboxCard(
                  item: item,
                  onToday: () {
                    state.promoteToToday(item);
                    AppToast.show(context, 'Moved to today');
                  },
                  onLater: () => AppToast.show(context, 'Kept for later'),
                  onDelete: () {
                    state.removeFromInbox(item);
                    AppToast.show(context, 'Deleted');
                  },
                ),
                const SizedBox(height: AppSpacing.s12),
              ],
            ],
          );
        },
      ),
    );
  }
}
