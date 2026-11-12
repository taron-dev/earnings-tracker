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

Finder get hoursField => inSheet(find.widgetWithText(TextField, 'Hodiny'));

Finder get minutesField => inSheet(find.widgetWithText(TextField, 'Minúty'));

String textOf(WidgetTester tester, Finder field) => tester.widget<TextField>(field).controller!.text;

Future<void> type(WidgetTester tester, {required String hours, required String minutes}) async {
  await tester.enterText(hoursField, hours);
  await tester.enterText(minutesField, minutes);
  await tester.pump();
}

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
      expect(inSheet(find.text('dnes, št 12. 11.')), findsOneWidget);
    });
  }

  testWidgets('a quick choice fills in whole hours', (tester) async {
    await pumpApp(tester);
    await openSheet(tester);
    await type(tester, hours: '3', minutes: '20');

    await tester.tap(inSheet(find.widgetWithText(ActionChip, '6 h')));
    await tester.pump();

    expect(textOf(tester, hoursField), '6');
    expect(textOf(tester, minutesField), '0');
    for (final hours in [1, 2, 4, 8]) {
      expect(inSheet(find.widgetWithText(ActionChip, '$hours h')), findsOneWidget);
    }
  });

  testWidgets('previews the earnings at the current rate', (tester) async {
    await pumpApp(tester);
    await openSheet(tester);

    await type(tester, hours: '6', minutes: '30');

    expect(inSheet(find.text('= 260$nbsp€ pri 40$nbsp€ / h')), findsOneWidget);
  });

  testWidgets('records the work, closes the sheet and refreshes', (tester) async {
    final overviewApi = FakePlanOverviewApi();
    final workLogApi = FakeWorkLogApi();
    await pumpApp(tester, overviewApi: overviewApi, workLogApi: workLogApi);
    final overviewLoads = overviewApi.requestedDays.length;
    await openSheet(tester);
    await type(tester, hours: '6', minutes: '30');

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(workLogApi.recorded.single, (testToday, 390));
    expect(sheet, findsNothing);
    expect(find.text('Zapísané 6 h 30 min · 260$nbsp€'), findsOneWidget);
    expect(overviewApi.requestedDays.length, overviewLoads + 1);
  });

  testWidgets('cannot save less than a minute, more than a day or nonsense', (tester) async {
    await pumpApp(tester);
    await openSheet(tester);

    for (final (hours, minutes) in [('', ''), ('0', '0'), ('24', '1'), ('25', ''), ('1', '60'), ('x', '5'), ('-1', '30')]) {
      await type(tester, hours: hours, minutes: minutes);

      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull, reason: '$hours h $minutes min');
    }

    await type(tester, hours: '24', minutes: '');
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
    await type(tester, hours: '', minutes: '1');
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
  });

  testWidgets('keeps the sheet open when saving fails', (tester) async {
    await pumpApp(tester, workLogApi: FakeWorkLogApi()..failSaving = true);
    await openSheet(tester);
    await type(tester, hours: '6', minutes: '30');

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(inSheet(find.text('Uloženie zlyhalo.')), findsOneWidget);
    expect(textOf(tester, hoursField), '6');
    expect(textOf(tester, minutesField), '30');
    expect(tester.widget<FilledButton>(saveButton).onPressed, isNotNull);
  });

  testWidgets('records work on another day picked in the calendar', (tester) async {
    final workLogApi = FakeWorkLogApi();
    await pumpApp(tester, workLogApi: workLogApi);
    await openSheet(tester);

    await tester.tap(inSheet(find.text('dnes, št 12. 11.')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('10'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(inSheet(find.text('ut 10. 11.')), findsOneWidget);
    await type(tester, hours: '2', minutes: '');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(workLogApi.recorded.single, (DateTime(2026, 11, 10), 120));
  });

  testWidgets('offers no days after today', (tester) async {
    await pumpApp(tester);
    await openSheet(tester);

    await tester.tap(inSheet(find.text('dnes, št 12. 11.')));
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
