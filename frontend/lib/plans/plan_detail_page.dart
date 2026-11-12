import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../format/date_format.dart';
import '../money/money_format.dart';
import '../overview/plan_items.dart';
import '../overview/plan_overview.dart';
import 'plans_api.dart';
import 'plans_page.dart';

/// One plan from the plan list: what was earned in its window and how far that funded each
/// item. No next milestone or rate, which only make sense for today's plan in the overview.
class PlanDetailPage extends ConsumerWidget {
  const PlanDetailPage({super.key, required this.planId});

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plans = ref.watch(plansProvider);
    final plan = plans.value?.where((plan) => plan.planId == planId).firstOrNull;
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/plans')),
        title: Text(plan == null ? 'Plán' : formatWindow(plan.windowFrom, plan.windowTo)),
      ),
      body: plans.when(
        data: (_) => plan == null
            ? PlansMessage(
                title: 'Plán neexistuje.',
                action: TextButton(onPressed: () => context.go('/plans'), child: const Text('Na zoznam plánov')),
              )
            : _PlanBody(plan: plan),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => PlansMessage(
          title: 'Nepodarilo sa načítať plán. Skontroluj pripojenie.',
          action: TextButton(onPressed: () => ref.invalidate(plansProvider), child: const Text('Skúsiť znova')),
        ),
      ),
    );
  }
}

class _PlanBody extends StatelessWidget {
  const _PlanBody({required this.plan});

  final PlanOverview plan;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Zarobené ${formatMoney(plan.earnings)}', style: Theme.of(context).textTheme.headlineSmall),
        if (plan.items.isEmpty) ...[
          const SizedBox(height: 24),
          const Text('Plán nemá položky.'),
        ],
        ...planItemSections(context, plan),
      ],
    );
  }
}
