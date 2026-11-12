import 'package:earnings_tracker/overview/plan_overview.dart';
import 'package:earnings_tracker/overview/plan_overview_api.dart';

import 'overview_json.dart';

/// Answers with [result], or throws [error] when set, and remembers the days asked for.
class FakePlanOverviewApi implements PlanOverviewApi {
  FakePlanOverviewApi([OverviewResult? result]) : result = result ?? OverviewFound(PlanOverview.fromJson(overviewJson()));

  OverviewResult result;
  Object? error;
  final List<DateTime> requestedDays = [];

  @override
  Future<OverviewResult> current(DateTime today) async {
    requestedDays.add(today);
    if (error != null) throw error!;
    return result;
  }
}

OverviewResult overviewFrom(Map<String, dynamic> json) => OverviewFound(PlanOverview.fromJson(json));
