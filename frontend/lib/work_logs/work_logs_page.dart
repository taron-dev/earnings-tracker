import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../format/date_format.dart';
import '../format/time_format.dart';
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
      appBar: AppBar(title: const Text('Záznamy práce'), actions: const [SettingsButton()]),
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

String _total(List<WorkLog> logs) {
  final minutes = logs.fold(0, (sum, log) => sum + log.minutes);
  final earnings = logs.map((log) => log.earnings).reduce((a, b) => a.plus(b));
  return 'Spolu ${formatMinutes(minutes)} · ${formatMoney(earnings)}';
}

class _WorkLogList extends StatelessWidget {
  const _WorkLogList({required this.range, required this.logs});

  final WorkLogRange range;
  final List<WorkLog> logs;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (range.todayOutsidePlans) ...[
          Text('Dnešok nepatrí do žiadneho plánu, zobrazujem posledných 30 dní.', style: textTheme.bodySmall),
          const SizedBox(height: 8),
        ],
        Text(formatWindow(range.from, range.to), style: textTheme.titleMedium),
        if (logs.isEmpty)
          const Padding(padding: EdgeInsets.only(top: 24), child: Text('Zatiaľ žiadne záznamy.'))
        else ...[
          Text(_total(logs)),
          const Divider(height: 24),
        ],
        for (final log in logs)
          InkWell(
            key: Key('work-log-${log.id}'),
            onTap: () => showWorkLogSheet(context, existing: log),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(width: 96, child: Text(formatDay(log.day))),
                  Expanded(child: Text(formatMinutes(log.minutes))),
                  Text(formatMoney(log.earnings)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
