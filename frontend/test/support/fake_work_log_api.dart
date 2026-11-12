import 'package:earnings_tracker/money/hourly_rate.dart';
import 'package:earnings_tracker/money/money.dart';
import 'package:earnings_tracker/work_logs/work_log.dart';
import 'package:earnings_tracker/work_logs/work_log_api.dart';

import 'overview_json.dart';
import 'work_log_json.dart';

/// Keeps work logs in memory and remembers which ranges were asked for.
class FakeWorkLogApi implements WorkLogApi {
  FakeWorkLogApi([List<WorkLog>? logs]) : logs = logs ?? [];

  List<WorkLog> logs;
  Object? error;
  final List<(DateTime, DateTime)> requestedRanges = [];

  @override
  Future<List<WorkLog>> list(DateTime from, DateTime to) async {
    requestedRanges.add((from, to));
    if (error != null) throw error!;
    return logs;
  }

  /// Days and minutes passed to [record], in order.
  final List<(DateTime, int)> recorded = [];
  bool failSaving = false;

  @override
  Future<WorkLog> record(DateTime day, int minutes) async {
    if (failSaving) throw Exception('backend down');
    recorded.add((day, minutes));
    // Like the server: the current rate (40 EUR/h in tests) is attached to the new log.
    final rate = HourlyRate(Money.fromJson(eurJson('40.00')));
    final log = WorkLog(
      id: 'new-${recorded.length}',
      day: day,
      minutes: minutes,
      hourlyRate: rate,
      earnings: rate.earningsFor(minutes),
    );
    logs = [log, ...logs];
    return log;
  }
}

WorkLog workLog(String id, String day, int minutes, String earnings) =>
    WorkLog.fromJson(workLogJson(id, day, minutes, earnings));
