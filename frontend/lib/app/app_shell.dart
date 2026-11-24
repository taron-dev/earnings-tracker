import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../hourly_rate/hourly_rate_api.dart';
import '../work_logs/work_log_sheet.dart';

/// Bottom space a list needs so its last row can scroll out from under a floating action button:
/// 56 for the button and 16 above and below it.
const double fabClearance = 88;

/// Corner radius of the floating navigation bar (the Material 3 "extra large" shape).
const double floatingNavigationRadius = 28;

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
      // Floats above the bottom edge with rounded corners, so on a wide window it reads as part of the
      // centered column rather than a strip cut off at its edges.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Material(
          key: const Key('floating-navigation'),
          elevation: 3,
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(floatingNavigationRadius),
          clipBehavior: Clip.antiAlias,
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
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
        ),
      ),
    );
  }
}
