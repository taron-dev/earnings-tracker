import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../api/iso_date.dart';
import '../app/today.dart';
import '../overview/plan_overview.dart';
import '../overview/plan_overview_api.dart';
import 'work_log.dart';

/// `/api/work-logs`.
class WorkLogApi {
  WorkLogApi(this._dio);

  final Dio _dio;

  /// Work logs dated between [from] and [to], both included, newest day first.
  Future<List<WorkLog>> list(DateTime from, DateTime to) async {
    final response = await _dio.get<List<dynamic>>(
      '/api/work-logs',
      queryParameters: {'from': isoDate(from), 'to': isoDate(to)},
    );
    return [for (final log in response.data!) WorkLog.fromJson(log as Map<String, dynamic>)];
  }
}

final workLogApiProvider = Provider((ref) => WorkLogApi(ref.watch(apiClientProvider)));

/// Which days the work log tab shows.
class WorkLogRange {
  const WorkLogRange({required this.from, required this.to, required this.isPlanWindow, required this.todayOutsidePlans});

  final DateTime from;
  final DateTime to;

  /// The Earning Window of today's plan, rather than the last 30 days.
  final bool isPlanWindow;

  /// No plan contains today (as opposed to the window being unknown for lack of a rate).
  final bool todayOutsidePlans;
}

/// The window of today's plan, or the last 30 days when there is no plan or no rate yet.
final workLogRangeProvider = FutureProvider<WorkLogRange>((ref) async {
  final today = ref.watch(todayProvider);
  final result = await ref.watch(overviewProvider.future);
  if (result case OverviewFound(:final overview)) {
    return WorkLogRange(from: overview.windowFrom, to: overview.windowTo, isPlanWindow: true, todayOutsidePlans: false);
  }
  return WorkLogRange(
    from: DateTime(today.year, today.month, today.day - 29),
    to: today,
    isPlanWindow: false,
    todayOutsidePlans: result is NoPlanForToday,
  );
});

/// Work logs in [workLogRangeProvider]; invalidate after recording, editing or deleting one.
final workLogsProvider = FutureProvider<List<WorkLog>>((ref) async {
  final range = await ref.watch(workLogRangeProvider.future);
  return ref.watch(workLogApiProvider).list(range.from, range.to);
});
