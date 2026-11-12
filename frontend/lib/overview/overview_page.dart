import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/today.dart';
import '../format/date_format.dart';
import '../format/time_format.dart';
import '../hourly_rate/hourly_rate_api.dart';
import '../money/money_format.dart';
import '../settings/settings_page.dart';
import 'plan_items.dart';
import 'plan_overview.dart';
import 'plan_overview_api.dart';

/// Where today's plan stands: what is covered and how many hours to the next milestone.
class OverviewPage extends ConsumerWidget {
  const OverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prehľad'), actions: const [SettingsButton()]),
      body: ref.watch(overviewProvider).when(
            data: (result) => switch (result) {
              OverviewFound(:final overview) => _OverviewBody(overview: overview),
              NoPlanForToday() => const _Message(
                  title: 'Dnešok nepatrí do žiadneho plánu.',
                  detail: 'Vytváranie plánov príde čoskoro. Prácu môžeš zapisovať aj tak, '
                      'započíta sa do plánu, ktorého okno bude dnešok obsahovať.',
                ),
              HourlyRateNotSet() => _Message(
                  title: 'Najprv nastav svoju hodinovú sadzbu.',
                  action: FilledButton(onPressed: () => context.push('/settings'), child: const Text('Nastaviť sadzbu')),
                ),
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _Message(
              title: 'Nepodarilo sa načítať prehľad. Skontroluj pripojenie.',
              action: TextButton(onPressed: () => ref.invalidate(overviewProvider), child: const Text('Skúsiť znova')),
            ),
          ),
    );
  }
}

/// A centered explanation of why there is nothing to show, with an optional way out.
class _Message extends StatelessWidget {
  const _Message({required this.title, this.detail, this.action});

  final String title;
  final String? detail;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
            if (detail != null) ...[const SizedBox(height: 8), Text(detail!, textAlign: TextAlign.center)],
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}

class _OverviewBody extends ConsumerWidget {
  const _OverviewBody({required this.overview});

  final PlanOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final rate = ref.watch(hourlyRateProvider).value;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // The window opens the plan's detail, the way the rate opens settings.
        Align(
          alignment: Alignment.centerLeft,
          child: InkWell(
            key: const Key('overview-window'),
            onTap: () => context.go('/plans/${overview.planId}'),
            child: Text(formatWindow(overview.windowFrom, overview.windowTo), style: textTheme.titleMedium),
          ),
        ),
        Text(daysLeftLabel(overview.windowTo, ref.watch(todayProvider)), style: textTheme.bodySmall),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text('Zarobené ${formatMoney(overview.earnings)}', style: textTheme.headlineSmall)),
            if (rate != null)
              TextButton(
                onPressed: () => context.push('/settings'),
                child: Text('${formatMoney(rate.perHour)} / h', style: textTheme.bodySmall),
              ),
          ],
        ),
        const SizedBox(height: 16),
        _MilestoneCard(overview: overview),
        ...planItemSections(context, overview),
      ],
    );
  }
}

/// The hours still needed for the next uncovered item, the number that motivates working.
class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.overview});

  final PlanOverview overview;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final milestone = overview.nextMilestone;
    return Card.filled(
      key: const Key('next-milestone'),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Najbližší cieľ', style: textTheme.labelLarge),
            const SizedBox(height: 4),
            if (milestone != null) ...[
              Text(overview.items[milestone.position].name, style: textTheme.titleLarge),
              Text('ešte ${formatMoney(milestone.missing)} · ${formatMinutes(milestone.minutesNeeded)}'),
            ] else if (overview.items.isEmpty)
              Text('Plán nemá položky', style: textTheme.titleLarge)
            else
              Text('Všetko pokryté ✓', style: textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}
