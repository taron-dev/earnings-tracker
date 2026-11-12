import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../format/date_format.dart';
import '../settings/settings_page.dart';
import 'plan_summary.dart';
import 'plans_api.dart';

/// All plans, newest first, each with one line on how it was funded.
class PlansPage extends ConsumerWidget {
  const PlansPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plány'), actions: const [SettingsButton()]),
      floatingActionButton: FloatingActionButton.extended(
        // No hero: the shell's own button can be in the same route during a tab switch.
        heroTag: null,
        icon: const Icon(Icons.add),
        label: const Text('Nový plán'),
        onPressed: () => context.go('/plans/new'),
      ),
      body: ref.watch(plansProvider).when(
            data: (plans) => plans.isEmpty
                ? const PlansMessage(title: 'Zatiaľ nemáš žiadny plán.')
                : ListView(
                    padding: const EdgeInsets.only(bottom: 88),
                    children: [
                      for (final plan in plans)
                        ListTile(
                          key: Key('plan-${plan.planId}'),
                          title: Text(formatWindow(plan.windowFrom, plan.windowTo)),
                          subtitle: Text(planSummary(plan)),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => context.go('/plans/${plan.planId}'),
                        ),
                    ],
                  ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => PlansMessage(
              title: 'Nepodarilo sa načítať plány. Skontroluj pripojenie.',
              action: TextButton(onPressed: () => ref.invalidate(plansProvider), child: const Text('Skúsiť znova')),
            ),
          ),
    );
  }
}

/// A centered explanation of why there is nothing to show, with an optional way out.
class PlansMessage extends StatelessWidget {
  const PlansMessage({super.key, required this.title, this.action});

  final String title;
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
            if (action != null) ...[const SizedBox(height: 16), action!],
          ],
        ),
      ),
    );
  }
}
