import 'package:earnings_tracker/work_logs/work_log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/fake_work_log_api.dart';
import '../support/pump_app.dart';
import '../support/work_log_json.dart';

/// Slovak formatting separates thousands and the currency sign with a no-break space.
const nbsp = ' ';

Finder get sheet => find.byKey(const Key('work-log-sheet'));

Finder inSheet(Finder matching) => find.descendant(of: sheet, matching: matching);

Finder get hoursField => inSheet(find.widgetWithText(TextField, 'Hodiny'));

Finder get minutesField => inSheet(find.widgetWithText(TextField, 'Minúty'));

Finder get saveButton => inSheet(find.widgetWithText(FilledButton, 'Uložiť'));

Finder get deleteButton => inSheet(find.byTooltip('Zmazať'));

Finder get dialog => find.byType(AlertDialog);

String textOf(WidgetTester tester, Finder field) => tester.widget<TextField>(field).controller!.text;

/// Recorded at 30 EUR/h, before the rate went up to the current 40 EUR/h.
WorkLog oldRateLog() => WorkLog.fromJson(workLogJson('a1', '2026-11-11', 390, '195.00', rate: '30.00'));

Future<FakeWorkLogApi> openLog(WidgetTester tester, {bool failDeleting = false}) async {
  final api = FakeWorkLogApi([oldRateLog()])..failDeleting = failDeleting;
  await pumpApp(tester, location: '/work-logs', workLogApi: api);
  await tester.tap(find.byKey(const Key('work-log-a1')));
  await tester.pumpAndSettle();
  return api;
}

void main() {
  testWidgets('opens the work log filled in, previewed at its own rate', (tester) async {
    await openLog(tester);

    expect(inSheet(find.text('Upraviť záznam')), findsOneWidget);
    expect(inSheet(find.text('st 11. 11.')), findsOneWidget);
    expect(textOf(tester, hoursField), '6');
    expect(textOf(tester, minutesField), '30');
    expect(inSheet(find.text('= 195$nbsp€ pri 30$nbsp€ / h')), findsOneWidget);
  });

  testWidgets('saves the changed time and refreshes the list', (tester) async {
    final api = await openLog(tester);
    final loads = api.requestedRanges.length;

    await tester.enterText(hoursField, '7');
    await tester.pump();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(api.updated.single, ('a1', DateTime(2026, 11, 11), 450));
    expect(api.recorded, isEmpty);
    expect(sheet, findsNothing);
    expect(find.text('Záznam upravený.'), findsOneWidget);
    expect(api.requestedRanges.length, greaterThan(loads));
    expect(find.descendant(of: find.byKey(const Key('work-log-a1')), matching: find.text('7 h 30 min')), findsOneWidget);
  });

  testWidgets('deletes the work log after confirmation', (tester) async {
    final api = await openLog(tester);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    expect(find.descendant(of: dialog, matching: find.text('Zmazať záznam?')), findsOneWidget);
    await tester.tap(find.descendant(of: dialog, matching: find.text('Zmazať')));
    await tester.pumpAndSettle();

    expect(api.deleted, ['a1']);
    expect(sheet, findsNothing);
    expect(find.text('Záznam zmazaný.'), findsOneWidget);
    expect(find.byKey(const Key('work-log-a1')), findsNothing);
  });

  testWidgets('keeps the work log when deleting is cancelled', (tester) async {
    final api = await openLog(tester);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: dialog, matching: find.text('Zrušiť')));
    await tester.pumpAndSettle();

    expect(api.deleted, isEmpty);
    expect(dialog, findsNothing);
    expect(sheet, findsOneWidget);
  });

  testWidgets('keeps the sheet open when deleting fails', (tester) async {
    await openLog(tester, failDeleting: true);

    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: dialog, matching: find.text('Zmazať')));
    await tester.pumpAndSettle();

    expect(sheet, findsOneWidget);
    expect(inSheet(find.text('Zmazanie zlyhalo.')), findsOneWidget);
  });

  testWidgets('offers no delete when recording new work', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Zapísať prácu'));
    await tester.pumpAndSettle();

    expect(deleteButton, findsNothing);
  });

  testWidgets('lets the calendar reach a work log older than a year', (tester) async {
    final old = WorkLog.fromJson(workLogJson('o1', '2025-06-02', 60, '30.00', rate: '30.00'));
    await pumpApp(tester, location: '/work-logs', workLogApi: FakeWorkLogApi([old]));
    await tester.tap(find.byKey(const Key('work-log-o1')));
    await tester.pumpAndSettle();

    await tester.tap(inSheet(find.text('po 2. 6.')));
    await tester.pumpAndSettle();

    final picker = tester.widget<DatePickerDialog>(find.byType(DatePickerDialog));
    expect(picker.firstDate, DateTime(2025, 6, 2));
  });
}
