import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../hourly_rate/hourly_rate_api.dart';
import '../work_logs/work_log_sheet.dart';
import 'app_theme.dart';

/// Diameter of the round "+" button.
const double fabSize = 60;

/// Bottom space a list needs so its last row can scroll out from under the floating "+" button:
/// the button and 16 above and below it.
const double fabClearance = fabSize + 2 * 16;

/// Corner radius of the floating navigation bar.
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
    final colors = AppColors.of(context);
    return Scaffold(
      body: navigationShell,
      floatingActionButton: onPlans
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: colors.fabShadow, blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: SizedBox.square(
                dimension: fabSize,
                child: FloatingActionButton(
                  heroTag: null,
                  tooltip: 'Zapísať prácu',
                  shape: const CircleBorder(),
                  elevation: 0,
                  highlightElevation: 0,
                  backgroundColor: colors.accentFill,
                  foregroundColor: colors.onAccentFill,
                  onPressed: () => rateMissing ? context.push('/settings') : showWorkLogSheet(context),
                  child: const Icon(Icons.add, size: 28),
                ),
              ),
            ),
      // Floats above the bottom edge with rounded corners, so on a wide window it reads as part of the
      // centered column rather than a strip cut off at its edges.
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(floatingNavigationRadius),
            boxShadow: [BoxShadow(color: colors.navigationShadow, blurRadius: 20, offset: const Offset(0, 6))],
          ),
          child: Material(
            key: const Key('floating-navigation'),
            color: colors.card,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(floatingNavigationRadius),
              side: BorderSide(color: colors.cardBorder),
            ),
            clipBehavior: Clip.antiAlias,
            child: NavigationBarTheme(
              data: _navigationTheme(colors),
              child: NavigationBar(
                height: 72,
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
                    icon: Icon(Icons.format_list_bulleted),
                    label: 'Záznamy',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.calendar_today_outlined),
                    selectedIcon: Icon(Icons.calendar_today),
                    label: 'Plány',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// No pill behind the active tab: its icon and label turn blue instead.
NavigationBarThemeData _navigationTheme(AppColors colors) {
  Color color(Set<WidgetState> states) => states.contains(WidgetState.selected) ? colors.accent : colors.textSecondary;
  return NavigationBarThemeData(
    indicatorColor: Colors.transparent,
    labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    iconTheme: WidgetStateProperty.resolveWith((states) => IconThemeData(color: color(states), size: 24)),
    labelTextStyle: WidgetStateProperty.resolveWith(
      (states) => TextStyle(
        fontFamily: appFontFamily,
        fontSize: 12,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w600,
        color: color(states),
      ),
    ),
  );
}
