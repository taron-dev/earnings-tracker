import '../money/money_format.dart';
import '../overview/plan_overview.dart';

/// One line about how a plan was funded: `1 480 / 2 650 € · základ ✗ · 1 z 5`. Essentials
/// are left out when the plan has none.
String planSummary(PlanOverview plan) {
  final items = plan.items;
  if (items.isEmpty) return 'Bez položiek';
  final funded = items.map((item) => item.funded).reduce((sum, amount) => sum.plus(amount));
  final target = items.map((item) => item.target).reduce((sum, amount) => sum.plus(amount));
  final covered = items.where((item) => item.state == CoverageState.covered).length;
  return [
    '${formatAmount(funded)} / ${formatMoney(target)}',
    if (plan.essentialsCount > 0) 'základ ${plan.essentialsCovered ? '✓' : '✗'}',
    '$covered z ${items.length}',
  ].join(' · ');
}
