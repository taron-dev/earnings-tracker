import 'package:earnings_tracker/work_logs/work_log.dart';
import 'package:earnings_tracker/work_logs/work_log_api.dart';

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
}

WorkLog workLog(String id, String day, int minutes, String earnings) =>
    WorkLog.fromJson(workLogJson(id, day, minutes, earnings));
