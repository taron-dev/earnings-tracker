import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/app_theme.dart';
import '../app/today.dart';
import '../format/date_format.dart';
import '../money/money_format.dart';
import '../overview/plan_items.dart';
import '../overview/plan_overview.dart';
import '../overview/plan_overview_api.dart';
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
        actions: [
          // A finished plan stays as it was, a fact to reflect on (enforced only here, in the UI).
          if (plan != null && !plan.windowTo.isBefore(ref.watch(todayProvider)))
            IconButton(
              tooltip: 'Upraviť',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.go('/plans/${plan.planId}/edit'),
            ),
          if (plan != null)
            IconButton(
              tooltip: 'Zmazať',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, plan),
            ),
        ],
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

/// Deletes [plan] once the user confirms. Its Work Logs stay and count again as soon as a
/// plan covers their days.
Future<void> _delete(BuildContext context, WidgetRef ref, PlanOverview plan) async {
  final window = formatWindow(plan.windowFrom, plan.windowTo);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Zmazať plán $window?'),
      content: const Text('Záznamy práce z jeho okna ostanú a započítajú sa do plánu, ktorý ich dni neskôr pokryje.'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Zrušiť')),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Zmazať')),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await ref.read(plansApiProvider).delete(plan.planId);
  } catch (_) {
    messenger.showSnackBar(const SnackBar(content: Text('Zmazanie zlyhalo.')));
    return;
  }
  ref.invalidate(plansProvider);
  ref.invalidate(overviewProvider);
  if (context.mounted) context.go('/plans');
  messenger.showSnackBar(const SnackBar(content: Text('Plán zmazaný.')));
}

class _PlanBody extends StatelessWidget {
  const _PlanBody({required this.plan});

  final PlanOverview plan;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          'Zarobené ${formatMoney(plan.earnings)}',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.of(context).earned),
        ),
        if (plan.items.isEmpty) ...[
          const SizedBox(height: 24),
          const Text('Plán nemá položky.'),
        ],
        ...planItemSections(context, plan),
      ],
    );
  }
}
