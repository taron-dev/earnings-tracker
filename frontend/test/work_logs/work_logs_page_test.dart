import 'package:earnings_tracker/overview/plan_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fab_clearance.dart';
import '../support/fake_plan_overview_api.dart';
import '../support/fake_work_log_api.dart';
import '../support/pump_app.dart';

/// Slovak formatting separates thousands and the currency sign with a no-break space.
const nbsp = ' ';

Finder inLog(String id, Finder matching) => find.descendant(of: find.byKey(Key('work-log-$id')), matching: matching);

void main() {
  testWidgets('lists the work logs of the current plan with their total', (tester) async {
    final api = FakeWorkLogApi([
      workLog('a1', '2026-11-12', 390, '260.00'),
      workLog('b2', '2026-11-11', 480, '320.00'),
      workLog('c3', '2026-11-11', 75, '50.00'),
    ]);
    await pumpApp(tester, location: '/work-logs', workLogApi: api);

    expect(api.requestedRanges.single, (DateTime(2026, 11, 1), DateTime(2026, 11, 30)));
    expect(find.text('1. 11. – 30. 11.'), findsOneWidget);
    expect(find.text('15 h 45 min'), findsOneWidget);
    expect(find.text('630$nbsp€ zarobené'), findsOneWidget);
    expect(inLog('a1', find.text('ŠT')), findsOneWidget);
    expect(inLog('a1', find.text('12')), findsOneWidget);
    expect(inLog('a1', find.text('6 h 30 min')), findsOneWidget);
    expect(inLog('a1', find.text('260$nbsp€')), findsOneWidget);
    expect(inLog('c3', find.text('1 h 15 min')), findsOneWidget);
  });

  const lastThirtyDays = 'Dnešok nepatrí do žiadneho plánu, zobrazujem posledných 30 dní.';

  testWidgets('shows the last 30 days when no plan contains today', (tester) async {
    final api = FakeWorkLogApi([workLog('a1', '2026-11-12', 60, '40.00')]);
    await pumpApp(
      tester,
      location: '/work-logs',
      overviewApi: FakePlanOverviewApi(const NoPlanForToday()),
      workLogApi: api,
    );

    expect(api.requestedRanges.single, (DateTime(2026, 10, 14), DateTime(2026, 11, 12)));
    expect(find.text(lastThirtyDays), findsOneWidget);
    expect(find.text('14. 10. – 12. 11.'), findsOneWidget);
  });

  testWidgets('shows the last 30 days without a hint while the rate is not set', (tester) async {
    final api = FakeWorkLogApi();
    await pumpApp(
      tester,
      location: '/work-logs',
      overviewApi: FakePlanOverviewApi(const HourlyRateNotSet()),
      workLogApi: api,
    );

    expect(api.requestedRanges.single, (DateTime(2026, 10, 14), DateTime(2026, 11, 12)));
    expect(find.text(lastThirtyDays), findsNothing);
  });

  testWidgets('says when there are no work logs yet', (tester) async {
    await pumpApp(tester, location: '/work-logs', workLogApi: FakeWorkLogApi());

    expect(find.text('Zatiaľ žiadne záznamy.'), findsOneWidget);
    expect(find.textContaining('zarobené'), findsNothing);
  });

  testWidgets('offers a retry when loading fails', (tester) async {
    final api = FakeWorkLogApi([workLog('a1', '2026-11-12', 60, '40.00')])..error = Exception('offline');
    await pumpApp(tester, location: '/work-logs', workLogApi: api);

    expect(find.text('Nepodarilo sa načítať záznamy. Skontroluj pripojenie.'), findsOneWidget);

    api.error = null;
    await tester.tap(find.text('Skúsiť znova'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('work-log-a1')), findsOneWidget);
  });

  testWidgets('offers a retry when the plan cannot be loaded', (tester) async {
    final overviewApi = FakePlanOverviewApi()..error = Exception('offline');
    await pumpApp(tester, location: '/work-logs', overviewApi: overviewApi);

    expect(find.text('Nepodarilo sa načítať záznamy. Skontroluj pripojenie.'), findsOneWidget);

    overviewApi.error = null;
    await tester.tap(find.text('Skúsiť znova'));
    await tester.pumpAndSettle();
    expect(find.text('Zatiaľ žiadne záznamy.'), findsOneWidget);
  });

  testWidgets('the last work log can be scrolled out from under the "+" button', (tester) async {
    final api = FakeWorkLogApi([for (var i = 0; i < 30; i++) workLog('w$i', '2026-11-12', 60, '40.00')]);
    await pumpApp(tester, location: '/work-logs', workLogApi: api);

    await expectLastRowClearOfFab(tester, find.byKey(const Key('work-log-w29')));
  });

  testWidgets('groups the work logs by Monday to Sunday week with subtotals', (tester) async {
    final api = FakeWorkLogApi([
      workLog('a1', '2026-11-12', 390, '260.00'),
      workLog('b2', '2026-11-09', 120, '80.00'),
      workLog('c3', '2026-11-08', 480, '320.00'),
      workLog('d4', '2026-11-02', 60, '40.00'),
    ]);
    await pumpApp(tester, location: '/work-logs', workLogApi: api);

    expect(find.text('Tento týždeň'), findsOneWidget);
    expect(find.text('8 h 30 min · 340$nbsp€'), findsOneWidget);
    expect(find.text('2. – 8. 11.'), findsOneWidget);
    expect(find.text('9 h · 360$nbsp€'), findsOneWidget);
    double top(String id) => tester.getTopLeft(find.byKey(Key('work-log-$id'))).dy;
    final lastWeekY = tester.getTopLeft(find.text('2. – 8. 11.')).dy;
    expect(top('b2'), lessThan(lastWeekY));
    expect(top('c3'), greaterThan(lastWeekY));
    expect(top('d4'), greaterThan(top('c3')));
  });
}
