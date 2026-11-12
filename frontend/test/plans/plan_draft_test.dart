import 'package:earnings_tracker/money/money.dart';
import 'package:earnings_tracker/overview/plan_overview.dart';
import 'package:earnings_tracker/plans/plan_draft.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/overview_json.dart';

Money eur(int euros, [int cents = 0]) => Money(minorUnits: euros * 100 + cents, scale: 2, currency: 'EUR');

DraftItem item(String name, int euros) => DraftItem(name: name, target: eur(euros));

PlanOverview plan(String from, String to, {String id = defaultPlanId, int essentialsCount = 3}) =>
    PlanOverview.fromJson(overviewJson(planId: id, window: (from, to), essentialsCount: essentialsCount, nextMilestone: null));

/// Taxes and mortgage are essentials, vacation is an extra.
final draft = PlanDraft(
  windowFrom: DateTime(2026, 12, 1),
  windowTo: DateTime(2026, 12, 31),
  items: [item('Dane', 900), item('Hypotéka', 750), item('Dovolenka', 200)],
  essentialsCount: 2,
);

List<String> names(PlanDraft draft) => draft.items.map((item) => item.name).toList();

void main() {
  group('a new plan', () {
    test('without any plan has no items and no window', () {
      final empty = PlanDraft.newPlan(const []);

      expect(empty.hasWindow, isFalse);
      expect(empty.items, isEmpty);
      expect(empty.essentialsCount, 0);
    });

    test('copies items, amounts, order and essentials line of the plan that ends last, but not its window', () {
      final october = plan('2026-10-01', '2026-10-31', id: 'october', essentialsCount: 1);
      final november = plan('2026-11-01', '2026-11-30', essentialsCount: 3);

      final copy = PlanDraft.newPlan([october, november]);

      expect(names(copy), ['Dane a odvody', 'Hypotéka', 'Jedlo', 'Investovanie', 'Dovolenka']);
      expect(copy.items[1].target.toJson(), eurJson('750.00'));
      expect(copy.essentialsCount, 3);
      expect(copy.hasWindow, isFalse);
      expect((copy.windowFrom, copy.windowTo), (null, null));
    });

    test('gets a window once one is picked', () {
      final picked = PlanDraft.newPlan(const []).withWindow(DateTime(2026, 12, 1), DateTime(2026, 12, 31));

      expect(picked.hasWindow, isTrue);
      expect(picked.toJson()['window'], {'from': '2026-12-01', 'to': '2026-12-31'});
    });

    test('cannot be written without a window', () {
      expect(() => PlanDraft.newPlan(const []).toJson(), throwsStateError);
    });
  });

  test('editing starts from the plan as it is', () {
    final edited = PlanDraft.fromPlan(plan('2026-11-01', '2026-11-30', essentialsCount: 3));

    expect(edited.hasWindow, isTrue);
    expect((edited.windowFrom, edited.windowTo), (DateTime(2026, 11, 1), DateTime(2026, 11, 30)));
    expect(names(edited), ['Dane a odvody', 'Hypotéka', 'Jedlo', 'Investovanie', 'Dovolenka']);
    expect(edited.essentialsCount, 3);
  });

  group('rows', () {
    // Rows of [draft]: Dane, Hypotéka, essentials line, Dovolenka.

    test('put the essentials line after the essentials', () {
      expect(draft.rows, [
        ItemRow(0, draft.items[0]),
        ItemRow(1, draft.items[1]),
        const EssentialsLineRow(),
        ItemRow(2, draft.items[2]),
      ]);
    });

    test('moving an item within the essentials keeps the line', () {
      final moved = draft.moveRow(1, 0);

      expect(names(moved), ['Hypotéka', 'Dane', 'Dovolenka']);
      expect(moved.essentialsCount, 2);
    });

    test('moving an essential below the line makes it an extra', () {
      final moved = draft.moveRow(0, 3);

      expect(names(moved), ['Hypotéka', 'Dovolenka', 'Dane']);
      expect(moved.essentialsCount, 1);
    });

    test('moving an extra above the line makes it an essential', () {
      final moved = draft.moveRow(3, 0);

      expect(names(moved), ['Dovolenka', 'Dane', 'Hypotéka']);
      expect(moved.essentialsCount, 3);
    });

    test('moving the line to the top leaves no essentials', () {
      final moved = draft.moveRow(2, 0);

      expect(names(moved), ['Dane', 'Hypotéka', 'Dovolenka']);
      expect(moved.essentialsCount, 0);
    });

    test('moving the line to the bottom makes everything essential', () {
      expect(draft.moveRow(2, 3).essentialsCount, 3);
    });
  });

  group('items', () {
    test('a new item goes to the end, among the extras', () {
      final added = draft.addItem(item('Investovanie', 300));

      expect(names(added), ['Dane', 'Hypotéka', 'Dovolenka', 'Investovanie']);
      expect(added.essentialsCount, 2);
    });

    test('a new item in a plan with everything essential stays below the line', () {
      final allEssential = draft.moveRow(2, 3).addItem(item('Investovanie', 300));

      expect(allEssential.essentialsCount, 3);
      expect(allEssential.rows.last, ItemRow(3, allEssential.items[3]));
    });

    test('replacing an item keeps its place', () {
      final replaced = draft.replaceItem(1, item('Nájom', 600));

      expect(names(replaced), ['Dane', 'Nájom', 'Dovolenka']);
      expect(replaced.items[1].target.minorUnits, 60000);
      expect(replaced.essentialsCount, 2);
    });

    test('removing an essential moves the line up', () {
      final removed = draft.removeItem(0);

      expect(names(removed), ['Hypotéka', 'Dovolenka']);
      expect(removed.essentialsCount, 1);
    });

    test('removing an extra keeps the line', () {
      expect(draft.removeItem(2).essentialsCount, 2);
    });
  });

  test('a new window keeps the items', () {
    final moved = draft.withWindow(DateTime(2027, 1, 1), DateTime(2027, 1, 31));

    expect((moved.windowFrom, moved.windowTo), (DateTime(2027, 1, 1), DateTime(2027, 1, 31)));
    expect(names(moved), names(draft));
    expect(moved.essentialsCount, 2);
  });

  test('is written as the body of POST and PUT /api/plans', () {
    final withCents = draft.replaceItem(2, DraftItem(name: 'Dovolenka', target: eur(200, 50)));

    expect(withCents.toJson(), {
      'window': {'from': '2026-12-01', 'to': '2026-12-31'},
      'items': [
        {'name': 'Dane', 'target': eurJson('900.00')},
        {'name': 'Hypotéka', 'target': eurJson('750.00')},
        {'name': 'Dovolenka', 'target': eurJson('200.50')},
      ],
      'essentialsCount': 2,
    });
  });

  test('knows whether anything changed', () {
    expect(draft.sameAs(draft.withWindow(DateTime(2026, 12, 1), DateTime(2026, 12, 31))), isTrue);
    expect(draft.sameAs(draft.moveRow(1, 0)), isFalse);
    expect(draft.sameAs(draft.moveRow(1, 0).moveRow(1, 0)), isTrue);
    expect(draft.sameAs(draft.moveRow(2, 0)), isFalse);
  });
}
