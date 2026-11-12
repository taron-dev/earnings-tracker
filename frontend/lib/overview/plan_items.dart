import 'package:flutter/material.dart';

import '../money/money_format.dart';
import 'plan_overview.dart';

/// The plan's items under ZÁKLAD and EXTRA with how far each is funded, then Unassigned
/// Earnings when there are any; shared by the overview and the plan detail.
List<Widget> planItemSections(BuildContext context, PlanOverview plan) {
  final textTheme = Theme.of(context).textTheme;
  return [
    ..._section(
      context,
      title: 'ZÁKLAD',
      status: plan.essentialsCovered ? 'pokrytý' : 'nepokrytý',
      items: plan.items.where((item) => item.essential),
    ),
    ..._section(context, title: 'EXTRA', items: plan.items.where((item) => !item.essential)),
    if (plan.unassignedEarnings.minorUnits > 0) ...[
      const SizedBox(height: 24),
      Text('Nepriradené ${formatMoney(plan.unassignedEarnings)}', style: textTheme.titleMedium),
      Text('Zárobok nad všetky položky, zatiaľ bez účelu.', style: textTheme.bodySmall),
    ],
  ];
}

/// A titled group of item rows; nothing at all when [items] is empty.
List<Widget> _section(BuildContext context, {required String title, String? status, required Iterable<OverviewItem> items}) {
  if (items.isEmpty) return const [];
  final style = Theme.of(context).textTheme.labelLarge;
  return [
    const SizedBox(height: 24),
    Row(
      children: [
        Expanded(child: Text(title, style: style)),
        if (status != null) Text(status, style: style),
      ],
    ),
    for (final item in items) _ItemRow(item: item),
  ];
}

/// One Budget Item: state icon, name, amount and a bar of how much is funded.
class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final OverviewItem item;

  @override
  Widget build(BuildContext context) {
    final (icon, amount) = switch (item.state) {
      CoverageState.covered => (Icons.check_circle, formatMoney(item.target)),
      CoverageState.inProgress => (Icons.timelapse, '${formatAmount(item.funded)} / ${formatMoney(item.target)}'),
      CoverageState.uncovered => (Icons.radio_button_unchecked, formatMoney(item.target)),
    };
    final progress = item.target.minorUnits == 0 ? 1.0 : item.funded.minorUnits / item.target.minorUnits;
    return Padding(
      key: Key('item-${item.position}'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(item.name)),
              Text(amount),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(value: progress),
        ],
      ),
    );
  }
}
