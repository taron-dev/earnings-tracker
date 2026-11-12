import 'package:earnings_tracker/overview/plan_overview.dart';
import 'package:earnings_tracker/plans/plan_draft.dart';
import 'package:earnings_tracker/plans/plans_api.dart';

import 'overview_json.dart';

/// Keeps plans in memory, newly written ones unfunded, and remembers what was written.
class FakePlansApi implements PlansApi {
  FakePlansApi([List<PlanOverview>? plans]) : plans = plans ?? [PlanOverview.fromJson(overviewJson(nextMilestone: null))];

  List<PlanOverview> plans;

  /// Thrown by [list] when set.
  Object? error;

  /// Thrown by [create], [update] and [delete] when set.
  Object? writeError;
  int requests = 0;

  final List<PlanDraft> created = [];
  final List<(String, PlanDraft)> updated = [];
  final List<String> deleted = [];

  @override
  Future<List<PlanOverview>> list() async {
    requests++;
    if (error != null) throw error!;
    return plans;
  }

  @override
  Future<String> create(PlanDraft draft) async {
    if (writeError != null) throw writeError!;
    created.add(draft);
    final id = 'created-${created.length}';
    plans = [_unfunded(id, draft), ...plans];
    return id;
  }

  @override
  Future<void> update(String id, PlanDraft draft) async {
    if (writeError != null) throw writeError!;
    updated.add((id, draft));
    plans = [for (final plan in plans) plan.planId == id ? _unfunded(id, draft) : plan];
  }

  @override
  Future<void> delete(String id) async {
    if (writeError != null) throw writeError!;
    deleted.add(id);
    plans = plans.where((plan) => plan.planId != id).toList();
  }

  /// [draft] as the server would list it before any work in its window.
  static PlanOverview _unfunded(String id, PlanDraft draft) {
    final json = draft.toJson();
    final window = json['window'] as Map<String, dynamic>;
    return PlanOverview.fromJson(overviewJson(
      planId: id,
      window: (window['from'] as String, window['to'] as String),
      essentialsCount: draft.essentialsCount,
      items: [
        for (final (index, item) in draft.items.indexed)
          itemJson(index, item.name, item.target.toJson()['amount'] as String, '0.00', 'UNCOVERED',
              essential: index < draft.essentialsCount),
      ],
      essentialsCovered: draft.essentialsCount == 0,
      nextMilestone: null,
      earnings: '0.00',
    ));
  }
}
