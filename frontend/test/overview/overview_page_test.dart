import 'package:earnings_tracker/overview/plan_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fab_clearance.dart';
import '../support/fake_hourly_rate_api.dart';
import '../support/fake_plan_overview_api.dart';
import '../support/overview_json.dart';
import '../support/pump_app.dart';

/// Slovak formatting separates thousands and the currency sign with a no-break space.
const nbsp = ' ';

void main() {
  testWidgets('shows the window, days left, earnings and rate', (tester) async {
    await pumpApp(tester);

    expect(find.text('1. – 30. 11. 2026'), findsOneWidget);
    expect(find.text('ešte 19 dní'), findsOneWidget);
    expect(find.text('Zarobené 1${nbsp}480$nbsp€'), findsOneWidget);
    expect(find.text('40$nbsp€ / h'), findsOneWidget);
  });

  testWidgets('opens the plan detail from the window', (tester) async {
    final router = await pumpApp(tester);

    await tester.tap(find.byKey(const Key('overview-window')));
    await tester.pumpAndSettle();

    expect(currentPath(router), '/plans/$defaultPlanId');
    expect(find.widgetWithText(AppBar, '1. – 30. 11. 2026'), findsOneWidget);
  });

  testWidgets('opens settings from the rate', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('40$nbsp€ / h'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Nastavenia'), findsOneWidget);
  });

  testWidgets('shows the next milestone in hours', (tester) async {
    await pumpApp(tester);

    final card = find.byKey(const Key('next-milestone'));
    expect(find.descendant(of: card, matching: find.text('Najbližší cieľ')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('Hypotéka')), findsOneWidget);
    expect(find.descendant(of: card, matching: find.text('ešte 170$nbsp€ · 4 h 15 min')), findsOneWidget);
  });

  testWidgets('celebrates a fully covered plan', (tester) async {
    final covered = overviewJson(
      items: [itemJson(0, 'Dane a odvody', '900.00', '900.00', 'COVERED', essential: true)],
      essentialsCovered: true,
      nextMilestone: null,
    );
    await pumpApp(tester, overviewApi: FakePlanOverviewApi(overviewFrom(covered)));

    expect(find.descendant(of: find.byKey(const Key('next-milestone')), matching: find.text('Všetko pokryté ✓')), findsOneWidget);
  });

  testWidgets('says when the plan has no items', (tester) async {
    final empty = overviewJson(items: [], essentialsCovered: true, nextMilestone: null);
    await pumpApp(tester, overviewApi: FakePlanOverviewApi(overviewFrom(empty)));

    expect(find.descendant(of: find.byKey(const Key('next-milestone')), matching: find.text('Plán nemá položky')), findsOneWidget);
  });

  Finder inItem(int position, Finder matching) => find.descendant(of: find.byKey(Key('item-$position')), matching: matching);

  testWidgets('lists items under essentials and extras', (tester) async {
    await pumpApp(tester);

    expect(find.text('ZÁKLAD'), findsOneWidget);
    expect(find.text('nepokrytý'), findsOneWidget);
    expect(find.text('EXTRA'), findsOneWidget);
    final essentialsY = tester.getTopLeft(find.text('ZÁKLAD')).dy;
    final extrasY = tester.getTopLeft(find.text('EXTRA')).dy;
    expect(tester.getTopLeft(find.text('Jedlo')).dy, inExclusiveRange(essentialsY, extrasY));
    expect(tester.getTopLeft(find.text('Investovanie')).dy, greaterThan(extrasY));
  });

  testWidgets('shows how far each item is funded', (tester) async {
    await pumpApp(tester);

    expect(inItem(0, find.byIcon(Icons.check_circle)), findsOneWidget);
    expect(inItem(0, find.text('900$nbsp€')), findsOneWidget);
    expect(inItem(1, find.byIcon(Icons.timelapse)), findsOneWidget);
    expect(inItem(1, find.text('580 / 750$nbsp€')), findsOneWidget);
    expect(inItem(2, find.byIcon(Icons.radio_button_unchecked)), findsOneWidget);
    expect(inItem(2, find.text('500$nbsp€')), findsOneWidget);

    double progress(int position) => tester.widget<LinearProgressIndicator>(inItem(position, find.byType(LinearProgressIndicator))).value!;
    expect(progress(0), 1.0);
    expect(progress(1), closeTo(580 / 750, 0.0001));
    expect(progress(2), 0.0);
  });

  testWidgets('marks covered essentials and hides an empty section', (tester) async {
    final onlyEssentials = overviewJson(
      items: [itemJson(0, 'Dane a odvody', '900.00', '900.00', 'COVERED', essential: true)],
      essentialsCovered: true,
      nextMilestone: null,
    );
    await pumpApp(tester, overviewApi: FakePlanOverviewApi(overviewFrom(onlyEssentials)));

    expect(find.text('pokrytý'), findsOneWidget);
    expect(find.text('EXTRA'), findsNothing);
  });

  testWidgets('hides essentials when the line is at the top', (tester) async {
    final onlyExtras = overviewJson(
      items: [itemJson(0, 'Dovolenka', '200.00', '0.00', 'UNCOVERED', essential: false)],
      essentialsCovered: true,
      nextMilestone: {'position': 0, 'missing': eurJson('200.00'), 'minutesNeeded': 300},
    );
    await pumpApp(tester, overviewApi: FakePlanOverviewApi(overviewFrom(onlyExtras)));

    expect(find.text('ZÁKLAD'), findsNothing);
    expect(find.text('EXTRA'), findsOneWidget);
  });

  testWidgets('hides unassigned earnings while there are none', (tester) async {
    await pumpApp(tester);

    expect(find.textContaining('Nepriradené'), findsNothing);
  });

  testWidgets('invites to assign earnings beyond all items', (tester) async {
    final overfunded = overviewJson(
      items: [itemJson(0, 'Dane a odvody', '900.00', '900.00', 'COVERED', essential: true)],
      essentialsCovered: true,
      nextMilestone: null,
      earnings: '1020.00',
      unassigned: '120.00',
    );
    await pumpApp(tester, overviewApi: FakePlanOverviewApi(overviewFrom(overfunded)));

    expect(find.text('Nepriradené 120$nbsp€'), findsOneWidget);
  });

  testWidgets('asks to set the hourly rate first', (tester) async {
    await pumpApp(
      tester,
      hourlyRateApi: FakeHourlyRateApi(),
      overviewApi: FakePlanOverviewApi(const HourlyRateNotSet()),
    );

    expect(find.text('Najprv nastav svoju hodinovú sadzbu.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Nastaviť sadzbu'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'Nastavenia'), findsOneWidget);
  });

  testWidgets('explains a day outside every plan', (tester) async {
    await pumpApp(tester, overviewApi: FakePlanOverviewApi(const NoPlanForToday()));

    expect(find.text('Dnešok nepatrí do žiadneho plánu.'), findsOneWidget);
    expect(find.textContaining('započíta'), findsOneWidget);
    expect(find.textContaining('čoskoro'), findsNothing);
  });

  testWidgets('offers to create a plan when today is outside every plan', (tester) async {
    final router = await pumpApp(tester, overviewApi: FakePlanOverviewApi(const NoPlanForToday()));

    await tester.tap(find.text('Vytvoriť plán'));
    await tester.pumpAndSettle();

    expect(currentPath(router), '/plans/new');
  });

  testWidgets('offers to add items to a plan without any', (tester) async {
    final empty = overviewJson(essentialsCount: 0, items: [], essentialsCovered: true, nextMilestone: null);
    final router = await pumpApp(tester, overviewApi: FakePlanOverviewApi(overviewFrom(empty)));

    await tester.tap(find.text('Pridať položky'));
    await tester.pumpAndSettle();

    expect(currentPath(router), '/plans/$defaultPlanId/edit');
    expect(find.widgetWithText(AppBar, 'Upraviť plán'), findsOneWidget);
  });

  testWidgets('offers a retry when loading fails', (tester) async {
    final api = FakePlanOverviewApi()..error = Exception('offline');
    await pumpApp(tester, overviewApi: api);

    expect(find.text('Nepodarilo sa načítať prehľad. Skontroluj pripojenie.'), findsOneWidget);

    api.error = null;
    await tester.tap(find.text('Skúsiť znova'));
    await tester.pumpAndSettle();
    expect(find.text('Zarobené 1${nbsp}480$nbsp€'), findsOneWidget);
  });

  testWidgets('the last item can be scrolled out from under the "+" button', (tester) async {
    final longPlan = overviewJson(
      items: [for (var i = 0; i < 30; i++) itemJson(i, 'Položka $i', '100.00', '0.00', 'UNCOVERED', essential: false)],
    );
    await pumpApp(tester, overviewApi: FakePlanOverviewApi(overviewFrom(longPlan)));

    await expectLastRowClearOfFab(tester, find.byKey(const Key('item-29')));
  });
}
