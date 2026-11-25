import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/app_shell.dart';
import '../app/app_theme.dart';
import '../app/today.dart';
import '../app/ui_parts.dart';
import '../format/date_format.dart';
import '../format/time_format.dart';
import '../money/money.dart';
import '../money/money_format.dart';
import '../overview/plan_overview_api.dart';
import '../settings/settings_page.dart';
import 'work_log.dart';
import 'work_log_api.dart';
import 'work_log_sheet.dart';

/// Work logs of today's plan, newest first, with their total.
class WorkLogsPage extends ConsumerWidget {
  const WorkLogsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(workLogRangeProvider).value;
    return Scaffold(
      appBar: AppBar(title: const Text('Záznamy'), actions: const [SettingsButton()]),
      body: ref.watch(workLogsProvider).when(
            data: (logs) => _WorkLogList(range: range!, logs: logs),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Nepodarilo sa načítať záznamy. Skontroluj pripojenie.', textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // The range comes from the overview, so reload it too when that is what failed.
                      if (ref.read(overviewProvider).hasError) ref.invalidate(overviewProvider);
                      ref.invalidate(workLogsProvider);
                    },
                    child: const Text('Skúsiť znova'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}

String _time(List<WorkLog> logs) => formatMinutes(logs.fold(0, (sum, log) => sum + log.minutes));

Money _earnings(List<WorkLog> logs) => logs.map((log) => log.earnings).reduce((a, b) => a.plus(b));

class _WorkLogList extends ConsumerWidget {
  const _WorkLogList({required this.range, required this.logs});

  final WorkLogRange range;
  final List<WorkLog> logs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppColors.of(context);
    final today = ref.watch(todayProvider);
    // Logs come newest first, so the weeks do too.
    final weeks = <DateTime, List<WorkLog>>{};
    for (final log in logs) {
      weeks.putIfAbsent(weekStart(log.day), () => []).add(log);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, fabClearance),
      children: [
        if (range.todayOutsidePlans) ...[
          Text(
            'Dnešok nepatrí do žiadneho plánu, zobrazujem posledných 30 dní.',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
          const SizedBox(height: 12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: logs.isEmpty
                  ? const Text('Zatiaľ žiadne záznamy.', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _time(logs),
                          key: const Key('work-logs-time'),
                          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1.1),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${formatMoney(_earnings(logs))} zarobené',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.earned),
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 12),
            CalendarChip(label: formatWindowShort(range.from, range.to), accent: true),
          ],
        ),
        for (final MapEntry(key: monday, value: weekLogs) in weeks.entries) ...[
          const SizedBox(height: 16),
          _Week(label: weekLabel(monday, today), logs: weekLogs),
        ],
      ],
    );
  }
}

/// One Monday to Sunday week: its label and subtotal above a card of its work logs.
class _Week extends StatelessWidget {
  const _Week({required this.label, required this.logs});

  final String label;
  final List<WorkLog> logs;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
              Text(
                '${_time(logs)} · ${formatMoney(_earnings(logs))}',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.textSecondary),
              ),
            ],
          ),
        ),
        Card(
          clipBehavior: Clip.antiAlias,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                for (final (index, log) in logs.indexed) ...[
                  if (index > 0) const Divider(indent: 16, endIndent: 16),
                  _WorkLogRow(log: log),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Day, earnings and time of one work log; tapping it opens the edit sheet.
class _WorkLogRow extends StatelessWidget {
  const _WorkLogRow({required this.log});

  final WorkLog log;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return InkWell(
      key: Key('work-log-${log.id}'),
      onTap: () => showWorkLogSheet(context, existing: log),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Text(
                      weekdayAbbreviation(log.day).toUpperCase(),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: colors.textSecondary, height: 1.1),
                    ),
                    Text('${log.day.day}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, height: 1.1)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(formatMoney(log.earnings), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: colors.pill, borderRadius: BorderRadius.circular(10)),
                child: Text(formatMinutes(log.minutes), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 20, color: colors.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}
