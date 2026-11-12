import 'package:earnings_tracker/overview/plan_overview.dart';
import 'package:earnings_tracker/plans/plans_api.dart';

import 'overview_json.dart';

/// Answers with [plans], or throws [error] when set, and counts the requests.
class FakePlansApi implements PlansApi {
  FakePlansApi([List<PlanOverview>? plans]) : plans = plans ?? [PlanOverview.fromJson(overviewJson(nextMilestone: null))];

  List<PlanOverview> plans;
  Object? error;
  int requests = 0;

  @override
  Future<List<PlanOverview>> list() async {
    requests++;
    if (error != null) throw error!;
    return plans;
  }
}
