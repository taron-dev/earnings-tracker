import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_theme.dart';
import '../app/today.dart';
import '../app/ui_parts.dart';
import '../format/date_format.dart';
import '../format/time_format.dart';
import '../hourly_rate/hourly_rate_api.dart';
import '../money/money_format.dart';
import '../overview/plan_overview_api.dart';
import '../plans/plans_api.dart';
import 'work_log.dart';
import 'work_log_api.dart';

/// Opens the bottom sheet for recording work, today preselected, or for editing [existing].
Future<void> showWorkLogSheet(BuildContext context, {WorkLog? existing}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => WorkLogSheet(existing: existing),
);

/// Day, worked time and a live earnings preview; one tap on a quick choice for a usual day, the
/// ±15 and ±30 minute buttons for the rest.
class WorkLogSheet extends ConsumerStatefulWidget {
  const WorkLogSheet({super.key, this.existing});

  /// The work log being edited; null when recording a new one.
  final WorkLog? existing;

  @override
  ConsumerState<WorkLogSheet> createState() => _WorkLogSheetState();
}

class _WorkLogSheetState extends ConsumerState<WorkLogSheet> {
  late DateTime _day = widget.existing?.day ?? ref.read(todayProvider);

  /// Worked time; null until a button sets it for new work. An edited log keeps its own value,
  /// even one off the 15 minute steps, and the buttons move it from there.
  late int? _minutes = widget.existing?.minutes;

  static const _quickHours = [1, 2, 4, 6, 8];

  /// The buttons stay within 15 minutes to 24 hours, the shortest step to the longest Work Log.
  static const _minStep = 15;
  static const _maxMinutes = 24 * 60;

  /// [_minutes] when it is a valid Work Log, 1 minute to 24 hours.
  int? get _workedMinutes {
    final minutes = _minutes;
    return minutes != null && minutes >= 1 && minutes <= _maxMinutes ? minutes : null;
  }

  /// Shortens the time by [delta] minutes, never below 15; null when that would not shorten it.
  VoidCallback? _shorten(int delta) {
    final minutes = _minutes;
    if (minutes == null || minutes <= _minStep) return null;
    return () => setState(() => _minutes = (minutes - delta).clamp(_minStep, _maxMinutes));
  }

  /// Lengthens the time by [delta] minutes, never above 24 hours; from nothing it starts at [delta].
  VoidCallback? _lengthen(int delta) {
    final minutes = _minutes ?? 0;
    if (minutes >= _maxMinutes) return null;
    return () => setState(() => _minutes = (minutes + delta).clamp(_minStep, _maxMinutes));
  }

  bool _saving = false;
  String? _error;

  Future<void> _save(int minutes) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final api = ref.read(workLogApiProvider);
      final existing = widget.existing;
      final String confirmation;
      if (existing == null) {
        final log = await api.record(_day, minutes);
        confirmation = 'Zapísané ${formatMinutes(log.minutes)} · ${formatMoney(log.earnings)}';
      } else {
        await api.update(existing.id, _day, minutes);
        confirmation = 'Záznam upravený.';
      }
      _closeWith(confirmation);
    } catch (_) {
      // The sheet stays open with what was typed, so saving again is one tap.
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Uloženie zlyhalo.';
      });
    }
  }

  /// Deletes [log] once the user confirms; there is no undo, because recording it again
  /// would attach the current rate instead of the original one.
  Future<void> _delete(WorkLog log) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Zmazať záznam?'),
        content: Text('${formatDay(log.day)} · ${formatMinutes(log.minutes)} · ${formatMoney(log.earnings)}'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Zrušiť')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Zmazať')),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(workLogApiProvider).delete(log.id);
      _closeWith('Záznam zmazaný.');
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Zmazanie zlyhalo.';
      });
    }
  }

  /// Refreshes everything Earnings feed into, closes the sheet and confirms with [message].
  void _closeWith(String message) {
    ref.invalidate(overviewProvider);
    ref.invalidate(workLogsProvider);
    ref.invalidate(plansProvider);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop();
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  /// Work is recorded after it is done: from a year back up to today, reaching further back
  /// only for an older work log being edited.
  Future<void> _pickDay() async {
    final today = ref.read(todayProvider);
    final yearBack = DateTime(today.year - 1, today.month, today.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: _day.isBefore(yearBack) ? _day : yearBack,
      lastDate: today,
    );
    if (picked != null) setState(() => _day = picked);
  }

  String get _dayLabel {
    final label = formatDay(_day);
    return _day == ref.read(todayProvider) ? 'Dnes, $label' : label;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final workedMinutes = _workedMinutes;
    // An edited log keeps the rate it was recorded with, so the preview uses that one.
    final rate = widget.existing?.hourlyRate ?? ref.watch(hourlyRateProvider).value;
    return Padding(
      key: const Key('work-log-sheet'),
      padding: EdgeInsets.fromLTRB(20, 0, 20, 28 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.existing == null ? 'Zapísať prácu' : 'Upraviť záznam',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.2),
                ),
              ),
              if (widget.existing != null)
                IconButton(
                  tooltip: 'Zmazať',
                  icon: const Icon(Icons.delete_outline),
                  color: colors.textSecondary,
                  onPressed: _saving ? null : () => _delete(widget.existing!),
                ),
              const SizedBox(width: 4),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: CalendarChip(label: _dayLabel, height: 36, onTap: _pickDay),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _StepColumn(
                big: _StepButton(key: const Key('minus-15'), label: '−15m', tooltip: 'O 15 minút menej', large: true, onPressed: _shorten(15)),
                small: _StepButton(key: const Key('minus-30'), label: '−30m', tooltip: 'O 30 minút menej', onPressed: _shorten(30)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _minutes == null ? '0 h' : _timeLabel(_minutes!),
                    key: const Key('work-log-time'),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.4,
                      height: 1,
                      color: _minutes == null ? colors.uncoveredRing : colors.text,
                      fontFeatures: tabularFigures,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _StepColumn(
                big: _StepButton(key: const Key('plus-15'), label: '+15m', tooltip: 'O 15 minút viac', large: true, onPressed: _lengthen(15)),
                small: _StepButton(key: const Key('plus-30'), label: '+30m', tooltip: 'O 30 minút viac', onPressed: _lengthen(30)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 22,
            child: workedMinutes != null && rate != null
                ? Text(
                    '= ${formatMoney(rate.earningsFor(workedMinutes))} pri ${formatMoney(rate.perHour)}/h',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: colors.earned),
                  )
                : null,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              for (final (index, hours) in _quickHours.indexed) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  child: _QuickChoice(
                    key: Key('quick-$hours'),
                    label: '$hours h',
                    selected: _minutes == hours * 60,
                    onPressed: () => setState(() => _minutes = hours * 60),
                  ),
                ),
              ],
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: colors.accent,
                    side: BorderSide(color: colors.accent),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Zrušiť'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                  onPressed: workedMinutes == null || _saving ? null : () => _save(workedMinutes),
                  child: const Text('Uložiť'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The time as large as the screen allows it: `6 h`, `6 h 15`, `45 min`.
String _timeLabel(int minutes) {
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  if (hours == 0) return '$rest min';
  if (rest == 0) return '$hours h';
  return '$hours h $rest';
}

/// The 15 minute button above the smaller 30 minute one, on either side of the time.
class _StepColumn extends StatelessWidget {
  const _StepColumn({required this.big, required this.small});

  final Widget big;
  final Widget small;

  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [big, const SizedBox(height: 8), small]);
}

/// −15m, −30m, +15m or +30m; the large ones are the usual step, the small ones still 44 dp.
class _StepButton extends StatelessWidget {
  const _StepButton({super.key, required this.label, required this.tooltip, required this.onPressed, this.large = false});

  final String label;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Tooltip(
      message: tooltip,
      child: SizedBox(
        width: large ? 68 : 56,
        height: large ? 60 : 44,
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            backgroundColor: large ? colors.card : colors.softButton,
            foregroundColor: large ? colors.text : colors.textSecondary,
            side: BorderSide(color: large ? colors.chipBorder : colors.cardBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(large ? 18 : 14)),
            textStyle: TextStyle(
              fontFamily: appFontFamily,
              fontSize: large ? 18 : 13,
              fontWeight: large ? FontWeight.w800 : FontWeight.w700,
            ),
          ),
          onPressed: onPressed,
          child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
        ),
      ),
    );
  }
}

/// One of the quick choices of whole hours; blue while it is the chosen time.
class _QuickChoice extends StatelessWidget {
  const _QuickChoice({super.key, required this.label, required this.selected, required this.onPressed});

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          backgroundColor: selected ? colors.accentFill : colors.softButton,
          foregroundColor: selected ? colors.onAccentFill : colors.text,
          side: BorderSide(color: selected ? colors.accentFill : colors.cardBorder),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontFamily: appFontFamily, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        onPressed: onPressed,
        child: FittedBox(fit: BoxFit.scaleDown, child: Text(label)),
      ),
    );
  }
}
