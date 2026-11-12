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

  /// Ids, days and minutes passed to [update], in order.
  final List<(String, DateTime, int)> updated = [];
  final List<String> deleted = [];
  bool failDeleting = false;

  @override
  Future<WorkLog> update(String id, DateTime day, int minutes) async {
    if (failSaving) throw Exception('backend down');
    updated.add((id, day, minutes));
    final original = logs.firstWhere((log) => log.id == id);
    final log = WorkLog(
      id: id,
      day: day,
      minutes: minutes,
      hourlyRate: original.hourlyRate,
      earnings: original.hourlyRate.earningsFor(minutes),
    );
    logs = [for (final each in logs) each.id == id ? log : each];
    return log;
  }

  @override
  Future<void> delete(String id) async {
    if (failDeleting) throw Exception('backend down');
    deleted.add(id);
    logs = logs.where((log) => log.id != id).toList();
  }
}

WorkLog workLog(String id, String day, int minutes, String earnings) =>
    WorkLog.fromJson(workLogJson(id, day, minutes, earnings));
