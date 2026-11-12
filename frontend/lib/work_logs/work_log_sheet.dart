import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/today.dart';
import '../format/date_format.dart';
import '../format/time_format.dart';
import '../hourly_rate/hourly_rate_api.dart';
import '../money/money_format.dart';
import '../overview/plan_overview_api.dart';
import 'work_log_api.dart';

/// Opens the bottom sheet for recording work, today preselected.
Future<void> showWorkLogSheet(BuildContext context) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => const WorkLogSheet(),
);

/// Day, worked time and a live earnings preview; one tap on a quick choice for a usual day.
class WorkLogSheet extends ConsumerStatefulWidget {
  const WorkLogSheet({super.key});

  @override
  ConsumerState<WorkLogSheet> createState() => _WorkLogSheetState();
}

class _WorkLogSheetState extends ConsumerState<WorkLogSheet> {
  late DateTime _day = ref.read(todayProvider);
  final _hours = TextEditingController();
  final _minutes = TextEditingController();

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
      final log = await ref.read(workLogApiProvider).record(_day, minutes);
      ref.invalidate(overviewProvider);
      ref.invalidate(workLogsProvider);
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text('Zapísané ${formatMinutes(log.minutes)} · ${formatMoney(log.earnings)}')),
      );
    } catch (_) {
      // The sheet stays open with what was typed, so saving again is one tap.
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Uloženie zlyhalo.';
      });
    }
  }

  /// Work is recorded after it is done: from a year back up to today.
  Future<void> _pickDay() async {
    final today = ref.read(todayProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: _day,
      firstDate: DateTime(today.year - 1, today.month, today.day),
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
    final rate = ref.watch(hourlyRateProvider).value;
    return Padding(
      key: const Key('work-log-sheet'),
      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Zapísať prácu', style: Theme.of(context).textTheme.titleLarge),
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
