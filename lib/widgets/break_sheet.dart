import 'package:flutter/material.dart';

import '../logic/formats.dart';
import '../state/app_state.dart';
import '../theme/app_tokens.dart';
import 'app_toast.dart';
import 'press_scale.dart';
import 'segmented_toggle.dart';

/// Break editor sheet (screen 04): live break timer, quick-add chips,
/// manual HH:MM range, reason chips. The task keeps tracking throughout.
Future<void> showBreakSheet(BuildContext context, AppState state) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: ListenableBuilder(
        listenable: state,
        builder: (context, _) => _BreakSheetBody(state: state),
      ),
    ),
  );
}

class _BreakSheetBody extends StatefulWidget {
  const _BreakSheetBody({required this.state});

  final AppState state;

  @override
  State<_BreakSheetBody> createState() => _BreakSheetBodyState();
}

class _BreakSheetBodyState extends State<_BreakSheetBody> {
  late final TextEditingController _startCtl;
  late final TextEditingController _endCtl;

  String _hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startCtl = TextEditingController(
        text: _hhmm(now.subtract(const Duration(minutes: 7))));
    _endCtl = TextEditingController(text: _hhmm(now));
  }

  @override
  void dispose() {
    _startCtl.dispose();
    _endCtl.dispose();
    super.dispose();
  }

  void _quickAdd(int minutes) {
    final state = widget.state;
    state.addBreakMinutes(minutes);
    Navigator.of(context).pop();
    AppToast.show(
        context, '+$minutes min ${state.breakType.label.toLowerCase()} logged');
  }

  int? _parseHhmm(String s) {
    final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(s.trim());
    if (m == null) return null;
    return int.parse(m.group(1)!) * 60 + int.parse(m.group(2)!);
  }

  void _addManual() {
    final a = _parseHhmm(_startCtl.text);
    final b = _parseHhmm(_endCtl.text);
    if (a == null || b == null || b <= a) {
      AppToast.show(context, 'Use HH:MM, end after start');
      return;
    }
    widget.state.addBreakMinutes(b - a);
    Navigator.of(context).pop();
    AppToast.show(context,
        '+${b - a} min logged (${_startCtl.text.trim()}–${_endCtl.text.trim()})');
  }

  void _toggleLive() {
    final state = widget.state;
    if (state.onBreak) {
      state.stopBreak();
      Navigator.of(context).pop();
      AppToast.show(context, 'Break logged — back to it');
    } else {
      state.startBreak();
    }
  }

  InputBorder get _timeBorder => OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadii.rInput),
        borderSide: const BorderSide(color: AppColors.borderInput),
      );

  Widget _timeField(TextEditingController controller) => SizedBox(
        width: 70,
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.datetime,
          style: AppText.monoBody,
          decoration: InputDecoration(
            fillColor: AppColors.surfaceSunken,
            contentPadding: const EdgeInsets.all(AppSpacing.s10),
            enabledBorder: _timeBorder,
            focusedBorder: _timeBorder.copyWith(
                borderSide: const BorderSide(color: AppColors.borderFocused)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final onBreak = state.onBreak;
    final liveRun = onBreak
        ? DateTime.now().difference(state.breakSince!)
        : Duration.zero;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20, 0, AppSpacing.s20, AppSpacing.s16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text('Log a break', style: AppText.cardTitle)),
                const SizedBox(width: AppSpacing.s8),
                SegmentedToggle<BreakType>(
                  values: BreakType.values,
                  selected: state.breakType,
                  onChanged: state.setBreakType,
                  labelOf: (t) => t.label,
                  activeBgOf: (t) =>
                      t == BreakType.rest ? AppColors.amber : AppColors.red,
                  activeFgOf: (t) =>
                      t == BreakType.rest ? AppColors.onAmber : AppColors.onRed,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s14),
            PressScale(
              onTap: _toggleLive,
              scale: 0.98,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: onBreak
                      ? AppColors.amberTintStrong
                      : AppColors.surfaceRaised,
                  border: Border.all(
                      color: onBreak
                          ? AppColors.borderAmberLive
                          : AppColors.borderHairline),
                  borderRadius: BorderRadius.circular(AppRadii.rCard),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                          onBreak ? '■ Stop break' : '▶ Start break timer',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.buttonLarge
                              .copyWith(fontSize: 15, color: AppColors.amber)),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(fmtClock(liveRun),
                        style: AppText.statValue
                            .copyWith(color: AppColors.amber)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s14),
            Row(
              children: [
                for (final minutes in const [3, 5, 10]) ...[
                  if (minutes != 3) const SizedBox(width: AppSpacing.s8),
                  Expanded(
                    child: PressScale(
                      onTap: () => _quickAdd(minutes),
                      scale: 0.95,
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.s12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceRaised,
                          borderRadius:
                              BorderRadius.circular(AppRadii.rButton),
                        ),
                        child: Text('+$minutes min',
                            textAlign: TextAlign.center,
                            style: AppText.monoBody.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColors.amber)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.s14),
            Row(
              children: [
                _timeField(_startCtl),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.s8),
                  child: Text('to', style: AppText.body),
                ),
                _timeField(_endCtl),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: PressScale(
                    onTap: _addManual,
                    child: Container(
                      padding: const EdgeInsets.all(11),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceRaised,
                        borderRadius: BorderRadius.circular(AppRadii.rInput),
                      ),
                      child: Text('Add past break',
                          textAlign: TextAlign.center,
                          style: AppText.buttonSecondary
                              .copyWith(fontSize: 12.5)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s14),
            Wrap(
              spacing: AppSpacing.s6,
              runSpacing: AppSpacing.s6,
              children: [
                for (final reason in AppState.breakReasonOptions)
                  GestureDetector(
                    onTap: () => state.toggleBreakReason(reason),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 13, vertical: AppSpacing.s6),
                      decoration: BoxDecoration(
                        color: state.breakReason == reason
                            ? AppColors.amber
                            : AppColors.surfaceRaised,
                        border: Border.all(
                            color: state.breakReason == reason
                                ? AppColors.amber
                                : AppColors.borderHairline),
                        borderRadius: BorderRadius.circular(AppRadii.rPill),
                      ),
                      child: Text(reason,
                          style: AppText.chip.copyWith(
                              color: state.breakReason == reason
                                  ? AppColors.onAmber
                                  : AppColors.textTertiary)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Task keeps tracking in the background · budget '
              '${state.breakBudgetUsedMin}/${state.breakBudgetMin}m',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
          ],
        ),
      ),
    );
  }
}
