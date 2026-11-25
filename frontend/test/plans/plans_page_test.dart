import 'package:earnings_tracker/overview/plan_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_plans_api.dart';
import '../support/overview_json.dart';
import '../support/pump_app.dart';

/// Slovak formatting separates thousands and the currency sign with a no-break space.
const nbsp = ' ';

const octoberId = '6f1c2d4e-0000-4000-8000-000000000010';

/// A finished October plan: taxes covered, vacation left uncovered, 100 € beyond the items.
PlanOverview october() => PlanOverview.fromJson(overviewJson(
      planId: octoberId,
      window: ('2026-10-01', '2026-10-31'),
      essentialsCount: 1,
      items: [
        itemJson(0, 'Dane a odvody', '900.00', '900.00', 'COVERED', essential: true),
        itemJson(1, 'Dovolenka', '400.00', '200.00', 'IN_PROGRESS', essential: false),
      ],
      essentialsCovered: true,
      nextMilestone: null,
      earnings: '1100.00',
    ));

PlanOverview november() => PlanOverview.fromJson(overviewJson(nextMilestone: null));

void main() {
  testWidgets('lists plans newest first with how each was funded', (tester) async {
    await pumpApp(tester, location: '/plans', plansApi: FakePlansApi([november(), october()]));

    expect(find.widgetWithText(AppBar, 'Plány'), findsOneWidget);
    final novemberTile = find.byKey(const Key('plan-$defaultPlanId'));
    final octoberTile = find.byKey(const Key('plan-$octoberId'));
    expect(find.descendant(of: novemberTile, matching: find.text('1. – 30. 11. 2026')), findsOneWidget);
    expect(find.descendant(of: novemberTile, matching: find.text('1${nbsp}480 / 2${nbsp}650$nbsp€ · základ ✗ · 1 z 5')),
        findsOneWidget);
    expect(find.descendant(of: octoberTile, matching: find.text('1. – 31. 10. 2026')), findsOneWidget);
    expect(find.descendant(of: octoberTile, matching: find.text('1${nbsp}100 / 1${nbsp}300$nbsp€ · základ ✓ · 1 z 2')),
        findsOneWidget);
    expect(tester.getTopLeft(novemberTile).dy, lessThan(tester.getTopLeft(octoberTile).dy));
  });

  testWidgets('offers no work recording on the plan list', (tester) async {
    await pumpApp(tester, location: '/plans');

    expect(find.byTooltip('Zapísať prácu'), findsNothing);
  });

  testWidgets('says when there are no plans yet', (tester) async {
    await pumpApp(tester, location: '/plans', plansApi: FakePlansApi([]));

    expect(find.text('Zatiaľ nemáš žiadny plán.'), findsOneWidget);
  });

  testWidgets('offers a retry when loading fails', (tester) async {
    final api = FakePlansApi()..error = Exception('backend down');
    await pumpApp(tester, location: '/plans', plansApi: api);

    expect(find.text('Nepodarilo sa načítať plány. Skontroluj pripojenie.'), findsOneWidget);
    api.error = null;
    await tester.tap(find.text('Skúsiť znova'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('plan-$defaultPlanId')), findsOneWidget);
  });

  testWidgets('opens a past plan with its earnings and items but no milestone or rate', (tester) async {
    final router = await pumpApp(tester, location: '/plans', plansApi: FakePlansApi([november(), october()]));

    await tester.tap(find.byKey(const Key('plan-$octoberId')));
    await tester.pumpAndSettle();

    expect(currentPath(router), '/plans/$octoberId');
    expect(find.widgetWithText(AppBar, '1. – 31. 10. 2026'), findsOneWidget);
    expect(find.text('Zarobené 1${nbsp}100$nbsp€'), findsOneWidget);
    expect(find.text('Základ'), findsOneWidget);
    expect(find.text('Pokrytý'), findsOneWidget);
    expect(find.text('Extra'), findsOneWidget);
    expect(find.descendant(of: find.byKey(const Key('item-1')), matching: find.text('200 / 400$nbsp€', findRichText: true)), findsOneWidget);
    expect(find.text('Nepriradené 100$nbsp€'), findsNothing);
    expect(find.byKey(const Key('next-milestone')), findsNothing);
    expect(find.textContaining('€/h'), findsNothing);
  });

  testWidgets('shows unassigned earnings of a plan', (tester) async {
    final funded = PlanOverview.fromJson(overviewJson(
      planId: octoberId,
      essentialsCount: 0,
      items: [itemJson(0, 'Dovolenka', '200.00', '200.00', 'COVERED', essential: false)],
      essentialsCovered: true,
      nextMilestone: null,
      earnings: '300.00',
      unassigned: '100.00',
    ));
    await pumpApp(tester, location: '/plans/$octoberId', plansApi: FakePlansApi([funded]));

    expect(find.text('Nepriradené 100$nbsp€'), findsOneWidget);
    expect(find.text('ZÁKLAD'), findsNothing);
  });

  testWidgets('goes back from the detail to the list', (tester) async {
    final router = await pumpApp(tester, location: '/plans/$octoberId', plansApi: FakePlansApi([november(), october()]));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(currentPath(router), '/plans');
  });

  testWidgets('says when the plan does not exist', (tester) async {
    final router = await pumpApp(tester, location: '/plans/unknown', plansApi: FakePlansApi([november()]));

    expect(find.text('Plán neexistuje.'), findsOneWidget);
    await tester.tap(find.text('Na zoznam plánov'));
    await tester.pumpAndSettle();

    expect(currentPath(router), '/plans');
  });

  testWidgets('says when a plan has no items', (tester) async {
    final empty = PlanOverview.fromJson(
        overviewJson(essentialsCount: 0, items: [], essentialsCovered: true, nextMilestone: null, earnings: '0.00'));
    await pumpApp(tester, location: '/plans/$defaultPlanId', plansApi: FakePlansApi([empty]));

    expect(find.text('Plán nemá položky.'), findsOneWidget);
  });
}
