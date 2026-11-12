import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/today.dart';
import '../format/date_format.dart';
import '../format/time_format.dart';
import '../hourly_rate/hourly_rate_api.dart';
import '../money/money_format.dart';
import '../overview/plan_overview_api.dart';
import 'work_log.dart';
import 'work_log_api.dart';

/// Opens the bottom sheet for recording work, today preselected, or for editing [existing].
Future<void> showWorkLogSheet(BuildContext context, {WorkLog? existing}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => WorkLogSheet(existing: existing),
);

/// Day, worked time and a live earnings preview; one tap on a quick choice for a usual day.
class WorkLogSheet extends ConsumerStatefulWidget {
  const WorkLogSheet({super.key, this.existing});

  /// The work log being edited; null when recording a new one.
  final WorkLog? existing;

  @override
  ConsumerState<WorkLogSheet> createState() => _WorkLogSheetState();
}

class _WorkLogSheetState extends ConsumerState<WorkLogSheet> {
  late DateTime _day = widget.existing?.day ?? ref.read(todayProvider);
  late final _hours = TextEditingController(text: widget.existing == null ? '' : '${widget.existing!.minutes ~/ 60}');
  late final _minutes = TextEditingController(text: widget.existing == null ? '' : '${widget.existing!.minutes % 60}');

  static const _quickHours = [1, 2, 4, 6, 8];

  @override
  void dispose() {
    _hours.dispose();
    _minutes.dispose();
    super.dispose();
  }

  /// Total worked minutes from both fields (an empty field counts as zero), or null when
  /// they do not form 1 minute to 24 hours, the range of a Work Log.
  int? get _workedMinutes {
    final hours = _hours.text.trim().isEmpty ? 0 : int.tryParse(_hours.text.trim());
    final minutes = _minutes.text.trim().isEmpty ? 0 : int.tryParse(_minutes.text.trim());
    if (hours == null || minutes == null || hours < 0 || minutes < 0 || minutes > 59) return null;
    final total = hours * 60 + minutes;
    return total >= 1 && total <= 24 * 60 ? total : null;
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

  void _fillHours(int hours) {
    setState(() {
      _hours.text = '$hours';
      _minutes.text = '0';
    });
  }

  String get _dayLabel {
    final label = formatDay(_day);
    return _day == ref.read(todayProvider) ? 'dnes, $label' : label;
  }

  @override
  Widget build(BuildContext context) {
    final workedMinutes = _workedMinutes;
    // An edited log keeps the rate it was recorded with, so the preview uses that one.
    final rate = widget.existing?.hourlyRate ?? ref.watch(hourlyRateProvider).value;
    return Padding(
      key: const Key('work-log-sheet'),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.existing == null ? 'Zapísať prácu' : 'Upraviť záznam',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (widget.existing != null)
                IconButton(
                  tooltip: 'Zmazať',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _saving ? null : () => _delete(widget.existing!),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today, size: 18),
              label: Text(_dayLabel),
              onPressed: _pickDay,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final hours in _quickHours) ActionChip(label: Text('$hours h'), onPressed: () => _fillHours(hours)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _numberField(_hours, 'Hodiny', 'h')),
              const SizedBox(width: 12),
              Expanded(child: _numberField(_minutes, 'Minúty', 'min')),
            ],
          ),
          const SizedBox(height: 8),
          if (workedMinutes != null && rate != null)
            Text('= ${formatMoney(rate.earningsFor(workedMinutes))} pri ${formatMoney(rate.perHour)} / h'),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Zrušiť')),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: workedMinutes == null || _saving ? null : () => _save(workedMinutes),
                child: const Text('Uložiť'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label, String suffix) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(labelText: label, suffixText: suffix, border: const OutlineInputBorder()),
    onChanged: (_) => setState(() {}),
  );
}
