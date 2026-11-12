import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../hourly_rate/hourly_rate_api.dart';
import '../work_logs/work_log_sheet.dart';

/// Bottom navigation between the overview and work log tabs; each tab keeps its own state.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Index of the plans branch in `appRoutes`.
  static const _plansTab = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Known without a rate means recording would fail, so "+" leads to setting one instead.
    final rateMissing = ref.watch(hourlyRateProvider).hasValue && ref.watch(hourlyRateProvider).value == null;
    // Recording work belongs to the overview and work log tabs, not to the plan list.
    final onPlans = navigationShell.currentIndex == _plansTab;
    return Scaffold(
      body: navigationShell,
      floatingActionButton: onPlans
          ? null
          : FloatingActionButton(
              heroTag: null,
              tooltip: 'Zapísať prácu',
              onPressed: () => rateMissing ? context.push('/settings') : showWorkLogSheet(context),
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: navigationShell.goBranch,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: 'Prehľad',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Záznamy',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_note_outlined),
            selectedIcon: Icon(Icons.event_note),
            label: 'Plány',
          ),
        ],
      ),
    );
  }
}
