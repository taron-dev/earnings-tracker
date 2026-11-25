import 'package:earnings_tracker/overview/plan_overview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_hourly_rate_api.dart';
import '../support/fake_plan_overview_api.dart';
import '../support/fake_work_log_api.dart';
import '../support/pump_app.dart';

Finder get sheet => find.byKey(const Key('work-log-sheet'));

Finder inSheet(Finder matching) => find.descendant(of: sheet, matching: matching);

/// Slovak formatting separates thousands and the currency sign with a no-break space.
const nbsp = '\u00A0';

Finder button(String key) => inSheet(find.byKey(Key(key)));

Future<void> tapIn(WidgetTester tester, String key, {int times = 1}) async {
  for (var i = 0; i < times; i++) {
    await tester.tap(button(key));
    await tester.pump();
  }
}

String timeShown(WidgetTester tester) => tester.widget<Text>(inSheet(find.byKey(const Key('work-log-time')))).data!;

bool enabled(WidgetTester tester, String key) =>
    tester.widget<OutlinedButton>(find.descendant(of: button(key), matching: find.byType(OutlinedButton))).onPressed != null;

Finder get saveButton => inSheet(find.widgetWithText(FilledButton, 'Uložiť'));

Future<void> openSheet(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Zapísať prácu'));
  await tester.pumpAndSettle();
}

void main() {
  for (final tab in ['/overview', '/work-logs']) {
    testWidgets('opens the sheet for today from $tab', (tester) async {
      await pumpApp(tester, location: tab);

      await openSheet(tester);

      expect(inSheet(find.text('Zapísať prácu')), findsOneWidget);
      expect(inSheet(find.text('Dnes, št 12. 11.')), findsOneWidget);
    });
  }

  testWidgets('starts with no time, so nothing can be saved yet', (tester) async {
    await pumpApp(tester);
    await openSheet(tester);

    expect(timeShown(tester), '0 h');
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
    expect(enabled(tester, 'minus-15'), isFalse);
    expect(enabled(tester, 'minus-30'), isFalse);
  });

  testWidgets('a quick choice sets whole hours and stays highlighted', (tester) async {
    await pumpApp(tester);
    await openSheet(tester);

    await tapIn(tester, 'quick-6');

    expect(timeShown(tester), '6 h');
    for (final hours in [1, 2, 4, 8]) {
      expect(button('quick-$hours'), findsOneWidget);
    }
    Color? background(String key) => tester
        .widget<OutlinedButton>(find.descendant(of: button(key), matching: find.byType(OutlinedButton)))
        .style!
        .backgroundColor!
        .resolve({});
    expect(background('quick-6'), isNot(background('quick-8')));
  });

  testWidgets('the buttons step by 15 and 30 minutes', (tester) async {
    await pumpApp(tester);
    await openSheet(tester);

    await tapIn(tester, 'plus-15');
    expect(timeShown(tester), '15 min');
    await tapIn(tester, 'plus-30', times: 2);
    expect(timeShown(tester), '1 h 15');
    await tapIn(tester, 'minus-15');
    expect(timeShown(tester), '1 h');
    await tapIn(tester, 'minus-30');
    expect(timeShown(tester), '30 min');
  });

  testWidgets('the buttons keep the time between 15 minutes and 24 hours', (tester) async {
    await pumpApp(tester);
    await openSheet(tester);

    await tapIn(tester, 'plus-30');
    await tapIn(tester, 'minus-30');
    expect(timeShown(tester), '15 min');
    expect(enabled(tester, 'minus-15'), isFalse);

    await tapIn(tester, 'quick-8');
    await tapIn(tester, 'plus-30', times: 33);
    expect(timeShown(tester), '24 h');
    expect(enabled(tester, 'plus-15'), isFalse);
    expect(enabled(tester, 'plus-30'), isFalse);
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
  });

  testWidgets('previews the earnings at the current rate', (tester) async {
    await pumpApp(tester);
    await openSheet(tester);

    await tapIn(tester, 'quick-6');
    await tapIn(tester, 'plus-30');

    expect(inSheet(find.text('= 260$nbsp€ pri 40$nbsp€/h')), findsOneWidget);
  });

  testWidgets('records the work, closes the sheet and refreshes', (tester) async {
    final overviewApi = FakePlanOverviewApi();
    final workLogApi = FakeWorkLogApi();
    await pumpApp(tester, overviewApi: overviewApi, workLogApi: workLogApi);
    final overviewLoads = overviewApi.requestedDays.length;
    await openSheet(tester);
    await tapIn(tester, 'quick-6');
    await tapIn(tester, 'plus-30');

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(workLogApi.recorded.single, (testToday, 390));
    expect(sheet, findsNothing);
    expect(find.text('Zapísané 6 h 30 min · 260$nbsp€'), findsOneWidget);
    expect(overviewApi.requestedDays.length, overviewLoads + 1);
  });

  testWidgets('keeps the sheet open when saving fails', (tester) async {
    await pumpApp(tester, workLogApi: FakeWorkLogApi()..failSaving = true);
    await openSheet(tester);
    await tapIn(tester, 'quick-6');
    await tapIn(tester, 'plus-30');

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(inSheet(find.text('Uloženie zlyhalo.')), findsOneWidget);
    expect(timeShown(tester), '6 h 30');
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
  });

  testWidgets('records work on another day picked in the calendar', (tester) async {
    final workLogApi = FakeWorkLogApi();
    await pumpApp(tester, workLogApi: workLogApi);
    await openSheet(tester);

    await tester.tap(inSheet(find.text('Dnes, št 12. 11.')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(inSheet(find.text('ut 10. 11.')), findsOneWidget);
    await tapIn(tester, 'quick-2');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(workLogApi.recorded.single, (DateTime(2026, 11, 10), 120));
  });

  testWidgets('offers no days after today', (tester) async {
    await pumpApp(tester);
    await openSheet(tester);

    await tester.tap(inSheet(find.text('Dnes, št 12. 11.')));
    await tester.pumpAndSettle();

    final picker = tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    expect(picker.lastDate, testToday);
    expect(picker.firstDate, DateTime(2025, 11, 12));
  });

  testWidgets('sends to settings while no rate is set', (tester) async {
    await pumpApp(
      tester,
      hourlyRateApi: FakeHourlyRateApi(),
      overviewApi: FakePlanOverviewApi(const HourlyRateNotSet()),
    );

    await openSheet(tester);

    expect(sheet, findsNothing);
    expect(find.widgetWithText(AppBar, 'Nastavenia'), findsOneWidget);
  });
}
