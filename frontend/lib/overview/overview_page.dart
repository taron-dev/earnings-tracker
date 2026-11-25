import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_shell.dart';
import '../app/app_theme.dart';
import '../app/today.dart';
import '../app/ui_parts.dart';
import '../format/date_format.dart';
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
      appBar: AppBar(title: const _OverviewTitle(), actions: const [SettingsButton()]),
      body: ref.watch(overviewProvider).when(
            data: (result) => switch (result) {
              OverviewFound(:final overview) => _OverviewBody(overview: overview),
              NoPlanForToday() => _Message(
                  title: 'Dnešok nepatrí do žiadneho plánu.',
                  detail: 'Prácu môžeš zapisovať aj tak, započíta sa do plánu, ktorého okno bude dnešok obsahovať.',
                  action: FilledButton(onPressed: () => context.go('/plans/new'), child: const Text('Vytvoriť plán')),
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

/// The app's clock mark next to the tab name.
class _OverviewTitle extends StatelessWidget {
  const _OverviewTitle();

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(color: colors.accentFill, borderRadius: BorderRadius.circular(10)),
          child: Icon(Icons.schedule, size: 20, color: colors.onAccentFill),
        ),
        const SizedBox(width: 10),
        const Text('Prehľad'),
      ],
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
    final colors = AppColors.of(context);
    final rate = ref.watch(hourlyRateProvider).value;
    final window = formatWindowShort(overview.windowFrom, overview.windowTo);
    final daysLeft = daysLeftLabel(overview.windowTo, ref.watch(todayProvider));
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, fabClearance),
      children: [
        Column(
          children: [
            // The window opens the plan's detail, the way the rate opens settings.
            CalendarChip(
              key: const Key('overview-window'),
              label: '$window · $daysLeft',
              onTap: () => context.go('/plans/${overview.planId}'),
            ),
            const SizedBox(height: 14),
            Text(
              'Zarobené v tomto pláne',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              formatMoney(overview.earnings),
              key: const Key('overview-earnings'),
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.4,
                height: 1,
                fontFeatures: tabularFigures,
              ),
            ),
            if (rate != null)
              TextButton(
                onPressed: () => context.push('/settings'),
                style: TextButton.styleFrom(foregroundColor: colors.earned, minimumSize: const Size(0, 36)),
                child: Text(
                  'pri ${formatMoney(rate.perHour)}/h',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        _MilestoneCard(overview: overview),
        ...planItemSections(context, overview),
      ],
    );
  }
}

/// The work still needed for the next uncovered item, the number that motivates working; a full
/// blue card, the strongest spot on the screen.
class _MilestoneCard extends StatelessWidget {
  const _MilestoneCard({required this.overview});

  final PlanOverview overview;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final milestone = overview.nextMilestone;
    final item = milestone == null ? null : overview.items[milestone.position];
    final onFill = colors.onAccentFill;
    final secondary = onFill.withValues(alpha: 0.85);
    return Container(
      key: const Key('next-milestone'),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: colors.accentFill, borderRadius: BorderRadius.circular(24)),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: onFill, fontFeatures: tabularFigures),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Najbližší cieľ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondary)),
                ),
                if (item != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: onFill.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      item.essential ? 'ZÁKLAD' : 'EXTRA',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (milestone != null && item != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                        const SizedBox(height: 2),
                        Text(
                          'ešte ${formatMoney(milestone.missing)} z ${formatMoney(item.target)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: onFill.withValues(alpha: 0.9)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _WorkNeeded(minutes: milestone.minutesNeeded, secondary: secondary),
                ],
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.target.minorUnits == 0 ? 1.0 : item.funded.minorUnits / item.target.minorUnits,
                  minHeight: 8,
                  color: onFill,
                  backgroundColor: onFill.withValues(alpha: 0.25),
                ),
              ),
            ] else if (overview.items.isEmpty) ...[
              const Text('Plán nemá položky', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: onFill, foregroundColor: colors.accentFill),
                  onPressed: () => context.go('/plans/${overview.planId}/edit'),
                  child: const Text('Pridať položky'),
                ),
              ),
            ] else
              const Text('Všetko pokryté ✓', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

/// The missing work, largest on the card: `6 h 15` over `min práce`, `7 h` over `práce`,
/// `45` over `min práce`.
class _WorkNeeded extends StatelessWidget {
  const _WorkNeeded({required this.minutes, required this.secondary});

  final int minutes;
  final Color secondary;

  @override
  Widget build(BuildContext context) {
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    final (big, small) = switch ((hours, rest)) {
      (0, _) => ('$rest', 'min práce'),
      (_, 0) => ('$hours h', 'práce'),
      _ => ('$hours h $rest', 'min práce'),
    };
    return Column(
      key: const Key('milestone-time'),
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(big, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.6, height: 1)),
        const SizedBox(height: 2),
        Text(small, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: secondary)),
      ],
    );
  }
}
