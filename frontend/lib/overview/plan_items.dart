import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/ui_parts.dart';
import '../money/money_format.dart';
import 'plan_overview.dart';

/// The plan's items in a Základ and an Extra card with how far each is funded, then Unassigned
/// Earnings when there are any; shared by the overview and the plan detail. Each widget is
/// preceded by its own spacing, so the list can follow other content directly.
List<Widget> planItemSections(BuildContext context, PlanOverview plan) {
  final colors = AppColors.of(context);
  final essentials = plan.items.where((item) => item.essential).toList();
  final extras = plan.items.where((item) => !item.essential).toList();
  return [
    if (essentials.isNotEmpty) ...[
      const SizedBox(height: 16),
      _SectionCard(key: const Key('section-essentials'), title: 'Základ', covered: plan.essentialsCovered, items: essentials),
    ],
    if (extras.isNotEmpty) ...[
      const SizedBox(height: 16),
      _SectionCard(
        key: const Key('section-extras'),
        title: 'Extra',
        covered: extras.every((item) => item.state == CoverageState.covered),
        items: extras,
      ),
    ],
    if (plan.unassignedEarnings.minorUnits > 0) ...[
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nepriradené ${formatMoney(plan.unassignedEarnings)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.earned),
              ),
              const SizedBox(height: 2),
              Text(
                'Zárobok nad všetky položky, zatiaľ bez účelu.',
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    ],
  ];
}

/// A card of item rows under a title, with a green chip once all of them are covered and a count
/// of covered items until then.
class _SectionCard extends StatelessWidget {
  const _SectionCard({super.key, required this.title, required this.covered, required this.items});

  final String title;
  final bool covered;
  final List<OverviewItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final coveredCount = items.where((item) => item.state == CoverageState.covered).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                  if (covered)
                    const CoveredChip()
                  else
                    Text(
                      '$coveredCount z ${items.length} pokrytých',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
                    ),
                ],
              ),
            ),
            for (final item in items) _ItemRow(item: item),
          ],
        ),
      ),
    );
  }
}

/// One Budget Item: a green check when covered, a blue ring and a bar while in progress, a gray
/// ring before any money reached it.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OverviewItem item;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final inProgress = item.state == CoverageState.inProgress;
    final nameStyle = TextStyle(fontSize: 15, fontWeight: inProgress ? FontWeight.w600 : FontWeight.w500);
    final amountStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colors.textSecondary);
    final row = Row(
      children: [
        _StateMark(state: item.state),
        const SizedBox(width: 12),
        Expanded(child: Text(item.name, style: nameStyle)),
        if (inProgress)
          Text.rich(
            TextSpan(
              text: formatAmount(item.funded),
              style: const TextStyle(fontWeight: FontWeight.w700),
              children: [
                TextSpan(
                  text: ' / ${formatMoney(item.target)}',
                  style: TextStyle(fontWeight: FontWeight.w500, color: colors.textSecondary),
                ),
              ],
            ),
            style: const TextStyle(fontSize: 15),
          )
        else
          Text(formatMoney(item.target), style: amountStyle),
      ],
    );
    return DecoratedBox(
      key: Key('item-${item.position}'),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: colors.divider))),
      child: inProgress
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  row,
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 36),
                    child: LinearProgressIndicator(
                      value: item.target.minorUnits == 0 ? 1.0 : item.funded.minorUnits / item.target.minorUnits,
                    ),
                  ),
                ],
              ),
            )
          : SizedBox(height: 44, child: row),
    );
  }
}

/// The 24 px circle at the start of an item row.
class _StateMark extends StatelessWidget {
  const _StateMark({required this.state});

  final CoverageState state;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return switch (state) {
      CoverageState.covered => Container(
        key: const Key('mark-covered'),
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: colors.earnedContainer, shape: BoxShape.circle),
        child: Icon(Icons.check, size: 14, color: colors.earned),
      ),
      CoverageState.inProgress => _ring(colors.accent, const Key('mark-in-progress')),
      CoverageState.uncovered => _ring(colors.uncoveredRing, const Key('mark-uncovered')),
    };
  }

  Widget _ring(Color color, Key key) => Container(
    key: key,
    width: 24,
    height: 24,
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 2)),
  );
}
