import 'package:earnings_tracker/overview/plan_overview.dart';
import 'package:earnings_tracker/plans/plan_summary.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/overview_json.dart';

/// Slovak formatting separates thousands and the currency sign with a no-break space.
const nbsp = '\u00A0';

PlanOverview plan({required int essentialsCount, required List<Map<String, dynamic>> items, bool essentialsCovered = false}) =>
    PlanOverview.fromJson(overviewJson(essentialsCount: essentialsCount, items: items, essentialsCovered: essentialsCovered));

void main() {
  test('sums what is funded against the targets and counts covered items', () {
    final summary = planSummary(PlanOverview.fromJson(overviewJson()));

    expect(summary, '1${nbsp}480 / 2${nbsp}650$nbsp€ · základ ✗ · 1 z 5');
  });

  test('marks covered essentials', () {
    final summary = planSummary(plan(
      essentialsCount: 1,
      essentialsCovered: true,
      items: [
        itemJson(0, 'Dane', '900.00', '900.00', 'COVERED', essential: true),
        itemJson(1, 'Dovolenka', '200.50', '100.25', 'IN_PROGRESS', essential: false),
      ],
    ));

    expect(summary, '1${nbsp}000,25 / 1${nbsp}100,50$nbsp€ · základ ✓ · 1 z 2');
  });

  test('leaves out essentials when the plan has none', () {
    final summary = planSummary(plan(
      essentialsCount: 0,
      essentialsCovered: true,
      items: [itemJson(0, 'Dovolenka', '200.00', '0.00', 'UNCOVERED', essential: false)],
    ));

    expect(summary, '0 / 200$nbsp€ · 0 z 1');
  });

  test('says when the plan has no items', () {
    expect(planSummary(plan(essentialsCount: 0, essentialsCovered: true, items: [])), 'Bez položiek');
  });
}
