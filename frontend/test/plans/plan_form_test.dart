import 'package:earnings_tracker/overview/plan_overview.dart';
import 'package:earnings_tracker/plans/plans_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_plans_api.dart';
import '../support/overview_json.dart';
import '../support/pump_app.dart';

/// Slovak formatting separates thousands and the currency sign with a no-break space.
const nbsp = ' ';

/// The November plan of [overviewJson]: three essentials, two extras.
PlanOverview november() => PlanOverview.fromJson(overviewJson(nextMilestone: null));

Finder dragHandleOf(Finder row) => find.descendant(of: row, matching: find.byIcon(Icons.drag_handle));

Finder itemTile(String name) => find.widgetWithText(ListTile, name);

Future<void> addItem(WidgetTester tester, String name, String amount) async {
  await tester.tap(find.text('Pridať položku'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byKey(const Key('item-name')), name);
  await tester.enterText(find.byKey(const Key('item-amount')), amount);
  await tester.pump();
  await tester.tap(find.widgetWithText(FilledButton, 'Pridať'));
  await tester.pumpAndSettle();
}

/// Picks 1 – 31 December 2026 by typing it; widget tests run in the US English locale.
Future<void> pickDecember(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('plan-window')));
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(Icons.edit_outlined));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).at(0), '12/01/2026');
  await tester.enterText(find.byType(TextField).at(1), '12/31/2026');
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> pickDecemberAndSave(WidgetTester tester) async {
  await pickDecember(tester);
  await save(tester);
}

Future<void> save(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Uložiť'));
  await tester.pumpAndSettle();
}

void main() {
  group('new plan', () {
    testWidgets('is opened from the plan list', (tester) async {
      final router = await pumpApp(tester, location: '/plans');

      await tester.tap(find.text('Nový plán'));
      await tester.pumpAndSettle();

      expect(currentPath(router), '/plans/new');
      expect(find.widgetWithText(AppBar, 'Nový plán'), findsOneWidget);
      // Above the bottom navigation, so leaving goes through the unsaved changes check.
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('copies the items of the plan that ends last, but not its window', (tester) async {
      final api = FakePlansApi([november()]);
      final router = await pumpApp(tester, location: '/plans/new', plansApi: api);

      expect(find.text('Vyber okno'), findsOneWidget);
      expect(tester.widget<TextButton>(find.widgetWithText(TextButton, 'Uložiť')).onPressed, isNull);
      for (final name in ['Dane a odvody', 'Hypotéka', 'Jedlo', 'Investovanie', 'Dovolenka']) {
        expect(itemTile(name), findsOneWidget);
      }
      expect(find.descendant(of: itemTile('Hypotéka'), matching: find.text('750$nbsp€')), findsOneWidget);
      final lineY = tester.getTopLeft(find.byKey(const Key('essentials-line'))).dy;
      expect(tester.getTopLeft(itemTile('Jedlo')).dy, lessThan(lineY));
      expect(tester.getTopLeft(itemTile('Investovanie')).dy, greaterThan(lineY));

      await pickDecember(tester);
      expect(find.text('1. – 31. 12. 2026'), findsOneWidget);
      await save(tester);

      final created = api.created.single;
      expect((created.windowFrom, created.windowTo), (DateTime(2026, 12, 1), DateTime(2026, 12, 31)));
      expect(created.items.map((item) => item.name), ['Dane a odvody', 'Hypotéka', 'Jedlo', 'Investovanie', 'Dovolenka']);
      expect(created.essentialsCount, 3);
      expect(currentPath(router), '/plans/created-1');
      expect(find.widgetWithText(AppBar, '1. – 31. 12. 2026'), findsOneWidget);
      expect(find.text('Plán uložený.'), findsOneWidget);
    });

    testWidgets('without any plan is empty, window included', (tester) async {
      await pumpApp(tester, location: '/plans/new', plansApi: FakePlansApi([]));

      expect(find.text('Vyber okno'), findsOneWidget);
      expect(find.byType(ListTile), findsNothing);
      expect(find.byKey(const Key('essentials-line')), findsOneWidget);
    });

    testWidgets('gets new items at the end, among the extras', (tester) async {
      final api = FakePlansApi([]);
      await pumpApp(tester, location: '/plans/new', plansApi: api);

      await addItem(tester, '  Nájom ', '600');
      await addItem(tester, 'Dovolenka', '200,50');

      expect(find.descendant(of: itemTile('Nájom'), matching: find.text('600$nbsp€')), findsOneWidget);
      expect(find.descendant(of: itemTile('Dovolenka'), matching: find.text('200,50$nbsp€')), findsOneWidget);
      expect(tester.getTopLeft(itemTile('Nájom')).dy, greaterThan(tester.getTopLeft(find.byKey(const Key('essentials-line'))).dy));

      await pickDecemberAndSave(tester);

      expect(api.created.single.toJson()['items'], [
        {'name': 'Nájom', 'target': eurJson('600.00')},
        {'name': 'Dovolenka', 'target': eurJson('200.50')},
      ]);
      expect(api.created.single.essentialsCount, 0);
    });

    testWidgets('adds an item only with a name and a positive amount', (tester) async {
      await pumpApp(tester, location: '/plans/new', plansApi: FakePlansApi([]));
      await tester.tap(find.text('Pridať položku'));
      await tester.pumpAndSettle();
      final add = find.widgetWithText(FilledButton, 'Pridať');
      bool enabled() => tester.widget<FilledButton>(add).onPressed != null;

      expect(enabled(), isFalse);
      await tester.enterText(find.byKey(const Key('item-name')), 'Nájom');
      await tester.pump();
      expect(enabled(), isFalse);
      await tester.enterText(find.byKey(const Key('item-amount')), '0');
      await tester.pump();
      expect(enabled(), isFalse);
      await tester.enterText(find.byKey(const Key('item-amount')), '12,5');
      await tester.pump();
      expect(enabled(), isTrue);
      await tester.enterText(find.byKey(const Key('item-name')), '   ');
      await tester.pump();
      expect(enabled(), isFalse);
    });

    testWidgets('changes and removes items in their dialog', (tester) async {
      final api = FakePlansApi([november()]);
      await pumpApp(tester, location: '/plans/new', plansApi: api);

      await tester.tap(itemTile('Hypotéka'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(AlertDialog, 'Upraviť položku'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Hypotéka'), findsOneWidget);
      expect(find.widgetWithText(TextField, '750'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('item-amount')), '780');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Uložiť'));
      await tester.pumpAndSettle();
      expect(find.descendant(of: itemTile('Hypotéka'), matching: find.text('780$nbsp€')), findsOneWidget);

      await tester.tap(itemTile('Jedlo'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Odstrániť'));
      await tester.pumpAndSettle();
      expect(itemTile('Jedlo'), findsNothing);

      await pickDecemberAndSave(tester);
      final created = api.created.single;
      expect(created.items.map((item) => item.name), ['Dane a odvody', 'Hypotéka', 'Investovanie', 'Dovolenka']);
      expect(created.items[1].target.minorUnits, 78000);
      expect(created.essentialsCount, 2);
    });

    testWidgets('moves an essential below the line by dragging it', (tester) async {
      final api = FakePlansApi([november()]);
      await pumpApp(tester, location: '/plans/new', plansApi: api);

      final lineY = tester.getCenter(find.byKey(const Key('essentials-line'))).dy;
      final handle = dragHandleOf(itemTile('Dane a odvody'));
      await tester.timedDrag(handle, Offset(0, lineY - tester.getCenter(handle).dy + 5), const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await pickDecemberAndSave(tester);

      final created = api.created.single;
      expect(created.items.map((item) => item.name), ['Hypotéka', 'Jedlo', 'Dane a odvody', 'Investovanie', 'Dovolenka']);
      expect(created.essentialsCount, 2);
    });

    testWidgets('moves the essentials line by dragging it', (tester) async {
      final api = FakePlansApi([november()]);
      await pumpApp(tester, location: '/plans/new', plansApi: api);

      final handle = dragHandleOf(find.byKey(const Key('essentials-line')));
      final firstY = tester.getTopLeft(itemTile('Dane a odvody')).dy;
      await tester.timedDrag(handle, Offset(0, firstY - tester.getCenter(handle).dy - 10), const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await pickDecemberAndSave(tester);

      expect(api.created.single.essentialsCount, 0);
      expect(api.created.single.items.first.name, 'Dane a odvody');
    });

    testWidgets('shows an overlapping window at the window and keeps the form', (tester) async {
      final api = FakePlansApi([november()])..writeError = const OverlappingPlanException();
      final router = await pumpApp(tester, location: '/plans/new', plansApi: api);

      await pickDecemberAndSave(tester);

      expect(currentPath(router), '/plans/new');
      expect(find.text('Okno sa prekrýva s iným plánom.'), findsOneWidget);
      expect(itemTile('Hypotéka'), findsOneWidget);
    });

    testWidgets('keeps the form when saving fails', (tester) async {
      final api = FakePlansApi([november()])..writeError = Exception('backend down');
      final router = await pumpApp(tester, location: '/plans/new', plansApi: api);

      await pickDecemberAndSave(tester);

      expect(currentPath(router), '/plans/new');
      expect(find.text('Uloženie zlyhalo.'), findsOneWidget);
    });

    testWidgets('asks before throwing away unsaved changes', (tester) async {
      final router = await pumpApp(tester, location: '/plans', plansApi: FakePlansApi([]));
      await tester.tap(find.text('Nový plán'));
      await tester.pumpAndSettle();
      await addItem(tester, 'Nájom', '600');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('Zahodiť zmeny?'), findsOneWidget);
      await tester.tap(find.text('Pokračovať v úprave'));
      await tester.pumpAndSettle();
      expect(currentPath(router), '/plans/new');
      expect(itemTile('Nájom'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zahodiť'));
      await tester.pumpAndSettle();
      expect(currentPath(router), '/plans');
    });

    testWidgets('leaves without asking when nothing changed', (tester) async {
      final router = await pumpApp(tester, location: '/plans');
      await tester.tap(find.text('Nový plán'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Zahodiť zmeny?'), findsNothing);
      expect(currentPath(router), '/plans');
    });
  });

  group('editing', () {
    testWidgets('is offered for a running plan but not for a finished one', (tester) async {
      final october = PlanOverview.fromJson(overviewJson(planId: 'october', window: ('2026-10-01', '2026-10-31'), nextMilestone: null));
      await pumpApp(tester, location: '/plans/$defaultPlanId', plansApi: FakePlansApi([november(), october]));
      expect(find.byTooltip('Upraviť'), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('plan-october')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Upraviť'), findsNothing);
      expect(find.byTooltip('Zmazať'), findsOneWidget);
    });

    testWidgets('replaces the plan with what was changed', (tester) async {
      final api = FakePlansApi([november()]);
      final router = await pumpApp(tester, location: '/plans/$defaultPlanId', plansApi: api);

      await tester.tap(find.byTooltip('Upraviť'));
      await tester.pumpAndSettle();
      expect(currentPath(router), '/plans/$defaultPlanId/edit');
      expect(find.widgetWithText(AppBar, 'Upraviť plán'), findsOneWidget);
      expect(find.text('1. – 30. 11. 2026'), findsOneWidget);

      final handle = dragHandleOf(find.byKey(const Key('essentials-line')));
      final firstY = tester.getTopLeft(itemTile('Dane a odvody')).dy;
      await tester.timedDrag(handle, Offset(0, firstY - tester.getCenter(handle).dy - 10), const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      await save(tester);

      final (id, draft) = api.updated.single;
      expect(id, defaultPlanId);
      expect((draft.windowFrom, draft.windowTo), (DateTime(2026, 11, 1), DateTime(2026, 11, 30)));
      expect(draft.items, hasLength(5));
      expect(draft.essentialsCount, 0);
      expect(api.created, isEmpty);
      expect(currentPath(router), '/plans/$defaultPlanId');
      expect(find.text('ZÁKLAD'), findsNothing);
    });

    testWidgets('says when the plan to edit does not exist', (tester) async {
      await pumpApp(tester, location: '/plans/unknown/edit');

      expect(find.text('Plán neexistuje.'), findsOneWidget);
    });
  });

  group('deleting', () {
    testWidgets('removes the plan after confirmation', (tester) async {
      final api = FakePlansApi([november()]);
      final router = await pumpApp(tester, location: '/plans/$defaultPlanId', plansApi: api);

      await tester.tap(find.byTooltip('Zmazať'));
      await tester.pumpAndSettle();
      expect(find.text('Zmazať plán 1. – 30. 11. 2026?'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Zmazať'));
      await tester.pumpAndSettle();

      expect(api.deleted, [defaultPlanId]);
      expect(currentPath(router), '/plans');
      expect(find.text('Plán zmazaný.'), findsOneWidget);
      expect(find.text('Zatiaľ nemáš žiadny plán.'), findsOneWidget);
    });

    testWidgets('keeps the plan when cancelled', (tester) async {
      final api = FakePlansApi([november()]);
      final router = await pumpApp(tester, location: '/plans/$defaultPlanId', plansApi: api);

      await tester.tap(find.byTooltip('Zmazať'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Zrušiť'));
      await tester.pumpAndSettle();

      expect(api.deleted, isEmpty);
      expect(currentPath(router), '/plans/$defaultPlanId');
    });

    testWidgets('says when deleting fails', (tester) async {
      final api = FakePlansApi([november()])..writeError = Exception('backend down');
      final router = await pumpApp(tester, location: '/plans/$defaultPlanId', plansApi: api);

      await tester.tap(find.byTooltip('Zmazať'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Zmazať'));
      await tester.pumpAndSettle();

      expect(find.text('Zmazanie zlyhalo.'), findsOneWidget);
      expect(currentPath(router), '/plans/$defaultPlanId');
    });
  });
}
