import '../money/money.dart';

/// How far Earnings have filled a Budget Item in the Funding Order.
enum CoverageState { covered, inProgress, uncovered }

/// One Budget Item of the plan with how much of it is funded.
class OverviewItem {
  const OverviewItem({
    required this.position,
    required this.name,
    required this.target,
    required this.funded,
    required this.state,
    required this.essential,
  });

  /// Index in the Funding Order; the Next Milestone refers to items by it.
  final int position;
  final String name;
  final Money target;
  final Money funded;
  final CoverageState state;

  /// Above the Essentials Line.
  final bool essential;

  factory OverviewItem.fromJson(Map<String, dynamic> json) => OverviewItem(
    position: json['position'] as int,
    name: json['name'] as String,
    target: Money.fromJson(json['target'] as Map<String, dynamic>),
    funded: Money.fromJson(json['funded'] as Map<String, dynamic>),
    state: switch (json['state'] as String) {
      'COVERED' => CoverageState.covered,
      'IN_PROGRESS' => CoverageState.inProgress,
      'UNCOVERED' => CoverageState.uncovered,
      final other => throw FormatException('Unknown coverage state', other),
    },
    essential: json['essential'] as bool,
  );
}

/// First item not yet covered and the work still needed for it at the current rate.
class NextMilestone {
  const NextMilestone({required this.position, required this.missing, required this.minutesNeeded});

  final int position;
  final Money missing;
  final int minutesNeeded;

  factory NextMilestone.fromJson(Map<String, dynamic> json) => NextMilestone(
    position: json['position'] as int,
    missing: Money.fromJson(json['missing'] as Map<String, dynamic>),
    minutesNeeded: json['minutesNeeded'] as int,
  );
}

/// Where a plan stands: `GET /api/plans/current/overview` for today's plan, and each plan of
/// `GET /api/plans` (there always without the next milestone).
class PlanOverview {
  const PlanOverview({
    required this.planId,
    required this.windowFrom,
    required this.windowTo,
    required this.essentialsCount,
    required this.earnings,
    required this.essentialsCovered,
    required this.items,
    required this.nextMilestone,
    required this.unassignedEarnings,
  });

  final String planId;

  /// Earning Window, both days included.
  final DateTime windowFrom;
  final DateTime windowTo;

  /// How many items, from the start of the Funding Order, lie above the Essentials Line.
  final int essentialsCount;
  final Money earnings;
  final bool essentialsCovered;
  final List<OverviewItem> items;

  /// Null when the plan has no items or all of them are covered.
  final NextMilestone? nextMilestone;
  final Money unassignedEarnings;

  factory PlanOverview.fromJson(Map<String, dynamic> json) {
    final window = json['window'] as Map<String, dynamic>;
    final milestone = json['nextMilestone'] as Map<String, dynamic>?;
    return PlanOverview(
      planId: json['planId'] as String,
      windowFrom: DateTime.parse(window['from'] as String),
      windowTo: DateTime.parse(window['to'] as String),
      essentialsCount: json['essentialsCount'] as int,
      earnings: Money.fromJson(json['earnings'] as Map<String, dynamic>),
      essentialsCovered: json['essentialsCovered'] as bool,
      items: [for (final item in json['items'] as List<dynamic>) OverviewItem.fromJson(item as Map<String, dynamic>)],
      nextMilestone: milestone == null ? null : NextMilestone.fromJson(milestone),
      unassignedEarnings: Money.fromJson(json['unassignedEarnings'] as Map<String, dynamic>),
    );
  }
}

/// What the overview endpoint answered for today.
sealed class OverviewResult {
  const OverviewResult();
}

class OverviewFound extends OverviewResult {
  const OverviewFound(this.overview);

  final PlanOverview overview;
}

/// No plan's Earning Window contains today (404).
class NoPlanForToday extends OverviewResult {
  const NoPlanForToday();
}

/// The user has no hourly rate yet, so the Next Milestone cannot be computed (409).
class HourlyRateNotSet extends OverviewResult {
  const HourlyRateNotSet();
}
